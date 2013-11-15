package Kodiak::Pkg;
use Kodiak::Base;
use Kodiak::Pkg::Action;

# Identifiers:
has [qw/
  category
  name
  version
  loaded_from
/];

has slot => 0;

has atom => sub {
  my ($self) = @_;
  for (qw/category name version slot/) {
    confess "->atom called but missing attrib '$_'"
      unless defined $self->$_
  }
  $self->_create_pkg_atom;
};


# Package meta:
has [qw/
  description
  homepage
  license
/];

has depends_hash => sub {
  +{ 
    map {; $_ => [] } qw/ 
      build
      runtime
      test
      recommends
    /
  } 
};

has keywords    => sub { [] };
has fetch_urls  => sub { [] };

has settings    => sub { +{} };


# Build phases:
our @BuildPhases = qw/
  pl_init
  pl_fetch
  pl_unpack
  pl_build
  pl_test
  pl_preinst
  pl_install
  pl_postinst
  pl_prerm
  pl_postrm
/;

has \@BuildPhases;

has _executed_phases => sub { [] };


sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  state $required = [ qw/
    loaded_from
    category
    name
    version
  / ];

  my @missing;
  for (@$required) {
    push @missing, $_ unless defined $self->$_
  }
  confess "Missing required parameter(s): ".join ', ', @missing
    if @missing;

  $self
}


# Helpers:

sub _create_pkg_atom {
  my ($self) = @_;
  join ':', 
    $self->category, 
    $self->name, 
    $self->version, 
    $self->slot
}


# Action dispatch:

sub execute_action {
  my ($self, $action) = splice @_, 0, 2;
  confess "Expected an Action name" unless defined $action;
  my $obj = Kodiak::Pkg::Action->create( $action => @_ );
  $obj->execute($self)
}


# Managing dependency list:
sub add_depends {
  my ($self, $type, @atoms) = @_;
  # FIXME
}

sub remove_depends {
  my ($self, $type, @atoms) = @_;
  # FIXME support 'any' type?
}

sub list_depends_types {
  my ($self) = @_;
  keys %{ $self->depends_hash }
}

sub list_depends {
  my ($self, $type) = @_;
  confess "Expected a dependency type or 'any'" unless defined $type;
  if ($type eq 'any') {
    map {; @{ $self->depends_hash->{$_} } } $self->list_depends_types
  }
  @{ $self->depends_hash->{$type} || [] }
}

sub depends_on {
  my ($self, $type, $atom) = @_;
  confess "Expected a dependency type or 'any' and a pkg atom"
    unless defined $atom;
  my @depends = $type eq 'any' ? $self->list_depends('any')
    : $self->list_depends($type);
  !! first {; $_ eq $atom } @depends
}


# Managing build phases:

sub push_executed_phase {
  my ($self, $phase) = @_;
  confess "Expected a build phase" unless defined $phase;
  push @{ $self->_executed_phases }, $phase;
  $self->get_next_phase($phase)
}

sub pop_executed_phase {
  my ($self) = @_;
  pop @{ $self->_executed_phases }
}

sub get_next_phase {
  my ($self, $phase) = @_;
  confess "Expected a build phase" unless defined $phase;
  my $i = 0;
  BUILDPHASE: for my $possible (@BuildPhases) {
    return $BuildPhases[$i+1] if $possible eq $phase;
    last BUILDPHASE if $i++ >= $#BuildPhases;
  }
  confess "Unknown build phase $phase, cannot get next!"
}

sub list_prereq_phases {
  my ($self, $phase) = @_;
  confess "Invalid phase specified: '$phase'"
    unless defined $phase
    and first {; $_ eq $phase } @BuildPhases;
  my @needed;
  NEEDED: for my $prereq (@BuildPhases) {
    last NEEDED if $prereq eq $phase;
    push @needed, $prereq
  }
  @needed
}




# FIXME
#  - Needs to contain all relevant pkg info
#  - Needs to be able to delegate code generation / execution
#    for pl_* Actions
#  - Needs to be able to execute Actions derived from user Cmds
#    (CmdEngine bridge for this?)

1;
