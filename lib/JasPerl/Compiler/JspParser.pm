use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::JspParser;

# VERSION

my $RE = do {
    use Regexp::Grammars 1.026;
    use JasPerl::Compiler::Grammars::JSP;

    qr{
        <extends: JasPerl::Compiler::Grammars::JSP>
        <nocontext:>

        \A <page=JspPage> \Z
    }xs
};

use JasPerl::Util::Bean;

sub parse {
    my ($self, $page) = @_;

    if ($page =~ $RE) {
        return $/{page};
    } else {
        die "no match";
    }
}

sub parse_file {
    my ($self, $filename) = @_;
    open(my $fh, '<', $filename) or die "$filename: $!\n";
    my $page = join('', <$fh>);
    close($fh);
    return $self->parse($page);
}

1;

__END__

=head1 NAME

JasPerl::Compiler::JspParser - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::JspParser;

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
