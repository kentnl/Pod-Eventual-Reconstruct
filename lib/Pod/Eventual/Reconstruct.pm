use strict;
use warnings;

package Pod::Eventual::Reconstruct;

# ABSTRACT: Construct a document from Pod::Eventual events

=begin MetaPOD::JSON v1.0.0

{
    "namespace":"Pod::Eventual::Reconstruct",
    "inherits": "Moo::Object"
}

=end MetaPOD::JSON

=cut

use Moo;
use Path::Tiny qw(path);
use autodie qw(open close);
use Carp qw( croak );

has write_handle => ( is => ro =>, required => 1 );

sub string_writer {
    my $class = $_[0];
    my $string_write;

    if ( not ref $_[1] ) {
        $string_write = \$_[1];
    } elsif ( ref $_[1] ne 'SCALAR' ){
        die '->string_writer( string ) must be a scalar or scalar ref';
    } else {
        $string_write = $_[1];
    }
    open my $fh, '>', $string_write;
    return $class->handle_writer( $fh , $_[2] );
}

sub file_writer {
    my ( $class, $file , $mode ) = @_;
    return $class->handle_writer( path($file)->openw($mode) );
}
sub file_writer_raw {
    my ( $class, $file ) = @_;
    return $class->handle_writer( path($file)->openw_raw());
}
sub file_writer_utf8 {
    my ( $class, $file ) = @_;
    return $class->handle_writer( path($file)->openw_utf8() );
}
sub handle_writer {
    my ( $class, $handle ) = @_;
    return $class->new( write_handle => $handle );
}

sub write_event {
    my ( $self, $event ) = @_;
    my $writer = 'write_'. $event->{type};
    if ( not $self->can($writer) ){
        croak('no writer for event type ' . $event->{type});
    }
    return $self->$writer($event);
}

sub write_command {
    my ( $self, $event ) = @_;
    if ( $event->{type} ne 'command' ) {
        croak('write_command cant write anything but nonpod');
    }
    my $content = $event->{content};
    if ( $content !~ /^\s+$/ ) {
        $content = " " . $content;
    }
    $self->write_handle->printf(qq{=%s%s}, $event->{command},$content );
    #if ( $event->{command} ne 'cut' ){
    #    $self->write_handle->printf(qq{\n});
    #}
    return $self;
}

sub write_text {
    my ( $self, $event ) = @_;
    if ( $event->{type} ne 'text' ) {
        croak('write_text cant write anything but text');
    }
    $self->write_handle->print( $event->{content} );
    return $self;
}



sub write_nonpod {
    my ( $self, $event ) = @_;
    if ( $event->{type} ne 'nonpod' ) {
        croak('write_nonpod cant write anything but nonpod');
    }
    $self->write_handle->print( $event->{content} );
    return $self;

}
sub write_blank {
    my ( $self, $event ) = @_;
    if ( $event->{type} ne 'blank' ) {
        croak('write_blank cant write anything but blanks');
    }
    $self->write_handle->print( $event->{content} );
    return $self;
}

no Moo;

1;
