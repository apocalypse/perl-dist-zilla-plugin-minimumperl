package Dist::Zilla::Plugin::MinimumPerl;

# ABSTRACT: Detects the minimum version of Perl required for your dist

use Moose 1.03;
use Perl::MinimumVersion 1.26;
use MooseX::Types::Perl 0.101340 qw( LaxVersionStr );

with(
	'Dist::Zilla::Role::PrereqSource' => { -version => '5.006' }, # for the updated encoding system in dzil, RJBS++
	'Dist::Zilla::Role::FileFinderUser' => {
		-version => '4.200006',	# for :IncModules
		finder_arg_names => [ 'perl_Modules' ],
		method => 'found_modules',
		default_finders => [ ':InstallModules' ]
	},
	'Dist::Zilla::Role::FileFinderUser' => {
		finder_arg_names => [ 'perl_Tests' ],
		method => 'found_tests',
		default_finders => [ ':TestFiles' ]
	},
	'Dist::Zilla::Role::FileFinderUser' => {
		finder_arg_names => [ 'perl_Inc' ],
		method => 'found_inc',
		default_finders => [ ':IncModules' ]
	},
);

=attr perl

Specify a version of perl required for the dist. Please specify it in a format that Build.PL/Makefile.PL understands!
If this is specified, this module will not attempt to automatically detect the minimum version of Perl.

The default is: undefined ( automatically detect it )

Example: 5.008008

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	has perl => (
		is => 'ro',
		isa => subtype( 'Str'
			=> where { LaxVersionStr->check( $_ ) }
			=> message { "Perl must be in a valid version format - see version.pm" }
		),
		predicate => '_has_perl',
	);

	no Moose::Util::TypeConstraints;
}

has _scanned_perl => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
);

sub register_prereqs {
	my ($self) = @_;

	# TODO should we check to see if it was already set in the metadata?

	# Okay, did the user set a perl version explicitly?
	if ( $self->_has_perl ) {
		foreach my $p ( qw( runtime configure test ) ) {
			$self->zilla->register_prereqs(
				{ phase => $p },
				'perl' => $self->perl,
			);
		}
	} else {
		# Go through our 3 phases
		$self->_scan_file( 'runtime', $_ ) for @{ $self->found_modules };
		$self->_finalize( 'runtime' );
		$self->_scan_file( 'configure', $_ ) for @{ $self->found_inc };
		$self->_finalize( 'configure' );
		$self->_scan_file( 'test', $_ ) for @{ $self->found_tests };
		$self->_finalize( 'test' );
	}
}

sub _scan_file {
	my( $self, $phase, $file ) = @_;

	# We don't parse files marked with the 'bytes' encoding as they're special - see RT#96071
	return if $file->is_bytes;
	# Only check .t and .pm/pl files, thanks RT#67355 and DOHERTY
	return unless $file->name =~ /\.(?:t|p[ml])$/i;

	# TODO skip "bad" files and not die, just warn?
	my $pmv = Perl::MinimumVersion->new( \$file->content );
	if ( ! defined $pmv ) {
		$self->log_fatal( "Unable to parse '" . $file->name . "'" );
	}
	my $ver = $pmv->minimum_version;
	if ( ! defined $ver ) {
		$self->log_fatal( "Unable to extract MinimumPerl from '" . $file->name . "'" );
	}

	# cache it, letting _finalize take care of it
	if ( ! exists $self->_scanned_perl->{$phase} || $self->_scanned_perl->{$phase}->[0] < $ver ) {
		$self->_scanned_perl->{$phase} = [ $ver, $file ];
	}
}

sub _finalize {
	my( $self, $phase ) = @_;

	my $v;

	# determine the version we will use
	if ( ! exists $self->_scanned_perl->{$phase} ) {
		# We don't complain for test and inc!
		$self->log_fatal( 'Found no perl files, check your dist?' ) if $phase eq 'runtime';

		# ohwell, we just copy the runtime perl
		$self->log_debug( "Determined that the MinimumPerl required for '$phase' is v" . $self->_scanned_perl->{'runtime'}->[0] . " via defaulting to runtime" );
		$v = $self->_scanned_perl->{'runtime'}->[0];
	} else {
		$self->log_debug( "Determined that the MinimumPerl required for '$phase' is v" . $self->_scanned_perl->{$phase}->[0] . " via " .  $self->_scanned_perl->{$phase}->[1]->name );
		$v = $self->_scanned_perl->{$phase}->[0];
	}

	$self->zilla->register_prereqs(
		{ phase => $phase },
		'perl' => $v,
	);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=for stopwords dist prereqs

=for Pod::Coverage register_prereqs

=head1 DESCRIPTION

This plugin uses L<Perl::MinimumVersion> to automatically find the minimum version of Perl required
for your dist and adds it to the prereqs.

	# In your dist.ini:
	[MinimumPerl]

This plugin will search for files matching C</\.(t|pl|pm)$/i> in the C<lib/>, C<inc/>, and C<t/> directories.
If you need it to scan a different directory and/or a different extension please let me know.

=head1 SEE ALSO
Dist::Zilla
Dist::Zilla::Plugin::MinimumPerlFast

=cut
