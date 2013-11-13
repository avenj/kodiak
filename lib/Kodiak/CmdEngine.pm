package Kodiak::CmdEngine;
use Kodiak::Base;

has playback_depth => sub { 10 };

has _cmd_stack  => sub { [] };
has _undo_stack => sub { [] };

sub create {
  my ($self, $cmd) = splice @_, 0, 2;
  confess "Expected a Kodiak::Cmd class name" unless defined $cmd;
  my $target = 'Kodiak::Cmd::'.ucfirst($cmd);
  unless ($target->can('new')) {
    my $file = $target;
    $target =~ s{::|'}{/}g;
    require "$target.pm"
  }
  $target->new(@_)
}

sub execute {
  my ($self, @cmds) = @_;
  for my $cmd (@cmds) {
    $cmd->execute;
  }
  # Push if we didn't die during any execute() calls:
  $self->push_cmds(@cmds);
  $self
}

sub undo {
  my ($self, $depth) = @_;
  # FIXME
}


sub push_cmds {
  my $self = shift;
  push @{ $self->_cmd_stack }, @_
}

sub pop_cmd {
  my ($self, $cmd) = @_;
  pop @{ $self->_cmd_stack }
}

sub get_cmd_at {
  my ($self, $pos) = @_;
  $self->_cmd_stack->[$pos]
}

sub insert_cmd_at {
  my ($self, $pos, $cmd) = @_;
  splice @{ $self->_cmd_stack->[$pos] }, $pos, 0, $cmd;
  $cmd
}

sub set_cmd_at {
  my ($self, $pos, $cmd) = @_;
  $self->_cmd_stack->[$pos] = $cmd
}

sub rm_cmd_at {
  my ($self, $pos) = @_;
  splice @{ $self->_cmd_stack }, $pos, 1
}

sub rm_cmd_if {
  my ($self, $sub) = @_;
  confess "Expected a CODE ref but got $sub" unless reftype $sub eq 'CODE';
  my @removed;
  my $pos = @{ $self->_cmd_stack };
  while ($pos--) {
    push @removed, splice @{ $self->_cmd_stack }, $pos, 1
      if $sub->(local $_ = $self->[$pos])
  }
  @removed
}


1;
