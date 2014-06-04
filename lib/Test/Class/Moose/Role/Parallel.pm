package Test::Class::Moose::Role::Parallel;
$Test::Class::Moose::Role::Parallel::VERSION = '0.55'; # TRIAL
# ABSTRACT: Deprecated parallel runner role - see docs for details

use 5.10.0;
use Moose::Role 2.0000;
use namespace::autoclean;

requires 'runtests';

before runtests => sub {
    warn
        "The Test::Class::Moose::Role::Parallel role is deprecated. Use the new Test::Class::Moose::Runner class instead.";
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role::Parallel - Deprecated parallel runner role - see docs for details

=head1 VERSION

version 0.55

=head1 DESCRIPTION

This role is now deprecated. To run tests in parallel, use the new
L<Test::Class::Moose::Runner> class:

    use Test::Class::Moose::Runner;

    Test::Class::Moose::Runner->new(
        jobs => 4,
    )->runtests();

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
