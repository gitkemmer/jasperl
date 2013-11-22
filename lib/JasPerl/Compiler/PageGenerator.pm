use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::PageGenerator;

use JasPerl::Compiler::CustomAction;
use JasPerl::Compiler::CompilationContext;
use JasPerl::Compiler::RootAction;
use JasPerl::Compiler::StandardActions;
use JasPerl::TagExt::BodyContent;
use JasPerl::Util::Functions qw(quote);

use IO::Handle;
use Module::Runtime qw(use_module);

# VERSION

my $CONTENT_TYPE = 'text/html; charset=UTF-8';

my $INDENT = ' ' x 4;

my @MODULES = qw(JasPerl::JspException JasPerl::JspFactory);

my $PAGE_HEADER = <<'.';
use utf8;
use strict;
use warnings;
.

my $PAGE_BODY = <<'.';
use JasPerl::Util::Bean;

with qw(JasPerl::JspPage);

sub _jsp_service {
    my ($self, $request, $response) = @_;
    my $factory = JasPerl::JspFactory->get_default_factory();
    my $ctx = $factory->get_page_context($self, $request, $response, __CONTEXT_ARGS__);

    my $ok = eval {
        $response->set_content_type(__CONTENT_TYPE__);
        $self->_jspx_main($ctx);
        1;
    };

    unless ($ok) {
        if (my $e = JasPerl::JspException->caught()) {
            $ctx->handle_page_exception($e) unless $e->isa('JasPerl::SkipPageException');
        } else {
            $ctx->handle_page_exception(JasPerl::JspException->new(cause => $@));
        }
    }

    $factory->release_page_context($ctx);
}
.

use JasPerl::Util::Bean;

with qw(JasPerl::Util::Attributes);

has writer => ( is => 'ro', default => sub { \*STDOUT } );

has context => ( is => 'lazy' );

sub _build_context {
    return JasPerl::Compiler::CompilationContext->new();
}

sub generate {
    my ($self, $page) = @_;

    my $ctx = $self->get_context();
    foreach my $module (@MODULES) {
        $ctx->use_module($module);
    };

    my $main = JasPerl::TagExt::BodyContent->new();
    $main->println('my ($self, $ctx) = @_;');
    $main->println('my $out = $ctx->get_out();');
    $ctx->push_body($main);

    my $root = JasPerl::Compiler::RootAction->new(version => '2.0');
    $root->set_jsp_context($ctx);
    $root->set_jsp_body(sub { $_[0]->do_scriptless_body($page) });
    $root->do_tag();

    $ctx->add_method('_jspx_main', $main);

    my $cname = 'Local::JSP::date_jsp'; # FIXME
    my $ctype = quote($ctx->get_attribute(JasPerl::Compiler::CompilationContext::CONTENT_TYPE) || $CONTENT_TYPE);
    my $session = $ctx->get_attribute('session');

    my @cargs = (
        quote($ctx->get_attribute('errpage')),
        $session && JasPerl::Type::Boolean->parse($session) ? 1 : 0,
        $ctx->get_attribute('buffer') || 8192,
        $ctx->get_attribute('autoFlush') || 1
    );
    my $cargs = join(', ', map { defined $_ ? $_ : 'undef' } @cargs);

    my $out = $self->get_writer();

    my $body = $PAGE_BODY;
    $body =~ s/__CONTENT_TYPE__/$ctype/g;
    $body =~ s/__CONTEXT_ARGS__/$cargs/g;

    $out->print("$PAGE_HEADER\n");
    $out->print("package $cname;\n\n");

    foreach my $module (sort @{$ctx->get_modules()}) {
        $out->print("use $module;\n");
    };

    $out->print("\n");
    $out->print("$body\n");

    foreach my $global (sort @{$ctx->get_global_names()}) {
        $out->print("my ");

        my $body = $ctx->get_global($global);
        while (my $line = $body->getline()) {
            $out->print($line);
        }
        $out->print("\n");
    };

    # FIXME: explicit
    foreach my $method (sort @{$ctx->get_method_names()}) {
        $out->print("sub $method {\n");

        my $body = $ctx->get_method($method);
        while (my $line = $body->getline()) {
            $out->print($INDENT, $line);
        }
        $out->print("}\n\n");
    };

    $out->print("1;\n");
}

1;

__END__

=head1 NAME

JasPerl::Compiler::PageGenerator - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::PageGenerator;

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
