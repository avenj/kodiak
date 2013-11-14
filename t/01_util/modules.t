use Test::More;
use strict; use warnings;

use lib 't/inc';

use Kodiak::Util::Modules ':all';

# external pkg, succeeds
my $succeeds = 'Kodiak::T::ModuleSucceeds';
ok load_package($succeeds) eq $succeeds, 'load_package ok';

ok $succeeds->foo,                'pkg loaded ok';
ok package_is_loaded($succeeds),  'package_is_loaded ok';
ok unload_package($succeeds),     'unload_package ok';
ok !package_is_loaded($succeeds), 'pkg cleaned up ok';
ok !$succeeds->can('foo'),        'pkg cleaned up ok';

# external pkg, fails
my $failing = 'Kodiak::T::ModuleFails';

eval {; load_package($failing) };
like $@, qr/^Failed to load/,    'load_package threw exception';
ok !package_is_loaded($failing), 'negative package_is_loaded';

my $died = load_or_return_error($failing);
like $died, qr/explicit/, 'load_or_return_error ok';

# inline pkg
{ package Kodiak::T::Inline::Foo;
  use strict; use warnings;
  sub bar {}
}
{ package Kodiak::T::Inline;
  use strict; use warnings;
  sub foo {}
};
my $inline = 'Kodiak::T::Inline';
ok load_package($inline),   'inline pkg load returned ok';
ok !!$inline->can('foo'),   'inline pkg can foo()';
ok unload_package($inline), 'inline pkg unload ok';
ok !$inline->can('foo'),    'inline pkg unloaded successfully';
ok !!Kodiak::T::Inline::Foo->can('bar'),
  'did not accidentally kill namespace';

done_testing;
