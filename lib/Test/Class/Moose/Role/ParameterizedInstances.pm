package Test::Class::Moose::Role::ParameterizedInstances;
$Test::Class::Moose::Role::ParameterizedInstances::VERSION = '0.58';
# ABSTRACT: run tests against multiple instances of a test class

use Moose::Role;

requires '_constructor_parameter_sets';

sub _tcm_make_test_class_instances {
    my ( $class, $args ) = @_;

    my %base_args = %{$args};

    my %sets = $class->_constructor_parameter_sets;
    return map { $_ => $class->new( %{ $sets{$_} }, %base_args ) }
        keys %sets;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role::ParameterizedInstances - run tests against multiple instances of a test class

=head1 VERSION

version 0.58

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
