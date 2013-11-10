use Test::More;
use strict; use warnings;

use Kodiak::Stash;

# bare stash
my $st = Kodiak::Stash->new;
ok $st->keys == 0, 'bare stash has no keys';
ok $st->set(foo => 'bar'), 'single pair set ok';
ok $st->get('foo') eq 'bar', 'single value get ok';

ok $st->set(bar => 1, baz => 2, quux => 3), 'multi pair set ok';
my @vals = $st->get(qw/bar baz/);
is_deeply \@vals, [ 1, 2 ], 'multi value get ok';

ok $st->exists('bar'), 'exists ok';
ok !$st->exists('nada'), 'negative exists ok';

ok $st->delete(qw/foo bar/), 'delete ok';
is_deeply [ sort $st->keys ], [qw/baz quux/], 'keys ok';
is_deeply [ sort $st->values ], [ 2, 3 ], 'values ok';

# stash w/ initial values
$st = Kodiak::Stash->new(cake => 1, pie => 2);
ok $st->get('pie') == 2, 'stash initialized with correct values';
is_deeply +{ $st->export }, +{ cake => 1, pie => 2 }, 'export ok';
my $cloned = $st->clone;
is_deeply +{ $cloned->export }, +{ cake => 1, pie => 2 }, 'clone ok';

done_testing;
