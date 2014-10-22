package Test::Class::Moose::Role::Executor;
$Test::Class::Moose::Role::Executor::VERSION = '0.58';
# ABSTRACT: Common code for Runner classes

use 5.10.0;
use Moose::Role 2.0000;
use Carp;
use namespace::autoclean;

use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);
use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::Moose::Config;
use Test::Class::Moose::Report;
use Test::Class::Moose::Report::Instance;
use Test::Class::Moose::Report::Method;
use Test::Class::Moose::AttributeRegistry;

requires 'runtests';

has 'test_configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'test_report' => (
    is      => 'rw',
    isa     => 'Test::Class::Moose::Report',
    writer  => '__set_test_report',
    builder => '_build_test_report',
);

sub _build_test_report {
    my $self = shift;

    # XXX - This isn't very elegant and won't work well in the face of other
    # types of Executors. However, the real fix is to make parallel reporting
    # actually work so the report doesn't have to care about this.
    return Test::Class::Moose::Report->new(
        is_parallel => (ref $self) =~ /::Parallel$/ ? 1 : 0,
    );
}

sub _tcm_run_test_class {
    my ( $self, $test_class ) = @_;

    return sub {
        local *__ANON__ = 'ANON_TCM_RUN_TEST_CLASS';

        my %test_instances
            = $test_class->_tcm_make_test_class_instances(
            $self->test_configuration->args );

        foreach my $test_instance_name (sort keys %test_instances) {
            my $test_instance = $test_instances{$test_instance_name};

            if ( values %test_instances > 1 ) {
                $self->test_configuration->builder->subtest(
                    $test_instance_name,
                    sub {
                        $self->_tcm_run_test_instance(
                            $test_instance_name,
                            $test_instance,
                        );
                    },
                );
            }
            else {
                $self->_tcm_run_test_instance(
                    $test_instance_name,
                    $test_instance,
                );
            }
        }
    };
}

sub _tcm_run_test_instance {
    my ( $self, $test_instance_name, $test_instance ) = @_;

    my $config  = $self->test_configuration;
    my $builder = $config->builder;
    my $report  = $self->test_report;

    $test_instance->__set_test_report($report);

    # set up test class reporting
    my $instance_report = Test::Class::Moose::Report::Instance->new(
        {   name => $test_instance_name,
        }
    );
    $report->add_test_instance($instance_report);

    my @test_methods = $self->_tcm_test_methods_for_instance($test_instance);

    unless (@test_methods) {
        my $message = "Skipping '$test_instance_name': no test methods found";
        $instance_report->skipped($message);
        $instance_report->passed(1);
        $builder->plan( skip_all => $message );
        return;
    }
    $instance_report->_start_benchmark;

    $report->_inc_test_methods( scalar @test_methods );

    # startup
    if (!$self->_tcm_run_test_control_method(
            $test_instance, 'test_startup', $instance_report
        )
      )
    {
        fail "test_startup failed";
        return;
    }

    if ( my $message = $test_instance->test_skip ) {

        # test_startup skipped the class
        $instance_report->skipped($message);
        $builder->plan( skip_all => $message );
        return;
    }

    $builder->plan( tests => scalar @test_methods );

    # run test methods

    my $all_passed = 1;
    foreach my $test_method (@test_methods) {
        my $report_method = $self->_tcm_run_test_method(
            $test_instance,
            $test_method,
            $instance_report,
        );
        $report->_inc_tests( $report_method->num_tests_run );
        $all_passed = 0 if not $report_method->passed;
    }
    $instance_report->passed($all_passed);

    # shutdown
    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_shutdown',
        $instance_report,
    ) or $instance_report->passed( fail("test_shutdown() failed") );

    # finalize reporting
    $instance_report->_end_benchmark;
    if ( $config->show_timing ) {
        my $time = $instance_report->time->duration;
        $builder->diag("$test_instance_name: $time");
    }
    return $instance_report;
}

sub _tcm_test_methods_for_instance {
    my ( $self, $test_instance ) = @_;

    my @filtered = $self->_tcm_filtered_test_methods($test_instance);
    return uniq(
        $self->test_configuration->randomize
        ? shuffle(@filtered)
        : sort @filtered
    );
}

sub _tcm_filtered_test_methods {
    my ( $self, $test_instance ) = @_;

    my @method_list = $test_instance->test_methods;
    if ( my $include = $self->test_configuration->include ) {
        @method_list = grep {/$include/} @method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude ) {
        @method_list = grep { !/$exclude/ } @method_list;
    }

    return $self->_tcm_filter_by_tag(
        $test_instance->test_class,
        \@method_list
    );
}

sub _tcm_filter_by_tag {
    my ( $self, $class, $methods ) = @_;

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

sub _tcm_run_test_control_method {
    my ( $self, $test_instance, $phase, $report_object ) = @_;

    $TEST_CONTROL_METHODS->()->{$phase}
      or croak("Unknown test control method ($phase)");

    my $success;
    my $builder = $self->test_configuration->builder;
    try {
        my $num_tests = $builder->current_test;
        $test_instance->$phase($report_object);
        if ( $builder->current_test ne $num_tests ) {
            croak("Tests may not be run in test control methods ($phase)");
        }
        $success = 1;
    }
    catch {
        my $error = $_;
        my $class = $test_instance->test_class;
        $builder->diag("$class->$phase() failed: $error");
    };
    return $success;
}

sub _tcm_run_test_method {
    my ( $self, $test_instance, $test_method, $instance_report ) = @_;

    my $report  = Test::Class::Moose::Report::Method->new(
        { name => $test_method, instance_report => $instance_report } );

    $self->test_report->current_class->add_test_method($report);
    my $config = $self->test_configuration;

    my $builder = $config->builder;
    $test_instance->test_skip_clear;
    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_setup',
        $report
    ) or fail "test_setup failed";
    my $num_tests;

    my $test_class = $test_instance->test_class;
    Test::Most::explain("$test_class->$test_method()");
    my $passed = $builder->subtest(
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
                $report->passed(0);
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
    $report->passed($passed);

    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_teardown',
        $report,
    ) or $report->passed(fail "test_teardown failed");
    if ( !$report->is_skipped ) {
        $report->num_tests_run($num_tests);
        if ( !$report->has_plan ) {
            $report->tests_planned($num_tests);
        }
    }
    return $report;
}

sub test_classes {
    my $self = shift;

    if ( my $classes = $self->test_configuration->test_classes ) {
        if (@$classes) {    # ignore it if the array is empty
            return @$classes;
        }
    }

    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    foreach my $class ( keys %metaclasses ) {
        next if $class eq 'Test::Class::Moose';
        push @classes => $class if $class->isa('Test::Class::Moose');
    }

    # eventually we'll want to control the test class order
    return sort @classes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role::Executor - Common code for Runner classes

=head1 VERSION

version 0.58

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
