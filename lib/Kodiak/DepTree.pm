package Kodiak::DepTree;
use Kodiak::Base; no warnings 'recursion';

use Kodiak::DepTree::Node;

has _root => sub {
  Kodiak::DepTree::Node->new(
    atom => 'ROOT:ROOT:0:0',
  );
};

has _scheduled => sub { [] };


# FIXME
#  A 'found new dep' callback sub?

sub __resolve {
  #  my $result = [];
  #  __resolve( $startnode, $result, +{}, +{} )
  #                                # ^ last two params are discarded later
  my ($node, $resolved, $res_byatom, $unresolved) = @_;
  # Add this atom to the unresolved list:
  $unresolved->{ $node->atom } = 1;

  # Walk the dep list for our current node:
  DEP: for my $edge (@{ $node->depends }) {
    # Skip if we've already resolved:
    next DEP if exists $res_byatom->{ $edge->atom };

    # Circular dep if this edge's atom is in the unresolved list:
    if (exists $unresolved->{ $edge->atom }) {
      die "Circular dependency detected: ",
        $node->atom, ' -> ', $edge->atom, "\n"
    }

    # Recurse into dependency's node:
    __resolve($edge, $resolved, $res_byatom, $unresolved)
  }

  # Successful resolution;
  # push the node we're operating on to the resolved list,
  # remove its atom from the unresolved list, record the change
  # in the $res_byatom hash for quick checking on further iterations:
  push @$resolved, $node;
  $res_byatom->{ $node->atom } = delete $unresolved->{ $node->atom };
}

sub _order_deps {
  my ($self) = @_;
  my $scheduled = [];
  __resolve( $self->_root, $scheduled, +{}, +{} );
  $self->_scheduled( $scheduled );
  $self->_scheduled
}


sub scheduled {
  my ($self) = shift;
  $self->_order_deps
}

sub filter_via {
  my ($self, $filter) = @_;
  confess "Expected a CODE ref but got $filter"
    unless ref $filter;

  [ grep {; $filter->( $_ ) } @{ $self->scheduled } ]
}


sub new_node_for {
  # Factory method for creation of new nodes
  my ($self, $pkg) = @_;
  confess "Expected a Kodiak::Pkg but got $pkg"
    unless blessed($pkg)
    and $pkg->isa('Kodiak::Pkg');

  # FIXME needs a complementary implementation in Pkg:
  # FIXME
  #  - Create a Pkg::Tree::Node for this $pkg
  #  - Recursively add dependency mappings:
  #   - Parse $pkg -> Tree::Node
  #    - Parse $pkg deps -> Tree::Nodes
  #     - Parse further deps ... etc
  my $node = Kodiak::DepTree::Node->new(
    atom    => $pkg->atom,
    payload => $pkg,
  );

  for my $atom (@{ $pkg->dependency_atoms }) {
    # FIXME need an API to find pkg by atom, parse, return Pkg obj
    #  flyweight Pkg::Factory?
  }
}

sub add_root_nodes {
  my ($self, @nodes) = @_;
  $self->_root->add_depends($_) for @nodes;
  $self->_order_deps;
  $self
}

sub remove_root_nodes {
  # FIXME remove a node from _root (if possible)
  #  & reorder the tree
}



1;