package Kodiak::DB::Installed;
use Kodiak::Base;
use Kodiak::DB;
use Kodiak::Pkg;

use Carp;
use Scalar::Util 'blessed';

has install_db_path => sub { undef };

has _db => sub { undef };

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  unless ($self->install_db_path) {
    confess "Missing required parameter: 'install_db_path'"
  }

  $self->_db(
    Kodiak::DB->new(path => $self->install_db_path)
  );

  $self
}

sub add {
  # Add a Kodiak::Pkg to the installed DB.
  my ($self, $pkg) = @_;
  confess "Expected a Kodiak::Pkg object but got $pkg"
    unless blessed $pkg and $pkg->isa('Kodiak::Pkg');
  my $atom = $pkg->atom;
  my $val  = +{ %$pkg };
  $db->open;
  $db->set($atom => $val);
  $db->close;
}

sub get {
  # Retrieve a Kodiak::Pkg from the installed DB.
  my ($self, $pkg_or_atom) = @_;
  my $atom = blessed $pkg_or_atom ? $pkg_or_atom->atom : $pkg_or_atom;
  $db->open;
  my $retval = $db->get($atom);
  $db->close;
  Kodiak::Pkg->new($retval)
}

sub installed {
  # Check for an atom in the installed DB.
  my ($self, $pkg_or_atom) = @_;
  my $atom = blessed $pkg_or_atom ? $pkg_or_atom->atom : $pkg_or_atom;
  $db->open;
  my $retval = $db->exists($atom) ? 1 : 0;
  $db->close;
  $retval
}

sub remove {
  my ($self, $pkg) = @_;
  my $atom = blessed $pkg_or_atom ? $pkg_or_atom->atom : $pkg_or_atom;
  my $retval = 0;
  $db->open;
  if ( $db->exists($atom) ) {
    $db->delete($atom);
    $retval = 1 unless $db->exists($atom);
  } else {
    carp "Attempted remove() on nonexistant key '$atom'"
  }
  $db->close;
  $retval
}

# FIXME manage a DB of installed packages
#  Need to at least know:
#    - This atom
#    - Build environment info
#    - Atoms depended upon
#  Preserve whole build file (or info/stages) for Pkg obj reconstruction?
#  Probably a Pkg obj should just hold *everything*, serialize that out?

1;
