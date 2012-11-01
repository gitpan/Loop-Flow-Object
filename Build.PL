use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Loop::Flow::Object',
    license             => 'perl',
    dist_author         => q{Mikhail Che <m.che@aukama.dyndns.org>},
    dist_abstract       => "Looping code of one object with forking on/off. Executing code, control count and exit from loop by the object methods.",
    dist_version_from   => 'lib/Loop/Flow/Object.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Loop-Flow-Object-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
