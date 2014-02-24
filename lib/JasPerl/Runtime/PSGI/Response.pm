use strict;
use warnings;

package JasPerl::Runtime::PSGI::Response;

# VERSION

use HTTP::Headers;
use Plack::Response;

use JasPerl::Util::Bean;
with qw(JasPerl::Response);

has _headers => ( is => 'lazy' );

sub _build__headers {
    return HTTP::Headers->new;
}

sub _build_writer {
    return JasPerl::Runtime::PSGI::Response::Writer->new($_[0]);
}

sub reset {
}

sub reset_buffer {
}

sub flush_buffer {
}

sub contains_header {
    return defined $_[0]->_headers->header($_[1]);
}

sub set_header {
    $_[0]->_headers->header($_[1], $_[2]);
}

sub add_header {
    $_[0]->_headers->push_header($_[1], $_[2]);
}

# psgi/plack methods
sub finalize {
    my $self = shift;
    $self->_set_committed(1);
    return Plack::Response->new(
        $self->get_status(),
        $self->_headers,
        $self->get_writer()->body
    )->finalize();
}

package JasPerl::Runtime::PSGI::Response::Writer;

use Encode;

sub new {
    my ($class, $request) = @_;
    # TODO: contentType/characterEncoding/locale
    # TODO: UnsupportedEncodingException
    $request->set_header('Content-Type', $request->get_content_type());

    bless {
        encoding => find_encoding($request->get_character_encoding())
    }, $class;
}

sub flush {
    return $_[0]->{body} ||= [ ];
}

sub write {
    my ($self, $buf, $len, $off) = @_;
    $buf = substr($buf, $off || 0, $len)
        if defined $len;
    $buf = $self->{encoding}->encode($buf);
    return push @{$self->{body}}, $buf;
}

sub body {
    return $_[0]->{body};
}

1;

__END__

=head1 NAME

JasPerl::Runtime::PSGI::Response - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Runtime::PSGI::Response;

# Brief but working code example(s) here, showing the most common
# usage(s).

# This section will be as far as many users bother reading so make
# it as educational and exemplary as possible.

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)

=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's
interface.  These normally consist of either subroutines that may be
exported, or methods that may be called on objects belonging to the
classes that the module provides.  Name the section accordingly.

In an object-oriented module, this section should begin with a
sentence of the form "An object of this class represents...", to give
the reader a high-level context to help them understand the methods
that are subsequently described.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of
each problem, one or more likely causes, and any suggested remedies.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon,
including any restrictions on versions, and an indication whether
these required modules are part of the standard Perl distribution,
part of the module's distribution, or must be installed separately.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report bugs or feature requests to Thomas Kemmer <tkemmer@computer.org>.

=head1 SEE ALSO

L<JasPerl::Runtime::PSGI>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
