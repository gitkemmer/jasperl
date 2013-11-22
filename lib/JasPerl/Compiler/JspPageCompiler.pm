use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::JspPageCompiler;

use JasPerl::Compiler::JspCompilerFactory;
use JasPerl::Compiler::JspParser;
use Try::Tiny;

# VERSION

my $FACTORY = JasPerl::Compiler::JspCompilerFactory->get_default_factory();

my $MODULE_PERL_VERSION = '5.010';
my @MODULE_PRAGMAS = qw(strict warnings);

use JasPerl::Util::Bean;

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

with qw(JasPerl::Compiler::JspCompiler);

has [ qw(jspConfig parser) ] => ( is => 'lazy' );

sub _build_parser {
    # TODO: need parser or tree?
    my $self = shift;
    if ($self->get_jsp_config()->is_xml($self->get_source_path())) {
        die "JSP documents not supported\n";
    } else {
        return JasPerl::Compiler::JspParser->new();
    }
}

sub compile {
    my ($self, $module) = @_;
    # TODO: encoding
    $module->set_perl_version($MODULE_PERL_VERSION);
    $module->add_pragma($_) foreach @MODULE_PRAGMAS;

    my $out = $module->get_writer();
    my $path = $self->get_source_path();
    my $package = $self->get_jsp_config()->get_package_name($path);
    $out->println('package ', $package, ';');
    $self->include($module);
    $out->println('1;');
}

sub include {
    my ($self, $module) = @_;
    my $context = $FACTORY->get_compilation_context($self, $module);

    try {
        my $path = $self->get_context()->get_real_path($self->get_source_path());
        my $page = $self->get_parser()->parse_file($path); # encoding?
        my $root = JasPerl::Compiler::RootAction->new(version => '2.0');
        $root->set_jsp_context($context);
        $root->set_jsp_body(sub { $_[0]->do_scriptless_body($page) });
        $root->do_tag();
    } catch {
        if (my $e = JasPerl::JspException->caught($_)) {
            $context->handle_exception($e);
        } else {
            $context->handle_exception(JasPerl::JspException->new(cause => $_));
        }
    } finally {
        $FACTORY->release_page_context($context);
    };
}

1;

__END__

=head1 NAME

JasPerl::Compiler::JspPageCompiler - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::JspPageCompiler;

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
