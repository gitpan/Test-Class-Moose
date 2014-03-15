package Test::Class::Moose::Role::Reporting;
$Test::Class::Moose::Role::Reporting::VERSION = '0.52';
# ABSTRACT: Reporting gathering role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;
with 'Test::Class::Moose::Role::Timing';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'notes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has skipped => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'is_skipped',
);

1;

__END__

=pod

=cut
