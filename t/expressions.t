#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('JasPerl::Compiler::ExpressionParser');
}

{
    package Resolver;

    use JasPerl::Util::Bean;

    with qw{
        JasPerl::EL::FunctionMapper
        JasPerl::EL::VariableResolver
    };

    has [ qw(foo bar) ] => ( is => 'ro' );

    sub add { $_[0] + $_[1] }

    sub concat { join('', @_) }

    sub resolve_function {
        my ($self, $prefix, $name) = @_;

        if ($name eq 'add') {
            return *add;
        } elsif ($name eq 'concat') {
            return \&concat;
        } else {
            return;
        }
    }

    sub resolve_variable {
        my ($self, $name) = @_;

        if ($name eq 'foo') {
            return $self->get_foo();
        } elsif ($name eq 'bar') {
            return $self->get_bar();
        } else {
            return;
        }
    }
}

my $eval = new_ok('JasPerl::Compiler::ExpressionParser');

subtest "Literals" => sub {
    ok(
        $eval->evaluate(q(${true})),
        'Literal "true" yields true'
    );
    ok(
        !$eval->evaluate(q(${false})),
        'Literal "false" yields false'
    );
    is(
        $eval->evaluate(q(${true})),
        'true',
        'Literal "true" is "true"'
    );
    is(
        $eval->evaluate(q(${false})),
        'false',
        'Literal "false" is "false"'
    );
    is(
        $eval->evaluate(q(${null})),
        undef,
        'Literal "null" is undef'
    );
    cmp_ok(
        $eval->evaluate(q(${0})),
        '==',
        0,
        'Integer literal "0" == 0'
    );
    cmp_ok(
        $eval->evaluate(q(${42})),
        '==',
        42,
        'Integer literal "42" == 42'
    );
    # FIXME: floating point literals should be tested w/delta
    cmp_ok(
        $eval->evaluate(q(${0.02})),
        '==',
        0.02,
        'Floating point literal "0.02" == 0.02'
    );
    cmp_ok(
        $eval->evaluate(q(${1E03})),
        '==',
        1E03,
        'Floating point literal "1E03" == 1E03'
    );
    is(
        $eval->evaluate(q(${""})),
        q(),
        'Empty double-quoted string literal is empty string'
    );
    is(
        $eval->evaluate(q(${''})),
        q(),
        'Empty single-quoted string literal is empty string'
    );
    is(
        $eval->evaluate(q(${"abc"})),
        q(abc),
        'Simple double-quoted string literal'
    );
    is(
        $eval->evaluate(q(${'abc'})),
        q(abc),
        'Simple single-quoted string literal'
    );
    is(
        $eval->evaluate(q(${"''"})),
        q(''),
        'Single quotes in double-quoted string literal'
    );
    is(
        $eval->evaluate(q(${'""'})),
        q(""),
        'Double quotes in single-quoted string literal'
    );
    is(
        $eval->evaluate(q(${"\\"\\\\\\""})),
        q("\\"),
        'Escapes in double-quoted string literal'
    );
    is(
        $eval->evaluate(q(${'\\'\\\\\\''})),
        q('\\'),
        'Escapes in single-quoted string literal'
    );
};

subtest "Unary Operators" => sub {
    is(
        $eval->evaluate(q(${!true})),
        'false',
        '${!true} is false'
    );
    is(
        $eval->evaluate(q(${not false})),
        'true',
        '${not false} is true'
    );
    is(
        $eval->evaluate(q(${not null})),
        'true',
        '${not null} is true'
    );
    cmp_ok(
        $eval->evaluate(q(${-0})),
        '==',
        0,
        '${-0} is 0'
    );
    cmp_ok(
        $eval->evaluate(q(${-42})),
        '==',
        -42,
        '${-42} is -42'
    );
    is(
        $eval->evaluate(q(${empty null})),
        'true',
        '${empty null} is true'
    );
    is(
        $eval->evaluate(q(${empty ""})),
        'true',
        '${empty ""} is true'
    );
    is(
        $eval->evaluate(q(${empty 0})),
        'false',
        '${empty 0} is false'
    );
};

subtest "Binary Operators" => sub {
    is(
        $eval->evaluate(q(${false || true})),
        'true',
        '${false || true} is true'
    );
    is(
        $eval->evaluate(q(${false && true})),
        'false',
        '${false && true} is false'
    );
    is(
        $eval->evaluate(q(${0 == 0})),
        'true',
        '${0 == 0} is true'
    );
    is(
        $eval->evaluate(q(${0 != 0})),
        'false',
        '${0 != 0} is false'
    );
    is(
        $eval->evaluate(q(${"" == ""})),
        'true',
        '${"" == ""} is true'
    );
    is(
        $eval->evaluate(q(${"" != ""})),
        'false',
        '${"" != ""} is false'
    );
    is(
        $eval->evaluate(q(${1 + 2 == 3})),
        'true',
        '${1 + 2 == 3} is true'
    );
    is(
        $eval->evaluate(q(${2 * 2 == 4})),
        'true',
        '${2 * 2 == 4} is true'
    );
    is(
        $eval->evaluate(q(${7 * 8 == 42})),
        'false',
        '${7 * 8 == 42} is false'
    );
};

subtest "Conditional Operator" => sub {
    is(
        $eval->evaluate(q(${true ? 1 : 2})),
        1,
        '${true ? 1 : 2} is 1'
    );
    is(
        $eval->evaluate(q(${false ? 1 : 2})),
        2,
        '${false ? 1 : 2} is 2'
    );
    is(
        $eval->evaluate(q(${"true" ? 1 : 2})),
        1,
        '${"true" ? 1 : 2} is 1'
    );
    is(
        $eval->evaluate(q(${"" ? 1 : 2})),
        2,
        '${"" ? 1 : 2} is 2'
    );
};

subtest "Variables" => sub {
    my $res = new_ok('Resolver', [ foo => 'FOO', bar => 'BAR' ]);

    is(
        $eval->evaluate(q(${foo}), $res),
        'FOO',
        '${foo} resolved'
    );
    is(
        $eval->evaluate(q(${empty foo}), $res),
        'false',
        '${empty foo} resolved'
    );
    is(
        $eval->evaluate(q(${foo ne bar}), $res),
        'true',
        '${foo ne bar} resolved'
    );
    is(
        $eval->evaluate(q(${emptyfoo}), $res),
        undef,
        '${emptyfoo} resolved'
    );
    is(
        $eval->evaluate(q(${foonebar}), $res),
        undef,
        '${foonebar} resolved'
    );

#    is(
#        $eval->evaluate(q(${not}), $res),
#        undef,
#        '${not} resolved'
#    );

    # use Data::Dumper;

    # $eval->parse_expression(q(${foo != bar}))->dump(\*STDERR);
    #
    # $eval->parse_expression(q(${foo.bar}))->dump(\*STDERR);
    # $eval->parse_expression(q(${foo[bar]}))->dump(\*STDERR);
    # $eval->parse_expression(q(${foo[bar.baz]}))->dump(\*STDERR);
    # $eval->parse_expression(q(${foo[bar].baz}))->dump(\*STDERR);
    # $eval->parse_expression(q(${foo[bar.x].y}))->dump(\*STDERR);
    # $eval->parse_expression(q(${foo[0]}))->dump(\*STDERR);
};

subtest "Functions" => sub {
    my $res = new_ok('Resolver');

    is(
        $eval->evaluate(q(${add(1, 2)}), undef, $res),
        3,
        '${add(1, 2)} called'
    );
    is(
        $eval->evaluate(q(${x:concat("a", "b")}), undef, $res),
        'ab',
        '${x:concat("a", "b")} called'
    );
};

done_testing();
