package Test::Class::Moose::Role;
{
  $Test::Class::Moose::Role::VERSION = '0.41';
}

#ABSTRACT : Test::Class::Moose for roles

use 5.10.0;
use Carp qw/carp croak cluck/;

use Test::Class::Moose::TagRegistry;

our $NO_CAN_HAZ_ATTRIBUTES;
BEGIN {
    eval "use Sub::Attribute";
    unless($NO_CAN_HAZ_ATTRIBUTES = $@){
        eval <<'DECLARE_ATTRIBUTE';
        sub Tags : ATTR_SUB {
            my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

            my @tags;
            if ($data) {
                $data =~ s/^\s+//g;
                @tags = split /\s+/, $data;
            }

            if ( $symbol eq 'ANON' ) {
                die "Cannot tag anonymous subs at file $file, line $line\n";
            }

            my $method = *{ $symbol }{ NAME };

            {           # block for localising $@
                local $@;

                Test::Class::Moose::TagRegistry->add(
                    $class,
                    $method,
                    \@tags,
                );
                if ( $@ ) {
                    croak "Error in adding tags: $@";
                }
            }
        }
DECLARE_ATTRIBUTE
        $NO_CAN_HAZ_ATTRIBUTES = $@;
    }    
}


sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;


    my $preamble = <<"END";
package $caller;
use Moose::Role;
use Test::Most;

use strict;
use warnings;

use Carp;
use Data::Dumper;
END

    unless ($NO_CAN_HAZ_ATTRIBUTES) {
        $preamble .= "use Sub::Attribute;\n";   
    }
    eval $preamble;
    unless ($NO_CAN_HAZ_ATTRIBUTES) {
        no strict "refs";	    
    	*{"$caller\::Tags"} = \&Tags;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role

=head1 VERSION

version 0.41

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
