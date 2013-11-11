package Kodiak::DepTree;
use Kodiak::Base; no warnings 'recursion';

use Kodiak::DepTree::Node;


# Callback for resolved nodes (useful for manipulating payloads f.ex):
has node_resolved_cb => sub { };


has _root => sub {
  Kodiak::DepTree::Node->new(
    atom => 'ROOT:ROOT:0:0',
  );
};


sub __resolve {
  #  my $result = [];
  #  __resolve( $startnode, $result, +{}, +{} )
  #                                # ^ last two params are discarded later
  my ($self, $node, $resolved, $res_byatom, $unresolved) = @_;
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
    __resolve($self, $edge, $resolved, $res_byatom, $unresolved)
  }

  # Successful resolution;
  # push the node we're operating on to the resolved list,
  # remove its atom from the unresolved list, record the change
  # in the $res_byatom hash for quick checking on further iterations:
  push @$resolved, $node;
  $res_byatom->{ $node->atom } = delete $unresolved->{ $node->atom };

  if (my $code = $self->node_resolved_cb) {
    $code->( $node )
  }
}


sub scheduled {
  my ($self) = shift;
  my $scheduled = [];
  __resolve( $self, $self->_root, $scheduled, +{}, +{} );
  $scheduled
}

sub filtered_via {
  my ($self, $filter) = @_;
  confess "Expected a CODE ref but got $filter"
    unless ref $filter;

  [ grep {; $filter->( $_ ) } @{ $self->scheduled } ]
}


sub add_root_nodes {
  my ($self, @nodes) = @_;
  $self->_root->add_depends($_) for @nodes;
  $self
}


=pod

=head1 NAME

Kodiak::DepTree - Build dependency graphs

=head1 SYNOPSIS

  use Kodiak::DepTree;
  use Kodiak::DepTree::Node;

  sub _mknode {
    my ($named) = @_;
    Kodiak::DepTree->new( atom => $named )
  }

  my $tree = Kodiak::DepTree->new;

  # Create nodes A through E:
  my $node = +{ map $_ => $mknode->($_) } qw/ A B C D E /;

  # Set up some relationships
  # A depends on B and C:
  $node->{A}->add_depends( $node->{B} );
  $node->{A}->add_depends( $node->{D} );
  # B depends on C and E:
  $node->{B}->add_depends( $node->{C} );
  $node->{B}->add_depends( $node->{E} );
  # C depends on E and E:
  $node->{C}->add_depends( $node->{D} );
  $node->{C}->add_depends( $node->{E} );

  # Add start-point node(s) to the tree, in this case 'A':
  $tree->add_root_nodes( $node->{A} );

  # Retrieve ordered dependency schedule:
  for my $node (@{ $tree->scheduled }) {
    my $item_named = $node->atom;
    # ...
  }

=head1 DESCRIPTION

A generic dependency resolver. 

The tree is composed of L<Kodiak::DepTree::Node> objects; see that POD for
details.

=head2 METHODS

=head3 add_root_nodes

  $tree->add_root_nodes( @wanted_nodes );

Add initial nodes to the tree.

=head3 scheduled

  my @nodes = @{ $tree->scheduled };

Resolves the dependency tree and returns an ARRAY containing the ordered list
of nodes.

An exception is thrown if circular dependencies are detected.

Every call to L</scheduled> forces a fresh graph resolution. Node dependencies can
change dynamically, so it is only safe to reuse the L</scheduled> list if
you're sure nodes aren't changing underneath you.

=head3 filtered_via

  my $filter = sub {
    my ($node) = @_;
    # Filter nodes named 'foo':
    return if $node->atom eq 'foo';
    1
  };

  my @nodes = @{ $tree->filtered_via($filter) };

Sugar for forcing a re-schedule & executing a C<grep> against the list in one
call.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

1;
