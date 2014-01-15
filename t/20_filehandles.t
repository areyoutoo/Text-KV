use strict;
use warnings;

use Text::KV;
use Test::More tests => 7;

use File::Temp 'tempfile';

	#get_all_pairs
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
	
my $fh = tempfile();

print $fh <<CUT
# This is an example file for use with Text::KV
# Note that the module should skip these comment lines completely!
#
# Now, we're ready for some data:
cat=meow|doggy=woof

# This next line sets thimble and boat size. Important!
thimble=tiny|boat=huge

# Finally, a duplicate line so we can test merging.
cat=duplicate|doggy=not woof
CUT
;

my $kv = Text::KV->new({
	rec_separator => '|',
});

my $kv_first = Text::KV->new({
	rec_separator => '|',
	merge_overwrite => 0
});

#read pairs
seek($fh, 0, 0);
my $all_pairs = [
	[
		['cat', 'meow'], 
		['doggy','woof']
	],
	[
		['thimble', 'tiny'],
		['boat', 'huge']
	],
	[
		['cat', 'duplicate'],
		['doggy', 'not woof']
	]
];
is_deeply(
	$kv->get_all_pairs($fh),
	$all_pairs,
	'get_all_pairs'
);

#read merge (no overwrite)
seek($fh, 0, 0);
my $merged_first = {
	cat     => 'meow',
	doggy   => 'woof',
	thimble => 'tiny',
	boat    => 'huge',
};
is_deeply(
	$kv_first->get_all_merge($fh),
	$merged_first,
	'get_all_merged first'
);

#read merge (with overwrite)
seek($fh, 0, 0);
my $merged_last = {
	cat     => 'duplicate',
	doggy   => 'not woof',
	thimble => 'tiny',
	boat    => 'huge',
};
is_deeply(
	$kv->get_all_merge($fh),
	$merged_last,
	'get_all_merged last'
);

#empty file
my $empty = tempfile();
print $empty '';


#single pair per line
$fh = tempfile();
print $fh <<CUT
#This test file has only one kv pair
#per line.

#But it does have several comments.

#Here's some data:
cat=meow

#And some more:
dog=woof
kittens=cutest

#end of file comment
CUT
;

$kv = Text::KV->new;

seek($fh, 0, 0);
is_deeply($kv->get_line_pair($fh), ['cat', 'meow'], 'get_line_pair 1');
is_deeply($kv->get_line_pair($fh), ['dog', 'woof'], 'get_line_pair 2');
is_deeply($kv->get_line_pair($fh), ['kittens', 'cutest'], 'get_line_pair 3');
is_deeply($kv->get_line_pair($fh), undef, 'get_line_pair at eof');