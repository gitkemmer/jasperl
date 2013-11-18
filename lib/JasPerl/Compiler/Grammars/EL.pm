use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::Grammars::EL;

use Regexp::Grammars 1.033;

# VERSION

my @RESERVED = qw{
    and div empty eq false ge gt instanceof le lt mod ne not null or true
};

our %RESERVED = map { $_ => 1 } @RESERVED;

my $RE = qr{
    <grammar: JasPerl::Compiler::Grammars::EL>
    <nocontext:>

    <rule: Expression>
        <MATCH=Expression1>
    |   <[arg=Expression1]> \? <[arg=Expression]> \: <[arg=Expression]> <op='cond'>

    <rule: Expression1>
        <[arg=Expression2]>+ % <[op=BinaryOp1]>
        <minimize:>

    <rule: Expression2>
        <[arg=Expression3]>+ % <[op=BinaryOp2]>
        <minimize:>

    <rule: Expression3>
        <[arg=Expression4]>+ % <[op=BinaryOp3]>
        <minimize:>

    <rule: Expression4>
        <[arg=Expression5]>+ % <[op=BinaryOp4]>
        <minimize:>

    <rule: Expression5>
        <[arg=Expression6]>+ % <[op=BinaryOp5]>
        <minimize:>

    <rule: Expression6>
        <[arg=UnaryExpression]>+ % <[op=BinaryOp6]>
        <minimize:>

    <rule: UnaryExpression>
        <op=UnaryOp> \b <arg=UnaryExpression>
    |   <MATCH=Value>

    <rule: Value>
        <[arg=ValuePrefix]> ( <[arg=ValueSuffix]>+ <op='prop'> )?
        <minimize:>

    <rule: ValuePrefix>
        <MATCH=Literal>
    |   <MATCH=NonLiteralValuePrefix>

    <rule: NonLiteralValuePrefix>
        <op='var'> <arg=Identifier>
    |   <MATCH=FunctionInvocation>
    |   \( <MATCH=Expression> \)

    <rule: ValueSuffix>
        \. <MATCH=IdentifierValueSuffix>
    |   \[ <MATCH=Expression> \]

    <rule: IdentifierValueSuffix>
        <op='string'> <arg=Identifier>

    <rule: FunctionInvocation>
        (<prefix=Identifier>:)?<name=Identifier>
            \( <[arg=Expression]>* % , \)

    <rule: Literal>
        <op='int'>    <arg=IntegerLiteral>
    |   <op='bool'>   <arg=BooleanLiteral>
    |   <op='float'>  <arg=FloatingPointLiteral>
    |   <op='string'> <arg=StringLiteral>
    |   <MATCH=NullLiteral>

    <token: BinaryOp1>
        \|\|    <MATCH='or'>
    |   or

    <token: BinaryOp2>
        \&\&    <MATCH='and'>
    |   and

    <token: BinaryOp3>
        ==      <MATCH='eq'>
    |   !=      <MATCH='ne'>
    |   eq
    |   ne

    <token: BinaryOp4>
        \<      <MATCH='lt'>
    |   \>      <MATCH='gt'>
    |   \<=     <MATCH='le'>
    |   \>=     <MATCH='ge'>
    |   lt
    |   gt
    |   le
    |   ge

    <token: BinaryOp5>
        \+      <MATCH='add'>
    |   \-      <MATCH='sub'>

    <token: BinaryOp6>
        \*       <MATCH='mul'>
    |   \/       <MATCH='div'>
    |   \%       <MATCH='mod'>
    |   div
    |   mod

    <token: UnaryOp>
        \!      <MATCH='not'>
    |   \-      <MATCH='neg'>
    |   not
    |   empty

    <token: Identifier>
    # FIXME!
  #      <Reserved> \b <fatal: (?{ die "reserved keyword $CAPTURE"})>
       <MATCH=([^\W\d]\w*\b)>

    <token: BooleanLiteral>
        true
      | false

    <token: IntegerLiteral>
        \d+

    <token: FloatingPointLiteral>
        \d* \. \d* ( [eE] [+-]? \d+ )?
      | \d+ [eE] [+-]? \d+

    <token: StringLiteral>
        ' <MATCH=SingleQuotedString> '
      | " <MATCH=DoubleQuotedString> "

    <token: SingleQuotedString>
        (?:
            \\ <[MATCH=([\\\'])]>
        |   <[MATCH=([^\\\']*)]>
        )+
        <MATCH=(?{ join(q(), @{$MATCH}) })>

    <token: DoubleQuotedString>
        (?:
            \\ <[MATCH=([\\\"])]>
        |   <[MATCH=([^\\\"]*)]>
        )+
        <MATCH=(?{ join(q(), @{$MATCH}) })>

    <token: NullLiteral>
        null <MATCH=(?{ undef })>

    <token: Reserved>
        <%JasPerl::Compiler::Grammars::EL::RESERVED { \w+\b }>
}xs;

1;

__END__

=head1 NAME

JasPerl::Compiler::Grammars::EL - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::Grammars::EL;

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
