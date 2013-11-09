package Kodiak::Pkg;
use Kodiak::Base;

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
has [qw/
  pl_init
  pl_fetch
  pl_unpack
  pl_build
  pl_test
  pl_preinst
  pl_install
/];


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

sub _create_pkg_atom {
  my ($self) = @_;
  join '/', 
    $self->category, 
    $self->name, 
    $self->version, 
    $self->slot
}



# FIXME
#  - Needs to contain all relevant pkg info
#  - Needs to be able to delegate code generation / execution
#    for pl_* Actions
#  - Needs to be able to execute Actions derived from user Cmds
#    (CmdEngine bridge for this?)

1;
