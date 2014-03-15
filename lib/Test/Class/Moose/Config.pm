package Test::Class::Moose::Config;
$Test::Class::Moose::Config::VERSION = '0.52';
# ABSTRACT: Configuration information for Test::Class::Moose

use 5.10.0;
use Moose;
use Moose::Util::TypeConstraints;
use TAP::Formatter::Color;
use namespace::autoclean;

subtype 'ArrayRefOfStrings', as 'Maybe[ArrayRef[Str]]';

coerce 'ArrayRefOfStrings', from 'Str', via { defined($_) ? [$_] : undef };

has 'show_timing' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        if ( $_[0]->use_environment and $ENV{HARNESS_IS_VERBOSE} ) {
            return 1;
        }
        return;
    },
);

has 'builder' => (
    is      => 'ro',
    isa     => 'Test::Builder',
    default => sub {
        Test::Builder->new;
    },
);

has 'statistics' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        if ( $_[0]->use_environment and $ENV{HARNESS_IS_VERBOSE} ) {
            return 1;
        }
        return;
    },
);

has 'use_environment' => (
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

has 'include_tags' => (
    is      => 'ro',
    isa     => 'ArrayRefOfStrings',
    coerce  => 1,
    clearer => 'clear_include_tags',
);

has 'exclude_tags' => (
    is      => 'ro',
    isa     => 'ArrayRefOfStrings',
    coerce  => 1,
    clearer => 'clear_exclude_tags',
);

has 'test_classes' => (
    is     => 'ro',
    isa    => 'ArrayRefOfStrings',
    coerce => 1,
);

has 'jobs' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has '_current_schedule' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => '_has_schedule',
);

has '_color' => (
    is         => 'rw',
    isa        => 'TAP::Formatter::Color',
    lazy_build => 1,
);

sub _build__color {
    return TAP::Formatter::Color->new;
}

sub args {
    my $self = shift;

    return {
        map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
        map { $_->name } $self->meta->get_all_attributes
    };
}

sub running_in_parallel {
    my $self = shift;
    return $self->jobs > 1 && $self->_has_schedule;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=cut

__END__


1;
