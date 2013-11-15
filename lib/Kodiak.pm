package Kodiak;
use Kodiak::Base;

use Kodiak::DB::Installed;
use Kodiak::DepTree;
use Kodiak::DepTree::Node;

has config => sub { };

has installed_db => sub {
  my ($self) = @_;
  Kodiak::DB::Installed->new(
    install_db_path => $self->config->paths->get('install_db')
  )
};

has parser => sub {
  my ($self) = @_;
  my $configured_parser = $self->config->packages->get('format');
  if ($configured_parser) {
    $configured_parser = 'Kodiak::Pkg::Parser::'.$configured_parser
      unless index($configured_parser, '::') != -1;
  }
  Kodiak::Pkg::Parser->new(
    ($configured_parser ? (backend => $configured_parser) : () ),
  )
};

sub load_pkg {
  my ($self, %params) = @_;



  my $pkg = 
    $params{from_file} ? $self->parser->parse_from_file($params{from_file})
      : $params{from_fh} ? $self->parser->parse_from_fh($params{from_fh})
      : $params{from_string} ? $self->parser->parse_from_raw($params{from_string})
      : confess "Expected one of: from_file, from_fh, from_string"
  ;

  confess "Parser failed to return a Kodiak::Pkg"
    unless blessed($pkg) and $pkg->isa('Kodiak::Pkg');

  my $node = Kodiak::DepTree::Node->new(
    atom    => $pkg->atom,
    payload => $pkg,
    depends => [],
  );
  # FIXME add appropriate depends to node from pkg
  #   requires knowledge of depends types 
  #   separate trees for 'build', 'test' deps,
  #   attach these to pkg objs (or nodes/subclass thereof?),
  #   it should be possible for these to be only installed within
  #   the build env & never merged
}


has tree => sub { Kodiak::DepTree->new };

sub resolved_tree {
  my ($self) = @_;
  $self->tree->filtered_via(
    sub { $self->installed_db->installed($_->atom) ? () : 1 }
  )
}

sub resolved_tree_list { @{ shift->resolved_tree } }

sub clear_tree { shift->tree( Kodiak::DepTree->new ) }



sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  state $required = +{
    config => sub { $_ and $_->isa('Kodiak::Config') },
  / };

  for my $attr (keys %$required) {
    my $val = $self->$attr;
    croak "Undefined required attribute '$attr'"
      unless defined $val;
    if (my $test = $required->{$attr}) {
      croak "Value '$val' for attribute '$attr' failed type constraint"
        unless $test->(local $_ = $val)
    }
  }

  for (@$required) {
    croak "Missing required attribute '$_'" unless defined $self->$_
  }

  $self
}


1;

=pod

=head1 NAME

Kodiak - Kodiak software manager

=head1 SYNOPSIS

=head1 DESCRIPTION

Flexible software manager.

A work in progress.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

This dist includes code derived from or inspired by various CPAN projects
licensed under the same or compatible terms, including:

L<File::cd> by SYALTUT

L<Mojolicious> by SRI et al

L<Parallel::ForkManager> by DLUX, SZABDAB, et al

L<YAML::Tiny> by ADAMK

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
