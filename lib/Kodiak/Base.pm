package Kodiak::Base;
use strict; use warnings;
use Carp ();

use feature       ();
use List::Util    ();
use Scalar::Util  ();

use Kodiak::Util::Modules ();

sub import {
  my $class = shift;
  my $super = shift;
  if ($super && !Kodiak::Util::Modules::package_is_loaded($super)) {
    Kodiak::Util::Modules::load_package($super)
  }

  $super = $class unless $super;

  my $target = caller;

  { no strict 'refs'; no warnings 'redefine';
    push @{ $target .'::ISA' }, $super;
    *{ $target .'::has' } = sub { add_attr($target, @_) };
    eval qq{
      package $target; 
      use Carp qw/carp croak confess/;
      use List::Util qw/first reduce/;
      use Scalar::Util qw/blessed refaddr reftype/;
    };
    Carp::croak $@ if $@;
  }
  
  strict->import;
  warnings->import;
  utf8->import;
  feature->import(':5.14');
  feature->unimport('switch');
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? +{@_} : +{%{$_[0]}} : +{}, 
    ref $class || $class
}

sub add_attr {
  my ($class, $attrs, $default) = @_;
  Carp::croak "No name specified for attribute" unless $attrs;
  Carp::croak "Default value should be a CODE reference"
    if ref $default and ref $default ne 'CODE';
  for my $attr (@{ ref $attrs eq 'ARRAY' ? $attrs : [$attrs] }) {
    Carp::croak "Invalid attribute name '$attr'"
      unless $attr =~ /^[a-zA-Z_]\w*$/;

    my $c = "package $class;\nsub $attr {\n  if (\@_ == 1) {\n";
    unless (defined $default) { 
      $c .= "    return \$_[0]{'$attr'};" 
    } else {
      $c .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";
      $c .= "    return \$_[0]{'$attr'} = ";
      $c .= ref $default ? '$default->($_[0]);' : '$default;';
    }
    $c .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";
    $c .= "  \$_[0];\n}";

    warn "-- Attribute $attr in $class\n$c\n\n" if $ENV{KODIAK_DEBUG};
    no strict 'refs';
    Carp::croak "Failed to compile attribute: $@" unless eval "$c;1";
  }
}

1;

=pod

=head1 NAME

Kodiak::Base - Kodiak class builder

=head1 SYNOPSIS

  package My::Class;
  use Kodiak::Base;

  has foo => sub { 'bar' };
  has [qw/bar baz/] => sub { 'quux' };

  package My::Subclass;
  use Kodiak::Base 'My::Class';

=head1 DESCRIPTION

A base class for L<Kodiak> modules, derived from L<Mojo::Base>.

Packages that C<use> this class import the functions described in
L</FUNCTIONS> & inherit the methods described in L</METHODS>.

In addition, packages automatically C<use> a few helpful modules:

  use Kodiak::Base;
  # Same as:
  use strict; use warnings;
  use Carp qw/ carp croak confess /;
  use List::Util qw/ first reduce /;
  use Scalar::Util qw/ blessed refaddr reftype /;

=head2 FUNCTIONS

=head3 has

  has 'foo';
  has foo => sub { [] };
  has [qw/foo bar baz/] => sub { +{} };

Declares attributes for the current class. See L</add_attr>.

=head2 METHODS

=head3 new

  my $obj = My::Class->new;
  my $obj = My::Class->new(foo => []);

The provided constructor creates HASH-type objects; attribute values can be
passed, in which case their default value coderef is never called (see
L</add_attr>).

=head3 add_attr

  $obj->add_attr(foo => sub { [] });
  My::Class->add_attr('foo');

Add a new attribute to an object or class, with an optional (lazy) default.

=head1 AUTHOR

Attribute generation derived from L<Mojo::Base>, authored by the L<Mojolicious>
team.

Adapted to L<Kodiak> by Jon Portnoy <avenj@cobaltirc.org>

=cut
