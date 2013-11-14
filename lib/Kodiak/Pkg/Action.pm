package Kodiak::Pkg::Action;
use Kodiak::Base 'Kodiak::CmdEngine';

use Kodiak::Util::Modules 'load_package';

sub create {
  my ($self, $action) = splice @_, 0, 2;
  confess "Expected a Kodiak::Pkg::Action class name"
    unless defined $action;
  my $target = 'Kodiak::Pkg::Action'.ucfirst($action);
  load_package($target)->new(@_)
}

1;
