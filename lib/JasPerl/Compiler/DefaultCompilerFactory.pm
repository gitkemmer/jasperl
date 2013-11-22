use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::DefaultCompilerFactory;

# FIXME: private impl
use JasPerl::Compiler::CompilationContext;

# VERSION

use JasPerl::Util::Bean;

with qw(JasPerl::Compiler::JspCompilerFactory);

sub get_compilation_context {
    my $self = shift;
    my $context = JasPerl::Compiler::CompilationContext->new();
    $context->initialize(@_);
    return $context;
}

sub release_compilation_context {
    my ($self, $context) = @_;
    # warn "$self: release $context";
    $context->release() if $context;
}

package # hide from PAUSE
    JasPerl::Compiler::DefaultCompilerFactory::Attributes;

use JasPerl::Util::Enumeration;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub get_attribute_names {
    return JasPerl::Util::Enumeration->from_list(keys %{$_[0]});
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

package # hide from PAUSE
    JasPerl::Compiler::DefaultCompilerFactory::Context;

use JasPerl::Util::IllegalArgumentException;

#my @SCOPES = ( FILE_SCOPE, MODULE_SCOPE, APPLICATION_SCOPE );

sub throw_illegal_argument {
    JasPerl::Util::IllegalArgumentException->throw(@_);
}

use JasPerl::Util::Bean;

with qw(JasPerl::JspContext); # FIXME: CompilationContext

has [ qw(attributes scopes) ] => ( is => 'lazy' );

sub _build_attributes {
    return JasPerl::Compiler::DefaultCompilerFactory::Attributes->new(
        APPLICATION() => $_[0]->get_runtime_context(),
        COMPILER()    => $_[0]->get_jsp_compiler(),
        CONFIG()      => $_[0]->get_jsp_config(),
        MODULE()      => $_[0]->get_module(),
        OUT()         => $_[0]->get_out()
    );
}

sub _build_scopes {
    return {
        FILE_SCOPE()        => $_[0]->get_attributes(),
        MODULE_SCOPE()      => $_[0]->get_jsp_compiler(),
        APPLICATION_SCOPE() => $_[0]->get_runtime_context(),
    };
}

sub initialize {
    my ($self, $compiler, $module) = @_;
    $self->_set_jsp_compiler($compiler);
    $self->_set_module($module);
    #$self->_set_out(JasPerl::PageContext::Writer->new($response, @bufargs));
}

sub release {
    my $self = shift;

    # clear pushed bodies
    while ($self->pop_body()) { }
    $self->get_out()->flush();

    $self->_set_out(undef);
    $self->_set_jsp_compiler(undef);
    $self->_set_module(undef);
    $self->_clear_jsp_config();
    $self->_clear_runtime_context(undef);

    $self->_clear__attributes();
    $self->_clear__scopes();
}

sub get_attribute {
    my ($self, $name, $scope) = @_;
    my $object = $self->get_scopes()->{$scope // FILE_SCOPE}
        or throw_illegal_argument("invalid scope: $scope");
    return $object->get_attribute($name);
}

sub set_attribute {
    my ($self, $name, $value, $scope) = @_;
    my $object = $self->get_scopes()->{$scope // FILE_SCOPE}
        or throw_illegal_argument("invalid scope: $scope");
    $object->set_attribute($name, $value);
}

sub remove_attribute {
    my ($self, $name, $scope) = @_;
    my $scopes = $self->get_scopes();
    if (defined $scope) {
        my $object = $scopes->{$scope}
            or throw_illegal_argument("invalid scope: $scope");
        $object->remove_attribute($name);
    } else {
        foreach my $object (grep { defined } values %{$scopes}) {
            $object->remove_attribute($name);
        }
    }
}

sub get_attribute_names_in_scope {
    my ($self, $scope) = @_;
    my $object = $self->get_scopes()->{$scope}
        or throw_illegal_argument("invalid scope: $scope");
    return $object->get_attribute_names();
}

sub get_attributes_scope {
    my ($self, $name) = @_;
    my $scopes = $self->get_scopes();
    foreach my $scope (@SCOPES) {
        if (my $object = $scopes->{$scope}) {
            my $value = $object->get_attribute($name);
            return $scope if defined $value;
        }
    }
    return undef;
}

sub find_attribute {
    my ($self, $name) = @_;
    my $scopes = $self->get_scopes();
    foreach my $scope (@SCOPES) {
        if (my $object = $scopes->{$scope}) {
            my $value = $object->get_attribute($name);
            return $value if defined $value;
        }
    }
    return undef;
}

1;

__END__

=head1 NAME

JasPerl::Compiler::DefaultCompilerFactory - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::DefaultCompilerFactory;

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
