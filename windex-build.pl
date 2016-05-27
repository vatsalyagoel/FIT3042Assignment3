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
use subs qw(main normalizeURL traversePages indexPage writeToFile loadSkippedWords setParams); #Functions in script

my ( $indexName, $startURL, $skippedWordsFile ); #Mandatory Arguments

my ( $maxDepth, $path ); #Optional arguments

my $cwd = getcwd; #Current Directory

my @skippedWords; #Array for skipped words

my @visitedLinks; #Array for visited links
my @nextDepthLinks; #links to visit in next depth

my %index; #Hash of indexed words

my $totalLinks = 0; #Total visited links
my $maxLinks = 1000; #maximum links we can visit

my $baseURL = "https://en.wikipedia.org";
main;

sub main {
	setParams;
	show_options
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

#Breadth first traversal
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

			if($totalLinks >= $maxLinks) {
				last;
			}
		}
		$depth += 1;
	}
}

#download page content and index words
sub indexPage {
	my $URL = $_[0];
	my $ua = LWP::UserAgent -> new();
	my $response = $ua->get($URL);

	unless ($response -> is_success) {
		print "Could not reach: $URL\n";
		print $response -> status_line;
		return;
	}

	push @visitedLinks, $URL;

	my $content = $response -> content;
	my $tree = HTML::TreeBuilder -> new();
	$tree -> parse($content);

	$tree -> elementify;

	my $contentText = $tree -> look_down("id", "mw-content-text"); #Only get page content

	my $references = $tree -> look_down("class", "references"); #Remove references

	if (defined $references) {
		$references -> detach();
	}

	my @linksInPage = @{$contentText -> extract_links('a')};

	foreach(@linksInPage) {
		my($link, $element, $attr, $tag) = @$_;
		unless ($baseURL . $link ~~ @visitedLinks || $baseURL . $link ~~ @nextDepthLinks || $link =~ /^\/wiki\/\w+:/ || $link !~ /^\/wiki\/.+/g) {
			push @nextDepthLinks, $baseURL . $link;
		}
	}

	my %tags = %{$contentText->tagname_map}; #match every heading

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
		foreach my $word ($text =~ /\w+/g) {
            $word = lc $word;

            unless ($word ~~ @skippedWords) {
            	if(exists $index{$word}) {
            		push @{$index{$word}}, $URL unless $URL ~~ @{$index{$word}};
            	} else {
            		@{$index{$word}} = ($URL);
            	}
            }
        }
	}
}

#write index to file
sub writeToFile {
	my $fileName = $path . $indexName;
	open(my $fh, '>', $fileName) or die "Could not open file $fileName\n";

	foreach my $key (sort keys %index) {
		my @wordLinks = @{$index{$key}};
		print $fh $key;

		foreach(@wordLinks) {
			print $fh ",$_";
		}

		print $fh "\n";
	}
	close($fh);
}

#load skipped words
sub loadSkippedWords {
	open (my $fh, '<', $skippedWordsFile) or die "Could not open file $skippedWordsFile";
	@skippedWords = split("\n", <$fh>);
	close($fh);
}


#parse command line arguments
sub setParams {
	die "Error - Number of arguments " . scalar @ARGV . ". Expected 3-5 arguments.\n" unless @ARGV >= 3 && @ARGV <= 5;

	($indexName, $startURL, $skippedWordsFile) = ( @ARGV );

	die "Error - Invalid arg1: \"" . scalar $ARGV[0] . "\". Index filename not specified" unless $ARGV[0] =~ /\w+/; #no filename

    die "Error - Invalid arg2: \"" . scalar $ARGV[1] . "\". Invalid Start URL" unless $ARGV[1] =~ /.+\.wikipedia\.org\/.*/; #Not a wikipedia url

    die "Error - Invalid arg3: \"" . scalar $ARGV[2] . "\". File does not exist" unless -f $cwd . "/" . scalar $ARGV[2]; #noskipped words file

    if (@ARGV >= 4) {
        if ($ARGV[3] =~ /^maxdepth=\d$/) {

            my @split = split(/=/, $ARGV[3]);
            my $value = int $split[1];

            if ($value >= 0 and $value <= 5) {
                $maxDepth = $value;
            } else {
                print "Invalid maxdepth, setting to default=3.";
                $maxDepth = 3;
            }
        } elsif ($ARGV[3] =~ /^dir=\w+/) {

            my @split = split(/=/, $ARGV[3]);
            my $value = $split[1];

            if (-d $cwd . "/" . $value) {
                $path = $cwd . "/" . $value . "/";
            }
        }
    }

    if (@ARGV == 5) {
        if ($ARGV[4] =~ /^maxdepth=\d$/) {

            my @split = split(/=/, $ARGV[4]);
            my $value = int $split[1];

            if ($value >= 0 and $value <= 5) {
                $maxDepth = $value;
            } else {
                print "Invalid maxdepth, setting to default=3.";
                $maxDepth = 3;
            }
        } elsif ($ARGV[4] =~ /^dir=\w+/) {

            my @split = split(/=/, $ARGV[4]);
            my $value = $split[1];

            if (-d $cwd . "/" . $value) {
                $path = $cwd . "/" . $value . "/";
            }
        }
    }
    $path = $cwd . "/" unless defined $path;
    $maxDepth = 3 unless defined $maxDepth;
}