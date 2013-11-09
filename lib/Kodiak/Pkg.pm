package Kodiak::Pkg;
use Kodiak::Base;
use Kodiak::Pkg::Action;

# Identifiers:
has [qw/
  category
  name
  version
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
  +{ build => [], runtime => [] }
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
  join '/', 
    $self->category, 
    $self->name, 
    $self->version, 
    $self->slot
}


# Action dispatch:

sub execute_action {
  my ($self, $action) = splice @_, 0, 2;
  my $obj = Kodiak::Pkg::Action->new_action( $action => @_ );
  $obj->execute($self)
}


# Managing build phases:

sub executed_phase {
  my ($self, $phase) = @_;
  push @{ $self->_executed_phases }, $phase;
  $self->get_next_phase($phase)
}

sub get_next_phase {
  my ($self, $phase) = @_;
  my $i = 0;
  BUILDPHASE: for my $possible (@BuildPhases) {
    return $BuildPhases[$i+1] if $possible eq $phase;
    last BUILDPHASE if $i++ >= $#BuildPhases;
  }
  confess "Unknown build phase $phase, cannot get next!"
}


# FIXME
#  - Needs to contain all relevant pkg info
#  - Needs to be able to delegate code generation / execution
#    for pl_* Actions
#  - Needs to be able to execute Actions derived from user Cmds
#    (CmdEngine bridge for this?)

1;
