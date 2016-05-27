#!/usr/bin/perl

use strict;
use warnings;
no warnings 'experimental::smartmatch';

#Imports
use LWP::UserAgent;
use URL::Normalize;
use HTML::TreeBuilder 5 -weak;
use Time::HiRes "usleep";
use Cwd;

#Globals
use subs qw(main setParams loadSkippedWords normalizeURL traversePages indexPage writeToFile); #Functions in script

my ( $indexName, $startURL, $skippedWordsFile ); #Mandatory Arguments

my ( $maxDepth, $path ); #Optional arguments

my cwd = getcwd; #Current Directory

my @skippedWords; #Array for skipped words

my @visitedLinks; #Array for visited links
my @nextDepthLinks; #links to visit in next depth

my %index; #Hash of indexed words

my $totalLinks = 0; #Total visited links
my $maxLinks = 1000; #maximum links we can visit

my $baseURL = "https://en.wikipedia.org";

sub main {
	setParams;
	loadSkippedWords;

	push @nextDepthLinks, $startURL;
	traversePages;

	writeToFile;
}

sub normalizeURL {
	my $URL = shift;
	my $normalizer = URL::Normalize -> new(
			url => "$URL"
		);

	$normalizer -> make_canonical;
	$normalizer -> remove_dot_segments;
	$normalizer -> remove_directory_index;
	$normalizer -> remove_fragments;
	$normalizer -> remove_duplicate_slashes;
	$URL = $normalizer -> url;
}

sub traversePages {

	my $depth = 0;

	while ($depth < $maxDepth) {
		if ($totalLinks >= $maxLinks) {
			last;
		}

		my @linksToVisit = @nextDepthLinks; 
		@nextDepthLinks = (); #reinitialize next depth array

		while (scalar @linksToVisit > 0) {
			my $URL = normalizeURL(shift @linksToVisit);

			unless ($URL ~~ @visitedLinks) {
				indexPage $URL;
				$totalLinks += 1;
				usleep(200);
			} 

			if($visitedLinks >= $maxLinks) {
				last;
			}
		}
	}
}

sub indexPage {
	my $URL = $_[0];
	my $ua = LWP::UserAgent -> new();
	my $response = $ua -> get($URL);

	unless (response -> is_success) {
		say "Could not reach: $URL";
		say $response -> status_line;
		return;
	}

	push @visitedLinks, $URL;

	my $content = $response -> content;
	my $tree = HTML::TreeBuilder -> new();
	$tree -> parse($content);

	$tree -> elementify;

	my $content = $tree -> look_down("id", "mw-content-text"); #Only get page content

	my $references = $tree -> look_down("class", "references"); #Remove references

	if (defined $references) {
		$references -> detach();
	}

	my @linksInPage = @{$content -> extract_links('a')};

	foreach(@linksInPage) {
		my($link, $element, $attr, $tag) = @$_;
		unless ($baseURL . $link ~~ @visitedLinks || $baseURL . $link ~~ @nextDepthLinks || $link =~ /^\/wiki\/\w+:/ || $link !~ /^\/wiki\/.+/g) {
			push @nextDepthLinks, $baseURL . $link;
		}
	}

	my %tags = %{$content->tagname_map};

	my @wordsInContent = ();

	if(exists $tags{"h2"}) {
		push @wordsInContent, @{$tags{"h2"}};
	}
	if(exists $tags{"h3"}) {
		push @wordsInContent, @{$tags{"h3"}};
	}
	if(exists $tags{"h4"}) {
		push @wordsInContent, @{$tags{"h4"}};
	}
	if(exists $tags{"p"}) {
		push @wordsInContent, @{$tags{"p"}};
	}
	if(exists $tags{"li"}) {
		push @wordsInContent, @{$tags{"li"}};
	}
	if(exists $tags{"a"}) {
		push @wordsInContent, @{$tags{"a"}};
	}

	foreach (@wordsInContent) {
		my $text = $_ -> as_text;
		foreach my $word ($element_text =~ /\w+/g) {
            $word = lc $word;

            unless ($word ~~ @skippedWords) {
            	# body...
            }
        }
	}


}