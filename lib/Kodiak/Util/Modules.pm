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
  return 1 if defined ${ $pkg .'::VERSION' };
  return 1 if @{ $pkg .'::ISA' };

  for (keys %{ $pkg .'::' }) {
    next if substr($_, -2, 2) eq '::';
    return 1 if defined &{ $pkg .'::'. $_ };
  }

  my $file = package_to_filename($pkg);
  return 1 if defined $INC{ $file };

  ()
}

sub package_to_filename {
  my ($pkg) = @_;
  confess "Expected a package name" unless defined $pkg;
  join('/', split /::|'/, $pkg) . '.pm'
}

1;

=pod

=head1 NAME

Kodiak::Util::Modules - Module load utils



=cut
