package TAP::Stream::Role::ToString;
{
  $TAP::Stream::Role::ToString::VERSION = '0.40';
}

# ABSTRACT: Experimental role for TAP stream builder

use Moose::Role;

requires qw(
    tap_to_string
);
has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Unnamed TAP stream',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::Stream::Role::ToString - Experimental role for TAP stream builder

=head1 VERSION

version 0.40

=head1 DESCRIPTION

See L<TAP::Stream>.

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
