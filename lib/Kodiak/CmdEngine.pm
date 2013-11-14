package Kodiak::CmdEngine;
use Kodiak::Base;

use Kodiak::Util::Modules 'load_package';

has playback_depth => sub { 10 };

has _cmd_stack  => sub { [] };
has _undo_stack => sub { [] };

sub create {
  my ($self, $cmd) = splice @_, 0, 2;
  confess "Expected a Kodiak::Cmd class name" unless defined $cmd;
  my $target = 'Kodiak::Cmd::'.ucfirst($cmd);
  load_package($target)->new(@_)
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


sub _reduce_stack {
  my ($self) = @_;
  if ((my $count = @{ $self->_cmd_stack }) > $self->playback_depth) {
    splice @{ $self->_cmd_stack }, 0, ($count - $self->playback_depth)
  }
  $self
}


sub push_cmds {
  my $self = shift;
  push @{ $self->_cmd_stack }, @_;
  $self->_reduce_stack
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
  $self->_reduce_stack
}

sub set_cmd_at {
  my ($self, $pos, $cmd) = @_;
  $self->_cmd_stack->[$pos] = $cmd;
  $self
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
