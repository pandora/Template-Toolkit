#============================================================= -*-perl-*-
#
# t/preproc.t
#
# Template script testing the PRE_PROCESS and POST_PROCESS directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: preproc.t,v 1.1 1999/08/15 20:40:29 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $config = {
    PRE_PROCESS  => 'preproc',
    POST_PROCESS => 'postproc',
    POST_CHOMP   => 1,
    INTERPOLATE  => 1,
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],
};

test_expect(\*DATA, $config);


__DATA__
<h1>$title</h1>
-- expect --
Content-type: text/html

<html>
<head><title>Hello World</title></head>
<body bgcolor="#ffffff">
<h1>Hello World</h1>
<p>Copyright &copy; 1999 Andy Wardley</p>
</body>
</html>