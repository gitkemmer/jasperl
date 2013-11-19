use 5.010;
use strict;
use warnings;

package JasPerl::TagExt::TagLibrary;

use Carp ();
use Class::Method::Modifiers qw(install_modifier);
use Module::Runtime qw(is_module_spec use_module);
use Import::Into;

use JasPerl::TagExt::Tag ();
use JasPerl::Util::Role ();

# VERSION

our %INFO;
our %TAGINFO;
our %TAGLIBS;

our @CARP_NOT;

my $DYNAMIC_ATTRIBUTES = qw(JasPerl::TagExt::DynamicAttributes);

BEGIN { *TAGINFO = \%JasPerl::TagExt::Tag::INFO }

sub _croak {
    local $Carp::CarpLevel = 4; # @CARP_NOT doesn't handle '(eval 30)'
#    my @caller = caller 2;
#    warn "caller: @caller";
    Carp::confess @_;
}

sub _make_tag_spec {
    my ($class, $module) = @_;
    # FIXME: use ClassLoader
    my $info = $TAGINFO{use_module($module)}
        or _croak "no info for tag '$module'"; # FIXME: empty tag?
    my %spec = %{$info};
    $spec{class} = $module;
    $spec{bodyContent} = $module->BODY_CONTENT;
    $spec{dynamicAttributes} = $module->DOES($DYNAMIC_ATTRIBUTES);
    return %spec;
}

sub _set_uri {
    my ($class, $taglib, $uri) = @_;
    _croak "URI already defined for taglib '$taglib'"
        if $INFO{$taglib}{uri};
    _croak "URI '$uri' already defined for taglib '$TAGLIBS{$uri}'"
        if $TAGLIBS{$uri};
    $INFO{$taglib}{uri} = $uri;
    $TAGLIBS{$uri} = $taglib;
}

sub _add_tag {
    my ($class, $taglib, $name, @spec) = @_;
    _croak "Tag '$name' already defined for taglib '$taglib'"
        if $INFO{$taglib}{tags}{$name};
    @spec = $class->_make_tag_spec(@spec)
        if @spec == 1;
    $INFO{$taglib}{tags}{$name} = { name => $name, @spec };
}

sub _add_function {
    my ($class, $taglib, $name, @spec) = @_;
    _croak "Function '$name' already defined for taglib '$taglib"
        if $INFO{$taglib}{functions}{$name};
    $INFO{$taglib}{functions}{$name} = { name => $name, @spec };
}

sub import {
    my $class = shift;
    my $target = caller;

    install_modifier $target, 'fresh', 'uri', sub {
        $class->_set_uri($target, @_);
    };
    install_modifier $target, 'fresh', 'tag', sub {
        $class->_add_tag($target, @_);
    };
    install_modifier $target, 'fresh', 'function', sub {
        $class->_add_function($target, @_);
    };

    JasPerl::Util::Role->apply_roles_to_package($target, $class);
}

# Role interface

use JasPerl::Util::Role;

sub _build_tags {
    require JasPerl::TagExt::TagInfo;
    my $info = $INFO{$_[0]}{tags} ||= { };
    return [ map { JasPerl::TagExt::TagInfo->new($_) } values %{$info} ];
}

sub _build_functions {
    require JasPerl::TagExt::FunctionInfo;
    my $info = $INFO{$_[0]}{functions} ||= { };
    return [ map { JasPerl::TagExt::FunctionInfo->new($_) } values %{$info} ];
}

sub _build_tag_library_info {
    require JasPerl::TagExt::TagLibraryInfo;

    my $class = shift;
    my $info = $INFO{$class} ||= { };

    return JasPerl::TagExt::TagLibraryInfo->new(
        uri       => $info->{uri},
        tags      => $class->_build_tags(),
        functions => $class->_build_functions()
    );
}

sub get_tag_library_info {
    return $INFO{$_[0]}{info} ||= $_[0]->_build_tag_library_info();
}

# sub add_tag_library {
#     my ($class, $uri, $taglib) = @_;
#     if (($TAGLIBS{$uri} || $taglib) eq $taglib) {
#         $TAGLIBS{$uri} = $taglib;
#     } else {
#         die "tag uri '$uri' already registered";
#     }
# }
#

sub get_tag_library {
    my ($class, $uri) = @_;
    if (my $taglib = $TAGLIBS{$uri}) {
        return use_module($taglib);
    }
    if (is_module_spec(undef, $uri) && eval { use_module($uri) }) {
        return $TAGLIBS{$uri} = $uri;
    }
    return;
}

#
# sub remove_tag_library {
#     my ($class, $uri) = @_;
#     delete $TAGLIBS{$uri};
# }

1;

__END__

=head1 NAME

JasPerl::TagExt::TagLibrary - <One line description of module's purpose>

=head1 SYNOPSIS

use JasPerl::TagExt::TagLibrary;

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
