package Kodiak::Base;
use strict; use warnings;

use Carp ();
use feature ();

sub import {
  my $class = shift;
  my $super = shift;
  if ($super && !$super->can('new')) {
    my $file = $super;
    $file =~ s{::|'}{/}g;
    require "$file.pm";
  }

  $super = $class unless $super;

  my $caller = caller;

  { no strict 'refs';
    push @{ $caller .'::ISA' }, $super;
    *{ $caller .'::has' } = sub { add_attr($caller, @_) };
  }
  
  strict->import;
  warnings->import;
  utf8->import;
  feature->import(':5.14');
  feature->unimport('switch');
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class
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

=head1 DESCRIPTION

=head1 AUTHOR

Attribute generation derived from L<Mojo::Base>, authored by the L<Mojolicious>
team.

Adapted to L<Kodiak> by Jon Portnoy <avenj@cobaltirc.org>

=cut
