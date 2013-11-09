package Kodiak::DB;
use Kodiak::Base;

use DB_File;
use Fcntl ':DEFAULT', ':flock';
use IO::File;
use Storable ();
use Time::HiRes 'sleep';


has path    => sub { undef };
has perms   => sub { 0644 };
has timeout => sub { 30 };
has raw     => sub { 0 };

has is_open => sub { 0 };

has _db    => sub { undef };

has _orig => sub { +{} };
has _tied => sub { +{} };

has _lockfh   => sub { undef };
has _lockmode => sub { undef };

sub open {
  # tie, sync, dup, lock, retie dance
  # (safe locking)
  my ($self, %args) = @_;
  my $readonly = $args{ro} || $args{readonly} || 0;

  croak "No path() currently specified"
    unless defined $self->path;

  if ($self->is_open) {
    carp "Attempted to open() already open DB";
    return
  }

  my ($lflags, $fflags);
  if ($readonly) {
    $lflags = LOCK_SH | LOCK_NB;
    $fflags = O_CREAT | O_RDONLY;
    $self->_lockmode( LOCK_SH );
  } else {
    $lflags = LOCK_EX | LOCK_NB;
    $fflags = O_CREAT | O_RDWR;
    $self->_lockmode( LOCK_EX );
  }

  my $origdb = tie %{ $self->_orig }, 
                DB_File => $self->path, $fflags, $self->perms, $DB_HASH
    or confess "Database open failure: ", $self->path, ": $!";
  $origdb->sync;

  my $fd = $origdb->fd;
  my $fh = IO::File->new("<&=$fd")
    or confess "Failed dup() in DB open: $!";

  my $timer = 0;
  my $timeout = $self->timeout;
  
  until (flock $fh, $lflags) {
    if ($timer > $timeout) {
      undef $origdb; undef $fh;
      untie %{ $self->_orig };
      croak "Timed out attempting to gain lock on db ".$self->path;
    }
    sleep 0.01;
    $timer += 0.01;
  }

  my $db = tie %{ $self->_tied },
            DB_File => $self->path, $fflags, $self->perms, $DB_HASH
    or confess "Database re-open failure: ", $self->path, ": $!";

  $self->is_open(1);
  $self->_lockfh( $fh );
  $self->_db( $db );
  undef $origdb;

  $self->_db->filter_fetch_key( sub { s/\0$// } );
  $self->_db->filter_store_key( sub { $_ .= "\0" } );

  $self->_db->filter_fetch_value( sub {
    s/\0$//;
    $_ = Storable::thaw($_)
  });

  $self->_db->filter_store_value( sub {
    $_ = Storable::nfreeze($_) . "\0"
  });

  $self
}

sub close {
  my ($self) = @_;
  
  unless ($self->is_open) {
    carp "Attempted to close unopened DB";
    return
  }

  if ($self->_lockmode == LOCK_EX) {
    $self->_db->sync
  }

  $self->_db( undef );
  untie( %{ $self->_tied } )
    or carp "untie failed in closing DB ($!), attempting to continue";
  flock( $self->_lockfh, LOCK_UN )
    or carp "unlock failed in closing DB ($!), attempting to continue";
  untie( %{ $self->_orig } )
    or carp "untie failed on orig in closing DB ($!), attempting to continue";
  $self->_lockfh( undef );
  $self->_lockmode( undef );
  $self->_tied(+{});
  $self->is_open(0);

  $self
}


sub keys {
  my ($self) = @_;
  croak "Attempted to retrieve keys() from closed db" unless $self->is_open;
  keys %{ $self->_tied }
}

sub get {
  my ($self, $key) = @_;
  croak "get() called with no key specified" unless defined $key;
  croak "Attempted to get() from closed db" unless $self->is_open;
  $self->_tied->{$key}
}

sub exists {
  my ($self, $key) = @_;
  croak "exists() called with no key specified" unless defined $key;
  croak "Attempted exists() check on closed db" unless $self->is_open;
  exists $self->_tied->{$key}
}

sub export {
  my ($self) = @_;
  croak "Attempted to export() closed db" unless $self->is_open;
  +{ %{ $self->_tied } }
}


sub set {
  my ($self, $key, $val) = @_;
  croak "set() called with no key specified" unless defined $key;
  croak "Attempted to set() on closed db" unless $self->is_open;
  croak "Attempted to set() on read-only db"
    if $self->_lockmode == LOCK_SH;
  $self->_tied->{$key} = $val
}

sub delete {
  my ($self, $key) = @_;
  croak "delete() called with no key specified" unless defined $key;
  croak "Attempted to delete() from closed db" unless $self->is_open;
  croak "Attempted to delete() on read-only db"
    if $self->_lockmode == LOCK_SH;
  CORE::delete $self->_tied->{$key};
  $self
}


sub get_db {
  my ($self) = @_;
  croak "Attempted to get_db() on closed db" unless $self->is_open;
  $self->_db
}

sub get_tied {
  my ($self) = @_;
  croak "Attempted to get_tied() on closed db" unless $self->is_open;
  $self->_tied
}

sub DESTROY {
  my ($self) = @_;
  $self->close if $self->is_open;
}

1;
