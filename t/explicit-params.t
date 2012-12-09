#============================================================= -*-perl-*-
#
# t/explicit-params.t
#
# Tests the $Template::Stash::EXPLICIT_PARAMS package variable.
#
# Written by Anastasi Thomas <athomas@cpan.org>
#
# Copyright (C) 2011 Anastasi Thomas. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

$Template::Test::PRESERVE = 1;

my $template = Template->new() || die Template->error;
my $context  = $template->context();
my $view     = $context->view( );
ok( $view );

$view = $context->view( prefix => 'my' );
ok( $view );
match( $view->prefix(), 'my' );

my $block = q{
    [%- BLOCK granchild %]
        Passed Param = [% param %]
        Global Param = [% passedparam %]
    [%- END -%]

    [%- BLOCK child %]
        [%- INCLUDE granchild param = param -%]
    [%- END -%]

    Parent level = [% passedparam %]
    [%- INCLUDE child param = passedparam -%]
};

my $render_tmpl_and_run_common_tests = sub {
    my $output;
    Template::Test::assert( $template->process(\$block, {passedparam => 1}, \$output), 'Process template expecting globally passed params.' );

    my $check_parent = $output =~ m|Parent level = 1|m;
    Template::Test::assert( $check_parent, 'Passed param at parent level.' );

    my $check_param = $output =~ m|Passed Param = 1|m;
    Template::Test::assert( $check_param, 'Passed param at child level' );

    return $output;
};

my $output = $render_tmpl_and_run_common_tests->();
my $check_global = $output =~ m|Global Param = 1|m;
Template::Test::assert( $check_global, 'Passed param at global level. $Template::Stash::EXPLICIT_PARAMS = 0' );

{
    local $Template::Stash::EXPLICIT_PARAMS = 1;
    my $output = $render_tmpl_and_run_common_tests->();
    my $check_global = $output =~ m|Global Param = 1|m;
    Template::Test::assert( !$check_global, 'Passed param at global level. $Template::Stash::EXPLICIT_PARAMS = 1' );
}

