#============================================================= -*-perl-*-
#
# t/provider.t
#
# Test the Template::Provider module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: provider.t,v 2.3 2001/03/22 12:23:15 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Template::Config;
use Template::Provider;
use Cwd 'abs_path';

$^W = 1;
$Template::Test::DEBUG = 0;
#$Template::Provider::DEBUG = 0;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

# uncommenting the next line should cause test 43 to fail because
# the provider doesn't stat the file.
# $Template::Provider::STAT_TTL = 10;

my $DEBUG = 0;

my $factory = 'Template::Config';

# script may be being run in distribution root or 't' directory
my $dir     = -d 't' ? 't/test/src' : 'test/src';
my $file    = 'foo';
my $relfile = "./$dir/$file";
my $absfile = abs_path($dir) . '/' . $file;
my $newfile = "$dir/foobar";
my $vars = {
    file    => $file,
    relfile => $relfile,
    absfile => $absfile,
    fixfile => \&update_file,
};


#------------------------------------------------------------------------
# This is used to test that source files are automatically reloaded
# when updated on disk.  we call it first to write a template file, 
# which is then included in one of the -- test --  sections below.
# Then we call update_file() (via the 'fixfile' variable) and 
# include it again to see if the new file contents were loaded.
#------------------------------------------------------------------------

sub update_file {
    local *FP;
    sleep(2);     # ensure file time stamps are different
    open(FP, ">$newfile") || die "$newfile: $!\n";
    print(FP @_) || die "failed to write $newfile: $!\n";
    close(FP);
}

update_file('This is the old content');


#------------------------------------------------------------------------
# instantiate a bunch of providers, using various different techniques, 
# with different load options but sharing the same parser;  then set them
# to work fetching some files and check they respond as expected
#------------------------------------------------------------------------

my $parser = $factory->parser(POST_CHOMP => 1)
    || die $factory->error();
ok( $parser );

my $provinc = $factory->provider(INCLUDE_PATH => $dir, 
				 PARSER => $parser,
				 TOLERANT => 1)
    || die $factory->error();
ok( $provinc );

my $provabs = $factory->provider({ ABSOLUTE => 1, 
				   PARSER => $parser, })
    || die $factory->error();
ok( $provabs );

my $provrel = Template::Provider->new({ RELATIVE => 1, 
					PARSER => $parser, })
    || die $Template::Provider::ERROR;
ok( $provrel );

ok( $provinc->{ PARSER } == $provabs->{ PARSER } );
ok( $provabs->{ PARSER } == $provrel->{ PARSER } );

banner('matrix');

ok( delivered( $provinc, $file    ) );
ok(  declined( $provinc, $absfile ) );
ok(  declined( $provinc, $relfile ) );

ok(  declined( $provabs, $file    ) );
ok( delivered( $provabs, $absfile ) );
ok(    denied( $provabs, $relfile ) );

ok(  declined( $provrel, $file    ) );
ok(    denied( $provrel, $absfile ) );
ok( delivered( $provrel, $relfile ) );


sub delivered {
    my ($provider, $file) = @_;
    my ($result, $error) = $provider->fetch($file);
    print STDERR "$provider->fetch($file) -> [$result] [$error]\n"
	if $DEBUG;
    return ! $error;
}

sub declined {
    my ($provider, $file) = @_;
    my ($result, $error) = $provider->fetch($file);
    print STDERR "$provider->fetch($file) -> [$result] [$error]\n"
	if $DEBUG;
    return ($error == Template::Constants::STATUS_DECLINED);
}

sub denied {
    my ($provider, $file) = @_;
    my ($result, $error) = $provider->fetch($file);
    print STDERR "$provider->fetch($file) -> [$result] [$error]\n"
	if $DEBUG;
    return ($error == Template::Constants::STATUS_ERROR);
}

#------------------------------------------------------------------------
# now we'll fold those providers up into some Template objects that
# we can pass to text_expect() to do some template driven testing
#------------------------------------------------------------------------

my $ttinc = Template->new( LOAD_TEMPLATES => [ $provinc ] )
    || die "$Template::ERROR\n";
ok( $ttinc );

my $ttabs = Template->new( LOAD_TEMPLATES => [ $provabs ] )
    || die "$Template::ERROR\n";
ok( $ttabs );

my $ttrel = Template->new( LOAD_TEMPLATES => [ $provrel ] )
    || die "$Template::ERROR\n";
ok( $ttrel );


my $uselist = [ ttinc => $ttinc, ttabs => $ttabs, ttrel => $ttrel ];

test_expect(\*DATA, $uselist, $vars);


__DATA__
-- test --
-- use ttinc --
[% TRY %]
[% INCLUDE foo %]
[% INCLUDE $relfile %]
[% CATCH file %]
Error: [% error.type %] - [% error.info.split(': ').1 %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - not found


-- test --
[% TRY %]
[% INCLUDE foo %]
[% INCLUDE $absfile %]
[% CATCH file %]
Error: [% error.type %] - [% error.info.split(': ').1 %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - not found


-- test --
[% TRY %]
[% INSERT foo -%]
[% INSERT $absfile %]
[% CATCH file %]
Error: [% error %]
[% END %]
-- expect --
-- process --
[% TAGS [* *] %]
This is the foo file, a is [% a %]
Error: file error - [* absfile *]: not found

#------------------------------------------------------------------------

-- test --
-- use ttrel --
[% TRY %]
[% INCLUDE $relfile %]
[% INCLUDE foo %]
[% CATCH file -%]
Error: [% error.type %] - [% error.info %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - foo: not found

-- test --
[% TRY %]
[% INCLUDE $relfile -%]
[% INCLUDE $absfile %]
[% CATCH file %]
Error: [% error.type %] - [% error.info.split(': ').1 %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - absolute paths are not allowed (set ABSOLUTE option)


-- test --
foo: [% TRY; INSERT foo;      CATCH; "$error\n"; END %]
rel: [% TRY; INSERT $relfile; CATCH; "$error\n"; END %]
abs: [% TRY; INSERT $absfile; CATCH; "$error\n"; END %]
-- expect --
-- process --
[% TAGS [* *] %]
foo: file error - foo: not found
rel: This is the foo file, a is [% a %]
abs: file error - [* absfile *]: absolute paths are not allowed (set ABSOLUTE option)

#------------------------------------------------------------------------

-- test --
-- use ttabs --
[% TRY %]
[% INCLUDE $absfile %]
[% INCLUDE foo %]
[% CATCH file %]
Error: [% error.type %] - [% error.info %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - foo: not found

-- test --
[% TRY %]
[% INCLUDE $absfile %]
[% INCLUDE $relfile %]
[% CATCH file %]
Error: [% error.type %] - [% error.info.split(': ').1 %]
[% END %]
-- expect --
This is the foo file, a is 
Error: file - relative paths are not allowed (set RELATIVE option)


-- test --
foo: [% TRY; INSERT foo;      CATCH; "$error\n"; END %]
rel: [% TRY; INSERT $relfile; CATCH; "$error\n"; END %]
abs: [% TRY; INSERT $absfile; CATCH; "$error\n"; END %]
-- expect --
-- process --
[% TAGS [* *] %]
foo: file error - foo: not found
rel: file error - [* relfile *]: relative paths are not allowed (set RELATIVE option)
abs: This is the foo file, a is [% a %]



#------------------------------------------------------------------------
# test that files updated on disk are automatically reloaded.
#------------------------------------------------------------------------

-- test --
-- use ttinc --
[% INCLUDE foobar %]
-- expect --
This is the old content

-- test --
[% CALL fixfile('This is the new content') %]
[% INCLUDE foobar %]
-- expect --
This is the new content


