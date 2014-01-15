use Text::KV;
use Test::More tests => 7;
use Test::Exception;

new_ok('Text::KV') or BAIL_OUT('default constructor failed');

dies_ok { Text::KV->new({ invalidparam => 'error' }) } 'dies on invalid param';
dies_ok { Text::KV->new({ kv_separator => '' }) } 'dies on kv_sep empty';
dies_ok { Text::KV->new({ kv_separator => undef }) } 'dies on kv_sep undefined';
dies_ok { Text::KV->new({ kv_separator => '#', comment => '#' }) } 'dies on kv_sep equals comment';
dies_ok { Text::KV->new({ kv_separator => '$', rec_separator => '$' }) } 'dies on kv_sep equals rec_sep';
dies_ok { Text::KV->new({ kv_separator => '||', rec_separator => '|' }) } 'dies on kv_sep contains rec_sep';
