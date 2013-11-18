use 5.010;
use strict;
use warnings;

package JasPerl::Util::Locale;

# VERSION

use List::Util qw(first);
use I18N::LangTags qw(locale2language_tag);

use JasPerl::Util::NullPointerException;

our @EXPORT_OK = qw(ROOT POSIX);

my $ROOT_LOCALE = JasPerl::Util::Locale->new('', '', '');

my $POSIX_LOCALE = JasPerl::Util::Locale->new('en', 'US', 'POSIX');

my $DEFAULT_LOCALE = eval {
    my $env = first { $ENV{$_} } qw(LANGUAGE LC_ALL LANG)
        or die "getting locale from environment failed";
    JasPerl::Util::Locale->parse($ENV{$env});
} || $POSIX_LOCALE;

sub new {
    my ($class, $language, $country, $variant) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $language;
    $country ||= '';
    $variant ||= '';

    bless [ lc $language, uc $country, $variant ], $class;
}

sub parse {
    my ($class, $s) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $s;

    # strip all locale extensions, e.g. "en_US.UTF-8" -> en_US
    # TODO: handle scripts, language tags, etc.
    $s =~ s/[^a-zA-Z_-].*$//;

    return $ROOT_LOCALE unless length $s;
    return $POSIX_LOCALE if $s eq 'C' or $s eq 'POSIX';
    return JasPerl::Util::Locale->new(split /[_-]/, $s, 3);
}

sub from_language_tag {
    # FIXME
    return $_[0]->parse($_[1]);
}

sub get_default {
    return $DEFAULT_LOCALE;
}

sub set_default {
    my ($class, $locale) = @_;
    JasPerl::Util::NullPointerException->throw()
        unless defined $locale;
    $DEFAULT_LOCALE = $locale;
}

sub get_language {
    return $_[0]->[0];
}

sub get_country {
    return $_[0]->[1];
}

sub get_variant {
    return $_[0]->[2];
}

sub as_language_tag {
    return locale2language_tag($_[0]->as_string);
}

sub as_string {
    my $self = shift;

    # variant must accompany a well-formed language or country code
    return '' unless $self->get_language() or $self->get_country();

    my $s = $self->get_language();
    $s .= '_' . $self->get_country()
        if $self->get_country() or $self->get_variant();
    $s .= '_' . $self->get_variant()
        if $self->get_variant();
    return $s;
}

use overload (
    '""' => 'as_string'
);

sub ROOT {
    return $ROOT_LOCALE;
}

sub POSIX {
    return $POSIX_LOCALE;
}

1;

__END__

=head1 NAME

JasPerl::Util::Locale - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Util::Locale;

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
