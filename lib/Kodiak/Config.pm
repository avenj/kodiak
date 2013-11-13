package Kodiak::Config;
use Kodiak::Base;


has [qw/
  paths
/];


sub new {
  my $class  = shift;
  my $params = @_ ? @_ > 1 ? +{@_} : +{%{$_[0]}} : +{}
  my $self = bless $params, $class;

  $self->paths(
    Kodiak::Config::Paths->new( $self->paths )
  ) unless blessed $self->paths;

  $self
}

1;
