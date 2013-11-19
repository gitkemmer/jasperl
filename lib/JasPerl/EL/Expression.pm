use 5.010;
use strict;
use warnings;

package JasPerl::EL::Expression;

# VERSION

use JasPerl::Type::Boolean;
use JasPerl::Type::Number;
use JasPerl::Type::String;

use JasPerl::Util::Beans;

use Scalar::Util qw(blessed looks_like_number);

my ($TRUE, $FALSE) = (
    JasPerl::Type::Boolean::TRUE,
    JasPerl::Type::Boolean::FALSE
);

my %EMPTY_OPS = (
    '' => sub {
        return length $_[0] ? $FALSE : $TRUE;
    },
    ARRAY => sub {
        return @{$_[0]} ? $FALSE : $TRUE;
    },
    HASH => sub {
        return %{$_[0]} ? $FALSE : $TRUE;
    },
    'JasPerl::Type::String' => sub {
        return $_[0]->is_empty() ? $TRUE : $FALSE;
    }
);

my %UNARY_OPS = (
    var => sub {
        my ($arg, $resolver) = @_;
        die "no resolver for '$arg'" unless $resolver;
        return $resolver->resolve_variable($arg);
    },
    int => sub {
        return JasPerl::Type::Number->value_of($_[0]);
    },
    bool => sub {
        return JasPerl::Type::Boolean->value_of($_[0]);
    },
    float => sub {
        return JasPerl::Type::Number->value_of($_[0]);
    },
    string => sub {
        return JasPerl::Type::String->value_of($_[0]);
    },
    not => sub {
        return !JasPerl::Type::Boolean->value_of(_evaluate(@_));
    },
    neg => sub {
        return -JasPerl::Type::Number->value_of(_evaluate(@_));
    },
    empty => sub {
        my $obj = _evaluate(@_);
        if (my $op = $EMPTY_OPS{ref $obj}) {
            return $op->($obj);
        } else {
            return $FALSE;
        }
    },
    prop => sub {
        my ($arg, $resolver) = @_;
        my @args = @{$arg};
        my $obj = _evaluate(shift @args, $resolver);
        while (@args && defined $obj) {
            my $prop = _evaluate(shift @args, $resolver);
            last unless defined $prop;

            if (blessed $obj) {
                $obj = JasPerl::Util::Beans->get_property($obj, $prop);
            } elsif (ref $obj eq 'ARRAY') {
                $obj = $obj->[$prop];
            } elsif (ref $obj eq 'HASH') {
                $obj = $obj->{$prop};
            } else {
                warn "prop $obj . $prop ???";
            }
        }
        return $obj;
    },
    cond => sub {
        my ($arg, $resolver) = @_;

        # not really a unary operator...
        my $cond = _evaluate($arg->[0], $resolver);
        if (JasPerl::Type::Boolean->value_of($cond)) {
            return _evaluate($arg->[1], $resolver);
        } else {
            return _evaluate($arg->[2], $resolver);
        }
    }
);

my %BINARY_OPS = (
    or => sub {
        my $lhs = JasPerl::Type::Boolean->value_of(shift);
        return $lhs || JasPerl::Type::Boolean->value_of(_evaluate(@_));
    },
    and => sub {
        my $lhs = JasPerl::Type::Boolean->value_of(shift);
        return $lhs && JasPerl::Type::Boolean->value_of(_evaluate(@_));
    },
    eq => sub {
        return _compare(shift, _evaluate(@_)) == 0 ? $TRUE : $FALSE;
    },
    ne => sub {
        return _compare(shift, _evaluate(@_)) != 0 ? $TRUE : $FALSE;
    },
    lt => sub {
        return _compare(shift, _evaluate(@_)) < 0 ? $TRUE : $FALSE;
    },
    gt => sub {
        return _compare(shift, _evaluate(@_)) > 0 ? $TRUE : $FALSE;
    },
    le => sub {
        return _compare(shift, _evaluate(@_)) <= 0 ? $TRUE : $FALSE;
    },
    ge => sub {
        return _compare(shift, _evaluate(@_)) >= 0 ? $TRUE : $FALSE;
    },
    add => sub {
        my $lhs = JasPerl::Type::Number->value_of(shift);
        my $rhs = JasPerl::Type::Number->value_of(_evaluate(@_));
        # TODO: overload ops, Math::*, undef
        return JasPerl::Type::Number->value_of($lhs->value + $rhs->value);
    },
    sub => sub {
        my $lhs = JasPerl::Type::Number->value_of(shift);
        my $rhs = JasPerl::Type::Number->value_of(_evaluate(@_));
        # TODO: overload ops, Math::*, undef
        return JasPerl::Type::Number->value_of($lhs->value - $rhs->value);
    },
    mul => sub {
        my $lhs = JasPerl::Type::Number->value_of(shift);
        my $rhs = JasPerl::Type::Number->value_of(_evaluate(@_));
        # TODO: overload ops, Math::*, undef
        return JasPerl::Type::Number->value_of($lhs->value * $rhs->value);
    },
    div => sub {
        my $lhs = JasPerl::Type::Number->value_of(shift);
        my $rhs = JasPerl::Type::Number->value_of(_evaluate(@_));
        # TODO: overload ops, Math::*, undef
        return JasPerl::Type::Number->value_of($lhs->value / $rhs->value);
    },
    mod => sub {
        my $lhs = JasPerl::Type::Number->value_of(shift);
        my $rhs = JasPerl::Type::Number->value_of(_evaluate(@_));
        # TODO: overload ops, Math::*, undef
        return JasPerl::Type::Number->value_of($lhs->value % $rhs->value);
    }
);

sub _compare {
    my ($lhs, $rhs) = @_;

    # TODO: type coercions

    if (looks_like_number($lhs) && looks_like_number($rhs)) {
        return $lhs <=> $rhs;
    } else {
        return $lhs cmp $rhs;
    }
}

sub _invoke {
    return $_[0]->(map { _evaluate($_, $_[2]) } @{$_[1]});
}

sub _reduce {
    my ($ops, $expr, $resolver) = @_;
    my @expr = @{$expr};
    my $val = _evaluate(shift @expr, $resolver);

    foreach my $op (@{$ops}) {
        if (my $fn = $BINARY_OPS{$op}) {
            $val = $fn->($val, shift @expr, $resolver);
        } else {
            die "no op: $op";
        }
    }
    return $val;
}


sub _evaluate {
    my ($expr, $resolver) = @_;

    return $expr unless defined $expr or ref $expr eq 'HASH';

    if (my $op = $expr->{op}) {
        if (ref $op eq 'ARRAY') {
            return _reduce($op, $expr->{arg}, $resolver);
        } elsif (ref $op eq 'CODE' || ref \$op eq 'GLOB') {
            return _invoke($op, $expr->{arg}, $resolver);
        } elsif (my $fn = $UNARY_OPS{$op}) {
            return $fn->($expr->{arg}, $resolver);
        } else {
            die "WTF: $expr->{op}";
        }
    } else {
        die "WTF: ", keys %{$expr};
    }
}

use JasPerl::Util::Bean;

has root => ( is => 'ro', required => 1 );

has source => ( is => 'ro' );

sub evaluate {
    my ($self, $resolver) = @_;

    # TODO: eval block, parse exception
    return _evaluate($self->get_root(), $resolver);
}

1;

__END__

=head1 NAME

JasPerl::EL::Expression - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::EL::Expression;

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
