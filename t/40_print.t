use strict;
use warnings;

use File::Temp 'tempfile';

use Text::KV;
use Test::More tests => 9;
use Test::Exception;

my $kv_justified;
my $kv_flat;

my $fh;
my @file_lines;
my @expected_lines;

$kv_justified = Text::KV->new;

$kv_flat = Text::KV->new({
	print_justified => 0,
});

##########################
## PRINT CASE 1: hashref
##########################

my $hr = 
{
	cat => 'meow',
	thaumaturge => 'wonder',
	doggy => 'woof',
};

#print hashref justified
@expected_lines = map { "$_\n" } (
	'cat         = meow',
	'doggy       = woof',
	'thaumaturge = wonder',
);
$fh = tempfile();
$kv_justified->print($hr, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print hashref justified');

#print hashref flat
@expected_lines = map { "$_\n" } (
	'cat = meow',
	'doggy = woof',
	'thaumaturge = wonder',
);
$fh = tempfile();
$kv_flat->print($hr, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print hashref flat');

lives_ok { $kv_flat->print_stdout($hr); } 'print hashref stdout';


################################
## PRINT CASE 2: arrayref (2D)
################################

my $ar2 = 
[
	['cat', 'meow'],
	['thaumaturge', 'wonder'],
	['doggy', 'woof'],
	['cat', 'meow duplicate'],
];

#print arrayref 2D justified
@expected_lines = map { "$_\n" } (
	'cat         = meow',
	'thaumaturge = wonder',
	'doggy       = woof',
	'cat         = meow duplicate',
);
$fh = tempfile();
$kv_justified->print($ar2, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print arrayref 2D justified');

#print arrayref 2D flat
@expected_lines = map { "$_\n" } (
	'cat = meow',
	'thaumaturge = wonder',
	'doggy = woof',
	'cat = meow duplicate',
);
$fh = tempfile();
$kv_flat->print($ar2, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print arrayref 2D flat');

lives_ok { $kv_flat->print_stdout($ar2); } 'print arrayref 2D stdout';


################################
## PRINT CASE 3: arrayref (3D)
################################

$kv_justified = Text::KV->new({
	rec_separator => '|',
});

$kv_flat = Text::KV->new({
	print_justified => 0,
	rec_separator => '|',
});

my $ar3 = 
[
	[
		['cat', 'meow'], 
		['doggy','woof'],
		['boat', 'tiny'],
	],
	[
		['thimble', 'tiny'],
		['boat', 'huge'],
		['cat', 'meOOOW'],
	]
];

#print arrayref 3D justified
@expected_lines = map { "$_\n" } (
	'cat     = meow | doggy = woof | boat = tiny',
	'thimble = tiny | boat  = huge | cat  = meOOOW',
);
$fh = tempfile();
$kv_justified->print($ar3, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print arrayref 3D justified');

#print arrayref 3D flat
@expected_lines = map { "$_\n" } (
	'cat = meow | doggy = woof | boat = tiny',
	'thimble = tiny | boat = huge | cat = meOOOW',
);
$fh = tempfile();
$kv_flat->print($ar3, $fh);
seek($fh, 0, 0);
@file_lines = <$fh>;
is_deeply(\@file_lines, \@expected_lines, 'print arrayref 3D flat');

lives_ok { $kv_flat->print_stdout($ar3); } 'print arrayref 3D stdout';