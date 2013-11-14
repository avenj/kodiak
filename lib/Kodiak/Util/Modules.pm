package Kodiak::Util::Modules;
use Carp;
use strict; use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/
  load_package
  unload_package
  package_to_filename
/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _get_require_failure {
  my ($pkg) = @_;
  # Assume symbol table entries mean we're loaded:
  { no strict 'refs';
    my $table = $pkg .'::';
    for (keys %$table) {
      return () unless /\A[^:]+::\z/
    }
  }
  # Else try to require the file:
  my $file = package_to_filename($pkg);
  local $@;
  my $died = "require returned false"
    unless eval {; require "$file" };
  $died = $@ if $@;
  $died
}

sub load_package {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  my $died;
  return 1 unless $died = _get_require_failure($pkg);
  unload_package($pkg);
  confess "Failed to load '$pkg': $died"
}

sub unload_package {
  my ($pkg) = @_;
  my $file  = package_to_filename($pkg);
  delete $INC{$file};
  no strict 'refs';
  @{ $pkg .'::ISA' } = ();
  my $table = $pkg . '::';
  for my $sym (keys %$table) {
    # Skip other namespaces:
    next if $sym =~ /\A[^:]+::\z/;
    delete $table->{$sym}
  }
  1
}

sub package_to_filename {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  join('/', split /::|'/, $pkg) . '.pm'
}

1;
