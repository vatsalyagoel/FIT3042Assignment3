#FIT3042 - System Tools and Programming Languages 
-------------------------------------------------------------------------------------------
									   Assignment 3
									   WINDEX-BUILD
									   VATSALYA GOEL
									     25404776
-------------------------------------------------------------------------------------------


##Prerequisites
	1. Bundle::LWP
	2. HTML::Tree
	3. Protocol:https
	4. HTML:Format
	5. URL::Normalize
	6. Mozilla::CA 

##Build
	For first time use
		1. Start a terminal session
			> perl -MCPAN -eshell
		2. Install the folowing modules
			> install Bundle::LWP 
			> install Mozilla::CA
			> install HTML::Tree
			> install Protocol::https
			> install HTML::Format
			> install Mozilla::CA 
		3. Exit CPAN
			> exit
##Usage - Building Index:
	NAME:
		./windex-build.pl - builds an index file
	USAGE:
		./windex-build.pl Name StartURL ExcludeFile [dir=directory] [maxdepth=depth]
			1. ./windex-build.pl - program script
			2. Name - Name of index File
			3. StartURL - the first wikipedia page to index
			4. ExcludeFile - List of worlds you don't want to index
			4. [dir=directory] - optional path to store index
			5. [maxdepth=depth] - optional Maximum depth of search
##Usage - Viewing Index
	NAME:
		./windex.sh - reads an index file and shows the links
	USAGE:
		./windex.sh FILENAME WORD
			1. ./windex.sh - program script
			2. FILENAME - Name of index file
			3. WORD - Word to search

##Functionality
###Windex-Build
	The program takes in arguments as said above and indexed wikipedia pages using a breadth first algorithm
	It goes to the startURL provided and follow links until a 1000 link limit is reached
	Average time taken to execute is ~20 minutes
	Normalization of URLs is done usinga  perl library URL::Normalize
	it does the following normalizations
		1. make canonical
		2. remove dot segments
		3. remove directory index
		4. remove fragments 
		5. remove duplicate slashes
###Windex
	This is done using a bash script and uses regex to match entire words