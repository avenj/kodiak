use Test::More;
use strict; use warnings qw/FATAL all/;

use Kodiak::Util::TemplateStr;

cmp_ok(
  templatestr( 'things %and% %stuff',
    and   => 'or',
    stuff => 'some objects',
  ),
  'eq',
  'things or some objects',
  'list-style templatestr'
);

cmp_ok(
  templatestr( 'things %or %objects',
    {
      or      => 'and perhaps',
      objects => 'some cake',
    },
  ),
  'eq',
  'things and perhaps some cake',
  'hashref templatestr'
);

cmp_ok(
  templatestr( 'string with %code',
    code => sub { "things" },
  ),
  'eq',
  'string with things',
  'coderef replacement'
);

done_testing;
