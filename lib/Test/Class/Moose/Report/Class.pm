package Test::Class::Moose::Report::Class;
$Test::Class::Moose::Report::Class::VERSION = '0.52';
# ABSTRACT: Reporting on test classes

use Moose;
use Carp;
use namespace::autoclean;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_methods => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Method]',
    default => sub { [] },
    handles => {
        all_test_methods => 'elements',
        add_test_method  => 'push',
        num_test_methods => 'count',
    },
);

has 'error' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_error',
);

sub current_method {
    my $self = shift;
    return $self->test_methods->[-1];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=cut
