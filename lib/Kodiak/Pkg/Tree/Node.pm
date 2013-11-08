package Kodiak::Pkg::Tree::Node;
use strict; use warnings;
use Carp 'confess';

use Kodiak::Base;

has atom     => sub { undef };  # $cat/$pkg-$vers/$slot
has depends  => sub { [] };

sub add_depends {
  my ($self, $node) = @_;
  confess "Expected a Kodiak::Pkg::Tree::Node"
    unless defined $node and $node->isa('Kodiak::Pkg::Tree::Node');

  push @{ $self->depends }, $node;

  $self
}


1;
