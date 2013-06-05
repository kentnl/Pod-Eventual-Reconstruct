use strict;
use warnings;

use Test::More;
use FindBin;
use Path::Tiny qw( path );
use Test::Fatal;

my $corpus  = path($FindBin::Bin)->parent->parent->child('corpus')->child('grep');
my $in_dir  = $corpus->child('input');
my $out_dir = $corpus->child('output');

use lib path($FindBin::Bin)->parent->child('lib')->stringify;

use LinesMatch;
use EventsToList;
use Pod::Eventual::Reconstruct::LazyCut;

{

  package LazyCutConstructor;

  use Moo;
  extends 'Pod::Eventual::Reconstruct::LazyCut';

  sub write_text_outside_pod {
    my ( $self, $orig, $event ) = @_;
    $self->write_event( { type => 'command', 'command' => 'pod', content => qq{\n} } );
    $self->write_event( { type => 'blank', content => qq{\n} } );
    return $self->$orig($event);
  }

}

for my $file ( $in_dir->children() ) {
  my $content  = $file->slurp;
  my $expected = $out_dir->child( $file->basename )->slurp;
  my $elements;
  my $fn = $file->relative($corpus)->stringify;
  is(
    exception {
      $elements = EventsToList->transform_string($content);
    },
    undef,
    'can parse POD to list ' . $fn
  );
  my $elements_out = [ grep { $_->{type} ne 'command' or $_->{command} ne 'begin' } @{$elements} ];
  my $output;

  my $er = LazyCutConstructor->string_writer($output);
  $er->write_event($_) for @{$elements_out};

  LinesMatch::lines_match(
    "$fn generated" => $output,
    "$fn expected"  => $expected
  );
}
done_testing;
