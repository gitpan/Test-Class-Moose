package Test::Class::Moose::Role::Timing;
{
  $Test::Class::Moose::Role::Timing::VERSION = '0.07';
}

# ABSTRACT: Report timing role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

has '_start_benchmark' => (
    is            => 'rw',
    isa           => 'Benchmark',
    documentation => 'Trusted method for Test::Class::Moose',
);

has '_end_benchmark' => (
    is      => 'rw',
    isa     => 'Benchmark',
    trigger => sub {
        my $self = shift;
        my $time = Test::Class::Moose::Report::Time->new(
            timediff( $self->_end_benchmark, $self->_start_benchmark ) );
        $self->time($time);
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

=head1 NAME

Test::Class::Moose::Role::Timing - Report timing role

=head1 VERSION

version 0.07

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
