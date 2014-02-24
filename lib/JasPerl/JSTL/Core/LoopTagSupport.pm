use strict;
use warnings;

package JasPerl::JSTL::Core::LoopTagSupport;

use JasPerl::PageContext;
use JasPerl::JSTL::Core::LoopTagStatus;
use JasPerl::Type::Boolean;
use JasPerl::Type::Number;

# VERSION

my $SCOPE = JasPerl::PageContext::PAGE_SCOPE;

# Role interface

use JasPerl::Role;

with qw(JasPerl::TagExt::SimpleTagSupport);

requires qw(has_next next);

has [ qw(_begin _end _step) ] => (
    is => 'rw', writer_prefix => 'set'
);

has [ qw(_var _var_status) ] => (
    is => 'rw', writer_prefix => 'set'
);

sub do_tag {
    my $self = shift;
    my $body = $self->get_jsp_body(); # FIXME: or return?

    my $begin = $self->_begin;
    my $step = $self->_step;
    my $end = $self->_end;
    # FIXME: check

    my $var = $self->_var;
    my $var_status = $self->_var_status;

    my $status = JasPerl::JSTL::Core::LoopTagStatus->new(
        begin => defined $begin ? JasPerl::Type::Number->value_of($begin) : undef,
        step  => defined $step ? JasPerl::Type::Number->value_of($step) : undef,
        end   => defined $end ? JasPerl::Type::Number->value_of($end) : undef,

        first => JasPerl::Type::Boolean::TRUE,
        last => JasPerl::Type::Boolean::FALSE
    ) if defined $var_status;

    $begin ||= 0;
    $step ||= 1;

    my $ctx = $self->get_jsp_context();

    eval {
        my $index = 0;
        my $current = undef;

        while ($index < $begin) {
            warn "skip: $index $begin";
            return unless $self->has_next(); # from eval
            $current = $self->next();
            $index++;
        }

        return unless $self->has_next(); # from eval
        $current = $self->next();


        # TODO: set var_status

        for (my ($count, $last) = (1); !$last; $count++) {
            for (my $i = $step; $i; $i--) {
                $last ||= (defined $end && $index + $i > $end)
                    and last;
                $last ||= !$self->has_next()
                    and last;
                $self->next() unless $i == 1;
            }

            if ($status) {
                $status->_set_current($current);
                $status->_set_count(JasPerl::Type::Number->value_of($count));
                $status->_set_index(JasPerl::Type::Number->value_of($index));
                $status->_set_last(JasPerl::Type::Boolean->value_of($last));
            }

            $ctx->set_attribute($var, $current, $SCOPE)
                if defined $var;
            $ctx->set_attribute($var_status, $status, $SCOPE)
                if defined $var_status;
            warn "invoke: $index";
            $body->invoke() if $body;

            last if $last;
            $index += $step;
            $current = $self->next();
            $status->_set_first(JasPerl::Type::Boolean::FALSE) if $status;
        }
    };

    my $e = $@;
    $ctx->remove_attribute($var, $SCOPE)
        if defined $var;
    $ctx->remove_attribute($var_status, $SCOPE)
        if defined $var_status;
    die $e if $e;
}

1;

__END__

=head1 NAME

JasPerl::JSTL::Core::LoopTagSupport - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::JSTL::Core::LoopTagSupport;

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

L<JasPerl::JSTL>

=head1 AUTHOR

Thomas Kemmer <tkemmer@computer.org>

=head1 COPYRIGHT

Copyright (c) 2013 Thomas Kemmer.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
