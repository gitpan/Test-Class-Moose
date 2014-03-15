package Test::Class::Moose::Load;
$Test::Class::Moose::Load::VERSION = '0.52';
# ABSTRACT: Load L<Test::Class::Moose> classes automatically.

use strict;
use warnings;

use File::Find;
use File::Spec;

# Override to get your own filter
sub is_test_class {
    my ( $class, $file, $dir ) = @_;
    # By default, we only care about .pm files
    if ($file =~ /\.pm$/) {
        return 1;
    }
    return;
}

my %Added_to_INC;
sub _load {
    my ( $class, $file, $dir ) = @_;

    $file =~ s{\.pm$}{};             # remove .pm extension
    $file =~ s{\\}{/}g;              # to make win32 happy
    $dir  =~ s{\\}{/}g;              # to make win32 happy
    $file =~ s/^$dir//;
    my $_package = join '::' => grep $_ => File::Spec->splitdir( $file );

    # untaint that puppy!
    my ( $package ) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;
   
    # Filter out bad classes (mainly this means things in .svn and similar)
    return unless defined $package;

    unshift @INC => $dir unless $Added_to_INC{ $dir }++;

    # either "require" it or "use" it with no import list. Otherwise, this
    # module will inherit from Test::Class::Moose and break everything.
    eval "use $package ()"; ## no critic
    die $@ if $@;
}

sub import {
    my ( $class, @directories ) = @_;

    foreach my $dir ( @directories ) {
        $dir = File::Spec->catdir( split '/', $dir );
        find(
            {   no_chdir => 1,
                wanted   => sub {
                    my @args = ($File::Find::name, $dir);
                    if ($class->is_test_class(@args)) {
                        $class->_load(@args);
                    }
                },
            },
            $dir
        );
    }
}

1;

__END__

=pod

=cut
