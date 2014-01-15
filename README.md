Text-KV
========

Text::KV - File and text operations for key-value pairs.


Synopsis
--------

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

Additional instructions and documentation can be found in the module's POD. Use
perlpod or your other favorite tool to get at them.


Build
-----

We use standard Module::Build deployment:

    perl ./Build.PL
	./Build
	./Build test
	./Build install
    
Clone the repo, then run the above commands to test and install.