package Test::Class::Moose::Role::Timing;
$Test::Class::Moose::Role::Timing::VERSION = '0.52';
# ABSTRACT: Report timing role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

# this seems like some serious abuse of attributes. Plus, time() is only set
# as a side-effect of _end_benchmark(). I should rethink this. It's hidden
# from the outside world, but still ...
has '_start_benchmark' => (
    is            => 'rw',
    isa           => 'Benchmark',
    lazy          => 1,
    default       => sub { Benchmark->new },
    documentation => 'Trusted method for Test::Class::Moose',
);

has '_end_benchmark' => (
    is      => 'rw',
    isa     => 'Benchmark',
    lazy    => 1,
    default => sub {
        my $self      = shift;
        my $benchmark = Benchmark->new;
        my $time      = Test::Class::Moose::Report::Time->new(
            timediff( $benchmark, $self->_start_benchmark ) );
        $self->time($time);
        return $benchmark;
    },
    documentation => 'Trusted method for Test::Class::Moose',
);

has 'time' => (
    is  => 'rw',
    isa => 'Test::Class::Moose::Report::Time',
);

1;

__END__

=pod

=cut
