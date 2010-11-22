use strict;
use warnings;
package App::uri2epub;
# ABSTRACT: a simple application to transform a URL into an ePub file.

use Getopt::Long;
use Pod::Usage;
use HTML::ExtractMain qw( extract_main_html );
use LWP::UserAgent;
use Encode;
use EBook::EPUB;

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

    return $class, $self;
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

