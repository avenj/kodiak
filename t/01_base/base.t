use Test::More;
use strict; use warnings;

{ package My::Class;
  use Kodiak::Base;
  has foo => 'bar';
  has bar => sub { 'foo' };
  has 'baz';
}

{ package My::Subclass;
  use Kodiak::Base 'My::Class';
  has [qw/apple cherry banana/];
}

# Carp imported:
can_ok 'My::Class', qw/carp croak confess/;

# attrib defaults:
my $obj = My::Class->new;
ok $obj->foo eq 'bar', 'constant attr default ok';
ok $obj->bar eq 'foo', 'coderef attr default ok';
ok !defined $obj->baz, 'undef attr default ok';

# subclass:
my $sub = My::Subclass->new;
ok $sub->isa('My::Class'), 'inheritance ok';
ok $sub->foo eq 'bar', 'inherited attr ok';
can_ok $sub, qw/apple cherry banana/;

# writer:
ok $sub->apple('red'), 'setter ok';
ok $sub->apple eq 'red', 'value set ok';

# new w/ attribs set:
$obj = My::Subclass->new(foo => 1, cherry => 2);
ok $obj->foo == 1 && $obj->cherry == 2, 'new with attrib values ok';

# new from old:
my $cloned = $obj->new($obj);
ok $cloned->foo == 1 && $cloned->cherry == 2, 'cloned ok';

done_testing;
