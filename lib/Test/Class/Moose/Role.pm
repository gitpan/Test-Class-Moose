package Test::Class::Moose::Role;
$Test::Class::Moose::Role::VERSION = '0.54';
# ABSTRACT: Test::Class::Moose for roles

use 5.10.0;
use Carp;

use Sub::Attribute;
use Test::Class::Moose::AttributeRegistry;

BEGIN {
    require Test::Class::Moose;
    eval Test::Class::Moose->__create_attributes;
    croak($@) if $@;
}

sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;

    my $preamble = <<"END";
package $caller;
use Moose::Role;
use Test::Most;
use Sub::Attribute;
END

    eval $preamble;
    croak($@) if $@;
    no strict "refs";
    *{"$caller\::Tags"}  = \&Tags;
    *{"$caller\::Test"}  = \&Test;
    *{"$caller\::Tests"} = \&Tests;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role - Test::Class::Moose for roles

=head1 VERSION

version 0.54

=head1 DESCRIPTION

If you need the functionality of L<Test::Class::Moose> to be available inside
of a role, this is the module to do that. This is how you can declare a TCM
role:

    package TestsFor::Basic::Role;

    use Test::Class::Moose::Role;

    sub test_in_a_role {
        my $test = shift;

        pass "This is picked up from role";
    }


    sub in_a_role_with_tags : Tags(first){
        fail "We should never see this test";
    }


    sub test_in_a_role_with_tags : Tags(second){
        pass "We should see this test";
    }

    1;

And to consume it:

    package TestsFor::Basic::WithRole;
    use Test::Class::Moose;

    with qw/TestsFor::Basic::Role/;

    sub test_in_withrole {
        pass "Got here";
    }

    1;

Note that this cannot be consumed into classes and magically make them into
test classes. You must still (at the present time) inherit from
C<Test::Class::Moose> to create a test suite.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
