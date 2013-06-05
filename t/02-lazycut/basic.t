use strict;
use warnings;

use Test::More;
use FindBin;
use Path::Tiny qw( path );
use Test::Fatal;

my $corpus = path($FindBin::Bin)->parent->parent->child('corpus');

use lib path($FindBin::Bin)->parent->child('lib')->stringify;

use LinesMatch;
use EventPipe;

for my $file ( $corpus->children() ) {
  my $content = $corpus->child('01-sample.pl')->slurp;
  my $output;
  my $fn = $file->relative($corpus)->stringify;
  is(
    exception {
      $output = EventPipe->transform_string($content);
    },
    undef,
    'can parse and reconstruct ' . $fn
  );

  LinesMatch::lines_match(
    "$fn generated" => $output,
    "$fn orginal"   => $content
  );
}
done_testing;
