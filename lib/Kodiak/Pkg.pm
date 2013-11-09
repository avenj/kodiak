package Kodiak::Pkg;
use Kodiak::Base;

has [qw/
  atom
/];

# FIXME
#  - Needs to contain all relevant pkg info
#  - Needs to be able to delegate code generation / execution
#    for pl_* Actions
#  - Needs to be able to execute Actions derived from user Cmds
#    (CmdEngine bridge for this?)

1;
