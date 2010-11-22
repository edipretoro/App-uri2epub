use strict;
use warnings;
package App::uri2epub;
# ABSTRACT: a simple application to transform a URL into an ePub file.

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
    my ($self) = @_;
}

1;
