use strict;
use warnings;

package LinesMatch;
use Test::More;

sub lines {
  return split /\n/, $_[0];
}

sub lines_match {
  my ( $lname, $left, $rname, $right ) = @_;
  my (@left)  = lines($left);
  my (@right) = lines($right);

  my $n = ( $#left > $#right ? $#left : $#right );
  subtest "$lname == $rname" => sub {
    for my $line ( 0 .. $n ) {
      if ( not defined $left[$line] ) {
        fail("line $line not in $lname");
        diag( explain( { $rname, $right[$line] } ) );
        last;
      }
      if ( not defined $right[$line] ) {
        fail("line $line not in $rname");
        diag( explain( { $lname, $left[$line] } ) );
        last;
      }
      if ( $left[$line] ne $right[$line] ) {
        fail("line $line missmatches");
        diag( explain( { $lname, $left[$line], $rname, $right[$line] } ) );
        last;
      }
      pass( "line $line matches : " . $left[$line] );
    }
  };
}

1;
