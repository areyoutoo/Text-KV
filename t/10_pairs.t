use strict;
use warnings;

use Text::KV;
use Test::More;

my @keys = (
	'cat',
	'a1',
);

my @values = (
	'28',
	'meow',
	'',
);

my @ws = (
	' ',
	"\t",
	'',
);

my $perm_tests = 3 * @keys * @values * @ws ** 4;
my $other_tests = 1;
plan tests => $perm_tests + $other_tests;

my $kv = Text::KV->new;

#basic parse
is_deeply($kv->parse_line_pair('cat=meow'), ['cat', 'meow'], 'cat=meow');


for my $lhs (@keys) {
	for my $rhs (@values) {
		for my $ws1 (@ws) {
			for my $ws2 (@ws) {
				for my $ws3 (@ws) {
					for my $ws4 (@ws) {
						my $line = "$ws1$lhs$ws2=$ws3$rhs$ws4";
						is_deeply($kv->parse_line_pair($line), [$lhs, $rhs]);
						is_deeply($kv->parse_line_pairs($line), [[$lhs, $rhs]]);
						is_deeply($kv->parse_line_merge($line), { $lhs => $rhs });
					}
				}
			}
		}
	}
}