use 5.010;
use strict;
use warnings;

package JasPerl::EL::ImplicitObjectResolver;

# VERSION

use JasPerl::PageContext;

use JasPerl::Util::Bean;

with qw(JasPerl::EL::VariableResolver);

has pageContext => ( is => 'ro', required => 1, weak_ref => 1 );

has pageScope => ( is => 'lazy' );
has requestScope => ( is => 'lazy' );
has sessionScope => ( is => 'lazy' );
has applicationScope => ( is => 'lazy' );

has param => ( is => 'lazy', clearer => 1 );
has paramValues => ( is => 'lazy', clearer => 1 );
has header => ( is => 'lazy', clearer => 1 );
has headerValues => ( is => 'lazy', clearer => 1 );
has cookie => ( is => 'lazy', clearer => 1 );
has initParam => ( is => 'lazy', clearer => 1 );

my %IMPLICIT_OBJECT_METHODS = (
    pageContext => \&get_page_context,
    pageScope => \&get_page_scope,
    requestScope => \&get_request_scope,
    sessionScope => \&get_session_scope,
    applicationScope => \&get_application_scope,
    param => \&get_param,
    paramValues => \&get_param_values,
    header => \&get_header,
    headerValues => \&get_header_values,
    cookie => \&get_cookie,
    initParam => \&get_init_param
);

sub _make_scope_hash {
    my %hash;
    tie %hash, 'JasPerl::EL::ImplicitObjectResolver::ScopeHash', @_;
    return \%hash;
}

sub _build_page_scope {
    return _make_scope_hash($_[0], JasPerl::PageContext::PAGE_SCOPE);
}

sub _build_request_scope {
    return _make_scope_hash($_[0], JasPerl::PageContext::REQUEST_SCOPE);
}

sub _build_session_scope {
    # FIXME: undef if not available?
    return _make_scope_hash($_[0], JasPerl::PageContext::SESSION_SCOPE);
}

sub _build_application_scope {
    return _make_scope_hash($_[0], JasPerl::PageContext::APPLICATION_SCOPE);
}

sub _build_param {
    my $params = $_[0]->get_param_values()
        or return;
    return {
        map { $_ => $params->{$_}->[0] } keys %{$params}
    };
}

sub _build_param_values {
    my $context = $_[0]->get_page_context()
        or return;
    my $request = $context->get_request()
        or return;
    return $request->get_parameter_map();
}

sub _build_header {
    my $context = $_[0]->get_page_context()
        or return;
    my $request = $context->get_request()
        or return;
    my $headers = $request->get_header_names()
        or return;
    return {
        map { $_ => $request->get_header($_) } $headers->list()
    };
}

sub _build_header_values {
    my $context = $_[0]->get_page_context()
        or return;
    my $request = $context->get_request()
        or return;
    my $headers = $request->get_header_names()
        or return;
    return {
        map { $_ => $request->get_headers($_) } $headers->list()
    };
}

sub _build_cookie {
    my $context = $_[0]->get_page_context()
        or return;
    my $request = $context->get_request()
        or return;
    my $cookies = $request->get_cookies()
        or return;
    return {
        map { $_->get_name() => $_ } @{$cookies}
    };
}

sub _build_init_param {
    my $context = $_[0]->get_page_context()
        or return;
    my $page = $context->get_page()
        or return;
    my $params = $page->get_init_parameter_names()
        or return;
    return {
        map { $_ => $page->get_init_parameter($_) } $params->list()
    };
}

sub resolve_variable {
    my ($self, $name) = @_;
    if (my $method = $IMPLICIT_OBJECT_METHODS{$name}) {
        return $self->$method();
    } elsif (my $context = $self->get_page_context()) {
        return $context->find_attribute($name);
    } else {
        return;
    }
}

sub release {
    my $self = shift;
    $self->clear_param();
    $self->clear_param_values();
    $self->clear_header();
    $self->clear_header_values();
    $self->clear_cookie();
    $self->clear_init_param();
}

package # hide from PAUSE
    JasPerl::EL::ImplicitObjectResolver::ScopeHash;

use JasPerl::Util::Bean;

has '_context' => ( is => 'ro', weak_ref => 1 );
has '_scope' => ( is => 'ro' );
has '_names' => ( is => 'rw' );

sub TIEHASH {
    my ($class, $resolver, $scope) = @_;
    my $context = $resolver->get_page_context();
    return $class->new(_context => $context, _scope => $scope);
}

sub FETCH {
    my ($context, $scope) = ($_[0]->_context, $_[0]->_scope);
    return $context->get_attribute($_[1], $scope);
}

sub STORE {
    my ($context, $scope) = ($_[0]->_context, $_[0]->_scope);
    return $context->set_attribute($_[1], $_[2], $scope);
}

sub DELETE {
    my ($context, $scope) = ($_[0]->_context, $_[0]->_scope);
    return $context->remove_attribute($_[1], $scope);
}

sub EXISTS {
    my ($context, $scope) = ($_[0]->_context, $_[0]->_scope);
    return defined $context->get_attribute($_[1], $scope);
}

sub FIRSTKEY {
    my ($self, $context, $scope) = ($_[0], $_[0]->_context, $_[0]->_scope);
    $self->_names($context->get_attribute_names_in_scope($scope));
    return $self->NEXTKEY;
}

sub NEXTKEY {
    my ($context, $names) = ($_[0]->_context, $_[0]->_names);
    return unless $names and $names->has_next();
    return $names->next();
}

sub SCALAR {
    my ($context, $scope) = ($_[0]->_context, $_[0]->_scope);
    return $context->get_attribute_names_in_scope($scope)->has_next();
}

1;

__END__

=head1 NAME

JasPerl::EL::ImplicitObjectResolver - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::EL::ImplicitObjectResolver;

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
