package Kodiak::Cmd;
use Kodiak::Base;

# A base class for Cmds.

has params => sub { [] };


sub execute {
  confess "'execute' method not implemented in ".(blessed $_[0] || $_[0])
}

sub undo {
  confess "'undo' method not implemented in ".(blessed $_[0] || $_[0])
}


1;
