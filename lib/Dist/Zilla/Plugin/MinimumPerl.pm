package Dist::Zilla::Plugin::MinimumPerl;
use strict; use warnings;
our $VERSION = '0.02';

use Moose 1.01;
use Perl::MinimumVersion 1.24;

# TODO wait for improved Moose that allows "with 'Foo::Bar' => { -version => 1.23 };"
use Dist::Zilla::Role::PrereqSource 2.101170;
with 'Dist::Zilla::Role::PrereqSource';

has perl => (
	is => 'ro',
	isa => 'Str', # TODO add more validation?
	predicate => '_has_perl',
);

sub register_prereqs {
	my ($self) = @_;

	# Okay, did the user set a perl version explicitly?
	if ( $self->_has_perl ) {
		# Add it to prereqs!
		my $prereqs = $self->zilla->prereq->_guts->{runtime}{requires};
		my $prereq_hash = defined $prereqs ? $prereqs->as_string_hash : {};
		## no critic ( ProhibitAccessOfPrivateData )
		if ( exists $prereq_hash->{'perl'} ) {
			$self->log_debug( "Detected 'perl' prereq already set to v" . $prereq_hash->{'perl'} );
		} else {
			$self->zilla->register_prereqs(
				{ phase => 'runtime' },
				'perl' => $self->perl,
			);
		}
	} else {
		# Use Perl::MinimumVersion to scan all files
		my $minver;
		foreach my $file ( @{ $self->zilla->files } ) {
			# Logic taken from DZ:P:PkgVersion v2.101170
			if ( $file->name =~ /\.t$/ or $file->name =~ /\.(?:pm|pl)$/i or $file->content =~ /^#!(?:.*)perl(?:$|\s)/ ) {
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

=for stopwords AnnoCPAN CPAN CPANTS Kwalitee RT dist prereqs

=head1 NAME

Dist::Zilla::Plugin::MinimumPerl - Detects the minimum version of Perl required for your dist

=head1 DESCRIPTION

This plugin uses L<Perl::MinimumVersion> to automatically find the minimum version of Perl required
for your dist and adds it to the prereqs. You can specify a version of Perl to override the scanning
logic.

	# In your dist.ini:
	[MinimumPerl]

This plugin accepts the following options:

=over 4

=item * perl

Specify a version of perl required for the dist. Please specify it in a format that Build.PL/Makefile.PL understands!
If this is specified, this module will not attempt to automatically detect the minimum version of Perl.

Example: 5.008008

=back

=head1 SEE ALSO

L<Dist::Zilla>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Dist::Zilla::Plugin::MinimumPerl

=head2 Websites

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-MinimumPerl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-MinimumPerl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-MinimumPerl>

=item * CPAN Forum

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-MinimumPerl>

=item * RT: CPAN's Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-MinimumPerl>

=item * CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Dist-Zilla-Plugin-MinimumPerl>

=item * CPAN Testers Results

L<http://cpantesters.org/distro/D/Dist-Zilla-Plugin-MinimumPerl.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-MinimumPerl>

=item * Git Source Code Repository

L<http://github.com/apocalypse/perl-dist-zilla-plugin-minimumperl>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-dist-zilla-plugin-minimumperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-MinimumPerl>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
