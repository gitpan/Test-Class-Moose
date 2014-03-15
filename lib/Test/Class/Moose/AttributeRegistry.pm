package Test::Class::Moose::AttributeRegistry;
$Test::Class::Moose::AttributeRegistry::VERSION = '0.52';
## ABSTRACT: Global registry of tags by class and method.

use strict;
use warnings;

use Carp;
use Class::MOP;
use List::MoreUtils qw( any uniq );

my %BY_METHOD = (
    tags => {}, # {$method}{$test_class}
    plans => {},
);

sub add_plan {
    my ( $class, $test_class, $method, $plan ) = @_;
    if ( defined $plan ) {
        $plan =~ s/\D//g;
        undef $plan unless $plan =~ /\d/; # no_plan
    }
    $BY_METHOD{plans}{$method}{$test_class} = $plan;
}

sub get_plan {
    my ( $class, $test_class, $method ) = @_;
    return $BY_METHOD{plans}{$method}{$test_class};
}

sub has_test_attribute {
    my ( $class, $test_class, $method ) = @_;
    return exists $BY_METHOD{plans}{$method}{$test_class};
}

sub add_tags {
    my ( $class, $test_class, $method, $tags ) = @_;

    my @tags_copy = @{$tags};

    # check for additions or deletions to the inherited tag list
    if (any { /^[-+]/ } @tags_copy) {
        @tags_copy = $class->_augment_tags($test_class, $method, $tags);
    }

    foreach my $tag ( @tags_copy ) {
        if ( $tag !~ /^\w+$/ ) {
            die "tags must be alphanumeric\n";
        }
    }

    # dedupe tags
    my %tags = map { $_ => 1 } @tags_copy;

    if (exists $BY_METHOD{tags}{$method} && exists $BY_METHOD{tags}{$method}{$test_class}) {
        die
          "tags for $test_class->$method already exists, method redefinition perhaps?\n";
    }

    $BY_METHOD{tags}{$method}{$test_class} = \%tags;

    return;
}

sub tags {
    my @tags;
    for my $method ( keys %BY_METHOD ) {
        for my $test_class ( keys %{ $BY_METHOD{tags}{$method} } ) {
            push @tags, keys %{ $BY_METHOD{tags}{$method}{$test_class} };
        }
    }

    return sort( uniq(@tags) );
}

sub class_has_tag {
    my ( $class, $test_class, $tag ) = @_;

    croak("no class specified") if not defined $test_class;
    croak("no tag specified")   if not defined $tag;

    # XXX a naïve implementation, but it does the job for now.
    my $test_class_meta = Class::MOP::Class->initialize($test_class);
    foreach my $method ( $test_class_meta->get_all_method_names ) {
        next unless $method =~ /test_/;
        return 1 if $class->method_has_tag( $test_class, $method, $tag );
    }
    return;
}

sub method_has_tag {
    my ( $class, $test_class, $method, $tag ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;
    croak("no tag specified")    if not defined $tag;

    # avoid auto-vivication
    return if not exists $BY_METHOD{tags}{$method};

    if (not exists $BY_METHOD{tags}{$method}{$test_class}) {
        # If this method has no tag data at all, then inherit the tags from
        # from the superclass
        $BY_METHOD{tags}{$method}{$test_class} = $class->_superclass_tags($test_class, $method);
    }

    return exists $BY_METHOD{tags}{$method}{$test_class}{$tag};
}

sub _superclass_tags {
    my ( $class, $test_class, $method ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;

    return {} if not exists $BY_METHOD{tags}{$method};

    my $test_class_meta = Class::MOP::Class->initialize($test_class);
    my $method_meta;
    
    $method_meta = $test_class_meta->find_next_method_by_name($method)
    	if $test_class_meta->can('find_next_method_by_name');

    if(!$method_meta){
	#Might be a from a role or this class
	my $mm = $test_class_meta->find_method_by_name($method);
	my $orig = $mm->original_method;

	if($orig && ($mm->package_name ne $orig->package_name)){
		$method_meta = $orig;
	}
    }

    # no method, so no tags to inherit
    return {} if not $method_meta;

    my $super_test_class = $method_meta->package_name();
    if ( exists $BY_METHOD{tags}{$method}{$super_test_class} ) {
        # shallow copy the superclass method's tags, because it's possible to
        # change add/remove items from the subclass's list later
        my %tags = map { $_ => 1 } keys %{ $BY_METHOD{tags}{$method}{$super_test_class} };
        return \%tags;
    }

    # nothing defined at this level, recurse
    return $class->_superclass_tags($super_test_class, $method);
}

sub _augment_tags {
    my ( $class, $test_class, $method, $tags ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;

    # Get the base list from the superclass
    my $tag_list = $class->_superclass_tags($test_class, $method);

    for my $tag_definition (@{$tags}) {
        my $direction = substr($tag_definition, 0, 1);
        my $tag = substr($tag_definition, 1);
        if ($direction eq '+') {
            $tag_list->{$tag} = 1;
        }
        elsif ($direction eq '-') {
            # die here if the tag wasn't inherited?
            delete $tag_list->{$tag};
        }
        else {
            die "$test_class->$method attempting to override and modify tags, did you forget a '+'?\n";
        }
    }

    return keys %{$tag_list};
}

1;

__END__

=pod

=cut
