Mathgen
=======

Mathgen is a tool to randomly generate fake mathematics papers.

Online version: http://thatsmathematics.com/mathgen/
Blog page: http://thatsmathematics.com/blog/mathgen/
Source code (Github): https://github.com/neldredge/mathgen


Prerequisites
=============

Mathgen was developed and tested on Ubuntu Linux.  It should work on
other flavors of Unix also.  I have not tried other systems; if you
have a reasonable Perl installation I would guess you should be okay,
but I make no promises.

To run Mathgen, you will need:

- Perl
- LaTeX
- BibTeX
- zip (for --mode=zip)

You will need the following LaTeX packages:

- AMS-LaTeX
- fullpage
- mathrsfs
- natbib
- truncate

If you want to produce books `--product=book`, you will need the
following additional LaTeX packages:

- geometry
- txfonts
- hyphenat
- textcase
- hyperref
- titlesec
- makeidx
- url
- tocbibind

You will also need the `makeindex` program.


Running
=======

The main Mathgen program is `mathgen.pl`.  For a summary of options,
run:

    $ ./mathgen.pl --help

The current default behavior, if `mathgen.pl` is run without options,
is to generate an article with one randomly generated author and view
the output with `evince`.


Examples
========

Generate an article with author "J. Doe" and view the output with
xpdf:

    $ ./mathgen.pl --product=article --mode=view --author="J. Doe" --viewer=xpdf

The same, but write the PDF to `mypaper.pdf`:

    $ ./mathgen.pl --product=article --mode=pdf --author="J. Doe" --output=mypaper.pdf

Give yourself a famous collaborator, and create a zip file with the
source and PDF:

    $ ./mathgen.pl --product=article --mode=zip --output=mypaper.zip --author="J. Doe" --author="P. Erd\H{o}s"

Tip: To randomly generate an author's name, you can use
`--author=FAMOUS_AUTHOR` or `--author=GENERIC_AUTHOR`.

Generate a book:

    $ ./mathgen.pl --product=book --mode=pdf --output=mybook.pdf --author="J. Doe"

Note that this may take a couple of minutes to generate and compile.


Merchandising
=============

As an unofficial fundraiser for the American Mathematical Society, I
am selling randomly generated textbooks via Lulu.com.  For more
information, visit

http://thatsmathematics.com/blog/mathgen-books/

US$5.00 from each sale will be donated to the AMS.   I earn no other
money from these books.

Currently available titles:

_Convex Algebra_ by E. Brown.  Hardcover, 314 pages.

_Higher Group Theory_ by H. Smith.  Paperback, 351 pages.

Each is professionally bound, looks impressive on your desk or
bookshelf, and would make a great gift!

You can also use Lulu.com (or another self-publishing site) to produce
your own personalized Mathgen textbooks.  The output from
`--product=book` is set for 6x9 inch paper and should work directly
for Lulu's "US Trade" size.  


Source code
===========

A quick road map to the files in the source distribution:

- mathgen.pl: Main driver file, processes options and disposes of
  output.

- scigen.pm: The SCIgen grammar engine.  Reads the rules files and
  generates the output.

- scirules.in: Common grammar rules, included into the following
  files.

- sci{article,book,blurb}.in: Grammar rules specific for the
  corresponding products.


Credits
=======

Mathgen was written by Nate Eldredge <nate at thatsmathematics dot com>,
incorporating code from [SCIgen](http://pdos.csail.mit.edu/scigen/),
by Jeremy Stribling, Max Krohn, and Dan Aguayo, without whom this
project would not exist.  Jordan Eldredge wrote most of the web
interface.

A list of names of famous mathematicians, used in the program, was
extracted from the web site [The Greatest Mathematicians of All 
Time](http://fabpedigree.com/james/greatmm.htm) by James Dow Allen, and is
used by permission. A list of countries and other place names was
taken from [Wikipedia](http://en.wikipedia.org/wiki/List_of_adjectival_and_demonymic_forms_of_place_names)


License
=======

Mathgen is free software.  You are welcome to share, copy, and modify
it, under the terms of the GNU General Public License, version 2.0.
See the file COPYING.

