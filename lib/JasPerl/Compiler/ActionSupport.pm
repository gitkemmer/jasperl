use 5.010;
use strict;
use warnings;

package JasPerl::Compiler::ActionSupport;

use JasPerl::Compiler::CustomAction;
use JasPerl::TagExt::TagInfo;
use JasPerl::Util::Functions qw(quote);

# VERSION

my $STANDARD_ACTIONS = do {
    # rec. dep. StandardActions -> ActionSupport
    require JasPerl::Compiler::StandardActions;
    JasPerl::Compiler::StandardActions->get_tag_library_info();
};

my %BODY_CONTENT = (
    JasPerl::TagExt::TagInfo::BODY_CONTENT_EMPTY => sub {
        my ($taginfo, $body) = @_;
        die $taginfo->get_name() . " does not expect a body";
    },
    JasPerl::TagExt::TagInfo::BODY_CONTENT_SCRIPTLESS => sub {
        my ($taginfo, $body) = @_;
        return sub { $_[0]->do_scriptless_body($body) };
    },
    JasPerl::TagExt::TagInfo::BODY_CONTENT_TAG_DEPENDENT => sub {
        my ($taginfo, $body) = @_;
        return sub { $_[0]->do_tag_dependent_body($body) };
    }
);

use JasPerl::Util::Role;

sub _make_attributes {
    return { map { $_->{name} => $_->{value} } @{$_[0]} };
}

sub _do_expression {
    my ($self, $node) = @_;
    my $ctx = $self->get_jsp_context();
    my $out = $ctx->get_out();
    $out->println("# expression: '", $node->{''} || '', "'");
}

sub _do_custom_action {
    my ($self, $node) = @_;
    my $context = $self->get_jsp_context();
    my $taglib = $context->get_tag_library($node->{prefix})
        or die "no taglib for prefix '$node->{prefix}'";
    my $taginfo = $taglib->get_tag_library_info()->get_tag($node->{name})
        or die "no tag info for '$node->{prefix}:$node->{name}'";
    my $tag = JasPerl::Compiler::CustomAction->new(tagInfo => $taginfo);

    foreach my $attr (@{$node->{attr}}) {
        $tag->set_dynamic_attribute(undef, $attr->{name}, $attr->{value});
    }
    $tag->set_jsp_context($self->get_jsp_context());
    $tag->set_jsp_body($BODY_CONTENT{$taginfo->get_body_content()}->($taginfo, $node->{body})) if $node->{body};
    $tag->set_parent($self);
    $tag->do_tag();
}

sub _do_standard_action {
    my ($self, $node) = @_;
    my $info = $STANDARD_ACTIONS->get_tag($node->{name})
        or die "no tag info for $node->{name}";
    my $tag = $info->get_class()->new(
        _make_attributes($node->{attr})
    );
    $tag->set_jsp_context($self->get_jsp_context());
    $tag->set_jsp_body($BODY_CONTENT{$info->get_body_content()}->($info, $node->{body})) if $node->{body};
    $tag->set_parent($self);
    $tag->do_tag();
}

sub do_scriptless_body {
    my ($self, $body) = @_;
    my $ctx = $self->get_jsp_context();
    my $out = $ctx->get_out();

    foreach my $node (@{$body}) {
        next unless defined $node;

        if (not ref $node) {
            $out->println($self->get_out_var(), '->print(', quote($node), ');');
        } elsif (exists $node->{expr}) {
            $self->_do_expression($node);
        } elsif (exists $node->{prefix}) {
            $self->_do_custom_action($node);
        } elsif (exists $node->{name}) {
            $self->_do_standard_action($node);
        } else {
            die "invalid element: $node";
        }
    }
}

sub do_tag_dependent_body {
    my ($self, $body) = @_;
}

# FIXME: context?
sub get_jsp_context_var {
    return '$ctx';
}

sub get_out_var {
    return '$out';
}

1;

__END__

=head1 NAME

JasPerl::Compiler::ActionSupport - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::Compiler::ActionSupport;

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
