use utf8;
use strict;
use warnings;

package Local::JSP::date_jsp;

use JasPerl::JspException;
use JasPerl::JspFactory;
use JasPerl::Util::Beans;

use JasPerl::Bean;

with qw(JasPerl::JspPage);

sub _jsp_service {
    my ($self, $request, $response) = @_;
    my $factory = JasPerl::JspFactory->get_default_factory();
    my $ctx = $factory->get_page_context($self, $request, $response, undef, 0, 8192, 1);

    my $ok = eval {
        $response->set_content_type("text/html");
        $self->_jspx_main($ctx);
        1;
    };

    unless ($ok) {
        if (my $e = JasPerl::JspException->caught()) {
            $ctx->handle_page_exception($e) unless $e->isa('JasPerl::SkipPageException');
        } else {
            $ctx->handle_page_exception(JasPerl::JspException->new(cause => $@));
        }
    }

    $factory->release_page_context($ctx);
}

sub _jspx_main {
    my ($self, $ctx) = @_;
    my $out = $ctx->get_out();
    $out->print("\r\n\r\n");
    $out->print("\r\n\r\n");
    $out->print("<html>\r\n  ");
    $out->print("<head>\r\n    ");
    $out->print("<title>JSP 2.0 Examples (1) - Repeat SimpleTag Handler");
    $out->print("</title>\r\n  ");
    $out->print("</head>\r\n  ");
    $out->print("<body>\r\n    ");
    $out->print("<h1>JSP 2.0 Examples - Recursive Repeat SimpleTag Handler");
    $out->print("</h1>\r\n\r\n    ");
    $ctx->set_attribute("date", JasPerl::Util::Beans->new_instance("java.util.Date"));
    $out->print("\r\n    ");
    # expression: '${date}'
    $out->print(":\r\n    ");
    $out->print(JasPerl::Util::Beans->get_property($ctx->find_attribute("date"), "time"));
    $out->print("\r\n    ");
    $out->print("<br>\r\n    ");
    JasPerl::Util::Beans->set_property($ctx->find_attribute("date"), "time", "0");
    $out->print("\r\n    ");
    # expression: '${date}'
    $out->print(":\r\n    ");
    $out->print(JasPerl::Util::Beans->get_property($ctx->find_attribute("date"), "time"));
    $out->print("\r\n");
    $out->print("\r\n  ");
    $out->print("</body>\r\n");
    $out->print("</html>\r\n");
}

1;
