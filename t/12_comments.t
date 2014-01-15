use strict;
use warnings;

use Text::KV;
use Test::More tests => 6;

my $kv_def = Text::KV->new;
my $kv_dot = Text::KV->new({
	comment => '.'
});


my $lhs = 'cat';
my $rhs = 'meow';
my $line = "$lhs=$rhs";

is_deeply($kv_def->parse_line_pair($line), [$lhs, $rhs], 'basic line');
is_deeply($kv_def->parse_line_pair("#$line"), undef, 'basic comment');
is_deeply($kv_dot->parse_line_pair(".$line"), undef, 'dot comment');


my $kv_nocomment = Text::KV->new({
	comment => undef
});

is_deeply($kv_nocomment->parse_line_pair($line), [$lhs, $rhs], 'basic line w/o comments');
is_deeply($kv_nocomment->parse_line_pair("#$line"), ["#$lhs", $rhs], 'basic comment w/o comments');
is_deeply($kv_nocomment->parse_line_pair(".$line"), [".$lhs", $rhs], 'dot comment w/o comments');