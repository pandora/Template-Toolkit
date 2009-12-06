#============================================================= -*-Perl-*-
#
# Template::Plugin::Wrap
#
# DESCRIPTION
#   Plugin for wrapping text via the Text::Wrap module.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Wrap.pm,v 2.69 2006/05/30 17:01:36 abw Exp $
#
#============================================================================

package Template::Plugin::Wrap;

use strict;
use warnings;
use base 'Template::Plugin';
use Text::Wrap;

our $VERSION = 2.68;

sub new {
    my ($class, $context, $format) = @_;;
    $context->define_filter('wrap', [ \&wrap_filter_factory => 1 ]);
    return \&tt_wrap;
}

sub tt_wrap {
    my $text  = shift;
    my $width = shift || 72;
    my $itab  = shift;
    my $ntab  = shift;
    $itab = '' unless defined $itab;
    $ntab = '' unless defined $ntab;
    $Text::Wrap::columns = $width;
    Text::Wrap::wrap($itab, $ntab, $text);
}

sub wrap_filter_factory {
    my ($context, @args) = @_;
    return sub {
	my $text = shift;
	tt_wrap($text, @args);
    }
}


1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Plugin::Wrap - Plugin interface to Text::Wrap

=head1 SYNOPSIS

    [% USE wrap %]

    # call wrap subroutine
    [% wrap(mytext, width, initial_tab,  subsequent_tab) %]

    # or use wrap FILTER
    [% mytext FILTER wrap(width, initital_tab, subsequent_tab) %]

=head1 DESCRIPTION

This plugin provides an interface to the Text::Wrap module which 
provides simple paragraph formatting.

It defines a 'wrap' subroutine which can be called, passing the input
text and further optional parameters to specify the page width (default:
72), and tab characters for the first and subsequent lines (no defaults).

    [% USE wrap %]

    [% text = BLOCK %]
    First, attach the transmutex multiplier to the cross-wired 
    quantum homogeniser.
    [% END %]

    [% wrap(text, 40, '* ', '  ') %]

Output:

    * First, attach the transmutex
      multiplier to the cross-wired quantum
      homogeniser.

It also registers a 'wrap' filter which accepts the same three optional 
arguments but takes the input text directly via the filter input.

    [% FILTER bullet = wrap(40, '* ', '  ') -%]
    First, attach the transmutex multiplier to the cross-wired quantum
    homogeniser.
    [%- END %]

    [% FILTER bullet -%]
    Then remodulate the shield to match the harmonic frequency, taking 
    care to correct the phase difference.
    [% END %]

Output:

    * First, attach the transmutex
      multiplier to the cross-wired quantum
      homogeniser.

    * Then remodulate the shield to match
      the harmonic frequency, taking 
      care to correct the phase difference.

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

The Text::Wrap module was written by David Muir Sharnoff
E<lt>muir@idiom.comE<gt> with help from Tim Pierce and many
others.

=head1 VERSION

2.68, distributed as part of the
Template Toolkit version 2.18, released on 09 February 2007.

=head1 COPYRIGHT

  Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.


This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Text::Wrap|Text::Wrap>

