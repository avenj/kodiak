package Kodiak::Pkg::Tree;
use strict; use warnings;
use Carp;

use Kodiak::Base;
use Kodiak::Pkg::Tree::Node;

has _root => sub {
  Kodiak::Pkg::Tree::Node->new(
    atom => 'ROOT',
  );
};

has scheduled => sub { [] };


sub __resolve {
  my ($node, $resolved, $unresolved) = @_;
  $unresolved->{ $node->atom } = 1;
  DEP: for my $edge (@{ $node->depends }) {
    next DEP if first {; $_ == $edge } @$resolved;
    if (exists $unresolved->{ $edge->atom }) {
      confess "Circular dependency detected: ",
        $node->name, ' -> ', $edge->name
    }
    __resolve($edge, $resolved, $unresolved)
  }

  push @$resolved, $node;
  delete $unresolved->{ $node->atom }
}

sub _order_deps {
  my ($self) = @_;
  my $scheduled = [];
  __resolve( $self->_root, $scheduled, [] );
  $self->scheduled( $scheduled );
}


sub new_node_for {
  my ($self, $pkg) = @_;
  # FIXME factory method to create nodes for $pkg objects
}

sub add_pkg {
  my ($self, @nodes) = @_;
  $self->_root->add_depends($_) for @nodes;
  # FIXME reorder the tree
}

sub remove_pkg {
  # FIXME remove a node from _root (if possible)
  #  & reorder the tree
}



1;
