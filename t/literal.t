#============================================================= -*-perl-*-
#
# t/literal.t
#
# Template script testing literal lvalues.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: literal.t,v 1.2 1999/11/25 17:51:26 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
$Template::Context::DEBUG = 0;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my ($a, $b, $c, $d, $e, $f ) = 
	qw( alpha bravo charlie delta echo foxtrot);
my $params = {
    'a'    => $a,
    'b'    => $b,
    'c'    => $c,
    'd'    => {
	'e' => $e,
	'f' => $f,
    },
};


test_expect(\*DATA, undef, $params);

__DATA__
[% a %]
[% a = b; a %]
[% 'a' = c; a %]
-- expect --
alpha
bravo
charlie
