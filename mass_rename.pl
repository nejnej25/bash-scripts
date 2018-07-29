#!/usr/bin/perl
#Author: Perry

use strict;
use warnings;
use Getopt::Std;

#Use this hash for reference
my %file;

#Valid options to use
#getopts('vi:',\%file);
getopts('i:',\%file);

#Check if -i option has value
if ( not defined($file{'i'}) ){
	die("-i option must be declared. Usage: -i substitution file..\n");
}

if ( $file{'i'} !~ qw|s/.+?/.+?/*| ){
	die("Please use proper substitution: s/old/new/[g]\n");
}

#Read every file
foreach my $existing_file(@ARGV){

	my $new_file=$existing_file;
	
	#Executes the replacement
	#use eval subroutine to take effect the replacement because it's in variable
	eval "\$new_file=~$file{'i'}";

	#Make sure its not the same filename
	if ( $existing_file ne $new_file ){

		#If new file exist add an extender to filename
		if ( -f $new_file ){
			my $extender=0;
			while ( -f $new_file.".".$extender ){
				$extender++;
			}
			$new_file=$new_file.".".$extender;
		}

		#Rename the old file to new one
		rename($existing_file,$new_file);
		print $existing_file." -> ".$new_file."\n";
	}
}
