#!/usr/bin/perl
#
# Include polygen output in a page
# 
# by Enrico Zini
package IkiWiki::Plugin::polygen;

use warnings;
use strict;
use IkiWiki;
use File::Find;

sub import { #{{{
	IkiWiki::hook(type => "preprocess", id => "polygen",
		call => \&preprocess);
} # }}}

sub preprocess (@) { #{{{
	my %params=@_;
	my $grammar = ($params{grammar} or 'polygen');
	my $symbol = ($params{symbol} or undef);

	# Sanitize parameters
	$grammar =~ IkiWiki::basename($grammar);
	$grammar =~ s/\.grm$//;
	$grammar .= '.grm';
	$symbol =~ s/[^A-Za-z0-9]//g if defined $symbol;

	my $grmfile = '/usr/share/polygen/ita/polygen.grm';
	find({wanted => sub {
			if (substr($File::Find::name, -length($grammar)) eq $grammar) {
				$grmfile = IkiWiki::possibly_foolish_untaint($File::Find::name);
			}
		},
		no_chdir => 1,
	}, '/usr/share/polygen');
	
	my $res;
	if (defined $symbol) {
		$res = `polygen -S $symbol $grmfile 2>/dev/null`;
	}
	else {
		$res = `polygen $grmfile 2>/dev/null`;
	}

	if ($?) {
		$res="[[polygen failed]]";
	}

	# Strip trainling spaces and newlines so that we flow well with the
	# markdown text
	$res =~ s/\s*$//;
	return $res;
} # }}}

1
