package Dist::Zilla::Plugin::MinimumPerl;

# ABSTRACT: Detects the minimum version of Perl required for your dist

use Moose 1.03;
use Perl::MinimumVersion 1.26;
use MooseX::Types::Perl 0.101340 qw( LaxVersionStr );

with(
	'Dist::Zilla::Role::PrereqSource' => { -version => '4.102345' },
	'Dist::Zilla::Role::FileFinderUser' => {
		-version => '4.102345',
		default_finders => [ ':InstallModules', ':ExecFiles', ':TestFiles' ]
	},
);

=attr perl

Specify a version of perl required for the dist. Please specify it in a format that Build.PL/Makefile.PL understands!
If this is specified, this module will not attempt to automatically detect the minimum version of Perl.

Example: 5.008008

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	# TODO should we use the VersionObject from MX::Types::Perl and numify it when we write it to the metadata?
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



sub register_prereqs {
	my ($self) = @_;

	# TODO should we check to see if it was already set in the metadata?

	# Okay, did the user set a perl version explicitly?
	if ( $self->_has_perl ) {
		# Add it to prereqs!
		$self->zilla->register_prereqs(
			{ phase => 'runtime' },
			'perl' => $self->perl,
		);
	} else {
		# Use Perl::MinimumVersion to scan all files
		my $minver;
		foreach my $file ( @{ $self->found_files } ) {
			my $pmv = Perl::MinimumVersion->new( \$file->content );
			if ( ! defined $pmv ) {
				$self->log_fatal( "Unable to parse '" . $file->name . "'" );
			}
			my $ver = $pmv->minimum_version;
			if ( ! defined $ver ) {
				$self->log_fatal( "Unable to extract MinimumPerl from '" . $file->name . "'" );
			}
			if ( ! defined $minver or $ver > $minver ) {
				$minver = $ver;
			}
		}

		# Write out the minimum perl found
		if ( defined $minver ) {
			$self->log_debug( 'Determined that the MinimumPerl required is v' . $minver->stringify );
			$self->zilla->register_prereqs(
				{ phase => 'runtime' },
				'perl' => $minver->stringify,
			);
		} else {
			$self->log_fatal( 'Found no perl files, check your dist?' );
		}
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=for stopwords dist prereqs

=for Pod::Coverage register_prereqs

=head1 DESCRIPTION

This plugin uses L<Perl::MinimumVersion> to automatically find the minimum version of Perl required
for your dist and adds it to the prereqs. You can specify a version of Perl to override the scanning
logic.

	# In your dist.ini:
	[MinimumPerl]

=head1 SEE ALSO

L<Dist::Zilla>

=cut
