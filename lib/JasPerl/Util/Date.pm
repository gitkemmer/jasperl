use 5.010;
use strict;
use warnings;

package JasPerl::Util::Date;

use Time::HiRes;
use Time::Piece;

# VERSION

use JasPerl::Bean;

with qw(JasPerl::Util::Cloneable);

has time => ( is => 'rw', trigger => 1, default => sub {
    int(Time::HiRes::time() * 1000)
});

has [ qw(_epoch _gmtime _localtime _string) ] => (
    is => 'lazy', clearer => 1, reader_prefix => 'as'
);

sub _trigger_time {
    my $self = shift;
    $self->_clear_epoch();
    $self->_clear_gmtime();
    $self->_clear_localtime();
    $self->_clear_string();
}

sub _build__epoch {
    return int($_[0]->get_time() / 1000);
}

sub _build__gmtime {
    return gmtime($_[0]->as_epoch);
}

sub _build__localtime {
    return localtime($_[0]->as_epoch);
}

sub _build__string {
    return $_[0]->as_localtime->strftime('%a %b %d %T %Z %Y');
}

use overload (
    '""' => sub { $_[0]->as_string }
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    unshift @args, 'time' unless @args != 1 or ref $args[0];
    return $class->$orig(@args);
};

1;

__END__

=head1 NAME

JasPerl::Util::Date - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Util::Date;

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
