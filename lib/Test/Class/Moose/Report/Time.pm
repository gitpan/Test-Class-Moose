package Test::Class::Moose::Report::Time;
$Test::Class::Moose::Report::Time::VERSION = '0.52';
# ABSTRACT: Reporting object for timing

use Moose;
use Benchmark qw(timestr :hireswallclock);
use namespace::autoclean;

has 'real'             => ( is => 'ro', isa => 'Num',       required => 1 );
has 'user'             => ( is => 'ro', isa => 'Num',       required => 1 );
has 'system'           => ( is => 'ro', isa => 'Num',       required => 1 );
has '_children_user'   => ( is => 'ro', isa => 'Num',       required => 1 );
has '_children_system' => ( is => 'ro', isa => 'Num',       required => 1 );
has '_iters'           => ( is => 'ro', isa => 'Num',       required => 1 );
has '_timediff'        => ( is => 'ro', isa => 'Benchmark', required => 1 );

around 'BUILDARGS' => sub {
    my ( $orig, $class, $timediff ) = @_;
    my %args;
    @args{
        qw/
          real
          user
          system
          _children_user
          _children_system
          _iters
          /
      }
      = @$timediff;
    $args{_timediff} = $timediff;
    return $class->$orig(%args);
};

sub duration {
    my $self = shift;
    return timestr( $self->_timediff );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=cut
