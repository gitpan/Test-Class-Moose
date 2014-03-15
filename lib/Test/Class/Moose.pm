package Test::Class::Moose;
$Test::Class::Moose::VERSION = '0.52';
# ABSTRACT: Test::Class + Moose

use 5.10.0;
use Moose 2.0000;
use MooseX::ClassAttribute;
use Carp;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);
use namespace::autoclean;
use Sub::Attribute;

use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::Moose::Config;
use Test::Class::Moose::Report;
use Test::Class::Moose::Report::Class;
use Test::Class::Moose::Report::Method;
use Test::Class::Moose::AttributeRegistry;

sub __create_attributes {

    # XXX sharing this behavior here because my first attempt at creating a
    # role was a complete failure. MooseX::MethodAttributes can help here, but
    # I have to parse the attributes manually (as far as I can tell) and I
    # don't have the simple declarative style any more.
    return <<'DECLARE_ATTRIBUTES';
    sub Tags : ATTR_SUB {
        my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

        my @tags;
        if ($data) {
            $data =~ s/^\s+//g;
            @tags = split /\s+/, $data;
        }

        if ( $symbol eq 'ANON' ) {
            die "Cannot tag anonymous subs at file $file, line $line\n";
        }

        my $method = *{$symbol}{NAME};

        {    # block for localising $@
            local $@;

            Test::Class::Moose::AttributeRegistry->add_tags(
                $class,
                $method,
                \@tags,
            );
            if ($@) {
                croak "Error in adding tags: $@";
            }
        }
    }

    sub Test : ATTR_SUB {
        my ( $class, $symbol, undef, undef, undef, undef, $file, $line ) = @_;

        if ( $symbol eq 'ANON' ) {
            croak("Cannot add plans to anonymous subs at file $file, line $line");
        }

        my $method = *{$symbol}{NAME};
        if ( $method =~ /^test_(?:startup|setup|teardown|shutdown)$/ ) {
            croak("Test control method '$method' may not have a Test attribute");
        }

        Test::Class::Moose::AttributeRegistry->add_plan(
            $class,
            $method,
            1,
        );
        $class->meta->add_before_method_modifier($method, sub {
            my $test = shift;
            $test->test_report->plan(1);
        });
    }

    sub Tests : ATTR_SUB {
        my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

        if ( $symbol eq 'ANON' ) {
            croak("Cannot add plans to anonymous subs at file $file, line $line");
        }

        my $method = *{$symbol}{NAME};
        if ( $method =~ /^test_(?:startup|setup|teardown|shutdown)$/ ) {
            croak("Test control method '$method' may not have a Test attribute");
        }

        Test::Class::Moose::AttributeRegistry->add_plan(
            $class,
            $method,
            $data,
        );
        if ( defined $data ) {
            $class->meta->add_before_method_modifier($method, sub {
                my $test = shift;
                $test->test_report->plan($data);
            });
        }
    }
DECLARE_ATTRIBUTES
}

BEGIN {
    eval __PACKAGE__->__create_attributes;
    croak($@) if $@;
}

has 'test_configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'test_report' => (
    is      => 'rw',
    isa     => 'Test::Class::Moose::Report',
    writer  => '__set_test_report',
    default => sub { Test::Class::Moose::Report->new },
);

has 'test_class' => (
    is  => 'rw',
    isa => 'Str',
);

has 'test_skip' => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'test_skip_clear',
);

sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;

    my $preamble = <<"END";
package $caller;
use Moose;
use Test::Most;
use Sub::Attribute;
END

    eval $preamble;
    croak($@) if $@;
    strict->import;
    warnings->import;
    if ( my $parent
        = ( delete $arg_for{parent} || delete $arg_for{extends} ) )
    {
        my @parents = 'ARRAY' eq ref $parent ? @$parent : $parent;
        $caller->meta->superclasses(@parents);
    }
    else {
        $caller->meta->superclasses(__PACKAGE__);
    }
}

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    return $class->$orig(
        { test_configuration => Test::Class::Moose::Config->new(@_) } );
};

sub BUILD {
    my $self = shift;

    # stash that name lest something change it later. Paranoid?
    $self->test_class( $self->meta->name );
}

my $TEST_CONTROL_METHODS = sub {
    local *__ANON__ = 'ANON_TEST_CONTROL_METHODS';
    return {
        map { $_ => 1 }
          qw/
          test_startup
          test_setup
          test_teardown
          test_shutdown
          /
    };
};

my $RUN_TEST_CONTROL_METHOD = sub {
    local *__ANON__ = 'ANON_RUN_TEST_CONTROL_METHOD';
    my ( $self, $phase, $report_object ) = @_;

    $TEST_CONTROL_METHODS->()->{$phase}
      or croak("Unknown test control method ($phase)");

    my $success;
    my $builder = $self->test_configuration->builder;
    try {
        my $num_tests = $builder->current_test;
        $self->$phase($report_object);
        if ( $builder->current_test ne $num_tests ) {
            croak("Tests may not be run in test control methods ($phase)");
        }
        $success = 1;
    }
    catch {
        my $error = $_;
        my $class = $self->test_class;
        $builder->diag("$class->$phase() failed: $error");
    };
    return $success;
};

sub _tcm_run_test_method {
    my ( $self, $test_instance, $test_method, $report_class ) = @_;

    my $test_class = $test_instance->test_class;
    my $report  = Test::Class::Moose::Report::Method->new(
        { name => $test_method, report_class => $report_class } );
    $self->test_report->current_class->add_test_method($report);
    my $config = $self->test_configuration;

    my $builder = $config->builder;
    $test_instance->test_skip_clear;
    $test_instance->$RUN_TEST_CONTROL_METHOD(
        'test_setup',
        $report
    ) or fail "test_setup failed";
    my $num_tests;

    Test::Most::explain("$test_class->$test_method()");
    $builder->subtest(
        $test_method,
        sub {
            if ( my $message = $test_instance->test_skip ) {
                $report->skipped($message);
                $builder->plan( skip_all => $message );
                return;
            }
            $report->_start_benchmark;

            my $old_test_count = $builder->current_test;
            try {
                $test_instance->$test_method($report);
                if ( $report->has_plan ) {
                    $builder->plan( tests => $report->tests_planned );
                }
            }
            catch {
                fail "$test_method failed: $_";
            };
            $num_tests = $builder->current_test - $old_test_count;

            $report->_end_benchmark;
            if ( $config->show_timing ) {
                my $time = $report->time->duration;
                $config->builder->diag(
                    $report->name . ": $time" );
            }
        },
    );

    $test_instance->$RUN_TEST_CONTROL_METHOD(
        'test_teardown',
        $report
    ) or fail "test_teardown failed";
    if ( !$report->is_skipped ) {
        $report->num_tests_run($num_tests);
        if ( !$report->has_plan ) {
            $report->tests_planned($num_tests);
        }
    }
    return $report;
}

my $RUN_TEST_CLASS = sub {
    local *__ANON__ = 'ANON_RUN_TEST_CLASS';
    my ( $self, $test_class ) = @_;

    my $config  = $self->test_configuration;
    my $builder = $config->builder;
    my $report  = $self->test_report;

    return sub {

        # set up test class reporting
        my $report_class = Test::Class::Moose::Report::Class->new(
            {   name => $test_class,
            }
        );
        $report->add_test_class($report_class);
        my $test_instance
          = $test_class->new( $config->args );
        $test_instance->__set_test_report($report);

        my @test_methods = $test_instance->test_methods;
        unless (@test_methods) {
            my $message = "Skipping '$test_class': no test methods found";
            $report_class->skipped($message);
            $builder->plan( skip_all => $message );
            return;
        }
        $report_class->_start_benchmark;

        $report->_inc_test_methods( scalar @test_methods );

        # startup
        if (!$test_instance->$RUN_TEST_CONTROL_METHOD(
                'test_startup', $report_class
            )
          )
        {
            fail "test_startup failed";
            return;
        }

        if ( my $message = $test_instance->test_skip ) {

            # test_startup skipped the class
            $report_class->skipped($message);
            $builder->plan( skip_all => $message );
            return;
        }

        $builder->plan( tests => scalar @test_methods );

        # run test methods
        foreach my $test_method (@test_methods) {
            my $report_method = $self->_tcm_run_test_method(
                $test_instance,
                $test_method,
                $report_class,
            );
            $report->_inc_tests( $report_method->num_tests_run );
        }

        # shutdown
        $test_instance->$RUN_TEST_CONTROL_METHOD(
            'test_shutdown',
            $report_class
        ) or fail("test_shutdown() failed");

        # finalize reporting
        $report_class->_end_benchmark;
        if ( $config->show_timing ) {
            my $time = $report_class->time->duration;
            $config->builder->diag("$test_class: $time");
        }
    };
};

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $builder = $self->test_configuration->builder;
    $builder->plan( tests => scalar @test_classes );
    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nRunning tests for $test_class\n\n");
        $builder->subtest(
            $test_class,
            $self->$RUN_TEST_CLASS($test_class),
        );
    }

    $builder->diag(<<"END") if $self->test_configuration->statistics;
Test classes:    @{[ $report->num_test_classes ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END
    $builder->done_testing;
    $report->_end_benchmark;
    return $self;
}

sub test_classes {
    my $self        = shift;

    if ( my $classes = $self->test_configuration->test_classes ) {
        if (@$classes) {    # ignore it if the array is empty
            return @$classes;
        }
    }

    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    foreach my $class ( keys %metaclasses ) {
        next if $class eq __PACKAGE__;
        push @classes => $class if $class->isa(__PACKAGE__);
    }

    # eventually we'll want to control the test class order
    return sort @classes;
}

my $FILTER_BY_TAG = sub {
    my ( $self, $methods ) = @_;
    my $class            = $self->test_class;
    my @filtered_methods = @$methods;
    if ( my $include = $self->test_configuration->include_tags ) {
        my @new_method_list;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$include) {
                if (Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                    push @new_method_list => $method;
                }
            }
        }
        @filtered_methods = @new_method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude_tags ) {
        my @new_method_list = @filtered_methods;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$exclude) {
                if (
                    Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                  @new_method_list = grep { $_ ne $method } @new_method_list;
                }
            }
        };
        @filtered_methods = @new_method_list;
    };
    return @filtered_methods;
};

sub test_methods {
    my $self = shift;

    my @method_list;
    foreach my $method ( $self->meta->get_all_methods ) {

        # attributes cannot be test methods
        next if $method->isa('Moose::Meta::Method::Accessor');

        my $class = ref $self;
        my $name = $method->name;
        next
          unless $name =~ /^test_/
          || Test::Class::Moose::AttributeRegistry->has_test_attribute(
            $class, $name );

        # don't use anything defined in this package
        next if __PACKAGE__->can($name);
        push @method_list => $name;
    }

    if ( my $include = $self->test_configuration->include ) {
        @method_list = grep {/$include/} @method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude ) {
        @method_list = grep { !/$exclude/ } @method_list;
    }

    @method_list = $self->$FILTER_BY_TAG(\@method_list);

    return uniq(
        $self->test_configuration->randomize
        ? shuffle(@method_list)
        : sort @method_list
    );
}

# empty stub methods guarantee that subclasses can always call these
sub test_startup  { }
sub test_setup    { }
sub test_teardown { }
sub test_shutdown { }

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 CONTRIBUTORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Doug Bell <doug.bell@baml.com>

=item *

Doug Bell <madcityzen@gmail.com>

=item *

Gregory Oschwald <goschwald@maxmind.com>

=item *

Jonathan C. Otsuka <djgoku@gmail.com>

=item *

Neil Bowers <neil@bowers.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Ovid <curtis@weborama.com>

=item *

Ovid <curtis_ovid_poe@yahoo.com>

=item *

Paul Boyd <pboyd@dev3l.net>

=item *

Petrea Corneliu Stefan <stefan@garage-coding.com>

=item *

Stuckdownawell <stuckdownawell@gmail.com>

=item *

Tom Beresford <tom.beresford@bskyb.com>

=item *

Tom Heady <tom@punch.net>

=item *

Udo Oji <Velti@signor.com>

=back

=cut

__END__


1;
