use Test::More;
use strict; use warnings;

use Fcntl ':flock';

use File::Spec;
use File::Temp 'tempfile', 'tempdir';

use Kodiak::DB;

my $workdir = File::Spec->tmpdir;
my $tempdir = tempdir( CLEANUP => 1, DIR => $workdir );

sub _newtemp {
  my ($handle, $name) = tempfile( 'tmpdbXXXXX',
    DIR => $tempdir, UNLINK => 1
  );
  flock $handle, LOCK_UN;
  return ($handle, $name)
}

my ($fh, $path) = _newtemp();
my $db = Kodiak::DB->new(path => $path);

# open()
ok $db->open, 'database open ok';

# is_open()
ok $db->is_open, 'is_open ok';

# return on reopen
{ local *STDERR;
  my $myerr;
  open *STDERR, '+<', \$myerr;
  ok !$db->open, 'cannot reopen open db';
  ok $myerr, 'attempt to reopen warned';
}

# path()
ok $db->path eq $path, 'path attrib ok';

# set()
ok $db->set( test => +{ deep => [ struct => 1 ] } ),
  'ref set ok';

# keys()
ok $db->keys == 1, 'keys count ok';
my $first = ($db->keys)[0];
ok $first eq 'test', 'keys ok';

# exists()
ok $db->exists('test'), 'exists ok';
ok !$db->exists('quux'), 'negative exists ok' for 1 .. 2;

# get()
my $ref = $db->get( 'test' );
is_deeply $ref,
  +{ deep => [ struct => 1 ] },
  'get ok';


# close()
ok $db->close, 'close ok';


# is_open()
ok !$db->is_open, 'is_open false ok';

# reopen / get again
ok $db->open, 'reopened ok';
my $sameref = $db->get( 'test' );
is_deeply $sameref, $ref, 'data preserved ok';

# unicode
ok $db->set(unicode => +{ a => "\x{263A}" }), 'unicode set() ok';
my $utf = $db->get('unicode');
is_deeply $utf,
  +{ a => "\x{263A}" },
  'unicode get() ok';

ok $db->keys == 2, 'keys count ok';

# delete
ok $db->delete('unicode'), 'delete ok';
ok $db->keys == 1, 'keys count ok';
ok !$db->get('unicode'), 'deleted key ok';

$db->close;


# ro open
ok $db->open(ro => 1), 'read-only open ok';
ok $db->get('test'), 'read-only get ok';
eval {; $db->set(foo => +{}) };
ok $@, 'read-only set fails';
eval {; $db->delete('test') };
ok $@, 'read-only delete fails';

$db->close;

done_testing;
