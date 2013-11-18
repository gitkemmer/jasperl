use 5.010;
use strict;
use warnings;

package Method::Generate::Accessor::Role::JasPerl::Bean;

use Sub::Quote;

# VERSION

use Moo::Role;

around generate_method => sub {
    my $orig = shift;
    my $self = shift;

    my ($target, $name, $spec) = @_;

    if ($name !~ /^[_+]/) {
        # convert camel case to lower case w/underscores
        $name =~ s/([[:lower:]])([[:upper:]]+)/$1_\L$2\E/g;

        my $is = $spec->{is} or die "no is for $target -> $name";

        my $boolean = delete $spec->{boolean};
        my $get = delete $spec->{reader_prefix} || ($boolean ? "is_" : "get_");
        my $set = delete $spec->{writer_prefix} || ($is eq 'rwp' ? '_set_' : 'set_');

        if ($is eq 'ro') {
            $spec->{reader} = "${get}${name}" unless exists $spec->{reader};
        } elsif ($is eq 'rw' || $is eq 'rwp') {
            $spec->{reader} = "${get}${name}" unless exists $spec->{reader};
            $spec->{writer} = "${set}${name}" unless exists $spec->{writer};
        } elsif ($is eq 'lazy') {
            $spec->{reader} = "${get}${name}" unless exists $spec->{reader};
            $spec->{builder} = 1 unless exists $spec->{builder};
        }

        if (($spec->{builder} || 0) eq 1) {
            $spec->{builder} = "_build_${name}";
        }
        if (($spec->{trigger} || 0) eq 1) {
            $spec->{trigger} = quote_sub('shift->_trigger_'.$name.'(@_)');
        }

        if (($spec->{clearer} || 0) eq 1) {
            $spec->{clearer} = "clear_${name}";
        } elsif (($spec->{clearer} || 0) eq -1) {
            $spec->{clearer} = "_clear_${name}";
        }

        if (($spec->{predicate} || 0) eq 1) {
            $spec->{predicate} = "has_${name}";
        } elsif (($spec->{predicate} || 0) eq -1) {
            $spec->{predicate} = "_has_${name}";
        }
    } else {
        if (my $get = delete $spec->{reader_prefix}) {
            $spec->{reader} = "${get}${name}" unless exists $spec->{reader};
        }
        if (my $set = delete $spec->{writer_prefix}) {
            $spec->{writer} = "${set}${name}" unless exists $spec->{writer};
        }
    }

    $self->$orig(@_);
};

1;

__END__

=head1 NAME

Method::Generate::Accessor::Role::JasPerl::Bean - <One line description of module's purpose>

=head1 SYNOPSIS

use Method::Generate::Accessor::Role::JasPerl::Bean;

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
