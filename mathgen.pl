#!/usr/bin/perl -w

#    mathgen.pl: main driver code
#
#    Copyright (C) 2012  Nathaniel Eldredge
#    This file is part of Mathgen.
#
#    Mathgen is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    Mathgen is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Mathgen; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use scigen;
use Getopt::Long;
use File::Temp qw { tempdir };

my $default_mode = 'view';
my $default_viewer = 'evince';
my $default_product = 'article';

my %modes = map {$_ => 1} qw { pdf zip dir view raw };
my %products = (
    'article' => { PRETTY => 'latex' },
    'book' => { PRETTY => 'latexbook' },
    'blurb' => { PRETTY => 0 }
    );

my $bibname = "scigenbibfile.bib";

my $data_dir = '.';



sub usage {
    select(STDERR);
    print <<EOUsage;
    
$0 [options]
  Options:

    --help                    Display this help message
    --author=<quoted_name>    An author of the paper (can be specified 
                              multiple times)
                              Default: One random author
    --mode=pdf|zip|dir|view|raw
                              What to output
    	   		      pdf: Output a PDF file
			      zip: Output a zip file with 
			      	   LaTeX/BiBTeX source and PDF
			      dir: Leave source and PDF in directory
			       	   specified with --dir
			      view: Invoke viewer on PDF file
			      raw: Output raw tex/txt only (required for blurb)
    --viewer=<prog>	      Use <prog> as PDF viewer (default: $default_viewer)
    --dir=<dir>		      For --mode=dir: use <dir> for output
    --output=<file>	      For --mode=pdf,zip,raw: Output to <file>
    	     		      Use - for stdout
    --product=article|book|blurb
                              What to generate (default: $default_product)
    --seed=<seed>             Use <seed> to seed the PRNG
    --debug                   Enable various debugging features
EOUsage
    exit(1);

}

my @authors;
my $mode = $default_mode; # pdf, zip, dir, view, raw (undocumented)
my $viewer = $default_viewer;
my $dir;
my $output;
my $product = $default_product;
my $seed;
my $debug = 0;

my %options;
GetOptions( \%options, 
	    "help|?" => \&usage,
	    "author=s@" => \@authors, 
	    "mode=s" => \$mode,
	    "viewer=s" => \$viewer,
	    "dir=s" => \$dir,
	    "output=s" => \$output,
	    "product=s" => \$product,
	    "seed=i" => \$seed,
	    "debug!" => \$debug)
    or usage();

if (!$modes{$mode}) {
    printf STDERR "$0: Unknown mode $mode\n";
    usage();
}

if (!$products{$product}) {
    printf STDERR "$0: Unknown product $product\n";
    usage();
}

if (!@authors) { # No author supplied
    @authors = ("AUTHOR"); # random author
}

if (!defined($dir)) {
    $dir = tempdir("mathgen.$$.XXXXXXXXXXXXXXXXXXXXXXXX",
		   TMPDIR => 1,
		   CLEANUP => ($debug ? 0 : 1))
	or die("tempdir: $!");
    if ($debug) {
	print STDERR "dir = $dir\n";
    } 
}

my $output_fh;

if (defined($output)) {
    if ($output eq '-') {
	$output_fh = *STDOUT;
    } else {
	open($output_fh, ">$output")
	    or die("$output: $!");
    }
} else {
    if ($mode eq 'pdf' or $mode eq 'zip' or $mode eq 'raw') {
	print STDERR "$0: Must specify --output with --mode pdf,zip,raw\n";
	usage();
    }
}

if (defined($seed)) {
    srand($seed);
} else {
    # In 5.14 srand returns seed value
    if (0 and $^V and $^V ge v5.14) { # disabled until it can be tested
	$seed = srand();
    } else { # backward compatible
	$seed = int rand 0xffffffff;
	srand($seed);
    }
    if ($debug) {
	print STDERR "seed = $seed\n";
    }
}

# Blurb mode is a hack because the output is text not tex
if ($product eq 'blurb' and $mode ne 'raw') {
    printf STDERR "$0: --product=blurb only works with --mode=raw";
    usage();
}

# Open rule file
my $rulefile = "${data_dir}/sci${product}.in";
my $rule_fh;
open($rule_fh, "<$rulefile")
    or die("$rulefile: $!");

my $rules = {};
my $rules_RE = undef;

# add predefined rules
$rules->{"AUTHOR_NAME"} = \@authors;

{
    my $s = "";
    my @a = @authors;
    my $la = pop(@a);
    if (@a) {
	$s = join(', ', @a) . ' and ';
    }
    $s .= $la;
    $rules->{"SCIAUTHORS"} = [ $s ];
}

$rules->{"SEED"} = [ $seed ];

scigen::read_rules ($rule_fh, $rules, \$rules_RE, $debug);
my $text = scigen::generate (
    $rules, 'START', $rules_RE, $debug, $products{$product}{PRETTY});

if ($mode eq 'raw') {
    print $output_fh $text;
    exit 0; # why does indent screw up here?
}

sub generate_bibtex;
sub dump_to_file;
sub pdflatex;
sub bibtex;
sub makeindex;
sub output_filespec;
sub dump_to_file;
my $basename = "mathgen-$seed";

my $article_readme_text = <<"EOF";
To recompile this file, run:

pdflatex $basename
bibtex $basename
pdflatex $basename
pdflatex $basename

You need the following packages installed:

AMS-LaTeX
fullpage
mathrsfs
natbib
truncate
EOF
    ; # fix indentation for emacs

my $book_readme_text = <<"EOF";
To recompile this file, run:

pdflatex $basename
bibtex $basename
makeindex $basename.idx
pdflatex $basename
pdflatex $basename

You need the following packages installed:

AMS-LaTeX
geometry
mathrsfs
natbib
txfonts
hyphenat
textcase
hyperref
truncate
titlesec
makeidx
url
tocbibind

The output is set to 6x9 inch paper and is suitable for lulu.com.
EOF
    ;

my %readme_text = (
    'article' => $article_readme_text,
    'book' => $book_readme_text
    );


chdir($dir) or die("$dir: $!");
dump_to_file($text, "$basename.tex");
dump_to_file(generate_bibtex($text), $bibname);

pdflatex($basename);
bibtex($basename);
pdflatex($basename);
pdflatex($basename);

# Now just dispose of the output appropriately

if ($mode eq 'pdf') {
    output_filespec("<$basename.pdf", "$basename.pdf");
} elsif ($mode eq 'zip') {
    dump_to_file($readme_text{$product}, 'README');
    # Useless Use Of Cat issue: we could have zip write to the 
    # output directly.  But we already opened it, and I don't feel like
    # special casing that for --mode=zip.  Also trying to pass the output
    # filename in a shell command seems dicey.
    output_filespec("zip - $basename.tex $basename.pdf $bibname README |",
		    "zip");
} elsif ($mode eq 'view') {
    system("$viewer $basename.pdf");
} elsif ($mode eq 'dir') {
    # Nothing to do here!
}

# We need to not be in the temp directory if it's going to be deleted
if ($debug) {
    print STDERR "dir = $dir, seed = $seed\n";
}
chdir('/');
exit 0;

# Subroutines follow

sub output_filespec {
    my ($filespec, $filename) = @_;
    local $/ = \65536;
    open (my $fh, $filespec)
	or die("$filename: $!");
    while (<$fh>) {
	print $output_fh $_;
    }
    close($fh) 
	or die("$filename: $!");
}

sub dump_to_file {
    my ($text, $filename) = @_;
    open (my $fh, ">$filename")
	or die("$filename: $!");
    print $fh $text;
    close($fh)
	or die("$filename: $!");
}


sub generate_bibtex {
    my ($text) = @_;
    my $bib;
    my %citelabels = ();
    while( $text =~ /(cite\:\d+)[,\}]/gi ) {
	$citelabels{$1} = 1;
    }
    foreach my $clabel (keys(%citelabels)) {
	$rules->{"CITE_LABEL_GIVEN"} = [ $clabel ];
	scigen::compute_re($rules, \$rules_RE); # seems inefficient
	$bib .= scigen::generate 
	    ($rules, "BIBTEX_ENTRY", $rules_RE, $debug, 'bibtex');
	$bib .= "\n";
    }
    return $bib;
}

sub pdflatex {
    my ($base) = @_;
    system("pdflatex -halt-on-error $base " . '1>&2')
	and die("pdflatex failed");
}

sub bibtex {
    my ($base) = @_;
    system("bibtex $base " . '1>&2')
	and die("bibtex failed");
}

sub makeindex {
    my ($base) = @_;
    system("makeindex $base.idx " . '1>&2')
	and die("makeindex failed");
}
