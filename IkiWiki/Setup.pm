#!/usr/bin/perl
# Ikiwiki setup files are perl files that 'use IkiWiki::Setup::foo',
# passing it some sort of configuration data.
#
# There can be multiple modules, with different configuration styles.
# The setup modules each convert the data into the hashes used by ikiwiki
# internally (if it's not already in that format), and store it in
# IkiWiki::Setup::$raw_setup, to pass it back to this module.

package IkiWiki::Setup;

use warnings;
use strict;
use IkiWiki;
use IkiWiki::Wrapper;
use open qw{:utf8 :std};

our $raw_setup;

sub load ($) { # {{{
	my $setup=IkiWiki::possibly_foolish_untaint(shift);
	delete $config{setup};
	#translators: The first parameter is a filename, and the second
	#translators: is a (probably not translated) error message.
	open (IN, $setup) || error(sprintf(gettext("cannot read %s: %s"), $setup, $!));
	my $code;
	{
		local $/=undef;
		$code=<IN>;
	}
	($code)=$code=~/(.*)/s;
	close IN;

	eval $code;
	error("$setup: ".$@) if $@;

	my $ret=$raw_setup;
	$raw_setup=undef;

	return %$ret;
} #}}}

package IkiWiki;

sub setup () { #{{{
	my %setup=IkiWiki::Setup::load($config{setup});

	$setup{plugin}=$config{plugin};
	if (exists $setup{add_plugins}) {
		push @{$setup{plugin}}, @{$setup{add_plugins}};
		delete $setup{add_plugins};
	}
	if (exists $setup{exclude}) {
		push @{$config{wiki_file_prune_regexps}}, $setup{exclude};
	}

	if (! $config{render} && (! $config{refresh} || $config{wrappers})) {
		debug(gettext("generating wrappers.."));
		my @wrappers=@{$setup{wrappers}};
		delete $setup{wrappers};
		my %startconfig=(%config);
		foreach my $wrapper (@wrappers) {
			%config=(%startconfig, rebuild => 0, verbose => 0, %setup, %{$wrapper});
			checkconfig();
			if (! $config{cgi} && ! $config{post_commit}) {
				$config{post_commit}=1;
			}
			gen_wrapper();
		}
		%config=(%startconfig);
	}
	
	foreach my $c (keys %setup) {
		next if $c eq 'syslog';
		if (defined $setup{$c}) {
			if (! ref $setup{$c}) {
				$config{$c}=possibly_foolish_untaint($setup{$c});
			}
			elsif (ref $setup{$c} eq 'ARRAY') {
				$config{$c}=[map { possibly_foolish_untaint($_) } @{$setup{$c}}]
			}
			elsif (ref $setup{$c} eq 'HASH') {
				foreach my $key (keys %{$setup{$c}}) {
					$config{$c}{$key}=possibly_foolish_untaint($setup{$c}{$key});
				}
			}
		}
		else {
			$config{$c}=undef;
		}
	}
	
	if (! $config{refresh}) {
		$config{rebuild}=1;
	}
	
	loadplugins();
	checkconfig();

	if ($config{render}) {
		commandline_render();
	}

	if (! $config{refresh}) {
		debug(gettext("rebuilding wiki.."));
	}
	else {
		debug(gettext("refreshing wiki.."));
	}

	lockwiki();
	loadindex();
	refresh();

	debug(gettext("done"));
	saveindex();
} #}}}

1
