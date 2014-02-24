use strict;
use warnings;

package JasPerl::Runtime::PSGI;

# VERSION

use Module::Load;

use JasPerl::Runtime::PSGI::Dispatcher;
use JasPerl::Runtime::PSGI::Request;

use JasPerl::Util::Bean;

with qw(JasPerl::RuntimeContext);

sub new_request {
    my ($self, $env) = @_;
    return JasPerl::Runtime::PSGI::Request->new(context => $self, env => $env);
}

sub get_request_dispatcher {
    my ($self, $path) = @_;
    # TODO: check if plain file, use right file dispatcher
    # TODO: cache dispatchers
    # FIXME: exception handling

    my $module = get_module_name($path);

    load $module;

    my $page = $module->new;
    $page->init();

    warn "## $page $path";
    return JasPerl::Runtime::PSGI::Dispatcher->new($page);
}

sub get_module_name {
    # FIXME: from context?
    my $jsp_package = 'Local::JSP';

    my $path = shift;
    my @pseg = map {
        s/(\W|_)+/_/g;
        length($_) ? ($_) : ()
    } split('/', $path);
    unshift @pseg, $jsp_package if $jsp_package;
    return join('::', @pseg);
}

1;

__END__

=head1 NAME

JasPerl::Runtime::PSGI - Java Server Pages for PSGI

=head1 SYNOPSIS

use JasPerl::Runtime::PSGI;

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

L<JasPerl::Runtime::PSGI>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
