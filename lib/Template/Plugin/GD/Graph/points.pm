#============================================================= -*-Perl-*-
#
# Template::Plugin::GD::Graph::points
#
# DESCRIPTION
#
#   Simple Template Toolkit plugin interfacing to the GD::Graph::points
#   package in the GD::Graph.pm module.
#
# AUTHOR
#   Craig Barratt   <craig@arraycomm.com>
#
# COPYRIGHT
#   Copyright (C) 2001 Craig Barratt.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: points.pm,v 1.3 2001/06/15 14:30:56 abw Exp $
#
#============================================================================

package Template::Plugin::GD::Graph::points;

require 5.004;

use strict;
use GD::Graph::points;
use Template::Plugin;
use base qw( GD::Graph::points Template::Plugin );
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub new
{
    my $class   = shift;
    my $context = shift;
    return $class->SUPER::new(@_);
}

sub set
{
    my $self = shift;

    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    $self->SUPER::set(@_);
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

Template::Plugin::GD::Graph::points - Create point graphs with axes and legends

=head1 SYNOPSIS

    [% USE g = GD.Graph.points(x_size, y_size); %]

=head1 EXAMPLES

    [% FILTER null; 
        data = [
            ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
            [    5,   12,   24,   33,   19,    8,    6,    15,    21],
            [    1,    2,    5,    6,    3,  1.5,    2,     3,     4],
        ];
        USE my_graph = GD.Graph.points();
        my_graph.set(
                x_label => 'X Label',
                y_label => 'Y label',
                title => 'A Points Graph',
                y_max_value => 40,
                y_tick_number => 8,
                y_label_skip => 2,
                legend_placement => 'RC',
                long_ticks => 1,
                marker_size => 6, 
                markers => [ 1, 7, 5 ],
            
                transparent => 0,
        );  
        my_graph.set_legend('one', 'two');
        my_graph.plot(data).png | stdout(1);
       END; 
    -%]

=head1 DESCRIPTION

The GD.Graph.points plugin provides an interface to the GD::Graph::points
class defined by the GD::Graph module. It allows one or more (x,y) data
sets to be plotted as points, in addition to axes and legends.

See L<GD::Graph> for more details.

=head1 AUTHOR

Craig Barratt E<lt>craig@arraycomm.comE<gt>


The GD::Graph module was written by Martien Verbruggen.


=head1 VERSION

1.02, distributed as part of the
Template Toolkit version 2.03, released on 15 June 2001.

=head1 COPYRIGHT


Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>

GD::Graph is copyright 1999 Martien Verbruggen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Template::Plugin::GD|Template::Plugin::GD>, L<Template::Plugin::GD::Graphs::lines|Template::Plugin::GD::Graphs::lines>, L<Template::Plugin::GD::Graphs::lines3d|Template::Plugin::GD::Graphs::lines3d>, L<Template::Plugin::GD::Graphs::bars|Template::Plugin::GD::Graphs::bars>, L<Template::Plugin::GD::Graphs::bars3d|Template::Plugin::GD::Graphs::bars3d>, L<Template::Plugin::GD::Graphs::linespoints|Template::Plugin::GD::Graphs::linespoints>, L<Template::Plugin::GD::Graphs::area|Template::Plugin::GD::Graphs::area>, L<Template::Plugin::GD::Graphs::mixed|Template::Plugin::GD::Graphs::mixed>, L<Template::Plugin::GD::Graphs::pie|Template::Plugin::GD::Graphs::pie>, L<Template::Plugin::GD::Graphs::pie3d|Template::Plugin::GD::Graphs::pie3d>, L<GD::Graph|GD::Graph>
