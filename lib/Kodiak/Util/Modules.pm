package Kodiak::Util::Modules;
use Carp;
use strict; use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/
  load_package
  load_or_return_error
  unload_package
  package_to_filename
  package_is_loaded
/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _get_require_failure {
  my ($pkg) = @_;
  return if package_is_loaded($pkg);

  my $file = package_to_filename($pkg);

  local $@;
  my $died = "require returned false"
    unless eval {; require "$file" };
  $died = $@ if $@;

  unload_package($pkg) if $died;
  $died
}

sub load_or_return_error {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  _get_require_failure($pkg)
}

sub load_package {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  my $died;
  return $pkg unless $died = _get_require_failure($pkg);
  confess "Failed to load '$pkg': $died"
}

sub unload_package {
  my ($pkg) = @_;
  my $file  = package_to_filename($pkg);
  no strict 'refs';
  @{ $pkg .'::ISA' } = ();
  my $table = $pkg . '::';
  for (keys %$table) {
    next if substr($_, -2, 2) eq '::';
    delete $table->{$_}
  }
  delete $INC{$file};
  1
}

sub package_is_loaded {
  my ($pkg) = @_;

  no strict 'refs';
  
  return 1
    if defined ${ $pkg .'::VERSION' }
    or @{ $pkg .'::ISA' };

  for (keys %{ $pkg .'::' }) {
    next if substr($_, -2, 2) eq '::';
    return 1 if defined &{ $pkg .'::'. $_ };
  }

  return 1 if defined $INC{ package_to_filename($pkg) };

  ()
}

sub package_to_filename {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  join('/', split /(?:\'|::)/, $pkg) . '.pm'
}

1;

=pod

=head1 NAME

Kodiak::Util::Modules - Module management utils

=head1 SYNOPSIS

  use Kodiak::Util::Modules ':all';

  my $obj = load_package('My::Module')->new;
  # .. or check for exceptions:
  my $wanted = 'My::Module';
  my $err = load_or_return_error($wanted);
  my $obj = $wanted->new unless $err;
 
  if ( package_is_loaded('My::Module') ) {
    # ...
  }

  my $file = package_to_filename('My::Module');

  # Not very safe:
  unload_package('My::Module');

=head1 DESCRIPTION

utilities for (safely) handling module loading.

=head2 EXPORTED

=head3 load_package

Attempt to C<require> a specified module.

Returns the specified package name on success; otherwise an exception is
thrown.

If the package appears to be already available by some means (see
L</package_is_loaded>), the specified package name is returned immediately.

If the package load fails, L</unload_package> is automatically called to
perform a cleanup; this prevents partial compilations from polluting the
symbol table, potentially resulting in situations where, for example, 
C<< $pkg->can('foo') >> is true despite a package failing to compile.

=head3 load_or_return_error

Like L</load_package>, but exceptions are automatically caught.

Returns a true value containing the exception message upon failure.

Returns an empty list upon success.

=head3 package_is_loaded

Returns true if the package appears to be already loaded (even partially, eg.
from a failed compile performed outside of this module's load functions).

=head3 package_to_filename

Returns the file path for the specified package as used by perl (in C<require>
/ C<%INC>).

=head3 unload_package

Removes the specified package from the running interpreter.

(This is not especially safe and primarily exists to clean up failed partial
compilations, but it is exposed for completeness.)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Pieces of this code are inspired by L<Class::Unload>, L<Class::Inspector>,
L<Module::Runtime> et al.



=cut
