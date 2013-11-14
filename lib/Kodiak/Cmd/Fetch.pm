package Kodiak::Cmd::Fetch;
use Kodiak::Base 'Kodiak::Cmd';

use Kodiak::Util::Fetch;

sub execute {
  my ($self) = @_;
  my $fetch = Kodiak::Util::Fetch->new(
    %{ $self->params->{constructor_opts}
  );
  $fetch->get($_) for @{ $self->params->{urls} };
}

1;
