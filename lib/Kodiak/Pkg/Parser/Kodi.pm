package Kodiak::Pkg::Parser::Kodi;
use Kodiak::Base;
use Kodiak::Pkg;
use Kodiak::YAML;

sub parse {
  my ($self, $data) = @_;
  # FIXME
  #  (Attempt to) deserialize YAML $data
  #  Validate basic structure (some sort of grammar description?)
  #  Spit back out a Kodiak::Pkg
}

sub _validate {
  my ($self, $hash) = @_;
  # FIXME
}

sub _build_pkg {
  my ($self, $hash) = @_;
  # FIXME
}

1;
