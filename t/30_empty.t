use strict;
use warnings;

use File::Temp 'tempfile';

use Text::KV;
use Test::More tests => 8;


my $kv = Text::KV->new;

my $empty = '';
is_deeply($kv->parse_line_pairs($empty), undef, 'parse_line_pairs empty line');
is_deeply($kv->parse_line_merge($empty), undef, 'parse_line_merge empty line');
is_deeply($kv->parse_line_pairs(undef), undef, 'parse_line_pairs undef line');
is_deeply($kv->parse_line_merge(undef), undef, 'parse_line_merge undef line');

my $fh = tempfile();
print $fh '';
seek($fh, 0, 0); is_deeply($kv->get_all_merge($fh), undef, 'get_all_merged empty file');
seek($fh, 0, 0); is_deeply($kv->get_all_pairs($fh), undef, 'get_all_pairs empty file');
seek($fh, 0, 0); is_deeply($kv->get_line_merge($fh), undef, 'get_line_merge empty file');
seek($fh, 0, 0); is_deeply($kv->get_line_pairs($fh), undef, 'get_line_pairs empty file');
