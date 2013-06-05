use strict;
use warnings;

package Pod::Eventual::Reconstruct::LazyCut;
BEGIN {
  $Pod::Eventual::Reconstruct::LazyCut::AUTHORITY = 'cpan:KENTNL';
}
{
  $Pod::Eventual::Reconstruct::LazyCut::VERSION = '0.1.1';
}

# ABSTRACT: A Subclass of Pod::Eventual::Reconstruct that emits less =cut's



use Moo;
extends 'Pod::Eventual::Reconstruct';

has 'inpod' => (
  is        => ro  =>,
  writer    => 'set_inpod',
  clearer   => 'clear_inpod',
  predicate => 'is_inpod',
  lazy      => 1,
  builder   => sub { undef },
);

around write_command => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'command' ) {
    return $self->$orig($event);
  }
  if ( $event->{command} ne 'cut' ) {
    my $result = $self->$orig($event);
    $self->set_inpod(1);
    return $result;
  }
  if ( $self->is_inpod ) {
    my $result = $self->$orig($event);
    $self->clear_inpod();
    return $result;
  }

  # Skipping a cut
  return $self;
};

around write_text => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'text' ) {
    return $self->$orig($event);
  }
  if ( not $self->is_inpod ) {
    warn "POD Text element outside POD";
  }
  return $self->$orig($event);
};

around write_nonpod => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'nonpod' ) {
    return $self->$orig($event);
  }
  if ( $self->is_inpod ) {
    warn "NONPOD element inside POD";
  }
  return $self->$orig($event);
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Pod::Eventual::Reconstruct::LazyCut - A Subclass of Pod::Eventual::Reconstruct that emits less =cut's

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

If you're blindly filtering POD in an Eventual manner, sometimes removing elements
may change the semantics.

For instance, in

    codehere

    =begin foo

    =end foo

    =cut

    codehere

That C<=cut> is an "End of POD Marker".

However, if you simply remove the elements before the C<=cut>, the semantics change:

    codehere

    =cut

    codehere

Here, C<=cut> marks a "Start of POD" and the second C<codehere> is deemed "in the POD". 

This submodule attempts to keep the document "consistent" by not emitting C<=cut> unless a preceeding C<=command> is seen in the output.

Additionally, this module will warn if elements are posted to it in ways that are likely to cause errors, for instance:

=over 4

=item * A POD Text element outside a POD region

=item * A NonPod element inside a POD region

=back

=begin MetaPOD::JSON v1.0.0

{
    "namespace":"Pod::Eventual::Reconstruct::LazyCut",
    "inherits":"Pod::Eventual::Reconstruct"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
