use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::JspCompilationContext;

# VERSION

use JasPerl::EL::Expression;
use JasPerl::TagExt::BodyContent;
use Data::Dumper;
use Module::Runtime;

use constant {
    FILE_SCOPE        => 'file',
    PAGE_SCOPE        => 'page',
    APPLICATION_SCOPE => 'application',
};

# page directive
use constant {
    AUTO_FLUSH     => "jasperl.compiler.page.autoFlush",
    BUFFER         => "jasperl.compiler.page.buffer",
    CONTENT_TYPE   => "jasperl.compiler.page.contentType",
    ERROR_PAGE     => "jasperl.compiler.page.errorPage",
    EXTENDS        => "jasperl.compiler.page.extends",
    INFO           => "jasperl.compiler.page.info",
    IS_EL_IGNORED  => "jasperl.compiler.page.isELIgnored",
    IS_ERROR_PAGE  => "jasperl.compiler.page.isErrorPage",
    IS_THREAD_SAFE => "jasperl.compiler.page.isThreadSafe",
    PAGE_ENCODING  => "jasperl.compiler.page.pageEncoding",
    SESSION        => "jasperl.compiler.page.session"
};

# root action
use constant JSP_VERSION => "jasperl.compiler.page.jspVersion";

my @SCOPES = ( FILE_SCOPE, PAGE_SCOPE, APPLICATION_SCOPE );

use JasPerl::Bean;

with qw(JasPerl::JspContext);

has [ qw(pageGenerator runtime) ] => ( is => 'rwp' );

has config => ( is => 'lazy' );

has [ qw(_attributes _scopes) ] => ( is => 'lazy' );

sub _build_config {
    return $_[0]->get_runtime()->get_config();
}

sub _build__attributes {
    my $self = shift;
    return JasPerl::Compiler::JspCompilationContext::Attributes->new(
        #CONFIG()      => $self->get_config(),
        #OUT()         => $self->get_out(),
    );
}

sub _build__scopes {
    return {
        FILE_SCOPE()        => $_[0]->_attributes,
        PAGE_SCOPE()        => $_[0]->get_page_generator(),
        APPLICATION_SCOPE() => $_[0]->get_runtime(),
    };
}

sub include {
    my ($self, $path, $flush) = @_;

    my $out = $self->get_out();
    $out->flush() if $flush // 1;

    # TODO: make absolute path
    my $compiler = $self->get_runtime()->get_compiler($path);
    $compiler->include($self->get_module());
}

# JspContext interface

sub get_attribute {
    my ($self, $name, $scope) = @_;
    my $object = $self->_scopes->{$scope // FILE_SCOPE}
        or JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    return $object->get_attribute($name);
}

sub set_attribute {
    my ($self, $name, $value, $scope) = @_;
    my $object = $self->_scopes->{$scope // FILE_SCOPE}
        or JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    return $object->set_attribute($name, $value);
}

sub remove_attribute {
    my ($self, $name, $scope) = @_;

    if (defined $scope) {
        my $object = $self->_scopes->{$scope}
            or JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
        $object->remove_attribute($name);
    } else {
        foreach my $object (grep { defined } values %{$self->_scopes}) {
            $object->remove_attribute($name);
        }
    }
}

sub get_attribute_names_in_scope {
    my ($self, $scope) = @_;
    my $object = $self->_scopes->{$scope}
        or JasPerl::Util::IllegalArgumentException->throw("invalid scope: $scope");
    return $object->get_attribute_names();
}

sub get_attributes_scope {
    my ($self, $name) = @_;
    my $scopes = $self->_scopes;
    foreach my $scope (@SCOPES) {
        my $object = $scopes->{$scope}
            or next;
        my $value = $object->get_attribute($name);
        return $scope if defined $value;
    }
    return undef;
}

sub find_attribute {
    my ($self, $name) = @_;
    my $scopes = $self->_scopes;
    foreach my $scope (@SCOPES) {
        my $object = $scopes->{$scope}
            or next;
        my $value = $object->get_attribute($name);
        return $value if defined $value;
    }
    return undef;
}

# old interface

has _globals => ( is => 'lazy' );

has _methods => ( is => 'lazy' );

has _modules => ( is => 'lazy' );

has _taglibs => ( is => 'lazy' );

has _counters => ( is => 'ro', default => sub { +{ expr => 255 } } );

sub _build__globals {
    return { };
}

sub _build__methods {
    return { };
}

sub _build__modules {
    return { };
}

sub _build__taglibs {
    return { };
}

sub use_module {
    $_[0]->_modules->{Module::Runtime::use_module($_[1])}++;
}

sub get_modules {
    return [ keys %{$_[0]->_modules} ];
}

sub add_tag_library {
    my ($self, $prefix, $taglib) = @_;
    if (not exists $self->_taglibs->{$prefix}) {
        $self->_taglibs->{$prefix} = $taglib;
    } elsif ($self->_taglibs->{$prefix} ne $taglib) {
        die "prev taglib $prefix";
    }
}

sub get_tag_library {
    return $_[0]->_taglibs->{$_[1]};
}

sub add_expression {
    my ($self, $node) = @_;
    my $e = JasPerl::EL::Expression->new(
        root => $node->{expr}, source => $node->{''}
        );
    my $name = '_jspx_expr_' . $self->_counters->{expr}++;
    my $body = JasPerl::TagExt::BodyContent->new();
    my $dumper = Data::Dumper->new([ $e ], [ $name ]);
    $dumper->Terse(1) unless $name;
    $dumper->Indent(1);
    $body->print($dumper->Dump);

    $self->add_global($name, $body);
    $self->use_module('JasPerl::EL::Expression');

    return '$' . $name;
}

sub add_global {
    my ($self, $name, $code) = @_;
    die "existing global: $name" if exists $self->_globals->{$name};
    $self->_globals->{$name} = $code;
}

sub get_global {
    return $_[0]->_globals->{$_[1]};
}

sub get_global_names {
    return [ keys %{$_[0]->_globals} ];
}

sub add_method {
    my ($self, $name, $body) = @_;
    die if exists $self->_methods->{$name};
    $self->_methods->{$name} = $body;
}

sub get_method {
    return $_[0]->_methods->{$_[1]};
}

sub get_method_names {
    return [ keys %{$_[0]->_methods} ];
}

sub get_context_var {
    return '$ctx';
}

sub get_out_var {
    return '$out';
}

package # hide from PAUSE
    JasPerl::Compiler::JspCompilationContext::Attributes;

use JasPerl::Util::Enumeration;

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

1;

__END__

=head1 NAME

JasPerl::Compiler::JspCompilationContext - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::JspCompilationContext;

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

L<JasPerl::Compiler>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
