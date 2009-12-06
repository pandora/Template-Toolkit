#============================================================= -*-Perl-*-
#
# Template::Provider
#
# DESCRIPTION
#   This module implements a class which handles the loading, compiling
#   and caching of templates.  Multiple Template::Provider objects can
#   be stacked and queried in turn to effect a Chain-of-Command between 
#   them.  A provider will attempt to return the requested template,
#   an error (STATUS_ERROR) or decline to provide the template 
#   (STATUS_DECLINE), allowing subsequent providers to attempt to 
#   deliver it.   See 'Design Patterns' for further details.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# TODO:
#   * optional provider prefix (e.g. 'http:')
#   * fold ABSOLUTE and RELATIVE test cases into one regex?
#
#----------------------------------------------------------------------------
#
# $Id: Provider.pm,v 2.3 2000/11/14 15:54:58 abw Exp $
#
#============================================================================

package Template::Provider;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ERROR );
use base qw( Template::Base );
use Template::Config;
use Template::Constants;
use Template::Document;
use File::Basename;

$VERSION  = sprintf("%d.%02d", q$Revision: 2.3 $ =~ /(\d+)\.(\d+)/);

use constant PREV   => 0;
use constant NAME   => 1;
use constant DATA   => 2; 
use constant LOAD   => 3;
use constant NEXT   => 4;

$DEBUG = 0 unless defined $DEBUG;

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# fetch($name)
#
# Returns a compiled template for the name specified by parameter.
# The template is returned from the internal cache if it exists, or
# loaded and then subsequently cached.  The ABSOLUTE and RELATIVE
# configuration flags determine if absolute (e.g. '/something...')
# and/or relative (e.g. './something') paths should be honoured.  The
# INCLUDE_PATH is otherwise used to find the named file. $name may
# also be a reference to a text string containing the template text,
# or a file handle from which the content is read.  The compiled
# template is not cached in these latter cases given that there is no
# filename to cache under.  A subsequent call to store($name,
# $compiled) can be made to cache the compiled template for future
# fetch() calls, if necessary. 
#
# Returns a compiled template or (undef, STATUS_DECLINED) if the 
# template could not be found.  On error (e.g. the file was found 
# but couldn't be read or parsed), the pair ($error, STATUS_ERROR)
# is returned.  The TOLERANT configuration option can be set to 
# downgrade any errors to STATUS_DECLINE.
#------------------------------------------------------------------------

sub fetch {
    my ($self, $name) = @_;
    my ($data, $error);

    if (ref $name) {
	# $name can be a reference to a scalar, GLOB or file handle
	($data, $error) = $self->_load($name);
	($data, $error) = $self->_compile($data)
	    unless $error;
	$data = $data->{ data }
	    unless $error;
    }
    elsif ($name =~ m[^/]) {
	# absolute paths (starting '/') allowed if ABSOLUTE set
	($data, $error) = $self->{ ABSOLUTE } 
	    ? $self->_fetch($name) 
	    : $self->{ TOLERANT } 
		? (undef, Template::Constants::STATUS_DECLINED)
		: ("$name: absolute paths are not allowed (set ABSOLUTE option)",
		   Template::Constants::STATUS_ERROR);
    }
    elsif ($name =~ m[^\.+/]) {
	# anything starting "./" is relative to cwd, allowed if RELATIVE set
	($data, $error) = $self->{ RELATIVE } 
	    ? $self->_fetch($name) 
	    : $self->{ TOLERANT } 
		? (undef, Template::Constants::STATUS_DECLINED)
		: ("$name: relative paths are not allowed (set RELATIVE option)",
		   Template::Constants::STATUS_ERROR);
    }
    else {
	# otherwise, it's a file name relative to INCLUDE_PATH
	($data, $error) = $self->{ INCLUDE_PATH } 
	    ? $self->_fetch_path($name) 
	    : (undef, Template::Constants::STATUS_DECLINED);
    }

#    $self->_dump_cache() 
#	if $DEBUG > 1;

    return ($data, $error);
}


#------------------------------------------------------------------------
# store($name, $data)
#
# Store a compiled template ($data) in the cached as $name.
#------------------------------------------------------------------------

sub store {
    my ($self, $name, $data) = @_;
    $self->_store($name, {
	data => $data,
	load => 0,
    });
}


#------------------------------------------------------------------------
# load($name)
#
# Load a template without parsing/compiling it, suitable for use with 
# the INSERT directive.  There's some duplication with fetch() and at
# some point this could be reworked to integrate them a little closer.
#------------------------------------------------------------------------

sub load {
    my ($self, $name) = @_;
    my ($data, $error);
    my $path = $name;

    if ($name =~ m[^/]) {
	# absolute paths (starting '/') allowed if ABSOLUTE set
	$error = "$name: absolute paths are not allowed (set ABSOLUTE option)" 
	    unless $self->{ ABSOLUTE };
    }
    elsif ($name =~ m[^\.+/]) {
	# anything starting "./" is relative to cwd, allowed if RELATIVE set
	$error = "$name: relative paths are not allowed (set RELATIVE option)"
	    unless $self->{ RELATIVE };
    }
    else {
      INCPATH: {
	# otherwise, it's a file name relative to INCLUDE_PATH
	foreach my $dir (@{ $self->{ INCLUDE_PATH } }) {
	    $path = "$dir/$name";
	    last INCPATH
		if -f $path;
	}
	undef $path;	    # not found
      }
    }

    if (defined $path && ! $error) {
	local $/ = undef;    # slurp files in one go
	local *FH;
	if (open(FH, $path)) {
	    $data = <FH>;
	    close(FH);
	}
	else {
	    $error = "$name: $!";
	}
    }

    if ($error) {
	return $self->{ TOLERANT } 
	    ? (undef, Template::Constants::STATUS_DECLINED)
	    : ($error, Template::Constants::STATUS_ERROR);
    }
    elsif (! defined $path) {
	return (undef, Template::Constants::STATUS_DECLINED);
    }
    else {
	return ($data, Template::Constants::STATUS_OK);
    }
}

 

#------------------------------------------------------------------------
# include_path(\@newpath)
#
# Accessor method for the INCLUDE_PATH setting.  If called with an
# argument, this method will replace the existing INCLUDE_PATH with
# the new value.
#------------------------------------------------------------------------

sub include_path {
     my ($self, $path) = @_;
     $self->{ INCLUDE_PATH } = $path if $path;
     return $self->{ INCLUDE_PATH };
}


#------------------------------------------------------------------------
# DESTROY
#
# The provider cache is implemented as a doubly linked list which Perl
# cannot free by itself due to the circular references between NEXT <=> 
# PREV items.  This cleanup method walks the list deleting all the NEXT/PREV 
# references, allowing the proper cleanup to occur and memory to be 
# repooled.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    my ($slot, $next);

    $slot = $self->{ HEAD };
    while ($slot) {
	$next = $slot->[ NEXT ];
	undef $slot->[ PREV ];
	undef $slot->[ NEXT ];
	$slot = $next;
    }
    undef $self->{ HEAD };
    undef $self->{ TAIL };
}




#========================================================================
#                        -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init()
#
# Initialise the cache.
#------------------------------------------------------------------------

sub _init {
    my ($self, $params) = @_;
    my $size = $params->{ CACHE_SIZE   };
    my $path = $params->{ INCLUDE_PATH } || '.';
    my $cdir = $params->{ COMPILE_DIR  } || '';
    my $dlim = $params->{ DELIMITER    };
    $dlim = ':' unless defined $dlim;

    # coerce INCLUDE_PATH to an array ref, if not already so
    $path = [ split($dlim, $path) ]
	unless ref $path eq 'ARRAY';

    # don't allow a CACHE_SIZE 1 because it breaks things and the 
    # additional checking isn't worth it
    $size = 2 
	if defined $size && ($size == 1 || $size < 0);

    if ($DEBUG) {
	local $" = ', ';
	print(STDERR "creating cache of ", 
	      defined $size ? $size : 'unlimited',
	      " slots for [ @$path ]\n");
    }

    # create COMPILE_DIR and sub-directories representing each INCLUDE_PATH
    # element in which to store compiled files
    if ($cdir) {
	require File::Path;
	foreach my $dir (@$path) {
	    &File::Path::mkpath("$cdir/$dir");
	}
	# ensure $cdir is terminated with '/' for subsequent path building
	$cdir .= '/';
    }

    $self->{ LOOKUP }       = { };
    $self->{ SLOTS  }       = 0;
    $self->{ SIZE }         = $size;
    $self->{ INCLUDE_PATH } = $path;
    $self->{ DELIMITER }    = $dlim;
    $self->{ COMPILE_DIR }  = $cdir;
    $self->{ COMPILE_EXT }  = $params->{ COMPILE_EXT } || '';
    $self->{ ABSOLUTE }     = $params->{ ABSOLUTE } || 0;
    $self->{ RELATIVE }     = $params->{ RELATIVE } || 0;
    $self->{ TOLERANT }     = $params->{ TOLERANT } || 0;
    $self->{ PARSER }       = $params->{ PARSER };
    $self->{ DEFAULT }      = $params->{ DEFAULT };
#   $self->{ PREFIX }       = $params->{ PREFIX };
    $self->{ PARAMS }       = $params;

    return $self;
}


#------------------------------------------------------------------------
# _fetch($name)
#
# Fetch a file from cache or disk by specification of an absolute or
# relative filename.  No search of the INCLUDE_PATH is made.  If the 
# file is found and loaded, it is compiled and cached.
#------------------------------------------------------------------------

sub _fetch {
    my ($self, $name) = @_;
    my $size = $self->{ SIZE };
    my ($slot, $data, $error);

    print STDERR "_fetch($name)\n"
	if $DEBUG;

    if (defined $size && ! $size) {
	# caching disabled so load and compile but don't cache
	($data, $error) = $self->_load($name);
	($data, $error) = $self->_compile($data)
	    unless $error;
	$data = $data->{ data }
	    unless $error;
    }
    elsif ($slot = $self->{ LOOKUP }->{ $name }) {
	# cached entry exists, so refresh slot and extract data
	($data, $error) = $self->_refresh($slot);
	$data = $slot->[ DATA ]
	    unless $error;
    }
    else {
	# nothing in cache so try to load, compile and cache
	($data, $error) = $self->_load($name);
	($data, $error) = $self->_compile($data)
	    unless $error;
	$data = $self->_store($name, $data)
	    unless $error;
    }

    return ($data, $error);
}


#------------------------------------------------------------------------
# _fetch_path($name)
#
# Fetch a file from cache or disk by specification of an absolute cache
# name (e.g. 'header') or filename relative to one of the INCLUDE_PATH 
# directories.  If the file isn't already cached and can be found and 
# loaded, it is compiled and cached under the full filename.
#------------------------------------------------------------------------

sub _fetch_path {
    my ($self, $name) = @_;
    my ($size, $compext, $compdir) = 
	@$self{ qw( SIZE COMPILE_EXT COMPILE_DIR ) };
    my ($dir, $path, $compiled, $slot, $data, $error);
    local *FH;

    print STDERR "_fetch_path($name)\n"
	if $DEBUG;

    # caching is enabled if $size is defined and non-zero or undefined
    my $caching = (! defined $size || $size);

    INCLUDE: {

	# the template may have been stored using a non-filename name
	if ($caching && ($slot = $self->{ LOOKUP }->{ $name })) {
	    # cached entry exists, so refresh slot and extract data
	    ($data, $error) = $self->_refresh($slot);
	    $data = $slot->[ DATA ] 
		unless $error;
	    last INCLUDE;
	}

	# search the INCLUDE_PATH for the file, in cache or on disk
	foreach $dir (@{ $self->{ INCLUDE_PATH } }) {
	    next unless $dir;
	    $path = "$dir/$name";
	    
	    print STDERR "looking for $path\n" if $DEBUG;

	    if ($caching && ($slot = $self->{ LOOKUP }->{ $path })) {
		# cached entry exists, so refresh slot and extract data
		($data, $error) = $self->_refresh($slot);
		$data = $slot->[ DATA ]
		    unless $error;
		last INCLUDE;
	    }
	    elsif (-f $path) {
		if ($compext || $compdir) {
		    $compiled = "$compdir$path$compext";
		    $compiled =~ s[//][/]g;
		}
		if ($compiled && -f $compiled
		    && (stat($path))[9] < (stat($compiled))[9]) {
		    
		    # load compiled template via require();  we zap any
		    # %INC entry to ensure it is reloaded (we don't 
		    # want 1 returned by require() to say it's in memory)
		    delete $INC{ $compiled };
		    eval { $data = require $compiled };

		    if ($data && ! $@) {
			# store in cache
			$data  = $self->store($path, $data);
			$error = Template::Constants::STATUS_OK;
			last INCLUDE;
		    }
		    elsif ($@) {
			warn "failed to load compiled template $compiled: $@\n";
			# leave $compiled set to regenerate template
		    }
		}
		# $compiled is set if an attempt to write the compiled 
		# template to disk should be made

		($data, $error) = $self->_load($path, $name);
		($data, $error) = $self->_compile($data, $compiled)
		    unless $error;
		$data = $self->_store($path, $data)
		    unless $error || ! $caching;
		# all done if $error is OK or ERROR
		last INCLUDE if ! $error 
		    || $error == Template::Constants::STATUS_ERROR;
	    }
	}
	# template not found, so look for a DEFAULT template
	my $default;
	if (defined ($default = $self->{ DEFAULT }) && $name ne $default) {
	    $name = $default;
	    redo INCLUDE;
	}
	($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
    } # INCLUDE

#    printf "returning ($data, %s)\n", defined $error ? $error : '<no error>';

    return ($data, $error);
}


#------------------------------------------------------------------------
# _load($name, $alias)
#
# Load template text from a string ($name = scalar ref), GLOB or file 
# handle ($name = ref), or from an absolute filename ($name = scalar).
# Returns a hash array containing the following items:
#   name    filename or $alias, if provided, or 'input text', etc.
#   text    template text
#   time    modification time of file, or current time for handles/strings
#   load    time file was loaded (now!)  
#
# On error, returns ($error, STATUS_ERROR), or (undef, STATUS_DECLINED)
# if TOLERANT is set.
#------------------------------------------------------------------------

sub _load {
    my ($self, $name, $alias) = @_;
    my ($data, $error);
    my $tolerant = $self->{ TOLERANT };
    my $now = time;
    local $/ = undef;    # slurp files in one go
    local *FH;

    $alias = $name unless defined $alias or ref $name;

    print STDERR "_load($name, $alias)\n"
	if $DEBUG;

    LOAD: {
	if (ref $name eq 'SCALAR') {
	    # $name can be a SCALAR reference to the input text...
	    $data = {
		name => defined $alias ? $alias : 'input text',
		text => $$name,
		time => $now,
		load => 0,
	    };
	}
	elsif (ref $name) {
	    # ...or a GLOB or file handle...
	    my $text = <$name>;
	    $data = {
		name => defined $alias ? $alias : 'input file handle',
		text => $text,
		time => $now,
		load => 0,
	    };
	}
	elsif (open(FH, $name)) {
	    my $text = <FH>;
	    $data = {
		name => $alias,
		text => $text,
		time => (stat $name)[9],
		load => $now,
	    };
	}
	elsif ($tolerant) {
	    ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
	}
	else {
	    $data  = "$alias: $!";
	    $error = Template::Constants::STATUS_ERROR;
	}
    }

    return ($data, $error);
}


#------------------------------------------------------------------------
# _refresh(\@slot)
#
# Private method called to mark a cache slot as most recently used.
# A reference to the slot array should be passed by parameter.  The 
# slot is relocated to the head of the linked list.  If the file from
# which the data was loaded has been upated since it was compiled, then
# it is re-loaded from disk and re-compiled.
#------------------------------------------------------------------------

sub _refresh {
    my ($self, $slot) = @_;
    my ($head, $file, $data, $error);

    print STDERR "_refresh([ @$slot ])\n"
	if $DEBUG;

    # compare load time with current file modification time to see if
    # its modified and we need to reload it
    if ($slot->[ LOAD ] && stat $slot->[ NAME ]
			&& (stat(_))[9] > $slot->[ LOAD ]) {
	print STDERR "refreshing cache file ", $slot->[ NAME ], "\n"
	    if $DEBUG;

	($data, $error) = $self->_load($slot->[ NAME ], 
				       $slot->[ DATA ]->{ name });
	($data, $error) = $self->_compile($data)
	    unless $error;
	$slot->[ DATA ] = $data->{ data },
	    unless $error;
    }

    # remove existing slot from usage chain...
    if ($slot->[ PREV ]) {
	$slot->[ PREV ]->[ NEXT ] = $slot->[ NEXT ];
    }
    else {
	$self->{ HEAD } = $slot->[ NEXT ];
    }
    if ($slot->[ NEXT ]) {
	$slot->[ NEXT ]->[ PREV ] = $slot->[ PREV ];
    }
    else {
	$self->{ TAIL } = $slot->[ PREV ];
    }
    
    # ..and add to start of list
    $head = $self->{ HEAD };
    $head->[ PREV ] = $slot if $head;
    $slot->[ PREV ] = undef;
    $slot->[ NEXT ] = $head;
    $self->{ HEAD } = $slot;

    return ($data, $error);
}


#------------------------------------------------------------------------
# _store($name, $data)
#
# Private method called to add a data item to the cache.  If the cache
# size limit has been reached then the oldest entry at the tail of the 
# list is removed and its slot relocated to the head of the list and 
# reused for the new data item.  If the cache is under the size limit,
# or if no size limit is defined, then the item is added to the head 
# of the list.  
#------------------------------------------------------------------------

sub _store {
    my ($self, $name, $data, $compfile) = @_;
    my $size = $self->{ SIZE };
    my ($slot, $head);

    # extract the load time and compiled template from the data
    my $load = $data->{ load };
    $data = $data->{ data };

    print STDERR "_store($name, $data)\n"
	if $DEBUG;

    if (defined $size && $self->{ SLOTS } >= $size) {
	# cache has reached size limit, so reuse oldest entry

	print STDERR "reusing oldest cache entry (size limit reached: $size)\nslots: $self->{ SLOTS }\n"
	    if $DEBUG;

	# remove entry from tail of list
	$slot = $self->{ TAIL };
	$slot->[ PREV ]->[ NEXT ] = undef;
	$self->{ TAIL } = $slot->[ PREV ];
	
	# remove name lookup for old node
	delete $self->{ LOOKUP }->{ $slot->[ NAME ] };

	# add modified node to head of list
	$head = $self->{ HEAD };
	$head->[ PREV ] = $slot if $head;
	@$slot = ( undef, $name, $data, $load, $head );
	$self->{ HEAD } = $slot;

	# add name lookup for new node
	$self->{ LOOKUP }->{ $name } = $slot;
    }
    else {
	# cache is under size limit, or none is defined

	print STDERR "adding new cache entry\n"
	    if $DEBUG;

	# add new node to head of list
	$head = $self->{ HEAD };
	$slot = [ undef, $name, $data, $load, $head ];
	$head->[ PREV ] = $slot if $head;
	$self->{ HEAD } = $slot;
	$self->{ TAIL } = $slot unless $self->{ TAIL };

	# add lookup from name to slot and increment nslots
	$self->{ LOOKUP }->{ $name } = $slot;
	$self->{ SLOTS }++;
    }

    return $data;
}


#------------------------------------------------------------------------
# _compile($data)
#
# Private method called to parse the template text and compile it into 
# a runtime form.  Creates and delegates a Template::Parser object to
# handle the compilation, or uses a reference passed in PARSER.  On 
# success, the compiled template is stored in the 'data' item of the 
# $data hash and returned.  On error, ($error, STATUS_ERROR) is returned,
# or (undef, STATUS_DECLINED) if the TOLERANT flag is set.
# The optional $compiled parameter may be passed to specify
# the name of a compiled template file to which the generated Perl
# code should be written.  Errors are (for now...) silently 
# ignored, assuming that failures to open a file for writing are 
# intentional (e.g directory write permission).
#------------------------------------------------------------------------

sub _compile {
    my ($self, $data, $compfile) = @_;
    my $text = $data->{ text };
    my ($parsedoc, $error);

    my $parser = $self->{ PARSER } 
	||= Template::Config->parser($self->{ PARAMS })
	||  return (Template::Config->error(), Template::Constants::STATUS_ERROR);

    # discard the template text - we don't need it any more
    delete $data->{ text };   

    # call parser to compile template into Perl code
    if ($parsedoc = $parser->parse($text, $data)) {

	$parsedoc->{ METADATA } = { 
	    'name'    => $data->{ name },
	    'modtime' => $data->{ time },
	    %{ $parsedoc->{ METADATA } },
	};
	
	# write the Perl code to the file $compfile, if defined
	if ($compfile) {
	    my $basedir = &File::Basename::dirname($compfile);
	    &File::Path::mkpath($basedir) unless -d $basedir;

	    $error = 'cache failed to write '
		    . &File::Basename::basename($compfile)
		    . ": $Template::Document::ERROR"
		unless Template::Document::write_perl_file($compfile, 
							   $parsedoc);
	    print STDERR "error: $error" if $error;
	}

	unless ($error) {
	    return $data				        ## RETURN ##
		if $data->{ data } = Template::Document->new($parsedoc);
	    $error = $Template::Document::ERROR;
	}
    }
    else {
	$error = 'parse error: ' . $data->{ name } . ' ' . $parser->error();
    }

    # return STATUS_ERROR, or STATUS_DECLINED if we're being tolerant
    return $self->{ TOLERANT } 
	? (undef, Template::Constants::STATUS_DECLINED)
	: ($error,  Template::Constants::STATUS_ERROR)
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal object 
# state.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $size = $self->{ SIZE };
    my $parser = $self->{ PARSER }->_dump();
    $parser =~ s/\n/\n    /gm;
    $size = 'unlimited' unless defined $size;

    local $" = ', ';
    return <<EOF;
$self
INCLUDE_PATH => [ @{ $self->{ INCLUDE_PATH } } ]
ABSOLUTE     => $self->{ ABSOLUTE }
RELATIVE     => $self->{ RELATIVE }
TOLERANT     => $self->{ TOLERANT }
DELIMITER    => $self->{ DELIMITER }
COMPILE_EXT  => $self->{ COMPILE_EXT }
COMPILE_DIR  => $self->{ COMPILE_DIR }
CACHE_SIZE   => $size
SLOTS        => $self->{ SLOTS }
LOOKUP       => $self->{ LOOKUP }
PARSER       => $parser
EOF
#    join("\n", $self, map { "$_ => $self->{ $_ }" } keys %$self) . "\n";
}


#------------------------------------------------------------------------
# _dump_cache()
#
# Debug method which prints the current state of the cache to STDERR.
#------------------------------------------------------------------------

sub _dump_cache {
    my $self = shift;
    my ($node, $lut, $count);

    $count = 0;
    if ($node = $self->{ HEAD }) {
	while ($node) {
	    $lut->{ $node } = $count++;
	    $node = $node->[ NEXT ];
	}
	$node = $self->{ HEAD };
	print STDERR "CACHE STATE:\n";
	print STDERR "  HEAD: ", $self->{ HEAD }->[ NAME ], "\n";
	print STDERR "  TAIL: ", $self->{ TAIL }->[ NAME ], "\n";
	while ($node) {
	    my ($prev, $name, $data, $load, $next) = @$node;
#	    $name = '...' . substr($name, -10) if length $name > 10;
	    $prev = $prev ? "#$lut->{ $prev }<-": '<undef>';
	    $next = $next ? "->#$lut->{ $next }": '<undef>';
	    print STDERR "   #$lut->{ $node } : [ $prev, $name, $data, $load, $next ]\n";
	    $node = $node->[ NEXT ];
	}
    }
}

1;

