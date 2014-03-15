package Test::Class::Moose::Report::Method;
$Test::Class::Moose::Report::Method::VERSION = '0.52';
# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
use Test::Class::Moose::AttributeRegistry;

with qw(
  Test::Class::Moose::Role::Reporting
);

has 'report_class' => (
    is       => 'ro',
    isa      => 'Test::Class::Moose::Report::Class',
    required => 1,
    weak_ref => 1,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub tests_run {
    carp "tests_run() deprecated as of version 0.07. Use num_tests_run().";
    goto &num_tests_run;
}

has 'tests_planned' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_plan',
);

sub plan {
    my ( $self, $integer ) = @_;
    $self->tests_planned( ( $self->tests_planned || 0 ) + $integer );
}

sub add_to_plan {
    my ( $self, $integer ) = @_;
    carp("add_to_plan() is deprecated. You can now call plan() multiple times");
    return $self->plan($integer);
}

sub has_tag {
    my ( $self, $tag ) = @_;
    croak("has_tag(\$tag) requires a tag name") unless defined $tag;
    my $report_class = $self->report_class->name;
    my $method       = $self->name;
    return Test::Class::Moose::AttributeRegistry->method_has_tag( $report_class, $method, $tag );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=cut
