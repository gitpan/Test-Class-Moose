package Test::Class::Moose::Role::Reporting;
$Test::Class::Moose::Role::Reporting::VERSION = '0.54';
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

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role::Reporting - Reporting gathering role

=head1 VERSION

version 0.54

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Timing>.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<name>

The "name" of the statistic. For a class, this should be the class name. For a
method, it should be the method name.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<time>

(From L<Test::Class::Moose::Role::Timing>)

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
