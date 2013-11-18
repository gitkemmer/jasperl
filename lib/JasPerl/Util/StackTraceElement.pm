use 5.010;
use strict;
use warnings;

# ABSTRACT: JasPerl::Util::StackTraceElement

package JasPerl::Util::StackTraceElement;

# VERSION

sub new {
    my $class = shift;
    # FIXME: NullPointerException - if declaringClass or methodName is null
    # handle negative line (n/a), -2: native method
    # TBD: combined class/method name as returned by caller(0)?
    # warn "STE: @_\n";
    bless [ @_ ], $class;
}

sub get_class_name {
    return $_[0]->[0];
}

sub get_method_name {
    return $_[0]->[1];
}

sub get_file_name {
    return $_[0]->[2];
}

sub get_line_number {
    return $_[0]->[3];
}

sub as_string {
    return sprintf("%s::%s(%s:%d)", @{$_[0]});
}

sub equals {
    my ($lhs, $rhs) = @_;
    return unless $rhs->isa(__PACKAGE__);
    return if $lhs->[0] ne $rhs->[0];
    return if $lhs->[1] ne $rhs->[1];
    return if $lhs->[2] ne $rhs->[2];
    return if $lhs->[3] ne $rhs->[3];
    return 1;
}

use overload (
    '""' => 'as_string',
    '==' => 'equals'
);

1;

__END__

=head1 NAME

JasPerl::Util::StackTraceElement - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Util::StackTraceElement;

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

Please report bugs or feature requests to Thomas Kemmer <tkemmer@cpan.org>.

=head1 SEE ALSO

L<http://www.perl.org>

=head1 AUTHOR

Thomas Kemmer <tkemmer@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
