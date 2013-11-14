package Kodiak::Cmd::Check;
use Kodiak::Base 'Kodiak::Cmd';

use Digest::SHA ();

has prereqs => sub {
  [ 'Fetch' ]
};

has _sha => sub { Digest::SHA->new(256) };

sub execute {
  my ($self) = @_;
  # $paths{$thisfile} = sum
  my %paths = %{ $self->params };
  my @failed; my @result;
  for my $file (keys %paths) {
    $self->_calculate_sum($file) eq $paths{$file} ?
      push @result, $file : push @failed, $file
  }
  $self->stash->set( failed => \@failed ) if @failed;
  $self->stash->set( valid  => \@result ) if @result;
  @failed ? 0 : 1
}

sub _calculate_sum {
  my ($self, $file) = @_;
  $self->_sha->reset;
  $self->_sha->addfile($file, 'b');
  $self->_sha->hexdigest
}

1;
