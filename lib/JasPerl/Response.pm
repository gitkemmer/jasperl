use 5.010;
use strict;
use warnings;

package JasPerl::Response;

# VERSION

use constant {
    SC_CONTINUE                        => 100,
    SC_SWITCHING_PROTOCOLS             => 101,

    SC_OK                              => 200,
    SC_CREATED                         => 201,
    SC_ACCEPTED 	               => 202,
    SC_NON_AUTHORITATIVE_INFORMATION   => 203,
    SC_NO_CONTENT                      => 204,
    SC_RESET_CONTENT                   => 205,
    SC_PARTIAL_CONTENT                 => 206,

    SC_MULTIPLE_CHOICES                => 300,
    SC_MOVED_PERMANENTLY               => 301,
    SC_FOUND                           => 302,
    SC_MOVED_TEMPORARILY               => 302,
    SC_SEE_OTHER                       => 303,
    SC_NOT_MODIFIED                    => 304,
    SC_USE_PROXY                       => 305,
    SC_TEMPORARY_REDIRECT              => 307,

    SC_BAD_REQUEST 	               => 400,
    SC_UNAUTHORIZED                    => 401,
    SC_PAYMENT_REQUIRED                => 402,
    SC_FORBIDDEN                       => 403,
    SC_NOT_FOUND                       => 404,
    SC_METHOD_NOT_ALLOWED              => 405,
    SC_NOT_ACCEPTABLE                  => 406,
    SC_PROXY_AUTHENTICATION_REQUIRED   => 407,
    SC_REQUEST_TIMEOUT                 => 408,
    SC_CONFLICT 	               => 409,
    SC_GONE                            => 410,
    SC_LENGTH_REQUIRED                 => 411,
    SC_PRECONDITION_FAILED             => 412,
    SC_REQUEST_ENTITY_TOO_LARGE        => 413,
    SC_REQUEST_URI_TOO_LONG            => 414,
    SC_UNSUPPORTED_MEDIA_TYPE          => 415,
    SC_REQUESTED_RANGE_NOT_SATISFIABLE => 416,
    SC_EXPECTATION_FAILED              => 417,

    SC_INTERNAL_SERVER_ERROR           => 500,
    SC_NOT_IMPLEMENTED                 => 501,
    SC_BAD_GATEWAY 	               => 502,
    SC_SERVICE_UNAVAILABLE             => 503,
    SC_GATEWAY_TIMEOUT                 => 504,
    SC_HTTP_VERSION_NOT_SUPPORTED      => 505,
};

use URI;

use JasPerl::Util::Enumeration;
use JasPerl::Util::Locale;

use JasPerl::Role;

requires qw(reset reset_buffer flush_buffer);

requires qw(contains_header set_header add_header);

has 'characterEncoding' => ( is => 'rw', default => 'ISO-8859-1' );
has 'committed' => ( is => 'rwp', boolean => 1 );
has 'contentType' => ( is => 'rw' );
has 'locale' => ( is => 'rw', builder => 1 );
has 'status' => ( is => 'rw', default => SC_OK );
has 'writer';

sub _build_locale {
    return JasPerl::Util::Locale->get_default();
}

sub add_cookie {
    # TODO: via add_header?
}

sub send_redirect {
    # TODO: buffer, status, headers
}

sub send_error {
    # TODO: buffer, status, headers
}

sub encode_url {
    return $_[1];
}

sub encode_redirect_url {
    return $_[0]->encode_url($_[1]);
}

1;

__END__

=head1 NAME

JasPerl::Response - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Response;

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

L<JasPerl>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
