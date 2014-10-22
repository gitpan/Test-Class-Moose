package Test::Class::Moose::Report::Method;
{
  $Test::Class::Moose::Report::Method::VERSION = '0.20';
}

# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
with qw(
  Test::Class::Moose::Role::Reporting
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Test::Class::Moose::Report::Method - Reporting on test methods

=head1 VERSION

version 0.20

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<num_tests_run>

    my $tests_run = $method->num_tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
