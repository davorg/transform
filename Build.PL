use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Transform',
    license           => 'perl',
    dist_author       => 'Dave Cross <dave@dave.org.uk>',
    script_files      => ['bin/transform'],
    create_makefile   => 'traditional',
);

$build->create_build_script;
