#!/usr/bin/perl
use strict;
# use warnings;
use locale;
use Time::Piece;
use Cwd;
use Scalar::Util qw(looks_like_number);
# use Log::Log4perl qw(:easy);;
use open ':encoding(utf8)';
use utf8; # to have content from script in UTF-8
binmode STDOUT, ":encoding(UTF-8)"; # to exhaust everyting in UTF-8

# THE PLAN
# 1. Read TW file and push into array @twfile
# 2. Found the place you can put your new Tiddlers $insertionpoint
# 3. Read file with your raw data
# 4. Load up template for books and populate it
# 5. Load up template for other stuff and populat it
# 6. Merge your content with TW content
# 5. Print new file with all data fiszki.html
my @log;
my $timestamp = localtime->strftime("%Y%m%d %H:%M:%S");
my $startTime = $timestamp; 
my $fileTS = localtime->strftime("%Y%m%d%H%M%S");
my $path = 'E:\\fiszki\\';
my $twTemplate='fiszkiTemplate.html'; # file with TW source code
my $rawDataFilename = "rawfile.txt";
my $separator = "<>"; # strinig separating columns in raw data file
my $emptyLine = "<REMOVE>"; # empty lines to be removed
# my $bookTiddlerFile = "booktiddlers.txt"; # file with booktiddlers
my $fiszkiFile = "_TEST-fiszki.html"; # final file containign full content of TW Books List
my $currentDir = getcwd; # memorize current dir
# Variables for TIDDLER TEMPLATES
my $bookTiddlerTemplateFname = "tiddlerTemplates.txt";
my $tiddlerDate = "19730405121200000";
my $tiddlerCreator = "rotozda";
my $tiddlerModDate = "19730405121200000";
my $tiddlerModifier = "rotozda";
my $nodata = "<!-- BRAK DANYCH -->";
my $nodatainfo = 'brak danych';
# End of variables for TIDDLER TEMPLATES

# put configuraiton into log
push @log, formatLogRecord('INFO: Logging started at: \'\'' . localtime->strftime("%Y%m%d %H:%M:%S") . '\'\'');
push @log, formatLogRecord('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -');
push @log, formatLogRecord('Configuration of the script: ');
push @log, formatLogRecord('..... Start time: \'\'' . $startTime . '\'\'');
push @log, formatLogRecord('..... Path of working folder: \'\'' . $path . '\'\'');
push @log, formatLogRecord('..... File with TiddlyWiki template: \'\'' . $twTemplate) . '\'\'';
push @log, formatLogRecord('..... File with raw data copied from google spreadsheet: \'\'' . $rawDataFilename . '\'\'');
push @log, formatLogRecord('..... File with tiddler templates generic and book: \'\'' . $bookTiddlerTemplateFname) . '\'\'';
push @log, formatLogRecord('..... Destination file name: \'\'' . $fiszkiFile . '\'\'');
push @log, formatLogRecord('..... Current directory: \'\'' . $currentDir . '\'\'');
push @log, formatLogRecord('..... Date used for generated tiddlers: \'\'' . $tiddlerDate . '\'\'');
push @log, formatLogRecord('..... Creator name for generated tiddlers: \'\'' . $tiddlerCreator . '\'\'');
push @log, formatLogRecord('..... Modification date used for generated tiddlers: \'\'' . $tiddlerModDate . '\'\'');
push @log, formatLogRecord('..... Modifier name for generated tiddlers: \'\'' . $tiddlerModifier . '\'\'');
push @log, formatLogRecord('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -');
#push @log, formatLogRecord('<MESSAGE>');
#push @log, formatLogRecord('<MESSAGE>');
push @log, formatLogRecord('END OF CONFIGURATION');

my $line;
my $cnt = 0;
my $splitMark; # this is numer of line in which book tiddler shall be added
my $FLAG_A = 0; # first <\DIV> found
my $FLAG_B = 0; # second <\DIV> found
my $FLAG_C = 0; # <!--~~ Library modules ~~--> string found
print ">> \t INFO \t Parsing TiddlyWiki file template!\n";
push @log, formatLogRecord('INFO: Parsing TiddlyWiki file template!');

chdir($path); # change dir to the one with the file
open(FILE, $twTemplate) or die("ERROR: \t Could not open file $twTemplate $!\n.");
# find out the place in TWTemplate where new tiddlers can be put
foreach $line (<FILE>) {
	if ($line =~ /[^\n]/) {
		if ($line =~ m/^<\/div>/ ) {
			# setup of first flag
			if ($line =~ m/^<\/div>/ && $FLAG_A == 0) {
				$FLAG_A = 1;
				$cnt++;
				next;
			}	
			# setup of second flag
			if ($line =~ m/^<\/div>/ && $FLAG_A == 1) {
				$FLAG_B = 1;
				# seems the place has been found
				$splitMark = $cnt;
				$cnt++;
				next;
			}
		}
		# if next string is with "library modules" it means we have found
		# the place to put all our tiddlers
		if ($line =~ m/<!--~~ Library modules ~~-->/ && $FLAG_A == 1 && $FLAG_B == 1){
			# the place is confirmed we can exit the loop
			$FLAG_C = 1;
			print ">> \t OK \t Template placeholder for book tiddlers found!\n";
			push @log, formatLogRecord('OK: Template placeholder for book tiddlers found!');
			last;
		} else {
			$FLAG_A = 0;
			$FLAG_B = 0;	
		}
	}
	$cnt++;
}

close(FILE);
chdir($currentDir); # back to initial dir
print ">> \t OK \t TiddlyWiki file template parsing completed!\n";
push @log, formatLogRecord('OK: TiddlyWiki file template parsing completed!');

# get data from raw data file which is generated from
# google spreadsheet using copy from spreadsheet and paste into 
# flat text file named $rawDataFilename;
print ">> \t INFO \t Reading raw data file!\n";
push @log, formatLogRecord('INFO: Reading raw data file!');
my @rawdata = getFileContent($path, $rawDataFilename);
my $numberOfRawData = @rawdata;
print ">> \t INFO \t found " . $numberOfRawData . " in " . $rawDataFilename . "\n";
my $message = "INFO: found " . $numberOfRawData . " in " . $rawDataFilename;
push @log, formatLogRecord($message);

#Put raw data into array using key->value pattern
print ">> \t INFO \t Putting file content into array structure!\n";
push @log, formatLogRecord('INFO: Putting file content into array structure!');
my @bookDataSets;
foreach my $rdt (@rawdata) {
	if ($rdt =~ m/$separator/) {
		my @rows = split($separator, $rdt);
			push @bookDataSets, {
				RED => $rows[0],
				AUTOR1 => $rows[1],
				TYTUL => $rows[2],
				WYDAWNICTWO => $rows[3],
				TAG_WYDAWNICTWA => $rows[4],
				DYSTRYBUCJA => $rows[5],
				MIEJSCE => $rows[6],
				ROK => $rows[7],
				WYDANIE => $rows[8],
				ISBN1 => $rows[9],
				TOM => $rows[10],
				SERIA => $rows[11],
				TLUMACZ1 => $rows[12],
				ILUSTRATOR1 => $rows[13],
				RODZAJ => $rows[14],
				COPYRIGHT => $rows[15],
				TYTUL_ORYGINALU => $rows[16],
				JEZYK => $rows[17],
				UWAGI => $rows[18],
				REGAL => $rows[19], 		# unused
				POLKA_OD_GORY => $rows[20],	# unused
				FORMAT => $rows[21],
				TEMAT_DZIEDZINA => $rows[22],
				SLOWA_KLUCZOWE => $rows[23],
				KANONTZ => $rows[24],
				PRZECZYTANA => $rows[25],
				AUTOR2 => $rows[26],
				AUTOR3 => $rows[27],
				AUTOR4 => $rows[28],
				AUTOR5 => $rows[29],
				AUTOR6 => $rows[30],
				AUTOR7 => $rows[31],
				AUTOR8 => $rows[32],
				ISBN2 => $rows[33],
				ISBN3 => $rows[34],
				ISBN4 => $rows[35],
				TLUMACZ2 => $rows[36],
				TLUMACZ3 => $rows[37],
				TLUMACZ4 => $rows[38],
				TLUMACZ5 => $rows[39],
				TLUMACZ6 => $rows[40],
				ILUSTRATOR2 => $rows[41],
				ILUSTRATOR3 => $rows[42],
				PRZEZNACZENIE => $rows[43],
				TWINDEKS => $rows[44],
				TWTYTUL => $rows[45]
			};				
	}
}
print ">> \t OK \t Data loaded into array!\n";
push @log, formatLogRecord('OK: Data loaded into array!');
undef(@rawdata);

# first lets generate tiddlers with books and adjacent stuff
print ">> \t INFO \t Getting template for generic tiddlers!\n";
push @log, formatLogRecord('INFO: Getting template for generic tiddlers!');

# Variable $genericTemplate is also used by function 'getTiddlerForParameter'
my $genericTemplate = getTemplate('GENERIC'); # generic template
if ($genericTemplate) {
	print ">> \t OK \t Generic template found!\n";
	push @log, formatLogRecord('OK: Generic template found!');
}

my @authorsList;
my @translatorsList;
my @publishersList;
my @illustratorsList;
my @bookTiddlers;
print ">> \t INFO \t Getting template for book tiddlers!\n";
push @log, formatLogRecord('INFO: Getting template for book tiddlers!');
my $tiddlerBookTemplate = getTemplate('BOOK');
if ($tiddlerBookTemplate) {
	print ">> \t OK \t Template for book tiddler found!\n";
	push @log, formatLogRecord('OK: Template for book tiddler found!');
} 
my $booksCounter = 0;
foreach my $bookDataSet (@bookDataSets) {
		
	my $bookTemplate = $tiddlerBookTemplate;
	
	# get and populate autors
	my @authors = getValuesByKey ($bookDataSet, 'AUTOR1', 'AUTOR2', 'AUTOR3', 'AUTOR4', 'AUTOR5', 'AUTOR6', 'AUTOR7', 'AUTOR8');
	my $wikifiedAuthors = wikify(@authors);
	$bookTemplate =~ s/ARRAY_AUTORS/$wikifiedAuthors/;
	# collect authors into separate set for separate tiddlers
	push @authorsList, @authors;
	undef(@authors);
	
	# get and populate publishers
	my @publishers = getValuesByKey ($bookDataSet, 'WYDAWNICTWO');
	my $wikifiedPublisher = wikify(@publishers);
	# some clean-up is required for those that are undefined
	# instead of $nodata we are putting sting "brak danych"
	if ($wikifiedPublisher =~ m/NULL/g) {
		$wikifiedPublisher =~ s/NULL/$nodatainfo/g;
	}
	$wikifiedPublisher = convertCitationMark($wikifiedPublisher);	
	$bookTemplate =~ s/FLD_WYDAWCA/$wikifiedPublisher/;
	# collect authors into separate set for separate tiddlers
	push @publishersList, @publishers;
	undef(@publishers);

	# get and populate translators
	my @translators = getValuesByKey ($bookDataSet, 'TLUMACZ1', 'TLUMACZ2', 'TLUMACZ3', 'TLUMACZ4', 'TLUMACZ5', 'TLUMACZ6');
	my $wikifiedTranslators = wikify(@translators);
	$bookTemplate =~ s/ARRAY_TLUMACZE/$wikifiedTranslators/;
	# collect translators into separate set for separate tiddlers
	push @translatorsList, @translators;
	undef(@translators);

	# get and populate illustrators
	my @illustrators = getValuesByKey ($bookDataSet, 'ILUSTRATOR1', 'ILUSTRATOR2', 'ILUSTRATOR3');
	my $wikifiedIllustrators = wikify(@illustrators);
	$bookTemplate =~ s/ARRAY_ILUSTRATORZY/$wikifiedIllustrators/;
	# collect illustrators into separate set for separate tiddlers
	push @illustratorsList, @illustrators;
	undef(@illustrators);
	
	# and isbns
	my @isbns = getValuesByKey ($bookDataSet, 'ISBN1', 'ISBN2', 'ISBN3', 'ISBN4');
	my $wikifiedIsbns = wikify(@isbns);
	# FIX: Unwikify ISBN
	$wikifiedIsbns =~ s/\[\[//g;
	$wikifiedIsbns =~ s/\]\]//g;
	$bookTemplate =~ s/ARRAY_ISBNS/$wikifiedIsbns/;
	undef(@isbns);
	
	# get bookTiddler tags
	# first we need to process field "s³owa kluczowe as of they 
	# may contain a lot of values"
	my @rawBookKeywords = getValuesByKey($bookDataSet, 'SLOWA_KLUCZOWE');
	# one element array change into scalar ...
	my $flatBookKeyword = join('', @rawBookKeywords);
	# ... and then split into multi element array
	my @bKeywords = split(', ', $flatBookKeyword);
	my $bookKeywords = wikify(@bKeywords);
	$bookKeywords = convertCitationMark($bookKeywords);

	# now get the rest of tags
	my @bookTags = getValuesByKey($bookDataSet, 'RODZAJ', 'JEZYK', 'FORMAT', 'TEMAT_DZIEDZINA', 'KANONTZ', 'PRZECZYTANA');
	# join all together

	my $wikifiedTags = wikify(@bookTags) . ' ' . $bookKeywords;
	# and replace commas into spaces
	$wikifiedTags =~ s/, / /g;
	# FIX FOR WRONG TAGS LIKE '<!--' or '-->'
	$wikifiedTags =~ s/ $nodata//g;

	# By the way let's build tiddlers with book parameters in order
	# to have separate lists.
	# DOMAIN/SUBJECT TEMAT/DZIEDZINA
	# get domain
	my $bookDomainTiddler = getTiddlerForParameter($bookTags[3], '[[Spis wg. tematu/dziedziny]] #metainfo');
	push @bookTiddlers, $bookDomainTiddler;

	# KIND RODZAJ
	# get kind
	my $bookKindTiddler = getTiddlerForParameter($bookTags[0], '[[Spis wg. rodzaju]] #metainfo');
	push @bookTiddlers, $bookKindTiddler;
	
	# FORMAT FORMAT KSI¥¯KI
	# get format
	my $bookFormatTiddler = getTiddlerForParameter($bookTags[2], '[[Spis wg. format&#243;w]] #metainfo');
	push @bookTiddlers, $bookFormatTiddler;

	# LANGUAGE JÊZYK KSI¥¯KI
	# get language
	my $bookLangTiddler = getTiddlerForParameter($bookTags[1], '[[Spis wg. j&#281zyk&#243;w]] #metainfo');
	push @bookTiddlers, $bookLangTiddler;
	
	# populate remaining fields
	$bookTemplate =~ s/FLD_RED/$bookDataSet->{RED}/;
	my $bookTitle = deWikifyString($bookDataSet->{TYTUL});
	$bookTemplate =~ s/FLD_BOOKTITLE/$bookTitle/;
	$bookTemplate =~ s/FLD_DYSTRYBUTOR/$bookDataSet->{DYSTRYBUCJA}/;
	$bookTemplate =~ s/FLD_MIEJSCE/$bookDataSet->{MIEJSCE}/;
	$bookTemplate =~ s/FLD_ROK/$bookDataSet->{ROK}/;
	$bookTemplate =~ s/FLD_WYDANIE/$bookDataSet->{WYDANIE}/;
	$bookTemplate =~ s/FLD_TOM/$bookDataSet->{TOM}/;
	my $bookSerie = deWikifyString($bookDataSet->{SERIA});
	$bookTemplate =~ s/FLD_SERIA/$bookSerie/;
	$bookTemplate =~ s/FLD_COPYRIGHTS/$bookDataSet->{COPYRIGHT}/;
	$bookTemplate =~ s/FLD_TYTUL_ORYGINALU/$bookDataSet->{TYTUL_ORYGINALU}/;
	$bookTemplate =~ s/FLD_JEZYK/$bookDataSet->{JEZYK}/;
	$bookTemplate =~ s/FLD_UWAGI/$bookDataSet->{UWAGI}/;
	$bookTemplate =~ s/FLD_TIDDLERID/$bookDataSet->{TWINDEKS}/;
	# WRONG HTML FIX
	# Fix for hanging "> character set
	my $bookTiddlerTitle = $bookDataSet->{TWTYTUL};
	$bookTiddlerTitle =~ s/\s$//;
	$bookTiddlerTitle =~ s/"/'/g;
	$bookTemplate =~ s/FLD_TIDDLERNAME/$bookTiddlerTitle/;
	$bookTemplate =~ s/NULL/$nodata/g;
	$bookTemplate =~ s/ARRAY_TIDDLERSTAGS/$wikifiedTags/;

	push @bookTiddlers, $bookTemplate;
	$booksCounter++;
}
print ">> \t INFO \t " . $booksCounter . " books found!\n";
$message = "INFO: $booksCounter books found!";
push @log, formatLogRecord($message); 
print ">> \t OK \t\t Tiddlers with books are ready!\n";
push @log, formatLogRecord('OK: Tiddlers with books are ready!');

# now we can generate all other tiddlers
# generate unique #Autor tiddlers
my @authorTiddlers = populateGenericTemplate ($genericTemplate, '#Autor', $nodata, @authorsList);
# Let's put some macros into author tiddler body
@authorTiddlers = putBacklinksMacro(@authorTiddlers);

push @bookTiddlers, @authorTiddlers;
print ">> \t OK \t\t Tiddlers with authors are ready!\n";
push @log, formatLogRecord('OK: Tiddlers with authors are ready!'); 
# and clear big arrays
undef(@authorsList);
undef(@authorTiddlers);

# generate unique #T³umacz tiddlers
# my @translatorTiddlers = populateGenericTemplate($genericTemplate, '#T³umacz', $nodata, @translatorsList);
# Poni¿ej przyk³ad jak mo¿na _nie³adnie_ poradziæ sobie z dekodowaniem w utf8
# FIX FOR WRONG DEGODING OF UTF8 for T³umacz word
my @translatorTiddlers = populateGenericTemplate($genericTemplate, '#T&#322;umacz', $nodata, @translatorsList);

# Let's put some macros into translator tiddler body
@translatorTiddlers = putBacklinksMacro(@translatorTiddlers);
push @bookTiddlers, @translatorTiddlers;
print ">> \t OK \t\t Tiddlers with translators are ready!\n";
push @log, formatLogRecord('OK: Tiddlers with translators are ready!'); 
undef(@translatorsList);
undef(@translatorTiddlers);

# generate unique #Ilustrator tiddlers
my @illustratorTiddlers = populateGenericTemplate($genericTemplate, '#Ilustrator', $nodata, @illustratorsList);
# Let's put backlinks macro to have all books on within the tiddler
@illustratorTiddlers = putBacklinksMacro(@illustratorTiddlers);
push @bookTiddlers, @illustratorTiddlers;
print ">> \t OK \t\t Tiddlers with illustrators are ready!\n";
push @log, formatLogRecord('OK: Tiddlers with illustrators are ready!'); 
undef (@illustratorsList);
undef (@illustratorTiddlers);

# generate unique #Wydawnictwo tiddlers
@publishersList = convertCitationMarkInArray(@publishersList);
my @publisherTiddlers = populateGenericTemplate($genericTemplate, '#Wydawnictwo', $nodata, @publishersList);
# Let's put backlinks macro to have all books on within the tiddler
@publisherTiddlers = putBacklinksMacro(@publisherTiddlers);
push @bookTiddlers, @publisherTiddlers;
print ">> \t OK \t\t Tiddlers with publishers are ready!\n";
push @log, formatLogRecord('OK: Tiddlers with publishers are ready!'); 
undef(@publishersList);
undef(@publisherTiddlers);

# DO URUCHOMIENIA FRAGMENTU PONI¯EJ POTRZEBUJESZ TABLICY @bookTiddlers
print ">> \t INFO \t Putting all content into TiddlyWiki file!\n";
push @log, formatLogRecord('INFO: Putting all content into TiddlyWiki file!');
my @finalTiddlyWiki;
if ($FLAG_A == 1 && $FLAG_B == 1 && $FLAG_C ==1) {
	my $iCnt = 0;
	# reading TiddlyWiki file template
	my @twTemplateLines = getFileContent($path, $twTemplate);
	print ">> \t INFO \t Reading TiddlyWiki file template!\n";
	push @log, formatLogRecord('INFO: Reading TiddlyWiki file template!');
	if (@twTemplateLines) {
		print ">> \t OK \t TiddlyWiki template file found!\n";
		push @log, formatLogRecord('OK: TiddlyWiki template file found!');
	}
	foreach my $twTemplateLine (@twTemplateLines) {
		$iCnt++;
		
		$twTemplateLine =~ s/- OFFLINE/- $timestamp/;
		# looking for the place to put the tiddlers
		if ($iCnt == $splitMark) {
			# get and input new tiddlers
			# if such place found put all tiddlers marking the beginign ...
			push @finalTiddlyWiki, "<!-- $timestamp BOOK TIDDLER STARTS HERE -->\n";
			foreach my $bookTiddler (@bookTiddlers) {
				push @finalTiddlyWiki, $bookTiddler;
			}
			# ... and the end of file content
			push @finalTiddlyWiki, "<!-- $timestamp BOOK TIDDLER ENDS HERE -->\n";
		}
		push @finalTiddlyWiki, $twTemplateLine;
	}
}
if (@finalTiddlyWiki) {
	print ">> \t OK \t File content is ready! Writting into final file!\n";
	push @log, formatLogRecord('OK: File content is ready! Writting into final file!');
}

push @log, formatLogRecord('INFO: Tiddler with log created!\n');
push @log, formatLogRecord('INFO: Trying to write final TiddlyWiki file at: ' . $path . $fiszkiFile);
push @log, formatLogRecord('INFO: Trying to write control file at: ' . $path . 'lostBooks.txt');
push @log, formatLogRecord('INFO: Logging completed at' . localtime->strftime("%Y%m%d %H:%M:%S"));
my $genericLogTemplate = getTemplate('GENERIC');
my $strLog = join('<BR>', @log); # make log as scalar
# build the tiddler for log
my @logTiddlers = populateGenericTemplate($genericLogTemplate, '#metainfo', $strLog, 'Perl run log');
# convert this log tiddler into scalar
my $logTiddlerFinal = join('', @logTiddlers); 

my @lostBooksCtrlFile; # array for control file with books id
# review all records in final file ...
foreach my $finalTiddlyWikiLine (@finalTiddlyWiki) {

		# ... and if you find matching pattern put this what you tiddler with 
		# script run log
		$finalTiddlyWikiLine =~ s/<!-- $timestamp BOOK TIDDLER ENDS HERE -->\n/$logTiddlerFinal <!-- $timestamp BOOK TIDDLER ENDS HERE -->\n/;
		
		# aside get id's and title of book for control file
		if ($finalTiddlyWikiLine =~ m/<nowiki>/) {
			my $line = $finalTiddlyWikiLine;
			my @bookIdsData = split('\|',$line);
			push @lostBooksCtrlFile, $bookIdsData[2] . ' ' .$bookIdsData[4];  
		}
}

# write the hole stuff into file
writeFile($path, $fiszkiFile, @finalTiddlyWiki);
# generate control file with ids of books
writeFile($path, 'lostBooks.txt', @lostBooksCtrlFile);

print "#############################################################################\n";
print "######################## END OF THE SCRIPT ##################################\n";
print "#############################################################################\n";
my $stopTime = localtime->strftime("%Y%m%d %H:%M:%S");
print "Script start time:\t$startTime\n";
print "Script stop time:\t$stopTime\n";
# <STDIN>; # Just to have a chance to read script output

# #############################################################################
# ######################## END OF THE SCRIPT ##################################
# #############################################################################
sub wikify {
# Convert one array item into wiki notation by adding opening square bracket [[
# and closing squere bracket ]]
# ### USED CUSTOM FUNCTIONS
# none
# ### RETURN VALUE
# text scalar with wikified values divided by commas
# This means that if you want to put such values into tiddler tags 'tag="[[tag1]] [[tag2]]"
# you need to get ridd off commas

	my @inputs = @_; # array with values
	my $length = @inputs; # identification how many values is to be wikified
	my @wikifiedArray; # array for values
	my $output; # scalar for return value

	my $counter = 1; # it must be 1 (one) because we are counting number of items
	foreach my $input (@inputs) {
		if ($counter == $length) { # if this is the last item do not include comma at the end of line ... 
			push @wikifiedArray, "[[" . $input . "]]";
		} elsif ($length == 1) { # ... the same if this is only one element in the array
			push @wikifiedArray, "[[" . $input . "]]"
		} elsif ($counter > $length) {
			die ("ERROR \t Number of items is bigger than the whole array! It is wrong! Terminating...\n");
		} else {
			push @wikifiedArray, "[[" . $input . "]], "
		}
		$counter++;
	}
	
	$output = join('', @wikifiedArray); # change array into scalar
	
	# replace all lines not being words (tags)
	if ($output !~ m/\w/) {
			# jeœli tablica jest pusta to zwróæ <!-- BRAK DANYCH -->
			$output = $nodata;
	}
	
	return $output;
}


sub getValuesByKey {
# On the basis of key gets the values from array of hashes
# ### USED CUSTOM FUNCTIONS
# none
# ### RETURN VALUE
# array with values assigned to the specific key/s

	my @inputs = shift; # array of hashes having key-value pair
	my @keys = @_; # keys of which values we are looking for
	my @outputs; # return value
	
#	Szybsze ale nie rozumiem jak dzia³a	
#	foreach my $hash_ref (@inputs)	{
#	    foreach my $key (@keys) {
#	    	print "$hash_ref->{$key}";
#	    }
#	}

	foreach my $key (@keys)	{ # for each key
	    foreach my $input (@inputs) { # check if it exist in inputs
	    	if ($input->{$key} eq "NULL"){ # if value of key is 'null' skip to next input item
	    		next;
	    	} else {
				if (($key eq 'RODZAJ') || ($key eq 'FORMAT') 
						|| ($key eq 'TEMAT_DZIEDZINA'))
				{
					push @outputs, '#' . $input->{$key};		
				} 
				elsif ($key eq 'JEZYK') # For language we would like to add prefix "#JÊZYK"
				{
					# Needs to be decoded properly with UTF8
					## FIX FOR WRONG DECODING OF UTF
					# push @outputs, '#JÊZYK: ' . $input->{$key};
					push @outputs, '#J&#280;ZYK: ' . $input->{$key};
				}
				elsif ($key eq 'KANONTZ') 
				{
					if ($input->{$key} eq 'TAK') { # and for KANONTZ key that has value "TAK" ...
						push @outputs, '#kanontz'; # we want to substite it for #KANONTZ tag
					}
				} 
				elsif ($key eq 'PRZECZYTANA') # for "PRZECZYTANA" key we can get several values
				{
					push @outputs, '#PRZECZYTANA: ' . $input->{$key}; 
				} else {
					push @outputs, $input->{$key};
				}
	    	}
	    }
	}
	undef(@inputs); #clear
	undef(@keys);
	return @outputs;
}

sub getFileContent {
# Open file and push its content into array except empty lines
# ### USED CUSTOM FUNCTIONS
# none
# ### RETURN VALUE
# array with file content one line per array item

	my $path = shift; # path under which file shall be searched
	my $filename = shift; # file name under which file shall be looked for
	my $currentDir = getcwd; # memorize current dir
	my @fileContent; # array for file contents
	
	chdir($path); # change dir to the one with the file
	open( FILE, $filename ) or die ("ERROR \ t Could not open file $filename!\n");
	foreach my $line (<FILE>) {
		if ($line =~ m/^$emptyLine/) { # if line is only \n sign go to next line
			next;
		}
		push @fileContent, $line; # else push it to the array
	}
	close(FILE);
	print ">> \t OK \t File $filename loaded into array!\n";
	my $message = "OK: File $filename loaded into array!";
	push @log, formatLogRecord($message);
	chdir($currentDir); # back to initial dir	
	return @fileContent;
}

sub writeFile {
# Returns 1 when file has been written on hard drive.
# Exits script if such file cannot be written
# ### USED CUSTOM FUNCTIONS
# none
# ### RETURN VALUE
# 1 for OK
	my $path = shift; # path into which file should be stored
	my $filename = shift; # name of file under which file shall be stored
	my @content = @_; # content of the file
	my $currentDir = getcwd; # memorize current dir
	
	chdir($path); # go to requested location
	open(my $file, '>', $filename) or die "Could not open file '$filename' $!\n";
	print $file @content;
	close $file;
	print ">> \t OK \t $filename saved at $path!\n"; # report the result
	my $message = "OK: $filename saved at $path!";
	push @log, formatLogRecord($message);
	chdir($currentDir); # revert back to current dir
	
	return 1;
}

sub getTemplate {	
# Returns appropriate template stored in external file
# The structure if this file mark start of the template and end of template
# It also populates the tiddler with values for tiddler creator, modifier as well as for 
# date of creation and modification
# ### USED CUSTOM FUNCTIONS
# getFileContent - to read file with templates
# ### RETURN VALUE
# one single tiddler content either for book or for generic tiddler
	my $templateKind = shift; # string - kind of template to be retrievied from file
	my $mark; # string - from this row template is to be collected into array 
	my $cutMark = '### TEMPLATE_END'; # string - means this is the end of template
	
	# determine for which template we are looking for
	if ($templateKind eq 'BOOK') {
		$mark = '### BOOK TEMPLATE ###';
	} elsif ($templateKind eq 'GENERIC') {
		$mark = '### GENERIC TEMPLATE ###' 
	} else { # and if it is unknown then terminate script
		die ('ERROR \t There is no such template as requested ' . $templateKind . '! Exiting...\n');
	}
	
	my @template;
	my @templateLines = getFileContent($path, $bookTiddlerTemplateFname); # read whole file
	my $startFlag = 0;
	# ... and look for the requested templatea
	foreach my $templateLine (@templateLines) {
		if ($templateLine =~ m/^$mark/) { # if current line is the same as requested template mark
			$startFlag  = 1;
			next; # set flag to one and skip to next array item
		} elsif ($templateLine =~ m/^$cutMark/) {
			$startFlag = 0; # if current line is the same as mark indicating end of template set flag for 0
		}
		
		# if template is found then put all lines into array
		if ($startFlag == 1) {
			push @template, $templateLine;
		}
	}
	
	my $tiddlerTemplate = join('', @template); # convert into scalar
	# ... and substitute fields populating them by values
	$tiddlerTemplate =~ s/FLD_TIDDLER_CREATION_DATE/$tiddlerDate/;
	$tiddlerTemplate =~ s/FLD_TIDDLER_CREATOR_NAME/$tiddlerCreator/;
	$tiddlerTemplate =~ s/FLD_TIDDLER_MODIFICATION_DATE/$tiddlerModDate/;
	$tiddlerTemplate =~ s/FLD_TIDDLER_MODIFIER_NAME/$tiddlerModifier/;
	
	return $tiddlerTemplate;

}

sub getUniqueValues {
# For arrays containing multiplied values gets only unique values=
# ### USED CUSTOM FUNCTIONS
# none
# ### INPUT PARAMETERS
# array with multiplied values
# ### RETURN VALUE
# array @outputs with unique values

	my @input = @_; # array with multiplied values
	my @outputs; # array with unified values
	
	my @sortedInputs = sort @input; # sort to put alphabetical order
	my $counter = 0;
	foreach my $sortedInput (@sortedInputs) {
		# when it is not the first line
		if ($counter > 0) {
			# compare current with previous and ...
			if ($sortedInput eq $sortedInputs[$counter-1]) {
				# ... if is the same then skip to next array's items
				$counter++;
				next;
			}
		}
		# if is not the same as previous put into @output
		push @outputs, $sortedInput;
		$counter++;
	}
	
	return @outputs;
	
}

sub populateGenericTemplate {
# Gets generic template and populates it by values
# Mostly used for tiddlers with info about athors, translators, languages, etc.
# ### USED FUNCTIONS
# getUniqueValues - to unified multiplied values in @input array
# ### RETURN VALUE
# array @outputs with substituted values


	my $tiddlerTemplate = shift; # template of tiddler
	my $tiddlerTag = shift; # string of tags from worksheet after wikifying
	my $tiddlerText = shift; # text of tiddler
	my @inputs = @_; # list of values to be put into the template
# 	my $genericTemplate = getTemplate('GENERIC'); # generic template
	my @outputs; # return array
	
	# reduce array to the unique values
	@inputs = getUniqueValues(@inputs);
	foreach my $input (@inputs) {
		$input =~ s/NULL/$nodatainfo/g;
		my $genericTiddler = $tiddlerTemplate; 
		$genericTiddler =~ s/ARRAY_TIDDLERSTAGS/$tiddlerTag/;
		$genericTiddler =~ s/FLD_TIDDLERNAME/$input/;
		$genericTiddler =~ s/FLD_TIDDLER_TEXT/$tiddlerText/;
		push @outputs, $genericTiddler;
	}
	
	return @outputs;
}

sub convertCitationMark {
# Converst double citation mark " into single '
# Requires scalars
# It is necessary for corrent HTML rendering. Without it various values
# are iterpreted by TW as fields.
# ### USED FUNCTIONS
# none
# ### RETURN VALUE
# input string with substitued citation marks
	my $input = shift;
	$input =~ s/ "/ '/g;
	$input =~ s/" /' /g;
	return $input;
}

sub convertCitationMarkInArray {
# Converst double citation mark " into single ' in arrays
# Requires array
# It is necessary for corrent HTML rendering. Without it various values
# are iterpreted by TW as fields.
# ### USED FUNCTIONS
# convertCitationMark()
# ### RETURN VALUE
# outputs array with substitued citation marks
	my @inputs = @_;
	
	foreach my $input (@inputs) {
		$input = convertCitationMark($input);
	}
		
	return @inputs;
}

sub putBacklinksMacro {
# Puts TiddlyWiki macro into the contents of tiddler
# Macro allows to list all tiddlers backlining to the current tiddler
# Requires array
# ### USED FUNCTIONS
# getTiddlerTitle()
# ### RETURN VALUE
# outputs scalar with tiddler title value placed between title=" html tag and "> html tag
	
	my @inputs = @_;
	my $macroOpeninig = '&lt;&lt;list-links filter:&quot;[[';
	my $macroClosing = ']backlinks[]]&quot; ol&gt;&gt;';

	foreach my $input (@inputs) {
		my $tiddlerTitle = getTiddlerTitle($input);
		my $macroText = $macroOpeninig . $tiddlerTitle . $macroClosing ;
		$input =~ s/$nodata/$macroText/;
	}
	
	return @inputs;
}


sub getTiddlerTitle {
# gets title of tiddler
# Requires scalar
# ### USED FUNCTIONS
# none
# ### RETURN VALUE
# outputs scalar with tiddler title value placed between title=" html tag and "> html tag
	my $input = shift;
	my $startMarker = ' title="'; 	# look for this string to find where tiddler title starts
	my $stopMarker = '">'; 	# look for this string to find there tiddler title ends
	my $output;
	my $startIdx = index $input, $startMarker;
	my $stopIdx = index $input, $stopMarker;
	my $start = $startIdx + length($startMarker);
	my $stop = $stopIdx - $start;
	$output = substr($input, $start, $stop);
	return $output;
}


sub formatLogRecord {
	my $input = shift;
	my $timer = localtime->strftime("%Y%m%d %H:%M:%S");
	my $output;
	
	$input =~ s/: /&nbsp;&nbsp;&nbsp;/;
	$output = "$timer &nbsp;&nbsp;&nbsp; $input" . '&#10;';
		
	return $output;
}

sub getTiddlerForParameter {
# Generates tiddler with book parameters like TEMAT/DZIEDZINA, RODZAJ, JEZYK, itp
# CAUTION!!!: Requires global variable $genericTemplate
# ### USED CUSTOM FUNCTIONS
# populateGenericTemplate
# ### RETURN VALUE
# sclar with single tiddler
	
	my $input = shift;
	my $tiddlerTag = shift;
	my $output;

	# check if this is only one tag
	if (($tiddlerTag =~ m/ #/g) || ($tiddlerTag =~ m/^#/g) || ($tiddlerTag =~ m/\[\[/g)) {	
		# build the macro content
		my $macro = '&lt;&lt;list-links filter:&quot;[tag[' . $input . ']sort[]]&quot; ol&gt;&gt;';
		# to get tiddler title we need to get rid off # mark
		$input =~ s/#//;
		my @tiddlerForParam = populateGenericTemplate($genericTemplate, $tiddlerTag, $macro, $input);
		# convert to scalar
		$output = join('', @tiddlerForParam);	
	} else {
		die ('ERROR: It looks that variable \$tiddlerTag contains wrong spaces!\n It\' current value is'. $tiddlerTag . '\n Please put suqere brackets [[]] around each tag or eliminate spare spaces.\n Exitiing script at procedure ... getTiddlerForParameter with parameter value: ' . $input);
	}

	return $output;	
}

sub deWikifyString {
	my $input = shift;

	# McGee
	$input =~ s/([A-Z][a-d])/~\1/g;
	
	return $input;
}

__END__

ZADANIA

- dodaæ mechanizm logowania przebiegu skryptu i wygenerowania tiddlera z tymi informacjami.

- Poprawnie obs³u¿yc formatowanie HTMLa

- wyczyœciæ kod i zoptymalizowaæ

- czy nie mo¿na wykorzystaæ "pól" w TW i do czego


ZADANIA NICE TO HAVE
- modu³ do manipulowania filtrami w TW???
- £adniej obs³u¿yæ # WRONG HTML FIX
- £adniej obs³u¿yæ dekodowanie stringów UTF ze skryptu. Na razie zastosowane s¹ skróty