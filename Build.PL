# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Dist::Zilla::Plugin::MinimumPerl',
	'license'		=> 'perl',

	'dist_abstract'		=> 'Detects the minimum version of Perl required for your dist',
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,
	'create_license'	=> 1,
	'sign'			=> 0,

	'test_files'		=> 't/*.t',

	'build_requires'	=> {
		# Test stuff
		'Test::More'				=> '0.94',
	},

	'requires'		=> {
		# To use Dzil
		'Dist::Zilla::Role::PrereqSource'	=> '2.101170',
		'Moose'					=> '1.01',

		# The main reason why we're here :)
		'Perl::MinimumVersion'			=> '1.24',

		# we need a recent perl
		'perl'					=> '5.008',
	},

	# include the standard stuff in META.yml
	'meta_merge'	=> {
		'resources'	=> {
			'license'	=> 'http://dev.perl.org/licenses/',
			'homepage'	=> 'http://search.cpan.org/dist/Dist-Zilla-Plugin-MinimumPerl',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-MinimumPerl',
			'repository'	=> 'http://github.com/apocalypse/perl-dist-zilla-plugin-minimumperl',
		},
	},
);

# all done!
$build->create_build_script;
