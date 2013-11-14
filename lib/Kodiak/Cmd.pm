package Kodiak::Cmd;
use Kodiak::Base;
use Kodiak::Stash;

# A base class for Cmds.

has prereqs => sub { [] };

has params => sub { +{} };

has stash  => sub { Kodiak::Stash->new };

sub execute {
  confess "'execute' method not implemented in ".(blessed $_[0] || $_[0])
}

sub undo {
  confess "'undo' method not implemented in ".(blessed $_[0] || $_[0])
}

1;
