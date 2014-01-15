use Module::Build;

Module::Build->new(
	module_name => 'Text::KV',
	
	dist_abstract     => 'File and text operations for key-value pairs.',
	dist_version_from => 'lib/Text/KV.pm',
	dist_author       => 'Robert Utter <rutter@mail.csuchico.edu>',
    
    license => 'perl',
	
	requires => {
		'Carp' => 0,
	},
	
	recommends => {
		'IO::Handle' => 0,
	},
	
	test_requires => {
		'Test::More'      => 0,
		'Test::Exception' => 0,
		'File::Temp'      => 0,
	}
)->create_build_script;