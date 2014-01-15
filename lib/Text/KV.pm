package Text::KV;

use strict;
use warnings;

use Carp;

our $VERSION = 0.02;

#################
## CONSTRUCTOR ##
#################

my %default_attr = (
    kv_separator    => '=',
    rec_separator   => undef,	
    comment         => '#',
    trim_key        => 1,
    trim_value      => 1,
    merge_overwrite => 1,
    print_justified => 1,
);

sub new {
    my $class = shift;
    my $attr = @_ > 0 ? shift : {};
    
    my $self = { %default_attr };
    for my $prop (keys %$attr) {
    	unless (exists $default_attr{$prop}) {
    		croak "Unrecognized attribute $prop";
    	}
    	$self->{$prop} = $attr->{$prop};
    }
    
    bless $self, $class;
    $self->_check_sanity;
    
    return $self;
}

sub _check_sanity {
    my $self = shift;
    
    my $kv_sep = $self->{kv_separator};
    my $rec_sep = $self->{rec_separator};
    my $comment = $self->{comment};
    
    if (defined $kv_sep) {
    	croak "kv_separator cannot be empty" unless length($kv_sep) > 0;
    } else {
    	croak "kv_separator must be defined";
    }
    
    if (defined $rec_sep) {
    	croak "kv_separator cannot equal rec_separator" if $kv_sep eq $rec_sep;
    	croak "kv_separator cannot contain rec_separator" if defined $rec_sep && $kv_sep =~ /\Q$rec_sep\E/;
    }
    
    if (defined $comment) {
    	croak "kv_separator cannot equal comment" if $kv_sep eq $comment;
    }	
}

#######################
## LINE HELPER FUNCS ##
#######################

sub line_is_comment {
    my ($self, $line) = @_;
    
    #if we disallow comments, no line can be a comment
    return 0 unless defined $self->{comment};
    
    my $com = $self->{comment};
    return $line =~ /^\s*\Q$com\E/;
}

sub line_is_empty {
    my ($self, $line) = @_;
    
    return 1 unless defined $line;
    return 1 if $line eq '';
    return 1 if $self->line_is_comment($line);
    return $line =~ /^\s*$/;
}

sub _split_recs {
    my ($self, $line) = @_;
    
    my @recs;
    my $sep = $self->{rec_separator};
    if (defined $sep) {
    	@recs = split(/\Q$sep\E/, $line);
    } else {
    	@recs = ($line);
    }
    
    return @recs;
}

sub _split_kv {
    my ($self, $rec) = @_;
    
    my $sep = $self->{kv_separator};
    croak "Invalid record '$rec' (no separator)" unless $rec =~ /\Q$sep\E/;
    my ($key, $value) = split(/\Q$sep\E/, $rec, 2);
    croak "Invalid record '$rec' (no key)" unless $key;
    
    if ($self->{trim_key}) {
    	$key =~ s/^\s*//;
    	$key =~ s/\s*$//;
    }
    if ($value && $self->{trim_value}) {
    	$value =~ s/^\s*//;
    	$value =~ s/\s*$//;
    }
    
    return ($key, $value);
}

######################
## PARSE_LINE FUNCS ##
######################

sub parse_line_pair {
    my ($self, $line) = @_;
    
    croak 'parse_line_pair is invalid with rec_separator set' if defined $self->{rec_separator};
    
    my $pairs = $self->parse_line_pairs($line);
    if ($pairs) {
    	return @$pairs[0];
    } else {
    	return undef;
    }
}

sub parse_line_pairs {
    my ($self, $line) = @_;
    
    return undef if $self->line_is_empty($line);
    
    my @pairs;
    for my $rec ($self->_split_recs($line)) {
    	my ($key, $value) = $self->_split_kv($rec);
    	push @pairs, [$key, $value];
    }
    
    return \@pairs;
}

sub parse_line_merge {
    my ($self, $line) = @_;
    my $overwrite = $self->{merge_overwrite};
    
    return undef if $self->line_is_empty($line);
    
    my $hr = {};
    for my $rec ($self->_split_recs($line)) {
    	my ($key, $value) = $self->_split_kv($rec);
    	$hr->{$key} = $value if $overwrite || !exists $hr->{$key};
    }
    
    return $hr;
}

####################
## GET_LINE_FUNCS ##
####################

sub _next_line {
    my ($self, $io) = @_;
    require IO::Handle;
    
    until ($io->eof) {
    	my $line = $io->getline;
    	return $line unless $self->line_is_empty($line);
    }
    
    return undef;
}

sub get_line_pair {
    my ($self, $io) = @_;
    croak 'get_line_pair is invalid with rec_separator set' if defined $self->{rec_separator};
    
    my $line = $self->_next_line($io);
    return $self->parse_line_pair($line);
}

sub get_line_pairs {
    my ($self, $io) = @_;
    
    my $line = $self->_next_line($io);
    return $self->parse_line_pairs($line);
}

sub get_line_merge {
    my ($self, $io) = @_;
    
    my $line = $self->_next_line($io);
    return $self->parse_line_merge($line);
}

sub get_all_pairs {
    my ($self, $io) = @_;
    
    my @pairs;
    while (my $line = $self->_next_line($io)) {
    	push @pairs, $self->parse_line_pairs($line);
    }
    
    if (@pairs) {
    	return \@pairs;
    } else {
    	return undef;
    }
}

sub get_all_merge {
    my ($self, $io) = @_;
    my $overwrite = $self->{merge_overwrite};
    
    my %merge;
    while (my $line = $self->_next_line($io)) {
    	my $temp = $self->parse_line_merge($line);
    	for my $key (keys $temp) {
    		$merge{$key} = $temp->{$key} if $overwrite || !exists $merge{$key};
    	}
    }
    
    if (%merge) {
    	return \%merge;
    } else {
    	return undef;
    }
}

#################
## PRINT FUNCS ##
#################

sub print_stdout {
    my ($self, $hr) = @_;
    require IO::Handle;
    
    my $fh = IO::Handle->new_from_fd(fileno(STDOUT), '>') or croak 'Print to stdout failed';
    $self->print($hr, $fh);
}

sub print {
    my ($self, $arg, $io) = @_;
    
    my $ref = ref $arg;
    if ($ref eq 'HASH') {
    	$self->_print_hashref($arg, $io);
    } elsif ($ref eq 'ARRAY') {
    	$self->_print_arrayref($arg, $io);
    } else {
    	croak 'Value to print must be hashref or arrayref';
    }
}

sub _print_hashref {
    my ($self, $hr, $io) = @_;
    require IO::Handle;
    
    my $justify = $self->{print_justified};
    my $sep = $self->{kv_separator};
    
    my $justify_len = 0;
    if ($justify) {
    	for my $key (keys %$hr) {
    		my $len = length($key);
    		$justify_len = $len if $len > $justify_len;
    	}
    }
    
    for my $key (sort keys %$hr) {
    	my $key = $key;
    	my $value = $hr->{$key};
    	my $pad_key = '';
    	if ($justify) {
    		$pad_key = ' ' x ($justify_len - length($key));
    	}
    	
    	$io->print("$key$pad_key $sep $value\n");
    }
}

sub _print_arrayref {
    my ($self, $ar, $io) = @_;
    
    #check: 2D array or 3D?
    if (scalar @$ar > 0) {
    	my $child = @$ar[0];
    	my $childref = ref $child;
    	if ($childref) {
    		if ($childref eq 'ARRAY') {
    			if (scalar @$child > 0) {
    				my $grandchild = @$child[0];
    				my $grandchildref = ref $grandchild;
    				if ($grandchildref) {
    					if ($grandchildref eq 'ARRAY') {
    						$self->_print_3darrayref($ar, $io);
    					} else {
    						croak 'Arrayref must be 2D or 3D array';
    					}
    				} else {
    					$self->_print_2darrayref($ar, $io);
    				}
    			}
    		} else {
    			croak 'Arrayref must be 2D or 3D array';
    		}
    	} else {
    		confess 'Internal error';
    	}
    }
}

sub _print_2darrayref {
    my ($self, $lines, $io) = @_;
    require IO::Handle;
    
    my $justify = $self->{print_justified};
    my $sep = $self->{kv_separator};
    
    my $justify_len = 0;
    if ($justify) {
    	for my $pair (@$lines) {
    		my $key = @$pair[0];
    		my $len = length($key);
    		$justify_len = $len if $len > $justify_len;
    	}
    }
    
    for my $pair (@$lines) {
    	my $key = @$pair[0];
    	my $val = @$pair[1];
    	my $pad_key = '';
    	if ($justify) {
    		$pad_key = ' ' x ($justify_len - length($key));
    	}
    	
    	$io->print("$key$pad_key $sep $val\n");
    }
}

sub _print_3darrayref {
    my ($self, $lines, $io) = @_;
    require IO::Handle;
    
    my $justify = $self->{print_justified};
    my $sep = $self->{kv_separator};
    my $rec_sep = $self->{rec_separator};
    
    croak 'Cannot print 3D arrayref unless rec_separator is defined' unless defined $rec_sep;
    
    my @justify_lens;
    if ($justify) {
    	for my $line (@$lines) {
    		my $i = 0;
    		for my $pair (@$line) {
    			my $len;
    			
    			my $key = @$pair[0];
    			$len = length($key);
    			push(@justify_lens, 0) if $i >= scalar @justify_lens;
    			$justify_lens[$i] = $len if $len > $justify_lens[$i];
    			$i++;
    			
    			my $val = @$pair[1];
    			$len = length($val);
    			push(@justify_lens, 0) if $i >= scalar @justify_lens;
    			$justify_lens[$i] = $len if $len > $justify_lens[$i];
    			$i++;
    		}
    	}
    }
    
    for my $line (@$lines) {
    	my $i = 0;
    	my $print_rec = 0;
    	my $pad_val = '';
    	
    	for my $pair (@$line) {
    		$io->print("$pad_val $rec_sep ") if $print_rec;
    		$print_rec = 1;
    		
    		my $key = @$pair[0];
    		my $val = @$pair[1];
    		my $pad_key = '';
    		
    		if ($justify) {
    			my $key_justify_len = $justify_lens[$i];
    			my $val_justify_len = $justify_lens[$i+1];
    			
    			$pad_key = ' ' x ($key_justify_len - length($key));
    			$pad_val = ' ' x ($val_justify_len - length($val));
    		}
    		$i += 2;
    		
    		$io->print("$key$pad_key $sep $val");
    	}
    	$io->print("\n");
    }
}


1; #End of KV.pm


=head1 NAME

Text::KV - File and text operations for key-value pairs.


=head1 SYNOPSIS

    #read entire file
    open(my $file, '<', 'config.txt');
    my $kv = Text::KV->new;
    my $config = $kv->get_all_merge($file);
    
    #read line-by-line
    open(my $file, '<', 'records.txt');
    my $kv = Text::KV->new;
    while (my $rec = $kv->get_line_merge($file)) {
    	print $rec->{username}; #each line is one hashref
    }
    
Roughly analogous to Text::CSV, but for key-value files and text.


=head1 DESCRIPTION


=head2 new

    my $kv = Text::KV->new;
    
    my $kv = Text::KV->new({kv_separator => '->'});
    
    my $kv = Text::KV->new({comment => '//', trim_value => 0});
    
Constructor call. Default form takes no args. Alternate form takes one hashref,
which may contain overrides for the following default values:

    kv_separator    => '=',
    rec_separator   => undef,	
    comment         => '#',
    trim_key        => 1,
    trim_value      => 1,
    merge_overwrite => 1,
    print_justified => 1,

=over 4


=item kv_separator

What string separates keys and values?


=item rec_separator

What string separates multiple key-value pairs on the same line? If left
undefined, we will allow only one pair per line.


=item comment

Lines beginning with this string will be ignored (leading whitespace is okay). 
If undefined, there is no such thing as a comment line.


=item trim_key

Should we trim whitespace around keys?


=item trim_value

Should we trim whitespace around values?


=item merge_overwrite

When merging hashes, should we take the first or last value found?

If true, we will effectively read the last value found; else, we will 
effectively read the last one.


=item print_justified

When printing, should we add whitespace so that columns are aligned?

=back


=head2 get_all_merge

    open(my $io, '<', $some_path);
    my $kv = Text::KV->new;
    my $hr = $kv->get_all_merge($io);
    
    #INPUT:
    #
    #    cat     = meow
    #    doggy   = woof
    #    thimble = tiny
    #    boat    = huge
    #
    #OUTPUT:
    #
    #    { 
    #      cat     => 'meow',
    #      doggy   => 'woof',
    #      thimble => 'tiny',
    #      boat    => 'huge' 
    #    }
    
Simplest hook into the library. Reads an entire file in one call, returns a flat
data structure containing each unique key found.

Accepts any valid IO::Handle. Returns undef if no data is found.


=head2 get_all_pairs

    open(my $io, '<', $some_path);
    my $kv = Text::KV->new({ rec_separator => '|' });
    my $ar = $kv->get_all_pairs($io);
    
    #INPUT:
    #
    #    cat=meow|doggy=woof
    #    thimble=tiny|boat=huge
    #
    #OUTPUT:
    #
    #    [
    #      [
    #        ['cat', 'meow'], 
    #        ['doggy','woof']
    #      ],
    #      [
    #        ['thimble', 'tiny'],
    #        ['boat', 'huge']
    #      ]
    #    ]
    
Useful if you need each individual pair. Reads an entire file in one call, 
returns a deeply nested data arrayref containing all key-value pairs found.

NOTE: unless you set rec_separator, only one record is allowed per line.

Accepts any valid IO::Handle. Returns undef if no data is found.


=head2 get_line_merge

    open(my $io, '<', $some_path);
    while (my $hr = $kv->get_line_merge($io)) {
    	#do something with each line's data
    }
    
    #INPUT FILE:
    #
    #    cat=meow|doggy=woof
    #    thimble=tiny|boat=huge
    #
    #SUCCESSIVE OUTPUTS (for each call):
    #
    #    { cat => 'meow', doggy => 'woof' }
    #
    #    { thimble => 'tiny', boat => 'huge' }
    #
    #    undef
    
Reads a file line-by-line, returns a flat hashref containing one entry per
unique key.

NOTE: unless you set rec_separator, only one record is allowed per line.

Will advance an IO::Handle until it finds a non-empty, non-comment line to
parse; returns undef once eof is reached.


=head2 get_line_pairs

    open(my $io, '<', $some_path);
    while (my $ar = $kv->get_line_pairs($io)) {
    	for my $pair (@$ar) {
    		my $key = @$pair[0];
    		my $val = @$pair[0];
    		#do something with each pair on this line
    	}
    }
    
    #INPUT FILE:
    #
    #    cat=meow|doggy=woof
    #    thimble=tiny|boat=huge
    #
    #SUCCESSIVE OUTPUTS (for each call):
    #
    #    [['cat', 'meow'], ['doggy', 'woof']]
    #
    #    [['thimble', 'tiny'], ['boat', 'huge']]
    #
    #    undef	
    
Reads a file line-by-line, returns a nested arrayref containing one entry
per key-value pair found on each line.

Will advance an IO::Handle until it finds a non-empty, non-comment line to
parse; returns undef once eof is reached.


=head2 get_line_pair

    open(my $io, '<', $some_path);
    while (my $ar = $kv->get_line_pair($io)) {
    	#do something with each line's data
    }
    
    #INPUT FILE:
    #
    #    cat     = meow
    #    doggy   = woof
    #    thimble = tiny
    #    boat    = huge
    #
    #SUCCESSIVE OUTPUTS (for each call):
    #
    #    ['cat', 'meow']
    #
    #    ['doggy', 'woof']
    #
    #    ['thimble', 'tiny']
    #
    #    ['boat', 'huge']
    #
    #    undef	

As get_line_pairs, but expects one key-value pair per line.

This call will produce an error if called while rec_separator is set.


=head2 parse_line_pair

    my $line = 'cat=meow';
    my $ar = $kv->parse_line_pair($line);
    
    #returns: ['cat', 'meow']
    
As get_line_pair, but works on any string.
    
Given a string, parse a single key-value pair and return a single arrayref.

Note, this will die if called on a $kv with rec_separator defined.


=head2 parse_line_pairs

    my $line = 'cat=meow|dog=woof';
    my $ar = $kv->parse_line_pairs($line);
    
    #[['cat, 'meow'], ['dog', 'woof']]
    
As get_line_pairs, but works with any string.


=head2 parse_line_merge

    my $line = 'cat=meow|dog=woof';
    my $hr = $kv->parse_line_merge($line);
    
    #returns: {cat=>'meow', dog=>'woof'}

As get_line_merge, but works with any string.

Handling of duplicate keys is based on the merge_overwrite setting.


=head2 print

    open(my $file, '>', 'output.txt');
    $kv->print($some_ref, $file);
    
Prints some data structure to a file. The input data structure can be similar to
any you'd see returned from get_* methods, such as get_all_merge (hashref) or 
get_all_pairs (nested arrayref).


=head2 print_stdout

    $kv->print_stdout($some_ref);
    
Prints some data structure to stdout. See print for more info.


=head2 line_is_comment($line)

    my $line = '#need to tighten up the graphics on level 3'
    my $skip_line = $kv->line_is_comment($line);
    
    #returns: undef
    
Checks if a string looks like a comment.


=head2 line_is_empty($line)

    my $line = 'foo = bar';
    my $skip_line = $kv->line_is_empty($line);

Checks if a string looks meaningless to Text::KV; it is either a comment line or
contains only whitespace.


=head2 CAVEATS

This module provides no mechanism for mixing comments and data. They MUST be on
separate lines.

When merging duplicate hash keys, behavior is always governed by the 
merge_overwrite setting.

Unless rec_separator is set (it isn't, by default), this module expects
one key-value pair per line. Most unexpected parsing errors are an oversight
of this rule.

All get_line_* methods will skip over empty/comment lines; they will return 
undef once you've reached the end of your IO::Handle.

All get_* and parse_* functions will return undef if asked to parse a line or 
file which is empty or which contains no recognizable data.


=head2 TODO

What happens if whitespace is used for kv_separator or rec_separator?

Allow option to skip whitespace padding in print? (ie: 'cat=meow' vs 
'cat = meow').


=head1 AUTHOR

Robert Utter <utter.robert@gmail.com>


=cut