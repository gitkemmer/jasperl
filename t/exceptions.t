#!perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok('JasPerl::Util::Exception') }

subtest "Default constructor" => sub {
    my $e = new_ok('JasPerl::Util::Exception' => [ ],
       "The exception");
    is($e->get_message(), undef,
       "Message is null");
    is($e->get_cause(), undef,
       "Cause is null");
    is("$e", ref($e),
       "Stringify returns class name");
};

subtest "Constructor with message" => sub {
    my $e = new_ok('JasPerl::Util::Exception' => [ 'test' ],
       "The exception");
    is($e->get_message(), 'test',
       "Message as specified");
    is($e->get_cause(), undef,
       "Cause is null");
    is("$e", ref($e) . ': ' . $e->get_message(),
       "Stringify returns class name and message");
};

subtest "Constructor with cause" => sub {
    my $cause = new_ok('JasPerl::Util::Throwable' => [ 'cause' ],
       "The cause");
    my $e = new_ok('JasPerl::Util::Exception' => [ $cause ],
       "The exception");
    is($e->get_message(), $cause->as_string,
       "Message is cause description");
    is_deeply($e->get_cause(), $cause,
       "Cause as specified");
    is("$e", ref($e) . ': ' . $e->get_message(),
       "Stringify returns class name and message");
};

subtest "Two-argument constructor" => sub {
    my $cause = new_ok('JasPerl::Util::Throwable' => [ 'cause' ],
       "The cause");
    my $e = new_ok('JasPerl::Util::Exception' => [ 'test', $cause ],
       "The exception");
    is($e->get_message(), 'test',
       "Message as specified");
    is_deeply($e->get_cause(), $cause,
       "Cause as specified");
    is("$e", ref($e) . ': ' . $e->get_message(),
       "Stringify returns class name and message");
};

subtest "Throw/catch exception" => sub {
    eval {
        JasPerl::Util::Exception->throw("test");
    };
    if (my $e = JasPerl::Util::Exception->catch()) {
        is($e->get_message(), 'test', "Message as specified");
    } else {
        fail "no exception caught";
    }
};

subtest "Throwable coercion" => sub {
    eval {
        die "test";
    };
    if (my $e = JasPerl::Util::Exception->catch()) {
        fail "exception caught but throwable expected";
    } elsif (my $t = JasPerl::Util::Throwable->catch()) {
        like $t->get_message(), qr(^test), "Message is correct";
    } else {
        fail "no throwable caught";
    }
};

{
    package Local;
    sub baz {
        return JasPerl::Util::Exception->new(join(':', __LINE__, @_));
    };
};

sub bar {
    eval { Local::baz(__LINE__, @_) };
}

sub foo {
    bar(__LINE__, @_);
}

subtest "Get stack trace" => sub {
    my $e = foo(__LINE__);
    my $trace = $e->get_stack_trace();
    my @lines = split(':', $e->get_message());

    my $STE = 'JasPerl::Util::StackTraceElement';
    cmp_ok($trace->[0], '==', $STE->new('Local', 'baz', __FILE__, $lines[0]),
        "Stack frame [0] ok");
    cmp_ok($trace->[1], '==', $STE->new(__PACKAGE__, 'bar', __FILE__, $lines[1]),
        "Stack frame [1] ok");
    cmp_ok($trace->[2], '==', $STE->new(__PACKAGE__, 'foo', __FILE__, $lines[2]),
        "Stack frame [2] ok");
};

subtest "Print stack trace" => sub {
    my $e = new_ok('JasPerl::Util::Exception' => [ foo(__LINE__) ],
        "The exception");
    my $buf = '';
    open(my $fh, '>', \$buf) || fail "cannot open in-memory filehandle";
    $e->print_stack_trace($fh);

    like($buf, qr(^${e})s,
         "Stack trace starts with description");
    like($buf, qr(\.\.\. \d+ more$)s,
         "Stack trace ends with more");
};

done_testing();
