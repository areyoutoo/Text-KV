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

plan tests => 3 * @keys ** 4 * @values ** 4;

my $kv_first = Text::KV->new({
	rec_separator => '|',
	merge_overwrite => 0,
});
my $kv_last = Text::KV->new({
	rec_separator => '|',
	merge_overwrite => 1,
});


sub merge_first {
	my $pairs = shift;
	my $hr = {};
	for my $ar (@$pairs) {
		my $key = @$ar[0];
		my $val = @$ar[1];
		$hr->{$key} = $val unless exists $hr->{$key};
	}
	return $hr;
}

sub merge_last {
	my $pairs = shift;
	my $hr = {};
	for my $ar (@$pairs) {
		my $key = @$ar[0];
		my $val = @$ar[1];
		$hr->{$key} = $val;
	}
	return $hr;
}


for my $k1 (@keys) {
	for my $k2 (@keys) {
		for my $k3 (reverse @keys) {
			for my $k4 (reverse @keys) {
				for my $v1 (@values) {
					for my $v2 (@values) {
						for my $v3 (reverse @values) {
							for my $v4 (reverse @values) {
								my $line = "$k1=$v1|$k2=$v2|$k3=$v3|$k4=$v4";
								
								my $pairs = [
									[$k1, $v1],
									[$k2, $v2],
									[$k3, $v3],
									[$k4, $v4],
								];
								is_deeply($kv_first->parse_line_pairs($line), $pairs);
								is_deeply($kv_first->parse_line_merge($line), merge_first($pairs));
								is_deeply($kv_last->parse_line_merge($line), merge_last($pairs));
							}
						}
					}
				}
			}
		}
	}
}