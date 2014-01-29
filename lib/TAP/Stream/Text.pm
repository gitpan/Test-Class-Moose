package TAP::Stream::Text;
$TAP::Stream::Text::VERSION = '0.43';
# ABSTRACT: Experimental TAP stream builder for parallel tests

use Moose;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub tap_to_string { shift->text }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::Stream::Text - Experimental TAP stream builder for parallel tests

=head1 VERSION

version 0.43

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
