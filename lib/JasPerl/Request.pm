use 5.010;
use strict;
use warnings;

package JasPerl::Request;

# VERSION

# FIXME: CGI/1.1 defines "Basic" and "Digest"
use constant {
    BASIC_AUTH       => 'BASIC',
    CLIENT_CERT_AUTH => 'CLIENT_CERT',
    DIGEST_AUTH      => 'DIGEST',
    FORM_AUTH        => 'FORM'
};

use JasPerl::Util::Enumeration;

use JasPerl::Role;

with qw(JasPerl::Util::Attributes);

has 'authType';
has 'characterEncoding'; # TODO: lazy w/ set_character_encoding?
has 'contentLength';
has 'contentType';
has 'contextPath';
has 'cookies';
has 'localAddr';
has 'localName';
has 'localPort';
has 'locale';
has 'method';
has 'parameterMap';
has 'pathInfo';
has 'pathTranslated';
has 'protocol';
has 'queryString';
has 'reader';
has 'remoteAddr';
has 'remoteHost';
has 'remotePort';
has 'remoteUser';
has 'requestURI';
has 'requestURL';
has 'scheme';
has 'secure' => ( boolean => 1 );
has 'serverName';
has 'serverPort';
has 'servletPath';

has 'session' => ( predicate => 1 );

has 'context'; # TODO: private?

my %DEFAULT_PORTS = (
    http => 80,
    https => 442
);

# Accept-Language expressions
my $QVALUE        = qr{ \d+ (?: \. \d* )? }sx;
my $LANGUAGE_TAG  = qr{ [[:alpha:]]+ (?: - [[:alpha:]]+ )* }sx;
my $LANGUAGE_LIST = qr{ $LANGUAGE_TAG (?: , $LANGUAGE_TAG )* | [*] }sx;
my $LANGUAGE_Q    = qr{ ( $LANGUAGE_LIST ) (?: ; q= ( $QVALUE ) )? }sx;

sub _build_cookies {
    # FIXME: use headers?
    # default implementation returns null
}

sub _build_server_name {
    my $self = shift;
    # HTTP Host header always takes precedence
    if (my $header = $self->get_header('Host')) {
        my ($name, $port) = split(':', $header, 2);
        return $name;
    } else {
        return $self->get_local_name();
    }
}

sub _build_server_port {
    my $self = shift;
    # HTTP Host header always takes precedence
    if (my $header = $self->get_header('Host')) {
        my ($name, $port) = split(':', $header, 2);
        return $port || $DEFAULT_PORTS{$self->get_scheme()};
    } else {
        return $self->get_local_port();
    }
}

sub _build_request_uri {
    my $self = shift;
    # if PATH_INFO is not empty, it MUST start with a forward slash
    if (my $path_info = $self->get_path_info()) {
        $self->get_context_path() . $self->get_servlet_path() . $path_info;
    } else {
        $self->get_context_path() . $self->get_servlet_path();
    }
}

sub _build_request_url {
    my $self = shift;

    # FIXME: clone uri?
    my $uri = URI->new($self->get_request_uri());
    $uri->scheme($self->get_scheme());

    if (my $host = $self->get_header('Host')) {
        $uri->authority($host);
    } else {
        my $name = $self->get_server_name();
        my $port = $self->get_server_port();
        $uri->authority($name . ':' . $port);
    }

    return $uri->canonical;
}

sub _build_scheme {
    return $_[0]->is_secure() ? 'https' : 'http';
}

sub _build_parameter_map {
    return { }; # FIXME: required?
}

sub _build_locale {
    return $_[0]->get_locales()->next();
}

sub get_parameter {
    my $values = $_[0]->get_parameter_values($_[1])
        or return;
    return $values->[0];
}

sub get_parameter_names {
    return JasPerl::Util::Enumeration->from_list(
        keys %{$_[0]->get_parameter_map()}
    );
}

sub get_parameter_values {
    return $_[0]->get_parameter_map()->{$_[1]};
}

# HTTP interface

# TODO: -> enum: not an attribute?
sub get_locales {
    my $self = shift;

    # get_headers may return undef
    my $headers = $self->get_headers('Accept-Language')
        or return JasPerl::Util::Enumeration->from_list(JasPerl::Util::Locale->get_default());

    my %prefs = ( );
    while ($headers->has_next()) {
        my $header = $headers->next();
        $header =~ s/\s+//g; # remove all ws

        while ($header =~ m{\G $LANGUAGE_Q ,?}sxg) {
            next if $1 eq '*';
            my $q = defined $2 ? $2 : 1;
            push @{$prefs{$q}}, split(',', $1);
        }
    }

    # adapted from I18N::LangTags::Detect
    my @tags = map { @{$prefs{$_}} } sort { $b <=> $a } keys %prefs
        or return JasPerl::Util::Enumeration->from_list(JasPerl::Util::Locale->get_default());

    return JasPerl::Util::Enumeration->from_list(
        map { JasPerl::Util::Locale->from_language_tag($_) } @tags
    );
}

sub get_header {
    my $headers = $_[0]->get_headers($_[1])
        or return;
    return unless $headers->has_next();
    return $headers->next();
}

sub get_headers {
    # default implementation returns null - no access
}

sub get_header_names {
    # default implementation returns null - no access
}

sub get_request_dispatcher {
    my ($self, $path) = @_;
    my $uri = URI->new_abs($path, $self->get_request_uri());
    return $self->get_context()->get_request_dispatcher($uri);
}

1;

__END__

=head1 NAME

JasPerl::Request - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Request;

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
