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

my $obj = My::Class->new;
ok $obj->foo eq 'bar', 'constant attr default ok';
ok $obj->bar eq 'foo', 'coderef attr default ok';
ok !defined $obj->baz, 'undef attr default ok';

my $sub = My::Subclass->new;
ok $sub->isa('My::Class'), 'inheritance ok';
ok $sub->foo eq 'bar', 'inherited attr ok';
can_ok $sub, qw/apple cherry banana/;

ok $sub->apple('red'), 'setter ok';
ok $sub->apple eq 'red', 'value set ok';

done_testing;
