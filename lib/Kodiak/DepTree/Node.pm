package Kodiak::DepTree::Node;
use Kodiak::Base;


has atom     => sub { undef };  # $cat/$pkg-$vers/$slot
has depends  => sub { [] };
has payload  => sub { };


sub add_depends {
  my ($self, $node) = @_;
  confess "Expected a Kodiak::DepTree::Node"
    unless blessed $node and $node->isa('Kodiak::DepTree::Node');

  push @{ $self->depends }, $node;

  $self
}


1;
