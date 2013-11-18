#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

{
    package Tag;

    use JasPerl::TagExt::Tag;

    with qw(JasPerl::TagExt::SimpleTagSupport);

    has 'attr' => ( rtexprvalue => 1 );

    sub do_tag { }
}

$INC{'Tag.pm'} = 1; # mark as loaded

{
    package TagLib;

    use JasPerl::TagExt::TagLibrary;

    uri qw(testlib);

    tag foo => ( class => 'Tag', bodyContent => 'empty' );

    tag bar => 'Tag';
}

subtest "Tag library info" => sub {
    my $info = TagLib->get_tag_library_info();
    #warn Dumper($info);

    is(
        $info->get_uri(),
        'testlib',
        'Tag library uri'
    );
    is(
        $info->get_tag('foo')->get_body_content(),
        'empty',
        'Body content'
    );
    is(
        $info->get_tag('bar')->get_body_content(),
        'scriptless',
        'Body content'
    );
    #warn Dumper($info);
    #warn Dumper($info->get_tag('bar'));
    ok($info->get_tag('bar')->get_attribute('attr')->can_be_request_time());

};

done_testing();
