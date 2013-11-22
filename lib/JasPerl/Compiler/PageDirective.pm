use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::PageDirective;

use JasPerl::Compiler::CompilationContext;

# VERSION

use JasPerl::TagExt::Tag;

with qw(JasPerl::TagExt::EmptyTagSupport);

has [ qw(buffer contentType errorPage info pageEncoding) ] => (
    predicate => 1
);

has [ qw(session autoFlush) ] => (
    boolean => 1, predicate => 1, coerce => sub {
        # FIXME: Tag handles boolean?
        JasPerl::Type::Boolean->value_of($_[0])
    }
);

# ignored/error
has [ qw(isErrorPage isThreadSafe) ] => (
    reader_prefix => ''
);

# ignored/error
has [ qw(language import) ] => ( is => 'ro' );

sub do_tag {
    my $self = shift;
    my $ctx = $self->get_jsp_context();

    if ($self->has_buffer()) {
        my ($buffer) = $self->get_buffer() =~ /^(\d+)kb$/
            or die "invalid buffer '", $self->get_buffer(), "'";
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::BUFFER,
            $buffer * 1024
        );
    }

    if ($self->has_content_type()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::CONTENT_TYPE,
            $self->get_content_type()
        );
    }

    if ($self->has_error_page()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::ERROR_PAGE,
            $self->get_error_page()
        );
    }

    if ($self->has_info()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::INFO,
            $self->get_info()
        );
    }

    if ($self->has_page_encoding()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::PAGE_ENCODING,
            $self->get_page_encoding()
        );
    }

    if ($self->has_auto_flush()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::AUTO_FLUSH,
            $self->is_auto_flush()
        );
    }

    if ($self->has_session()) {
        $ctx->set_attribute(
            JasPerl::Compiler::CompilationContext::SESSION,
            $self->is_session()
        );
    }
}

1;

__END__

=head1 NAME

JasPerl::Compiler::PageDirective - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::PageDirective;

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
