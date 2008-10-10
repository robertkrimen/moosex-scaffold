use inc::Module::Install;

name 'MooseX-ClassScaffold';
all_from 'lib/MooseX/ClassScaffold.pm';

build_requires 'Test::More';

auto_install;

WriteAll;

