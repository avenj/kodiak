package Kodiak::Pkg::Action;
use Kodiak::Base;


sub new_action {
  my (undef, $action) = splice @_, 0, 2;
  $action = ucfirst $action;
  my $pkg = __PACKAGE__ .'::'. $action;
  unless ($pkg->can('new')) {
    my $file = $pkg;
    $pkg =~ s{::|'}{/}g;
    require "$file.pm"
  }
  $pkg->new(@_)
}

1;
