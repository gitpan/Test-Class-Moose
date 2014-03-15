package Test::Class::Moose::Role;
$Test::Class::Moose::Role::VERSION = '0.52';
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

=cut
