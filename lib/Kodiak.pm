package Kodiak;
use Kodiak::Base;
use Kodiak::CmdEngine;

has cmd_engine => sub { Kodiak::CmdEngine->new };

has config => sub { };


has _installed_db => sub {
  my ($self) = @_;
  Kodiak::DB::Installed->new(
    install_db_path => $config->paths->get('install_db')
  )
};


sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  state $required = [ qw/
    config
  / ];

  for (@$required) {
    croak "Missing required attribute '$_'" unless defined $self->$_
  }

  $self
}


1;

=pod

=head1 NAME

Kodiak - Kodiak software manager

=head1 SYNOPSIS

=head1 DESCRIPTION

Flexible software manager.

A work in progress.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

This dist includes code derived from or inspired by various CPAN projects
licensed under the same or compatible terms, including:

L<File::cd> by SYALTUT

L<Mojolicious> by SRI et al

L<Parallel::ForkManager> by DLUX, SZABDAB, et al

L<YAML::Tiny> by ADAMK

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
