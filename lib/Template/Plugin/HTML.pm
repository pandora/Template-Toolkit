#============================================================= -*-Perl-*-
#
# Template::Plugin::HTML
#
# DESCRIPTION
#
#   Template Toolkit plugin providing useful functionality for generating
#   HTML.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: HTML.pm,v 2.32 2002/01/22 18:09:43 abw Exp $
#
#============================================================================

package Template::Plugin::HTML;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;

$VERSION = sprintf("%d.%02d", q$Revision: 2.32 $ =~ /(\d+)\.(\d+)/);

sub new {
    my ($class, $context, @args) = @_;
    my $hash = ref $args[-1] eq 'HASH' ? pop @args : { };
    bless {
	_SORTED => $hash->{ sorted } || 0,
    }, $class;
}

sub element {
    my ($self, $name, $attr) = @_;
    ($name, $attr) = %$name if ref $name eq 'HASH';
    return '' unless defined $name and length $name;
    $attr = $self->attributes($attr);
    $attr = " $attr" if $attr;
    return "<$name$attr>";
}

sub attributes {
    my ($self, $hash) = @_;
    return '' unless UNIVERSAL::isa($hash, 'HASH');

    my @keys = keys %$hash;
    @keys = sort @keys if $self->{ _SORTED };

    join(' ', map { 
	"$_=\"" . $self->escape( $hash->{ $_ } ) . '"';
    } @keys);
}

sub escape {
    my ($self, $text) = @_;
    for ($text) {
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/"/&quot;/g;
    }
    $text;
}

sub url {
    my ($self, $text) = @_;
    return undef unless defined $text;
    $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $text;
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

Template::Plugin::HTML - Plugin to create HTML elements

=head1 SYNOPSIS

    [% USE HTML %]

    [% HTML.escape("if (a < b && c > d) ..." %]

    [% HTML.element(table => { border => 1, cellpadding => 2 }) %]

    [% HTML.attributes(border => 1, cellpadding => 2) %]

=head1 DESCRIPTION

The HTML plugin is very new and very basic, implementing a few useful
methods for generating HTML.  It is likely to be extended in the future
or integrated with a larger project to generate HTML elements in a generic
way (as discussed recently on the mod_perl mailing list).

=head1 METHODS

=head2 escape(text)

Returns the source text with any HTML reserved characters such as 
E<lt>, E<gt>, etc., correctly esacped to their entity equivalents.

=head2 attributes(hash)

Returns the elements of the hash array passed by reference correctly
formatted (e.g. values quoted and correctly escaped) as attributes for
an HTML element.

=head2 element(type, attributes)

Generates an HTML element of the specified type and with the attributes
provided as an optional hash array reference as the second argument or
as named arguments.

    [% HTML.element(table => { border => 1, cellpadding => 2 }) %]
    [% HTML.element('table', border=1, cellpadding=2) %]
    [% HTML.element(table => attribs) %]

=head1 DEBUGGING

The HTML plugin accepts a 'sorted' option as a constructor argument
which, when set to any true value, causes the attributes generated by
the attributes() method (either directly or via element()) to be
returned in sorted order.  Order of attributes isn't important in
HTML, but this is provided mainly for the purposes of debugging where
it is useful to have attributes generated in a deterministic order
rather than whatever order the hash happened to feel like returning
the keys in.

    [% USE HTML(sorted=1) %]
    [% HTML.element( foo => { charlie => 1, bravo => 2, alpha => 3 } ) %]

generates:

    <foo alpha="3" bravo="2" charlie="1">

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.32, distributed as part of the
Template Toolkit version 2.06d, released on 22 January 2002.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>