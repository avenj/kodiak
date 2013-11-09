package Kodiak::UserAgent;
use Kodiak::Base;

use Kodiak::Util::Chdir;
use Kodiak::Util::TemplateStr;


has dist_dir      => '/opt/kodi/dists';
has fetch_command => '/usr/bin/wget -c %url%';


sub get {
  my ($self, $url) = @_;
  
  croak "'dist_dir' not defined"      unless $self->dist_dir;
  croak "'fetch_command' not defined" unless $self->fetch_command;

  my $parsed_cmd = templatestr( $self->fetch_command =>
    url => $url,
  );

  my $rval;
  cd $self->dist_dir => sub {
    $rval = system( $parsed_cmd )
  };

  $rval == 0 ? $rval : die "Failed to fetch file ($url)!\n";
}

1;