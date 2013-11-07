package Kodiak::Util::Chdir;
use strict; use warnings;

use Carp qw/croak confess/;

use Cwd ();

use Scalar::Util 'reftype';

use Exporter 'import';
our @EXPORT = 'cd';

sub cd (&&) {
  my ($dir, $code) = @_;

  croak "No such directory: $dir" unless -e $dir;
  croak "No callback specified for cd()"
    unless reftype $code eq 'CODE';
  
  my $orig = Cwd::getcwd;
  
  chdir $dir or croak "chdir failed: '$dir': $!";
  my $retval = wantarray ? [ $code->() ] : $code->();
  chdir $orig or croak "chdir failed to return to original: '$orig': $!";
  
  wantarray ? @$retval : $retval
}

1;

=pod

=head1 AUTHOR

Derived from L<File::Cd> by Ahmad Syaltut.

Adapted to L<Kodiak> by Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
