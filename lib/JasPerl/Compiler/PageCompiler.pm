use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::PageCompiler;

use JasPerl::Compiler::RootAction;

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

# VERSION

my $MODULE_PERL_VERSION = '5.010';
my @PRAGMAS = qw(5.010 strict warnings);


use JasPerl::Util::Bean;

with qw(JasPerl::Compiler);

has [ qw(runtime) ] => ( is => 'ro', required => 1 );

has [ qw(jspConfig parser) ] => ( is => 'lazy' );

sub _build_jsp_config {
    return $_[0]->get_runtime()->get_jsp_config();
}

sub _build_parser {
    if ($_[0]->get_jsp_config()->is_xml($self->get_page())) {
        die "JSP documents not supported\n";
    } else {
        return JasPerl::Compiler::JspParser->new();
    }
}

sub compile {
    my ($self, $unit, $module) = @_;
    my $config = $self->get_jsp_config();
    my $path = $self->get_runtime()->get_real_path($unit->get_path());
    my $ast = $self->get_parser->parse_file($path); # encoding

    $module->set_perl_version($MODULE_PERL_VERSION);
    $module->add_pragma($_) foreach @PRAGMAS;

    my $ctx = JasPerl::Compiler::JspCompilationContext->new(
        module => $module,
        runtime => $self->get_runtime()
    );

    my $out = $module->get_writer();
    $out->println('package ', $config->get_package_name($unit->get_path()), ';');

    my $root = JasPerl::Compiler::RootAction->new(version => '2.0');
    $root->set_jsp_context($ctx);
    $root->set_jsp_body(sub { $_[0]->do_scriptless_body($page) });
    $root->do_tag();

    $out->println('1;');
}

sub include {
    my ($self, $unit, $module) = @_;
    my $path = $self->get_runtime()->get_real_path($unit->get_path());
    my $ast = $self->get_parser->parse_file($path);

    my $ctx = JasPerl::Compiler::JspCompilationContext->new(
        module => $module,
        runtime => $self->get_runtime()
    );
}

1;

__END__

=head1 NAME

JasPerl::Compiler::PageCompiler - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::PageCompiler;

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
