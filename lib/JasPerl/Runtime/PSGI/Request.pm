use strict;
use warnings;

package JasPerl::Runtime::PSGI::Request;

# VERSION

use Plack::Request;

use JasPerl::Util::Bean;
use JasPerl::Util::Enumeration;
use JasPerl::Runtime::PSGI::Response;
use JasPerl::Runtime::PSGI::Session;

with qw(JasPerl::Request);

has _env => ( is => 'ro', init_arg => 'env' );
has _request => ( is => 'lazy' );

sub _build__request {
    return Plack::Request->new($_[0]->_env);
}

sub _build_auth_type {
    # FIXME: Plack::Middleware::Auth::Basic doesn't set AUTH_TYPE
    return $_[0]->_env->{AUTH_TYPE};
}

sub _build_character_encoding {
    # TODO
}

sub _build_content_length {
    my $length = $_[0]->_env->{CONTENT_LENGTH};
    return defined $length ? $length : -1;
}

sub _build_content_type {
    return $_[0]->_env->{CONTENT_TYPE};
}

sub _build_local_addr {
    my $env = $_[0]->_env;
    if (my $socket = $env->{'psgix.io'}) {
        return $socket->sockhost;
    } else {
        return $env->{SERVER_NAME};
    }
}

sub _build_local_name {
    my $env = $_[0]->_env;
    if (my $socket = $env->{'psgix.io'}) {
        return $socket->sockhost;
    } else {
        return $env->{SERVER_NAME};
    }
}

sub _build_local_port {
    my $env = $_[0]->_env;
    if (my $socket = $env->{'psgix.io'}) {
        return $socket->sockport;
    } else {
        return $env->{SERVER_PORT};
    }
}

sub _build_method {
    return $_[0]->_env->{REQUEST_METHOD};
}

sub _build_parameter_map {
    return $_[0]->_request->parameters->multi;
}

sub _build_path_info {
    return $_[0]->_env->{PATH_INFO};
}

sub _build_path_translated {
    # FIXME: no PATH_TRANSLATED in PSGI?
    return $_[0]->_env->{PATH_TRANSLATED};
}

sub _build_protocol {
    return $_[0]->_env->{SERVER_PROTOCOL};
}

sub _build_query_string {
    # QUERY_STRING must be present if empty
    my $qs = $_[0]->_env->{QUERY_STRING};
    return unless length $qs;
    return $qs;
}

sub _build_reader {
    return $_[0]->_env->{'psgi.input'};
}

sub _build_remote_addr {
    return $_[0]->_env->{REMOTE_ADDR};
}

sub _build_remote_host {
    return $_[0]->_env->{REMOTE_HOST} || $_[0]->_env->{REMOTE_ADDR};
}

sub _build_remote_port {
    return $_[0]->_env->{REMOTE_PORT};
}

sub _build_remote_user {
    return $_[0]->_env->{REMOTE_USER};
}

sub _build_scheme {
    return $_[0]->_env->{'psgi.url_scheme'};
}

sub _build_servlet_path {
    # SCRIPT_NAME must be present if empty
    return $_[0]->_env->{SCRIPT_NAME};
}

sub _build_secure {
    return $_[0]->_env->{'psgi.url_scheme'} eq 'https';
}

sub _build_session {
    # FIXME: set in ctor if available, throw here
    return JasPerl::Runtime::PSGI::Session->new($_[0]->_env);
}

sub get_header {
    # PSGI always has single (combined) header
    return scalar $_[0]->_request->header($_[1]);
}

sub get_headers {
    return JasPerl::Util::Enumeration->from_list(
        $_[0]->_request->header($_[1])
    );
}

sub get_header_names {
    return JasPerl::Util::Enumeration->from_list(
        $_[0]->_request->headers->header_field_names
    );
}

sub new_response {
    my $self = shift;
    return JasPerl::Runtime::PSGI::Response->new(@_);
}

1;

__END__

=head1 NAME

JasPerl::Runtime::PSGI::Request - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Runtime::PSGI::Request;

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
