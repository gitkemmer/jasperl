use 5.010;
use strict;
use warnings;

package JasPerl::Util::Throwable;

# VERSION

use JasPerl::Util::StackTraceElement;

use JasPerl::Util::Bean;

use Scalar::Util qw(blessed);

my %SPECIAL_METHODS = (
    '(unknown)' => '<unknown>',
    '__ANON__' => '<anon>'
);

sub _coerce {
    my $from = shift;
    return unless $from;
    # TODO: parse stack trace from scalar, set empty otherwise
    # TODO: handle autodie::exception?
    return __PACKAGE__->new(message => $from) unless ref $from;
    return __PACKAGE__->new(message => '' . $from) unless blessed $from;
    return __PACKAGE__->new(message => '' . $from) unless $from->isa(__PACKAGE__);
    return $from;
}

sub _build_stack_trace {
    my ($package, $file, $line);
    my $depth = 0;

    # skip our own (and Moo's) call frames
    while (($package, $file, $line) = caller($depth++)) {
        next if $package->isa(__PACKAGE__);
        next if $package->isa('Sub::Quote');
        last;
    }

    my @trace = ( );
    while (my @caller = caller($depth++)) {
        my $sub = $caller[3];
#        $sub ||= '<unknown>';
        next if $sub eq '(eval)'; # TODO: init/is_require

        $sub = substr($sub, length($package) + 2)
            if (index($sub, $package) == 0);
        $sub = $SPECIAL_METHODS{$sub}
            if exists $SPECIAL_METHODS{$sub};
        push @trace, JasPerl::Util::StackTraceElement->new(
            $package, $sub, $file, $line
        );
        ($package, $file, $line) = @caller;
    }

    push @trace, JasPerl::Util::StackTraceElement->new(
        $package, '<main>', $file, $line
    );

    return \@trace;
}

has message => (
    is => 'ro',
    isa => sub { die "$_[0] is not a string" if ref $_[0] }
);

has cause => (
    is => 'ro',
    coerce => \&_coerce
);

has stackTrace => (
    is => 'rw',
    default => \&_build_stack_trace,
    init_arg => undef
);

sub BUILDARGS {
    my $class = shift;

    if (@_ == 1) {
        return { message => $_[0] } unless ref $_[0];
        return { message => '' . $_[0], cause => $_[0] };
    } elsif (@_ == 2 && $_[0] ne 'message' && $_[0] ne 'cause') {
        return { message => $_[0], cause => $_[1] };
    } else {
        return { @_ };
    }
}

sub throw {
    my $proto = shift;
    die $proto if ref $proto;
    die $proto->new(@_);
}

sub catch {
    my ($class, $e) = ($_[0], @_ > 1 ? $_[1] : $@);
    return $e if defined $e and blessed $e and $e->isa($class);
    return unless $class eq __PACKAGE__;
    return _coerce($e);
}

sub caught {
    # Exception::Class compatibility
    my $e = $@;
    return unless defined $e and blessed $e and $e->isa($_[0]);
    return $e;
}

sub fill_in_stack_trace {
    my $self = shift;
    $self->set_stack_trace(_build_stack_trace);
    return $self;
}

sub print_stack_trace {
    my ($self, $out) = @_;
    $out ||= \*STDERR;

    $out->print($self->as_string, "\n");
    foreach my $frame (@{$self->get_stack_trace()}) {
        $out->print("\tat ", $frame->as_string, "\n");
    }

    if (my $cause = $self->get_cause()) {
        $cause->_print_cause_trace($out, $self->get_stack_trace());
    }
}

sub _print_cause_trace {
    my ($self, $out, $enclosing) = @_;
    my $trace = $self->get_stack_trace();

    # compute number of common frames
    my $ncommon = 0;
    while ($ncommon < @{$trace} && $ncommon < @{$enclosing}) {
        last unless $trace->[-1 - $ncommon]->equals($enclosing->[-1 - $ncommon]);
        $ncommon++;
    }

    $out->print("Caused by: ", $self->as_string, "\n");
    for (my $i = 0; $i != @{$trace} - $ncommon; $i++) {
        $out->print("\tat ", $trace->[$i]->as_string, "\n");
    }
    $out->print("\t... $ncommon more\n") if $ncommon;

    if (my $cause = $self->get_cause()) {
        $cause->_print_cause_trace($out, $self->get_stack_trace());
    }
}

sub as_string {
    my $self = shift;
    my $class = ref $self;
    my $message = $self->get_message();

    if (defined $message) {
        return $class . ': ' . $message;
    } else {
        return $class;
    }
}

use overload (
    '""' => 'as_string'
);

1;

__END__

=head1 NAME

JasPerl::Util::Throwable - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Util::Throwable;

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
