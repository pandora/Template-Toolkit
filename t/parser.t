#============================================================= -*-perl-*-
#
# t/parser.t
#
# Test the Template::Parser module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: parser.t,v 2.3 2000/09/12 15:25:24 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ../lib );
use Template::Test;
use Template::Config;
use Template::Parser;
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Test::PRESERVE = 0;
#$Template::Stash::DEBUG = 1;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $p2 = Template::Parser->new({
    START_TAG => '\[\*',
    END_TAG   => '\*\]',
    ANYCASE   => 1,
    PRE_CHOMP => 1,
    V1DOLLAR  => 1,
});

my $p3 = Template::Config->parser({
    TAG_STYLE  => 'html',
    POST_CHOMP => 1,
    ANYCASE    => 1,
    INTERPOLATE => 1,
});

my $p4 = Template::Config->parser({
    ANYCASE => 0,
});

my $tt = [
    tt1 => Template->new(ANYCASE => 1),
    tt2 => Template->new(PARSER => $p2),
    tt3 => Template->new(PARSER => $p3),
    tt4 => Template->new(PARSER => $p4),
];

my $replace = &callsign;
$replace->{ alist } = [ 'foo', 0, 'bar', 0 ];

test_expect(\*DATA, $tt, $replace);

__DATA__
#------------------------------------------------------------------------
# tt1
#------------------------------------------------------------------------
-- test --
start $a
[% BLOCK a %]
this is a
[% END %]
=[% INCLUDE a %]=
=[% include a %]=
end
-- expect --
start $a

=
this is a
=
=
this is a
=
end

#------------------------------------------------------------------------
# tt2
#------------------------------------------------------------------------
-- test --
-- use tt2 --
begin
[% this will be ignored %]
[* a *]
end
-- expect --
begin
[% this will be ignored %]alpha
end

-- test --
$b does nothing: 
[* c = 'b'; 'hello' *]
stuff: 
[* $c *]
-- expect --
$b does nothing: hello
stuff: b

#------------------------------------------------------------------------
# tt3
#------------------------------------------------------------------------
-- test --
-- use tt3 --
begin
[% this will be ignored %]
<!-- a -->
end

-- expect --
begin
[% this will be ignored %]
alphaend

-- test --
$b does something: 
<!-- c = 'b'; 'hello' -->
stuff: 
<!-- $c -->
end
-- expect --
bravo does something: 
hellostuff: 
bravoend


#------------------------------------------------------------------------
# tt4
#------------------------------------------------------------------------
-- test --
-- use tt4 --
start $a[% 'include' = 'hello world' %]
[% BLOCK a -%]
this is a
[%- END %]
=[% INCLUDE a %]=
=[% include %]=
end
-- expect --
start $a

=this is a=
=hello world=
end


#------------------------------------------------------------------------
-- test --
[% sql = "
     SELECT *
     FROM table"
-%]
SQL: [% sql %]
-- expect --
SQL: 
     SELECT *
     FROM table

-- test --
[% a = "\a\b\c\ndef" -%]
a: [% a %]
-- expect --
a: abc
def

-- test --
[% a = "\f\o\o"
   b = "a is '$a'"
   c = "b is \$100"
-%]
a: [% a %]  b: [% b %]  c: [% c %]

-- expect --
a: foo  b: a is 'foo'  c: b is $100

-- test --
[% tag = {
      a => "[\%"
      z => "%\]"
   }
   quoted = "[\% INSERT foo %\]"
-%]
A directive looks like: [% tag.a %] INCLUDE foo [% tag.z %]
The quoted value is [% quoted %]

-- expect --
A directive looks like: [% INCLUDE foo %]
The quoted value is [% INSERT foo %]


#------------------------------------------------------------------------
# STOP RIGHT HERE!
#------------------------------------------------------------------------

-- stop --

-- test --
alist: [% $alist %]
-- expect --
alist: ??

-- test --
[% foo.bar.baz %]
