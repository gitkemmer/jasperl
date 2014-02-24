#!/usr/bin/perl
use strict;
use warnings;

use lib qw{
/home/tkemmer/lib/perl5
/home/tkemmer/src/jasperl/JasPerl/lib
/home/tkemmer/src/jasperl/JasPerl-JSTL/lib
/home/tkemmer/src/jasperl/JasPerl-Runtime-PSGI/lib
/home/tkemmer/src/jasperl/JasPerl-TagLib-JSTL-Core/lib
/home/tkemmer/src/jasperl.old/work
};

use JasPerl::Runtime::PSGI;
use JasPerl::Response;
use JasPerl::Cookie;
use JasPerl::Util::Exception;
use JasPerl::Util::Date;
use Plack::Builder;

my $context = JasPerl::Runtime::PSGI->new(attributes => { foo => 1 });

my $app = sub {
    my $env = shift;

    my $request = $context->new_request($env);
    my $response = $request->new_response();

    eval {
        my $path = $request->get_path_info();
        if (my $rd = $context->get_request_dispatcher($path)) {
            $rd->forward($request, $response);
        } else {
            $response->send_error(JasPerl::Response::SC_NOT_FOUND);
        }
    };

    if (my $e = JasPerl::Util::Exception->caught()) {
        $e->print_stack_trace();
        return [ 500, [ 'Context-Type' => 'text/plain' ], [ $e->as_string ] ];
    } elsif ($@) {
        warn "PSGI ERROR: $@";
        return [ 500, [ 'Context-Type' => 'text/plain' ], [ $@ ] ];
    } else {
        $request->get_session()->set_attribute("foobar", JasPerl::Util::Date->new());
        #$request->get_session()->invalidate();

        $response->add_cookie(JasPerl::Cookie->new("test", 1));
        my $cookie = JasPerl::Cookie->new("foo", "bar +1");
        $cookie->set_path("/");
        $cookie->set_max_age(42);
        $cookie->set_http_only(1);
        $response->add_cookie($cookie);
        return $response->finalize;
    }
};

builder {
    enable 'Session';
    $app;
};
