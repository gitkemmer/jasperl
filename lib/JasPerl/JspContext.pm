use 5.010;
use strict;
use warnings;

package JasPerl::JspContext;

# VERSION

use JasPerl::Role;

requires qw{
    get_attribute set_attribute remove_attribute
    get_attributes_scope get_attribute_names_in_scope
    find_attribute
};

has _bodies => ( is => 'rw', default => sub { [ ] } );

has out => ( is => 'rwp' );

has [ qw(expressionEvaluator variableResolver) ] => ( is => 'lazy' );

my $OUT = "javax.servlet.jsp.jspOut";

sub _build_expression_evaluator {
    # FIXME: JasPerl::EL::ExpressionEvaluator->get_default() ?
    require JasPerl::JspFactory;
    return JasPerl::JspFactory->get_default()->get_expression_evaluator();
}

sub _build_variable_resolver {
    require JasPerl::EL::ScopedAttributeResolver;
    return JasPerl::EL::ScopedAttributeResolver->new(jspContext => $_[0]);
}

sub push_body {
    my ($self, $writer) = @_;

    if (my $out = $self->get_out()) {
        push @{$self->_bodies}, $out;
    }

    $writer = JasPerl::JspContext::UnbufferedWriter->new($writer)
        unless $writer->DOES('JasPerl::JspWriter');
    $self->set_attribute($OUT, $writer);
    $self->_set_out($writer);
    return $writer;
}

sub pop_body {
    my ($self) = @_;
    my $out = pop @{$self->_bodies}
        or return;
    $self->set_attribute($OUT, $out);
    $self->_set_out($out);
    return $out;
}

package # hide from PAUSE
    JasPerl::JspContext::UnbufferedWriter;

use JasPerl::Bean;

use JasPerl::JspWriter; # NO_BUFFER

with qw(JasPerl::JspWriter);

has _writer => ( is => 'ro' );

sub clear {
    JasPerl::Util::IOException->throw();
}

sub flush {
    shift->_writer->flush() or JasPerl::Util::IOException->throw($!);
}

sub write {
    shift->_writer->write(@_) or JasPerl::Util::IOException->throw($!);
}

sub BUILDARGS {
    my ($class, $writer) = @_;

    return {
        bufferSize => JasPerl::JspWriter::NO_BUFFER,
        autoFlush => 0,
        _writer => $writer
    };
}

1;

__END__

=head1 NAME

JasPerl::JspContext - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::JspContext;

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
