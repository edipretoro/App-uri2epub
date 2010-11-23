use strict;
use warnings;
package App::uri2epub;
# ABSTRACT: a simple application to transform a URL into an ePub file.

use Getopt::Long;
use Pod::Usage;
use HTML::ExtractMain qw( extract_main_html );
use LWP::UserAgent;
use EBook::EPUB;
use Carp;
use File::Temp qw( tempfile );
use Data::UUID;

__PACKAGE__->run() unless caller;

=meth new

The constructor of App::uri2epub. 

You can use the following parameters:

=over

=item uri

The URL to retrieve and process.

=item output_file

The filename of the output.

=back

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    $self->{uri} = $args{uri} || '';
    $self->{epub} = $args{epub} || '';

    bless $self, $class;
}

=meth process

Run the conversion of the URI into an eBook

=cut

sub process {
    my ($self) = @_;

    croak "We need a URI to process\n" if $self->{uri} eq '';
    $self->{ua} = LWP::UserAgent->new( agent => 'Mozilla/5.0', cookie_jar => {}, timeout => 300 );
    $self->{response} = $self->{ua}->get( $self->{uri} );
    if ($self->{response}->is_success) {
        my $main_content = extract_main_html( $self->{response}->decoded_content );
        return $self->_build_epub( $main_content );
    } else {
        $self->{errstr} = "We can't get the URI: " . $self->{response}->status_line() . "\n";
        return 0;
    }
}

sub _build_epub {
    my ($self, $content) = @_;

    if (not defined $content) {
        $self->{errstr} = "We can't find the content of this page.";
        return 0;
    }

    $self->_get_xhtml( $content );
    $self->{epub_builder} = EBook::EPUB->new( filename => $self->{epub} );
    $self->{epub_builder}->add_title( $self->{response}->title() );
    $self->{epub_builder}->add_language( 'en' );
    my $du = Data::UUID->new();
    my $uuid = $du->create_from_name_str( NameSpace_URL, $self->{uri} );
    {
        # Ignore overridden UUID warning form EBook::EPUB.
        local $SIG{__WARN__} = sub { };
        $self->{epub_builder}->add_identifier( "urn:uuid:$uuid" );
    }
    $self->_get_css();
    $self->{epub_builder}->copy_stylesheet( $self->{css_filename}, 'style.css' );
    $self->{epub_builder}->copy_xhtml($self->{xhtml_filename}, 'content.xhtml' );
    $self->{epub_builder}->pack_zip( $self->{epub} );
    return 1;
}

sub _get_xhtml {
    my ($self, $content) = @_;

    $self->{xhtml} = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
        . qq{<!DOCTYPE html\n}
        . qq{     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
        . qq{    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n}
        . qq{\n}
        . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
        . qq{<head>\n}
        . qq{<title></title>\n}
        . qq{<meta http-equiv="Content-Type" }
        . qq{content="text/html; charset=iso-8859-1"/>\n}
        . qq{<link rel="stylesheet" href="../styles/style.css" }
        . qq{type="text/css"/>\n}
        . qq{</head>\n}
        . qq{\n}
        . qq{<body>\n}
        . qq{<h1>} . $self->{response}->title . qq{</h1>\n}
        . $content
        . qq{</body>\n}
            . qq{</html>};
    ( $self->{xhtml_fh}, $self->{xhtml_filename} ) = tempfile();
    print { $self->{xhtml_fh} } $self->{xhtml};
}

sub _get_css {
    my ($self) = @_;

    ( $self->{css_fh}, $self->{css_filename} ) = tempfile();
    print { $self->{css_fh} } "h1         { font-size: 110%; }\n";
    print { $self->{css_fh} } "h2, h3, h4 { font-size: 100%; }\n";
}

=meth run

The modulino part of this module.

=cut

sub run {
    my ($class) = @_;

    my $config = {
        epub => './uri2epub.epub',
    };
    GetOptions( $config, 'uri=s', 'epub=s', 'help' ) or pod2usage(2);
    pod2usage(1) if exists $config->{help};
    pod2usage(1) if not exists $config->{uri};

    my $converter = $class->new( uri => $config->{uri}, epub => $config->{epub} );
    if ($converter->process) {
        print "The creation of the eBook is successful\n";
    } else {
        warn "The creation of the eBook failed.\n";
    }
}

1;

__END__
=pod

=head1 NAME

uri2epub -- convert an URI into an ePub file.

=head1 SYNOPSIS

uri2epub --uri http://www.perl.com/ --epub perl.epub [--help]

=cut

