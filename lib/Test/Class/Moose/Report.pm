package Test::Class::Moose::Report;
$Test::Class::Moose::Report::VERSION = '0.52';
# ABSTRACT: Test information for Test::Class::Moose

use 5.10.0;
use Carp;
use Moose;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Timing';

has 'num_test_methods' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_num_test_methods',
    default => 0,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_tests_run',
    default => 0,
);

sub tests_run {
    carp "tests_run() deprecated as of version 0.07. Use num_tests_run().";
    goto &num_tests_run;
}

# see Moose::Meta::Attribute::Native::Trait::Array
has test_classes => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Class]',
    default => sub { [] },
    handles => {
        all_test_classes => 'elements',
        add_test_class   => 'push',
        num_test_classes => 'count',
    },
);

sub _inc_test_methods {
    my ( $self, $test_methods ) = @_;
    $test_methods //= 1;
    $self->set_num_test_methods( $self->num_test_methods + $test_methods );
}

sub _inc_tests {
    my ( $self, $tests ) = @_;
    $tests //= 1;
    $self->set_tests_run( $self->num_tests_run + $tests );
}

sub current_class {
    my $self = shift;
    return $self->test_classes->[-1];
}

sub current_method {
    my $self = shift;
    my $current_class = $self->current_class or return;
    return $current_class->current_method;
}

sub plan {
    my ( $self, $plan ) = @_;
    my $current_method = $self->current_method
        or croak("You tried to plan but we don't have a test method yet!");
    $current_method->plan($plan);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=cut

__END__


1;
