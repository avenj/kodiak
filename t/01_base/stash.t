use Test::More;
use strict; use warnings;

use Kodiak::Stash;

# bare stash
my $st = Kodiak::Stash->new;
ok $st->keys == 0, 'bare stash has no keys';
ok $st->set(foo => 'bar'), 'single pair set ok';
ok $st->get('foo') eq 'bar', 'single value get ok';

# stash w/ initial values

done_testing;
