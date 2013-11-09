package Kodiak::Pkg::Parser;
use Kodiak::Base;

# Backend object or class:
has backend => sub { 'Kodiak::Pkg::Parser::Kodi' };

has _backend_obj => sub { };

sub get_backend_obj {
  my ($self) = @_;
  return $self->_backend_obj if $self->_backend_obj;
  my $parser_class = $self->backend;
  # If ->backend is already an obj, don't set _backend_obj:
  return $parser_class if Scalar::Util::blessed($parser_class);
  unless ( $parser_class->can('new') ) {
    my $file = $parser_class;
    $file =~ s{::|'}{/}g;
    require "$file.pm";
  }
  $self->_backend_obj( $parser_class->new );
  $self->_backend_obj
}

sub parse_from_raw {
  my ($self, $data) = @_;
  confess "No data passed to parse_from_raw" unless $data;

  my $obj = $self->get_backend_obj->parse($data);

  unless (Scalar::Util::blessed($obj) && $obj->isa('Kodiak::Pkg')) {
    confess "Expected to return a Kodiak::Pkg but got $obj"
  }

  $obj
}

sub parse_from_file {
  my ($self, $path) = @_;
  open my $fh, '<:encoding(UTF-8)', $path
    or croak "open failed ($path): $!";
  my @data = readline($fh);
  close $fh;
  $self->parse_from_raw(join '', @data)
}

sub parse_from_fh {
  my ($self, $fh) = @_;
  my @data = readline($fh);
  $self->parse_from_raw(join '', @data)
}

1;
