use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::ExpressionParser;

use JasPerl::Compiler::Grammars::EL;
use JasPerl::EL::Expression;

# VERSION

my $RE = do {
    use Regexp::Grammars 1.026;

    qr{
        <extends: JasPerl::Compiler::Grammars::EL>

        \A \${ <expr=Expression> } \Z
    }xs
};

use JasPerl::Bean;

with qw(JasPerl::EL::ExpressionEvaluator);

sub apply_function_mapper {
    my ($self, $expr, $mapper) = @_;
    return JasPerl::EL::Expression->new(source => $expr, root => $/{expr});
}

sub parse_expression {
    my ($self, $expr, $mapper) = @_;

    my $actions = JasPerl::Compiler::ExpressionParser::Actions->new($mapper);

    if ($expr =~ $RE->with_actions($actions)) {
        return JasPerl::EL::Expression->new(source => $expr, root => $/{expr});
    } else {
        # FIXME: exception handling
        die "Error parsing expression '$expr': @!";
    }
}

package # hide from PAUSE
    JasPerl::Compiler::ExpressionParser::Actions;

use JasPerl::Type::Boolean;
use JasPerl::Type::Number;
use JasPerl::Type::String;

sub new {
    my ($class, $mapper) = @_;
    my $self = bless \$mapper, $class;
}

sub FunctionInvocation {
    my ($self, $match) = @_;
    my $prefix = $match->{prefix} || '';

    my $mapper = ${$self}
        or die "Expression uses functions, but no FunctionMapper provided";
    my $sub = $mapper->resolve_function($prefix, $match->{name})
        or die "Cannot locate function $prefix:$match->{name}";
    return { op => $sub, arg => $match->{arg} };
}

1;

__END__

=head1 NAME

JasPerl::Compiler::ExpressionParser - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::ExpressionParser;

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
