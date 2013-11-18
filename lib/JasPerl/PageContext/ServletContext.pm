use 5.010;
use strict;
use warnings;

package JasPerl::PageContext::ServletContext;

# VERSION

use JasPerl::Util::Enumeration;
use Scalar::Util;

sub new {
    my ($class, $context) = @_;
    Scalar::Util::weaken($context);
    bless \$context, $class;
}

sub get_attribute {
    return ${$_[0]}->get_request()->get_context()->get_attribute($_[1]);
}

sub set_attribute {
    return ${$_[0]}->get_request()->get_context()->set_attribute($_[1], $_[2]);
}

sub remove_attribute {
    return ${$_[0]}->get_request()->get_context()->remove_attribute($_[1]);
}

sub get_attribute_names {
    return ${$_[0]}->get_request()->get_context()->get_attribute_names();
}

sub get_context_path {
    return ${$_[0]}->get_request()->get_context()->get_context_path();
}

sub get_init_parameter {
    # no init parameters
}

sub get_init_parameter_names {
    return JasPerl::Util::Enumeration::EMPTY_ENUMERATION;
}

sub get_major_version {
    return 0;
}

sub get_minor_version {
    return 0;
}

sub get_server_info {
    return ${$_[0]}->get_request()->get_context()->get_server_info();
}

sub get_servlet_context_name {
    # null if no name has been declared in the deployment descriptor
}

1;

__END__

=head1 NAME

JasPerl::PageContext::ServletContext - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::PageContext::ServletContext;

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
