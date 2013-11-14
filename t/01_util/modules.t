use Test::More;
use strict; use warnings;

use lib 't/inc';

use Kodiak::Util::Modules ':all';

# external pkg, succeeds
my $succeeds = 'Kodiak::T::ModuleSucceeds';
ok load_package($succeeds),   'load_package ok';
ok $succeeds->foo,            'pkg loaded ok';
ok unload_package($succeeds), 'unload_package ok';
ok !$succeeds->can('foo'),    'pkg cleaned up ok';

# external pkg, fails
my $failing = 'Kodiak::T::ModuleFails';
eval {; load_package($failing) };
ok $@,                    'load_package threw exception';
ok !$failing->can('foo'), 'failing pkg cleaned up (foo)';
ok !$failing->can('bar'), 'failing pkg cleaned up (bar)';

# inline pkg
{ package Kodiak::T::Inline;
  use strict; use warnings;
  sub foo {}
};
my $inline = 'Kodiak::T::Inline';
ok load_package($inline),   'inline pkg load returned ok';
ok !!$inline->can('foo'),   'inline pkg can foo()';
ok unload_package($inline), 'inline pkg unload ok';
ok !$inline->can('foo'),    'inline pkg unloaded successfully';

done_testing;
