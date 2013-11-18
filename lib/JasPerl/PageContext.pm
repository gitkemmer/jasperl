use 5.010;
use strict;
use warnings;

package JasPerl::PageContext;

# VERSION

use JasPerl::ErrorData;
use JasPerl::RequestDispatcher;
use JasPerl::Response;

use JasPerl::JspException;
use JasPerl::Util::Exception;
use JasPerl::Util::IllegalArgumentException;
use JasPerl::Util::IllegalStateException;
use JasPerl::Util::NullPointerException;

use constant {
    PAGE_SCOPE        => 'page',
    REQUEST_SCOPE     => 'request',
    SESSION_SCOPE     => 'session',
    APPLICATION_SCOPE => 'application'
};

use constant {
    APPLICATION => 'javax.servlet.jsp.jspApplication',
    CONFIG      => 'javax.servlet.jsp.jspConfig',
    EXCEPTION   => 'javax.servlet.jsp.jspException',
    OUT         => 'javax.servlet.jsp.jspOut',
    PAGE        => 'javax.servlet.jsp.jspPage',
    PAGECONTEXT => 'javax.servlet.jsp.jspPageContext',
    REQUEST     => 'javax.servlet.jsp.jspRequest',
    RESPONSE    => 'javax.servlet.jsp.jspResponse',
    SESSION     => 'javax.servlet.jsp.jspSession'
};

use JasPerl::Bean;

with qw(JasPerl::JspContext);

has _attributes => ( is => 'lazy', builder => '_build_attributes', clearer => '_clear_attributes' );
has _scopes => ( is => 'lazy', builder => '_build_scopes', clearer => '_clear_scopes' );

has _error_page_url => ( is => 'rw', writer => '_set_error_page_url' );

has page => ( is => 'rwp' );
has request => ( is => 'rwp' );
has response => ( is => 'rwp' );
has session => ( is => 'rwp' );

has errorData => ( is => 'lazy', clearer => '_clear_error_data' );
has exception => ( is => 'lazy', clearer => '_clear_exception' );

has servletConfig => ( is => 'lazy' );
has servletContext => ( is => 'lazy' );

my @SCOPES = ( PAGE_SCOPE, REQUEST_SCOPE, SESSION_SCOPE, APPLICATION_SCOPE );

sub DESTROY {
    warn ">>> PageContext destroy: @_";
}

sub _get_attribute {
    return shift->_attributes->get_attribute(@_);
}

sub _set_attribute {
    return shift->_attributes->set_attribute(@_);
}

sub _remove_attribute {
    my ($self, $name) = @_;
    foreach my $object (grep { defined } values %{$self->_scopes}) {
        $object->remove_attribute($name);
    }
}

sub _build_attributes {
    my $self = shift;

    my $attributes = JasPerl::PageContext::Attributes->new(
        APPLICATION() => $self->get_servlet_context(),
        CONFIG()      => $self->get_servlet_config(),
        OUT()         => $self->get_out(),
        PAGE()        => $self->get_page(),
        PAGECONTEXT() => $self,
        REQUEST()     => $self->get_request(),
        RESPONSE()    => $self->get_response()
    );

    if (my $session = $self->get_session()) {
        $attributes->set_attribute(+SESSION => $session);
    };

    return $attributes;
}

sub _build_error_data {
    return JasPerl::ErrorData->new(
        requestUri => $_[0]->get_request()->get_attribute(
            JasPerl::RequestDispatcher::ERROR_REQUEST_URI
        ),
        servletName => $_[0]->get_request()->get_attribute(
            JasPerl::RequestDispatcher::ERROR_SERVLET_NAME
        ),
        statusCode => $_[0]->get_request()->get_attribute(
            JasPerl::RequestDispatcher::ERROR_STATUS_CODE
        ) || 0,
        throwable => $_[0]->get_request()->get_attribute(
            JasPerl::RequestDispatcher::ERROR_EXCEPTION
        )
    );
}

sub _build_exception {
    my $error = $_[0]->get_request()->get_attribute(
        JasPerl::RequestDispatcher::ERROR_EXCEPTION
    ) or return;

    if (!JasPerl::Util::Exception->caught($error)) {
        $error = JasPerl::JspException->new(cause => $error);
    }

    return $error;
}

sub _build_scopes {
    return {
        PAGE_SCOPE() => $_[0]->_attributes,
        REQUEST_SCOPE() => $_[0]->get_request(),
        SESSION_SCOPE() => $_[0]->get_session(),
        APPLICATION_SCOPE() => $_[0]->get_request()->get_context()
    };
}

sub _build_servlet_config {
    require JasPerl::PageContext::ServletConfig;
    return JasPerl::PageContext::ServletConfig->new($_[0]);
}

sub _build_servlet_context {
    require JasPerl::PageContext::ServletContext;
    return JasPerl::PageContext::ServletContext->new($_[0]);
}

sub _build_variable_resolver {
    require JasPerl::EL::ImplicitObjectResolver;
    return JasPerl::EL::ImplicitObjectResolver->new(pageContext => $_[0]);
}

sub initialize {
    my ($self, $page, $request, $response, $errpage, $session, @bufargs) = @_;

    $self->_set_page($page);
    $self->_set_request($request);
    $self->_set_response($response);
    $self->_set_error_page_url($errpage);

    # JasPerl extension: if undefined, use session iff available
    if (defined $session ? $session : $request->has_session()) {
        $self->_set_session($request->get_session());
    }

    $self->_set_out(JasPerl::PageContext::Writer->new($response, @bufargs));
}

sub release {
    my $self = shift;

    # clear pushed bodies
    while ($self->pop_body()) { }
    $self->get_out()->flush();

    $self->_set_out(undef);
    $self->_set_page(undef);
    $self->_set_request(undef);
    $self->_set_response(undef);
    $self->_set_session(undef);
    $self->_set_error_page_url(undef);

    $self->_clear_attributes();
    $self->_clear_error_data();
    $self->_clear_exception();
    $self->_clear_scopes();

    # TODO: check if exists/clear?
    $self->get_variable_resolver()->release();
}

sub forward {
    my ($self, $path) = @_;
    my $out = $self->get_out();
    my $request = $self->get_request();
    my $response = $self->get_response();

    eval {
        $out->clear();
    };
    if (my $e = JasPerl::Util::IllegalStateException->caught()) {
        $e->throw();
    } elsif ($@) {
        JasPerl::Util::IllegalStateException->throw(cause => $@);
    }

    # unwrap response
    while ($response->DOES('JasPerl::ResponseWrapper')) {
        $response = $response->get_response();
    }

    # TODO: forwarded request?
    my $dispatcher = $request->get_request_dispatcher($path)
        or JasPerl::JspException->throw("no dispatcher for '$path'");
    $dispatcher->forward($request, $response);
}

sub include {
    my ($self, $path, $flush) = @_;
    my $out = $self->get_out();
    my $request = $self->get_request();
    my $response = $self->get_response();

    if ($flush || not defined $flush) {
        $out->flush(); # TODO: BodyContext?
    }

    # append to current out
    $response = JasPerl::PageContext::IncludeResponseWrapper->new(
        response => $response, writer => $out
    );

    # TODO: included request?
    my $dispatcher = $request->get_request_dispatcher($path)
        or JasPerl::JspException->throw("no dispatcher for '$path'");
    $dispatcher->include($request, $response);
}

sub handle_page_exception {
    my ($self, $e) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless $e;
    my $errpage = $self->_error_page_url
        or $e->throw();

    my $request = $self->get_request();
    $request->set_attribute(EXCEPTION, $e);
    $request->set_attribute(JasPerl::RequestDispatcher::ERROR_EXCEPTION,
                            $e);
    $request->set_attribute(JasPerl::RequestDispatcher::ERROR_STATUS_CODE,
                            JasPerl::Response::SC_INTERNAL_SERVER_ERROR);
    $request->set_attribute(JasPerl::RequestDispatcher::ERROR_REQUEST_URI,
                            $request->get_request_uri());
    $request->set_attribute(JasPerl::RequestDispatcher::ERROR_SERVLET_NAME,
                            $self->get_servlet_config()->get_servlet_name());

    eval {
        $self->forward($errpage);
    };
    if (my $e = JasPerl::Util::IllegalStateException->caught()) {
        $self->include($errpage);
    } elsif ($@) {
        JasPerl::JspException->throw(cause => $@);
    }

    # TODO: deal with exception in error page
    $request->remove_attribute(EXCEPTION);
    $request->remove_attribute(JasPerl::RequestDispatcher::ERROR_EXCEPTION);
    $request->remove_attribute(JasPerl::RequestDispatcher::ERROR_STATUS_CODE);
    $request->remove_attribute(JasPerl::RequestDispatcher::ERROR_REQUEST_URI);
    $request->remove_attribute(JasPerl::RequestDispatcher::ERROR_SERVLET_NAME);
}

sub get_attribute {
    my ($self, $name, $scope) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $name;
    return $self->_get_attribute($name)
        unless defined $scope;

    if (my $object = $self->_scopes->{$scope}) {
        return $object->get_attribute($name);
    } elsif ($scope eq SESSION_SCOPE) {
        JasPerl::Util::IllegalStateException->throw("no session available");
    } else {
        JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    }
}

sub set_attribute {
    my ($self, $name, $value, $scope) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $name;
    return $self->_set_attribute($name, $value)
        unless defined $scope;

    if (my $object = $self->_scopes->{$scope}) {
        return $object->set_attribute($name, $value);
    } elsif ($scope eq SESSION_SCOPE) {
        JasPerl::Util::IllegalStateException->throw("no session available");
    } else {
        JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    }
}

sub remove_attribute {
    my ($self, $name, $scope) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $name;
    return $self->_remove_attribute($name)
        unless defined $scope;

    if (my $object = $self->_scopes->{$scope}) {
        return $object->remove_attribute($name);
    } elsif ($scope eq SESSION_SCOPE) {
        JasPerl::Util::IllegalStateException->throw("no session available");
    } else {
        JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    }
}

sub get_attribute_names_in_scope {
    my ($self, $scope) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $scope;

    if (my $object = $self->_scopes->{$scope}) {
        $object->get_attribute_names();
    } elsif ($scope eq SESSION_SCOPE) {
        JasPerl::Util::IllegalStateException->throw("no session available");
    } else {
        JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    }
}

sub get_attributes_scope {
    my ($self, $name) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $name;

    my $scopes = $self->_scopes;
    foreach my $scope (@SCOPES) {
        my $object = $scopes->{$scope}
            or next;
        my $value = $object->get_attribute($name);
        return $scope if defined $value;
    }
    return;
}

sub find_attribute {
    my ($self, $name) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $name;

    my $scopes = $self->_scopes;
    foreach my $scope (@SCOPES) {
        my $object = $scopes->{$scope}
            or next;
        my $value = $object->get_attribute($name);
        return $value if defined $value;
    }
    return;
}

package # hide from PAUSE
    JasPerl::PageContext::Attributes;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub get_attribute {
    return $_[0]->{$_[1]};
}

sub set_attribute {
    if (defined $_[2]) {
        $_[0]->{$_[1]} = $_[2];
    } else {
        delete $_[0]->{$_[1]};
    }
}

sub remove_attribute {
    delete $_[0]->{$_[1]};
}

sub get_attribute_names {
    return JasPerl::Util::Enumeration->from_list(keys %{$_[0]});
}

package # hide from PAUSE
    JasPerl::PageContext::Writer;

use JasPerl::Bean;

with qw(JasPerl::JspWriter);

has _buffer => ( is => 'rw', clearer => '_clear_buffer', predicate => '_has_buffer' );
has _response => ( is => 'ro' );
has _out => ( is => 'rw' );

my $DEFAULT_BUFFER_SIZE = 16384;

sub clear {
    my $self = shift;
    JasPerl::Util::IOException->throw("cannot clear flushed buffer")
        unless $self->_has_buffer; # TODO: not init
    $self->_buffer_('');
}

sub flush {
    my $self = shift;

    if ($self->_has_buffer) {
        $self->_out($self->_response->get_writer);
        $self->_out->write($self->_buffer);
        $self->_clear_buffer();
    }

    $self->_out->flush() or JasPerl::Util::IOException->throw($!);
}

sub write {
    my ($self, $buf, $len, $off) = @_;
    $len = length $buf unless defined $len;

    if ($self->_has_buffer) {
        if ($len <= $self->get_remaining()) {
            $self->_buffer($self->_buffer . substr($buf, $off || 0, $len));
            return;
        } elsif ($self->is_auto_flush()) {
            $self->flush();
        } else {
            JasPerl::Util::IOException->throw('buffer overflow');
        }
    }

    $self->_out->write($buf, $len, $off || 0)
        or JasPerl::Util::IOException->throw($!);
}

sub get_remaining {
    my $self = shift;
    return 0 unless $self->_has_buffer;
    return $self->get_buffer_size() - length $self->_buffer;
}

sub BUILDARGS {
    my ($class, $response, $buffer_size, $auto_flush) = @_;
    $buffer_size = $DEFAULT_BUFFER_SIZE if $buffer_size < 0;

    return {
        _buffer => '',
        _response => $response,
        bufferSize => $buffer_size,
        autoFlush => $auto_flush
    };
}

package # hide from PAUSE
    JasPerl::PageContext::IncludeResponseWrapper;

use JasPerl::Bean;

extends qw(JasPerl::ResponseWrapper);

has writer => ( is => 'ro', required => 1 );

sub reset_buffer {
    $_[0]->get_writer()->clear_buffer();
}

sub flush_buffer {
    $_[0]->get_writer()->flush();
}

1;

__END__

=head1 NAME

JasPerl::PageContext - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::PageContext;

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
