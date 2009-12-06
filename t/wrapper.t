#============================================================= -*-perl-*-
#
# t/wrapper.t
#
# Template script testing the WRAPPER directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: wrapper.t,v 2.0 2000/08/10 14:56:36 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template;
use Template::Test;
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Context::DEBUG = 0;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $dir   = -d 't' ? 't/test' : 'test';
my $tproc = Template->new({ 
    INCLUDE_PATH => "$dir/src:$dir/lib",
    TRIM         => 1,
#    WRAPPER      => 'wrapper',
});


test_expect(\*DATA, $tproc, &callsign());

__DATA__
-- test --
[% BLOCK mypage %]
This is the header
[% content %]
This is the footer
[% END -%]
[% WRAPPER mypage -%]
This is the content
[%- END %]
-- expect --
This is the header
This is the content
This is the footer

-- test --
[% WRAPPER mywrap
   title = 'Another Test' -%]
This is some more content
[%- END %]
-- expect --
Wrapper Header
Title: Another Test
This is some more content
Wrapper Footer


-- test --
[% WRAPPER mywrap
   title = 'Another Test' -%]
This is some content
[%- END %]
-- expect --
Wrapper Header
Title: Another Test
This is some content
Wrapper Footer


-- test --
[% WRAPPER page
   title = 'My Interesting Page'
%]
[% WRAPPER section
   title = 'Quantum Mechanics'
-%]
Quantum mechanics is a very interesting subject wish 
should prove easy for the layman to fully comprehend.
[%- END %]

[% WRAPPER section
   title = 'Desktop Nuclear Fusion for under $50'
-%]
This describes a simple device which generates significant 
sustainable electrical power from common tap water by process 
of nuclear fusion.
[%- END %]
[% END %]

[% BLOCK page -%]
<h1>[% title %]</h1>
[% content %]
<hr>
[% END %]

[% BLOCK section -%]
<p>
<h2>[% title %]</h2>
[% content %]
</p>
[% END %]

-- expect --
<h1>My Interesting Page</h1>

<p>
<h2>Quantum Mechanics</h2>
Quantum mechanics is a very interesting subject wish 
should prove easy for the layman to fully comprehend.
</p>

<p>
<h2>Desktop Nuclear Fusion for under $50</h2>
This describes a simple device which generates significant 
sustainable electrical power from common tap water by process 
of nuclear fusion.
</p>

<hr>

#========================================================================
# STOP!  The rest of these tests don't work because the WRAPPER content
#        is actually a closure constructed in the context of the
#        calling block rather than the enclosing one.
#========================================================================
-- stop --

-- test --
[%# FOREACH s = [ 'one' 'two' ]; WRAPPER section; PROCESS $s; END; END %]
[% PROCESS $s WRAPPER section FOREACH s = [ 'one' 'two' ] %]
[% BLOCK one; title = 'Block One' %]This is one[% END %]
[% BLOCK two; title = 'Block Two' %]This is two[% END %]
[% BLOCK section %]
<h1>[% title %]</h2>
<p>
[% content %]
</p>
[% END %]
-- expect --
<h1>Block One</h1>
<p>
This is one
</p>

<h1>Block Two</h1>
<p>
This is two
</p>

-- test --
[% BLOCK one; title = 'Block One' %]This is one[% END %]
[% BLOCK section %]
<h1>[% title %]</h1>
<p>
[% content %]
</p>
[% END %]
[% WRAPPER section %]
[% PROCESS one %]
[% END %]
title: [% title %]
-- expect --
<h1>Block One</h1>
<p>
This is one
</p>
