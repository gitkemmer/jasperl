use 5.010;
use strict;
use warnings;

package JasPerl::RequestDispatcher;

# VERSION

use JasPerl::Role;

use constant {
    ERROR_EXCEPTION      => "javax.servlet.error.exception",
    ERROR_EXCEPTION_TYPE => "javax.servlet.error.exception_type",
    ERROR_MESSAGE        => "javax.servlet.error.message",
    ERROR_REQUEST_URI    => "javax.servlet.error.request_uri",
    ERROR_SERVLET_NAME   => "javax.servlet.error.servlet_name",
    ERROR_STATUS_CODE    => "javax.servlet.error.status_code",

    FORWARD_CONTEXT_PATH => "javax.servlet.forward.context_path",
    FORWARD_PATH_INFO    => "javax.servlet.forward.path_info",
    FORWARD_SERVLET_PATH => "javax.servlet.forward.servlet_path",
    FORWARD_QUERY_STRING => "javax.servlet.forward.query_string",
    FORWARD_REQUEST_URI  => "javax.servlet.forward.request_uri",

    INCLUDE_CONTEXT_PATH => "javax.servlet.include.context_path",
    INCLUDE_PATH_INFO    => "javax.servlet.include.path_info",
    INCLUDE_SERVLET_PATH => "javax.servlet.include.servlet_path",
    INCLUDE_QUERY_STRING => "javax.servlet.include.query_string",
    INCLUDE_REQUEST_URI  => "javax.servlet.include.request_uri",
};

around forward => sub {
    my ($orig, $self, $request, $response) = @_;
    # TODO: wrap request/response
    return $self->$orig($request, $response);
};

around include => sub {
    my ($orig, $self, $request, $response) = @_;
    # TODO: wrap request/response
    return $self->$orig($request, $response);
};

1;

__END__

=head1 NAME

JasPerl::RequestDispatcher - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::RequestDispatcher;

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
