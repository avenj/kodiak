use Test::More;
use strict; use warnings;

use Kodiak::DepTree::Node;
use Kodiak::DepTree;

my $mknode = sub {
  my ($named) = @_;
  Kodiak::DepTree::Node->new(
    atom => $named,
  );
};

my $tree = Kodiak::DepTree->new;

my $nodeA = $mknode->('A');
my $nodeB = $mknode->('B');
my $nodeC = $mknode->('C');
my $nodeD = $mknode->('D');
my $nodeE = $mknode->('E');

$nodeA->add_depends($nodeB); # A deps on B
$nodeA->add_depends($nodeD); # A deps on D
$nodeB->add_depends($nodeC); # B deps on C
$nodeB->add_depends($nodeE); # B deps on E
$nodeC->add_depends($nodeD); # C (and A) dep on D
$nodeC->add_depends($nodeE); # C (and B) dep on E

ok $tree->add_root_nodes($nodeA), 'add_root_nodes single ok';
my @result = map {; $_->atom } @{ $tree->scheduled };
pop @result;  # Remove root of deptree (last item)
is_deeply \@result,
  [ 'D', 'E', 'C', 'B', 'A' ],
  'simple non-circular deps resolved ok'
    or diag explain \@result;

# filtered
my $code = sub { $_->atom eq 'C' ? 0 : 1 };
@result = map {; $_->atom } @{ $tree->filtered_via($code) };
pop @result;
is_deeply \@result,
  [ 'D', 'E', 'B', 'A' ],
  'filtered_via ok'
    or diag explain \@result;

# circular dep
$nodeD->add_depends($nodeB);
eval {; $tree->scheduled };
like $@, qr/Circular dependency/, 'circular dep died ok';

done_testing;
