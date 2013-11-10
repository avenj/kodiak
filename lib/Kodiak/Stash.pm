package Kodiak::Stash;
use strict; use warnings;

use Carp ();
use Scalar::Util ();

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? +{@_} : +{%{$_[0]}} : +{}, 
    ref $class || $class
}

sub clone {
  my ($self) = @_;
  bless +{%$self}, Scalar::Util::blessed($self)
}

sub export { %{ $_[0] } }

sub exists {
  CORE::exists $_[0]->{ $_[1] }
}

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

=pod

=head1 NAME

Kodiak::Stash - Simple object interface to a HASH

=head1 SYNOPSIS

  use Kodiak::Stash;

  my $st = Kodiak::Stash->new(foo => 'bar');

  my $foo = $st->get('foo');

  $set->set(
    foo => 'baz',
    bar => 'quux',
  );

=head1 DESCRIPTION

A simple HASH-based object.

=head2 new

  my $st = Kodiak::Stash->new;

Create a new stash; initial values can be specified:

  my $st = Kodiak::Stash->new(a => 1, b => 2);

=head2 clone

  my $newst = $st->clone;

Clone the current object.

Since L</set> returns the invocant, you can use the following syntax to clone
a stash and alter some values in the new stash at the same time:

  my $newst = $st->clone->set(c => 3, d => 4);

=head2 export

  my %flattened = $st->export;

Returns the contents of the current object as a list.

=head2 get

  my $item  = $st->get('a');
  my @items = $st->get('a', 'b', 'c');

Retrieve values from the stash.

=head2 set

  $obj->set(e => 5, f => 6 );

Set key/value pairs.

C<set> returns the stash object.

=head2 delete

  $obj->delete('a');
  $obj->delete('a', 'b', 'c');

Delete keys from the stash.

=head2 keys

  for my $key ($obj->keys) {
    my $value = $obj->get($key);
    ...
  }

Returns the list of keys present in the current stash object.

=head2 values

  for my $value ($obj->values) {
    ...
  }

Returns the list of values present in the current stash object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
