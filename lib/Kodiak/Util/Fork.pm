package Kodiak::Util::Fork; # Forked from Parallel::ForkManager
use Kodiak::Base;
use Kodiak::Stash;

use File::Spec ();
use File::Temp ();

use POSIX ();

use Time::HiRes 'sleep';


sub TEMPFILE_PREFIX () { 'kodiakf-' }


has max_proc => 5;
has temp_dir => sub {
  File::Temp::tempdir(CLEANUP => 0)
};

has _in_child   => 0;
has _parent_pid => undef;
has _procs  => sub { Kodiak::Stash->new };

# FIXME on_finish_cb should provide per-pid (or 0) callbacks
#  see Parallel::ForkManager
has [qw/
  on_start_cb
  on_wait_cb
  on_wait_cb_interval
/];

# Keyed on PID (or 0):
has _on_finish_cb => sub { Kodiak::Stash->new };
sub on_finish_cb {
  my ($self, $pid, $cb) = @_;
  $pid ||= 0;
  if ($cb) {
    $self->_on_finish_cb->set($pid => $cb);
    return $self
  }
  $self->_on_finish_cb->get($pid)
}


sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  my $tempdir = $self->temp_dir;
  confess "Specified temp_dir '$tempdir' not a directory"
    unless -e $tempdir && -d _;

  $self->_parent_pid( $$ );

  $self
}

sub start {
  my ($self, $tag) = @_;
  confess "Attempted to ->start from child process"
    if $self->_in_child;

  while ($self->max_proc && $self->_procs->keys >= $self->max_proc) {
    $self->_do_on_wait;
    $self->_wait_one_child(
      defined $self->on_wait_cb_interval ? POSIX::WNOHANG : ()
    )
  }

  $self->_wait_children;

  if ($self->max_proc) {
    my $pid = fork;
    croak "Failed to fork: $!" unless defined $pid;
    if ($pid) {
      $self->_procs->set($pid => $tag);
      $self->_do_on_start($pid => $tag);
    } else {
      $self->_in_child(1)
    }
    return $pid
  } else {
    # max_proc = 0
    $self->_procs->set($$ => $tag);
    $self->_do_on_start($$ => $tag);
    return 0  # pretend I'm the child
  }
}

sub finish {
  my ($self, $exitcode, $ref) = @_;
  if ($self->_in_child) {
    if (defined $ref) {
      my $destfile = File::Spec->catfile(
        $self->temp_dir,
        TEMPFILE_PREFIX . $self->_parent_pid .'-'. $$ .'.dat'
      );
      my $stored = eval {; Storable::store($ref, $destfile) };
      unless ($stored && !$@) {
        warn "Failed to serialize ref to disk ($destfile)",
          ( $@ ? ": $@" : () )
      }
    }

    CORE::exit($exitcode // 0)
  }

  if ($self->max_proc == 0) {
    # fake it
    $self->_do_on_finish(
      $$, $exitcode, $self->_procs->get($$), 0, 0, $ref
    );
    $self->_procs->delete($$)
  }

  0
}


sub _wait_children {
  my ($self) = @_;
  return unless $self->_procs->keys;

  my $child_pid;
  do { $child_pid = $self->_wait_one_child(POSIX::WNOHANG) }
    while $child_pid != 0 and $child_pid != -1;
}

sub _wait_one_child {
  my ($self, $flags) = @_;
  $flags ||= 0;

  my $child_pid;
  WAIT: while (1) {
    $child_pid = $self->_do_waitpid(-1, $flags);
    last WAIT if $child_pid == 0 || $child_pid == -1;
    redo WAIT unless $self->_procs->exists($child_pid);

    my $tag = $self->_procs->delete($child_pid);

    my $retrieved;
    my $tempfile = File::Spec->catfile(
      $self->temp_dir,
      TEMPFILE_PREFIX . $$ . '-' . $child_pid .'.dat'
    );
    if (-e $tempfile) {
      $retrieved = eval {; Storable::retrieve($tempfile) };
      unless ($retrieved && !$@) {
        warn "Failed to retrieve serialized ref from disk ($tempfile)",
          ( $@ ? ": $@" : () )
      }
      unlink $tempfile;
    }

    $self->_do_on_finish(
      $child_pid,          # deceased child PID
      $? >> 8,             # exit val
      $tag,                # process tag
      $? & 0x7f,           # exit signal
      $? & 0x80 ? 1 : 0,   # true if core dumped
      $retrieved           # serialized data, if any
    );

    last WAIT
  }

  $child_pid
}

sub wait_all_children {
  my ($self) = @_;
  while ($self->_procs->keys) {
    $self->_do_on_wait;
    $self->_wait_one_child(
      defined $self->on_wait_cb_interval ?
        POSIX::WNOHANG : ()
    )
  }
}


sub _do_waitpid {
  $^O eq 'MSWin32' ? 
    goto &_running_in_hell_waitpid : goto &_sane_waitpid
}

sub _sane_waitpid {
  waitpid( $_[1], $_[2] )
}

sub _running_in_hell_waitpid {
  my ($self, $pid, $flags) = @_;
  # Make WNOHANG not suck when RUNNING_IN_HELL
  if ($flags == POSIX::WNOHANG) {
    my @pids = keys %{ $self->_procs } || return -1;
    my $child_pid;
    for (@pids) {
      $child_pid = waitpid($_, $flags);
      # Win32 returns negative PIDs:
      return $child_pid if $child_pid != 0;
    }
    return $child_pid
  }

  waitpid($pid, $flags)
}


sub _do_on_wait {
  my $self = shift;
  my $retval;
  if (defined $self->on_wait_cb) {
    $retval = $self->on_wait_cb->(@_);
    if (defined $self->on_wait_cb_interval) {
      local $SIG{CHLD} = sub {} unless defined $SIG{CHLD};
      sleep $self->on_wait_cb_interval
    }
  }
  $retval
}

sub _do_on_start {
  my $self = shift;
  if (defined $self->on_start_cb) {
    return $self->on_start_cb->(@_)
  }
  ()
}

sub _do_on_finish {
  my $self = shift;
  my $pid  = $_[0] ||= 0;
  if (my $code = $self->on_finish_cb($pid)) {
    # Code ref passed $pid, @params:
    return $code->(@_)
  }
  ()
}

1;
