package Test::Class::Moose::Role::AutoUse;
$Test::Class::Moose::Role::AutoUse::VERSION = '0.52';
# ABSTRACT: Automatically load the classes you're testing

use Moose::Role;
use Carp 'confess';

has 'class_name' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    builder => '_build_class_name',
);

sub _build_class_name {
    my $test = shift;

    my $name = $test->get_class_name_to_use or return;

    eval "use $name";
    if ( my $error = $@ ) {
        confess("Could not use $name: $error");
    }
    return $name;
}

sub get_class_name_to_use {
    my $test = shift;
    my $name = ref $test;
    $name =~ s/^[^:]+:://;
    return $name;
}

1;

=pod

=cut

__END__


1;
