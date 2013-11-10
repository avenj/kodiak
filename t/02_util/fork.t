use Test::More;
use strict; use warnings;

use Kodiak::Util::Fork;

use File::Spec ();
use File::Temp 'tempdir';

sub do_concurrent {
  my $fork = Kodiak::Util::Fork->new(@_);

  my $dir = tempdir(CLEANUP => 1);

  for my $n (1 .. 10) {
    my $pid = $fork->start and next;
      my $tmppath = File::Spec->catfile($dir, $n);
      open my $fh, '>', $tmppath or die $!;
      close $fh or die $!;
    $fork->finish;
  }

  $fork->wait_all_children;

  opendir my $dirh, $dir or die $!;
  my @results = grep { $_ !~ /\./ } readdir $dirh;
  closedir $dirh or die $!;

  [sort {$a <=> $b} @results]
}

is_deeply do_concurrent(),  [ 1 .. 10 ], 'default args ok';
is_deeply do_concurrent(max_proc => 0), [ 1 .. 10 ], 'max_proc 0 ok';
is_deeply do_concurrent(max_proc => 1), [ 1 .. 10 ], 'max_proc 1 ok';


done_testing;
