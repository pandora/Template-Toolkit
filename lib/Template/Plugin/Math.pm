#============================================================= -*-Perl-*-
#
# Template::Plugin::Math
#
# DESCRIPTION
#   Plugin implementing numerous mathematical functions.
#
# AUTHORS
#   Andy Wardley   <abw@kfs.org>
#   ...your name here...
#
# COPYRIGHT
#   Copyright (C) 2002 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Math.pm,v 1.13 2006/01/30 20:05:48 abw Exp $
#
#============================================================================

package Template::Plugin::Math;

require 5.004;

use strict;
use vars qw( $VERSION $AUTOLOAD );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \%config)
#
# This constructor method creates a simple, empty object to act as a 
# receiver for future object calls.  No doubt there are many interesting
# configuration options that might be passed, but I'll leave that for 
# someone more knowledgable in these areas to contribute...
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $config) = @_;
    $config ||= { };

    bless {
	%$config,
    }, $class;
}

sub abs   { shift; CORE::abs($_[0]);          }
sub atan2 { shift; CORE::atan2($_[0], $_[0]); } # prototyped (ugg)
sub cos   { shift; CORE::cos($_[0]);          }
sub exp   { shift; CORE::exp($_[0]);          }
sub hex   { shift; CORE::hex($_[0]);          }
sub int   { shift; CORE::int($_[0]);          }
sub log   { shift; CORE::log($_[0]);          }
sub oct   { shift; CORE::oct($_[0]);          }
sub rand  { shift; CORE::rand($_[0]);         }
sub sin   { shift; CORE::sin($_[0]);          }
sub sqrt  { shift; CORE::sqrt($_[0]);         }
sub srand { shift; CORE::srand($_[0]);        }

# Use the Math::TrulyRandom module
# XXX This is *sloooooooowwwwwwww*
sub truly_random {
    eval { require Math::TrulyRandom; }
         or die(Template::Exception->new("plugin",
            "Can't load Math::TrulyRandom"));
    return Math::TrulyRandom::truly_random_value();
}

eval {
    require Math::Trig;
    no strict qw(refs);
    for my $trig_func (@Math::Trig::EXPORT) {
        my $sub = Math::Trig->can($trig_func);
        *{$trig_func} = sub { shift; &$sub(@_) };
    }
};

# To catch errors from a missing Math::Trig
sub AUTOLOAD { return; }

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

Template::Plugin::Math - Plugin interface to mathematical functions

=head1 NAME

Template::Plugin::Math - Plugin providing mathematical functions

=head1 SYNOPSIS

    [% USE Math %]

    [% Math.sqrt(9) %]

=head1 DESCRIPTION

The Math plugin provides numerous mathematical functions for use
within templates.

=head1 METHODS

Template::Plugin::Math makes available the following functions from
the Perl core:

=over 4

=item abs

=item atan2

=item cos

=item exp

=item hex

=item int

=item log

=item oct

=item rand

=item sin

=item sqrt

=item srand

=back

In addition, if the Math::Trig module can be loaded, the following
functions are also available:

=over 4

=item pi

=item tan

=item csc

=item cosec

=item sec

=item cot

=item cotan

=item asin

=item acos

=item atan

=item acsc

=item acosec

=item asec

=item acot

=item acotan

=item sinh

=item cosh

=item tanh

=item csch

=item cosech

=item sech

=item coth

=item cotanh

=item asinh

=item acosh

=item atanh

=item acsch

=item acosech

=item asech

=item acoth

=item acotanh

=item rad2deg

=item rad2grad

=item deg2rad

=item deg2grad

=item grad2rad

=item grad2deg

=back

If the Math::TrulyRandom module is available, and you've got the time
to wait, the C<truly_random_number> method is available:

    [% Math.truly_random_number %]

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

L<http://wardley.org/|http://wardley.org/>




=head1 VERSION

1.13, distributed as part of the
Template Toolkit version 2.15, released on 26 May 2006.

=head1 COPYRIGHT

  Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
