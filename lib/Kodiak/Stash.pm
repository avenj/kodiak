package Kodiak::Stash;
use strict; use warnings;

use Carp ();
use Scalar::Util ();

sub new {
  bless +{@_[1 .. $#_] }, $_[0]
}

sub clone {
  my ($self) = @_;
  bless +{%$self}, Scalar::Util::blessed($self)
}

sub export { %{ $_[0] } }

sub get {
  @_ > 2 ? @{ $_[0] }{ @_[1 .. $#_] } : $_[0]->{ $_[1] }
}

sub set {
  my $self = shift;
  my @keysidx = grep {; not $_ % 2 } 0 .. $#_;
  my @valsidx = grep {; $_ % 2 }     0 .. $#_;
  @{$self}{ @_[@keysidx] } = @_[@valsidx];
  $self
}

sub delete {
  CORE::delete @{ $_[0] }{ @_[1 .. $#_] }
}

sub keys {
  CORE::keys %{ $_[0] }
}

sub values {
  CORE::values %{ $_[0] }
}

1;
