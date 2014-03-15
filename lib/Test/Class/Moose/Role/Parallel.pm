package Test::Class::Moose::Role::Parallel;
$Test::Class::Moose::Role::Parallel::VERSION = '0.52';
# ABSTRACT: run tests in parallel (highly experimental)

use Moose::Role;
use Parallel::ForkManager;
use Test::Builder;
use TAP::Stream;
use Test::Class::Moose::AttributeRegistry;
use Carp;

has 'color_output' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

my $run_job = sub {
    my ( $self, $orig ) = @_;

    my $builder = Test::Builder->new;

    my $output;
    $builder->output( \$output );
    $builder->failure_output( \$output );
    $builder->todo_output( \$output );

    $self->$orig;

    return $output;
};

around 'runtests' => sub {
    my $orig = shift;
    my $self = shift;

    my $jobs = $self->test_configuration->jobs;
    return $self->$orig if $jobs < 2;

    my ( $sequential, @jobs ) = $self->schedule;

    # XXX for some reason, we need to fetch this output handle before forking
    # off jobs. Otherwise, we lose our test builder output if and only if we
    # have a sequential job after the parallel jobs. Weird.
    my $test_builder_output = Test::Builder->new->output;
    my $stream              = TAP::Stream->new;
    my $fork                = Parallel::ForkManager->new($jobs);
    $fork->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump,
                $result
            ) = @_;

            if ( defined($result) ) {
                my ( $job_num, $tap ) = @$result;
                $stream->add_to_stream(
                    TAP::Stream::Text->new( text => $tap, name => "Job #$job_num (pid: $pid)" ) );
            }
            else
            { # problems occuring during storage or retrieval will throw a warning
                carp("No TAP received from child process $pid!");
            }
        }
    );

    my $job_num = 0;
    my $config  = $self->test_configuration;
    foreach my $schedule (@jobs) {
        $job_num++;
        my $pid = $fork->start and next;
        $config->_current_schedule($schedule);
        my $output = $self->$run_job($orig);
        $fork->finish( 0, [ $job_num, $output ] );
    }
    $fork->wait_all_children;
    if ($sequential && keys %$sequential) {
        $config->_current_schedule($sequential);
        my $output = $self->$run_job($orig);
        $stream->add_to_stream( TAP::Stream::Text->new(
            text => $output,
            name => 'Sequential tests run after parallel tests',
        ) );
    }

    # this prevents overwriting the line of dots output from
    # $RUN_TEST_CONTROL_METHOD
    print STDERR "\n";

    # this is where we print the TAP results
    print $test_builder_output $stream->to_string;
};

around 'test_classes' => sub {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->test_configuration;
    if ( $config->jobs < 2 or not $config->_has_schedule ) {
        return $self->$orig;
    }
    return sort keys %{ $config->_current_schedule };
};

around 'test_methods' => sub {
    my $orig         = shift;
    my $self         = shift;
    my @test_methods = $self->$orig;
    my $config       = $self->test_configuration;

    if ( $config->jobs < 2 or not $config->_has_schedule ) {
        return @test_methods;
    }
    my $methods_for_jobs = $config->_current_schedule->{ $self->test_class }
      or return;
    
    return grep { $methods_for_jobs->{$_} } @test_methods;
};

after '_tcm_run_test_method' => sub {
    my $self    = shift;
    my $config  = $self->test_configuration;
    my $builder = $config->builder;

    # we're running under parallel testing, so rather than having
    # the code look like it's stalled, we'll output a dot for
    # every test method.
    my ( $color, $text )
      = ( $builder->details )[-1]{ok}
      ? ( 'green', '.' )
      : ( 'red', 'X' );

    # The set_color() method from Test::Formatter::Color is just ugly.
    if ( $self->color_output ) {
        $config->_color->set_color(
            sub { print STDERR shift, $text },
            $color,
        );
        $config->_color->set_color( sub { print STDERR shift }, 'reset' );
    }
    else {
        print STDERR $text;
    }
};

sub schedule {
    my $self   = shift;
    my $config = $self->test_configuration;
    my $jobs   = $config->jobs;
    my @schedule;

    my $current_job = 0;
    my %sequential;
    foreach my $test_class ( $self->test_classes ) {
        my $test_instance = $test_class->new( $config->args );
        METHOD: foreach my $method ( $test_instance->test_methods ) {
            if ( Test::Class::Moose::AttributeRegistry->method_has_tag( $test_class, $method, 'noparallel' ) ) {
                $sequential{$test_class}{$method} = 1;
                next METHOD;
            }

            $schedule[$current_job] ||= {};
            $schedule[$current_job]{$test_class}{$method} = 1;
            $current_job++;
            $current_job = 0 if $current_job >= $jobs;
        }
    }
    unshift @schedule => \%sequential;
    return @schedule;
}

1;

__END__

=pod

=cut
