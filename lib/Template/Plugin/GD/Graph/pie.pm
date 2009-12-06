#============================================================= -*-Perl-*-
#
# Template::Plugin::GD::Graph::pie
#
# DESCRIPTION
#
#   Simple Template Toolkit plugin interfacing to the GD::Graph::pie
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
# $Id: pie.pm,v 1.3 2001/06/15 14:30:56 abw Exp $
#
#============================================================================

package Template::Plugin::GD::Graph::pie;

require 5.004;

use strict;
use GD::Graph::pie;
use Template::Plugin;
use base qw( GD::Graph::pie Template::Plugin );
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

Template::Plugin::GD::Graph::pie - Create pie charts with legends

=head1 SYNOPSIS

    [% USE g = GD.Graph.pie(x_size, y_size); %]

=head1 EXAMPLES

    [% FILTER null;
        data = [
            ["1st","2nd","3rd","4th","5th","6th"],
            [    4,    2,    3,    4,    3,  3.5]
        ];

        USE my_graph = GD.Graph.pie( 250, 200 );

        my_graph.set(
                title => 'A Pie Chart',
                label => 'Label',
                axislabelclr => 'black',
                pie_height => 36,

                transparent => 0,
        );
        my_graph.plot(data).png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Graph.pie plugin provides an interface to the GD::Graph::pie
class defined by the GD::Graph module. It allows an (x,y) data set to
be plotted as a pie chart. The x values are typically strings.

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

L<Template::Plugin|Template::Plugin>, L<Template::Plugin::GD|Template::Plugin::GD>, L<Template::Plugin::GD::Graphs::lines|Template::Plugin::GD::Graphs::lines>, L<Template::Plugin::GD::Graphs::lines3d|Template::Plugin::GD::Graphs::lines3d>, L<Template::Plugin::GD::Graphs::bars|Template::Plugin::GD::Graphs::bars>, L<Template::Plugin::GD::Graphs::bars3d|Template::Plugin::GD::Graphs::bars3d>, L<Template::Plugin::GD::Graphs::points|Template::Plugin::GD::Graphs::points>, L<Template::Plugin::GD::Graphs::linespoints|Template::Plugin::GD::Graphs::linespoints>, L<Template::Plugin::GD::Graphs::area|Template::Plugin::GD::Graphs::area>, L<Template::Plugin::GD::Graphs::mixed|Template::Plugin::GD::Graphs::mixed>, L<Template::Plugin::GD::Graphs::pie3d|Template::Plugin::GD::Graphs::pie3d>, L<GD::Graph|GD::Graph>
