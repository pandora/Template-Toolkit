#============================================================= -*-Perl-*-
#
# Template::Utils
#
# DESCRIPTION
#   Various utility functions for the Template Toolkit.
#
# AUTHOR
#   Andy Wardley   <abw@cre.canon.co.uk>
#
# COPYRIGHT
#   Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: Utils.pm,v 1.4 1999/08/12 21:53:47 abw Exp $
#
#============================================================================

package Template::Utils;

require 5.004;
require Exporter;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

@ISA     = qw( Exporter );
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);



#========================================================================
#                         ----- EXPORTER -----
#========================================================================

# Exporter tags
my @SUBS     = qw( output_handler update_hash );
my @ALL      =   ( @SUBS );
@EXPORT_OK   =   ( @ALL  );
%EXPORT_TAGS =   (
    'subs'   =>  [ @SUBS ],
    'all'    =>  [ @ALL  ],
);



#========================================================================
#                       ----- PACKAGE SUBS -----
#========================================================================

#------------------------------------------------------------------------
# update_hash(\%target, \%params, \%defaults)
#
# Method called by constructors to update values in the target hash,
# $target, usully representing an object hash.  The second parameter
# should contain a reference to a hash of the intended values.  The 
# optional third parameter may contain a reference to a hash of default
# values.  When specified, the keys of $defaults will be used to extract
# values from $params, using the value of $defaults where it is undefined.
# If $defaults is undefined then all the keys/values of $params will 
# be copied to $target.
#
# Returns the $target reference.
#------------------------------------------------------------------------

sub update_hash {
    my ($target, $params, $defaults) = @_;
    my ($k, $p);

    $defaults = $params 
	unless defined $defaults;

    # look for any valid keys in $params and copy to $target
    foreach $k (keys %$defaults) {
	$p = $params->{ $k };
	$target->{ $k } = defined $p ? $p : $defaults->{ $k };
    }

    $target;
}



#------------------------------------------------------------------------
# output_handler($where)
# 
# Method called to construct an output handling sub-routine based on 
# the $where parameter.  If $where is already a CODE ref then it is 
# returned as is.  If $where is a GLOB then a closure is created to 
# write output to that GLOB.  Ditto for an object that isa(IO::Handle).
# A reference to a scalar indicates a target variable which should be
# appended to.  In all these cases, a reference to a sub-routine is 
# returned which will correctly write output to the target.
#------------------------------------------------------------------------

sub output_handler {
    my $where = shift;
    my ($output, $reftype);
    

    # default is to output to STDOUT, existing value for $what overrides it
    $where = \*STDOUT 
	unless defined $where;

    # if $where is a CODE reference, we alias directly to it 
    if (($reftype = ref($where)) eq 'CODE') {
	$output = $where;
    }
    # create a sub to print to a glob (such as \*STDOUT)
    elsif ($reftype eq 'GLOB') {
	$output = sub { print $where @_ };
    }   
    # create a sub to append output to a SCALAR ref
    elsif ($reftype eq 'SCALAR') {
	$output = sub { local $"=''; $$where .= "@_"; 1 };
    }
    # create a sub to call the print() method on an IO::Handle
    elsif (UNIVERSAL::isa($where, 'IO::Handle')) {
	$output = sub { $where->print(@_) };
    }
    # give up, we've done our best
    else {
	warn("output_handler() cannot determine target type\n");
    }

    # default handler in case we failed
    $output = sub { print @_ }
        unless defined $output;

    # return handler
    $output;
}



1;

__END__

=head1 NAME

Template::Utils - Various utility functions for the Template Tookit.

=head1 SYNOPSIS

    use Template::Utils qw( :all );

    my $handler = output_handler($target);
    my $target  = update_hash(\%target, \%params, \%defaults)

=head1 DESCRIPTION

The Template::Utils module defines a number of general sub-routines used
by the Template Toolkit.  These can be called by explicitly prefixing
the C<Template::Utils> package name to the sub-routine, or by first 
importing the functions into the current package by passing the ':subs'
or ':all' tagset names to the C<use Template::Utils> line.

=head1 UTILITY SUB-ROUTINES

=head2 output_handler($target)

Creates a closure which can be called to send output to a particular 
target.  The $target parameter may be an existing CODE ref (the ref
is returned), a reference to a GLOB such as C<\*STDOUT> (a closure which 
print to the GLOB is returned), a reference to an IO::Handle (a closure
which calls the handle's print() method is returned) or a reference to
a target string (a closure which appends output to the string is returned).

The closure returned will print all parameters passed to it, as per 
print().

    open(ERRLOG, "> $errorlog")
	|| die "$errorlog: $!\n";

    my $fh = IO::File->new("> $myfile")
	|| die "$myfile: $!\n";

    my $h1 = output_handler(\*STDERR);
    my $h2 = output_handler(\*ERRLOG);
    my $h3 = output_handler($fh);
    my $h4 = output_handler(\$mystring);

    foreach my $h ( $h1, $h2, h3, $h4 ) {
        &$h("An error has occured...\n");
    }

=head2 update_hash(\%target, \%params, \%defaults)

Updates the target hash referenced by the first paramter with values 
specified in the second.  The third parameter may also reference a hash
which is used to define the valid keys and default values.

A reference to the target hash ($target) is returned.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.4 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>

=cut



