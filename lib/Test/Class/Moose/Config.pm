package Test::Class::Moose::Config;

use 5.10.0;
use Moose;
use namespace::autoclean;

our $VERSION = 0.03;

has 'show_timing' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'builder' => (
    is      => 'ro',
    isa     => 'Test::Builder',
    default => sub {
        Test::Builder->new;
    },
);

has 'statistics' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'test_class' => (
    is  => 'rw',
    isa => 'Str',
);

has 'randomize' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'include' => (
    is  => 'ro',
    isa => 'Regexp',
);

has 'exclude' => (
    is  => 'ro',
    isa => 'Regexp',
);

sub args {
    my $self = shift;

    return {
        map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
        map { $_->name } $self->meta->get_all_attributes
    };
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Test::Class::Moose::Config - Configuration information for Test::Class

=head1 VERSION

0.03

=head1 SYNOPSIS

 my $tc_config = Test::Class::Moose::Config->new({
     show_timing => 1,
     builder     => Test::Builder->new,
     statistics  => 1,
     randomize   => 0,
 });
 my $test_suite = Test::Class::Moose->new($tc_config);

=head1 DESCRIPTION

For internal use only (maybe I'll expose it later). Not guaranteed to be
stable.

This class defines many of the attributes for L<Test::Class::Moose>. They're
kept here to minimize namespace pollution in L<Test::Class::Moose>.

=head1 ATTRIBUTES

=head2 * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=head2 * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=head2 C<builder>

Usually defaults to C<< Test::Builder->new >>, but you could substitute your
own if it conforms to the interface.

=head2 C<randomize>

Boolean. Will run tests in a random order.

=head1 METHODS

=head2 C<args>

 my $tests = Some::Test::Class->new($test_suite->test_configuration->args);

Returns a hash reference of the args used to build the configuration. Used in
testing. You probably won't need it.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-class-moose at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Class-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Class-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Class-Moose/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
