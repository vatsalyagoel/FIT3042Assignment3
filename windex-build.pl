#!/usr/bin/perl
use strict;
use warnings;

use LWP::UserAgent;
use URL::Normalize;

my @visitedPages = ();
# my %index = {};

my $start = "https://en.wikipedia.org/wiki/Plancton#BASLKJRHFKLASH";
getPage($start);

sub getPage {
	my $start = shift;
	my $normalized = normalizeURL($start);
	print "$normalized\n";
	getURLContent($normalized);
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

sub getURLContent {
	my $URL = shift;
	print "$URL\n";
	my $ua = LWP::UserAgent -> new(ssl_opts => {verify_hostname => 1});
	my $response = $ua -> get($URL);
	my $code = $response->code();
	print "$code\n";
}