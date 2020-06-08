Overview

Let's see what happens in the life of collecting a pile of files
(a series, movies, etc) and look at the processes use from simply
downloading to final burn and if not happened... use of the files.
[Assmption: use of 1% CYA par2]

1) find your file(s) on the net and start downloading them via
   a client.  browser, bt, irc, anything works but the more automated
   is the better way to go.

   You'll want to point your client to a temporary place where you *know*
   these files are in-progress of being downloaded.  This is especially
   true for IRC since downloads will fail.  Thus, over time, it becomes
   a problem to really know which files are complete in the mess.

    * download =>
	$DVDSTAG/download/irc

	e.g. this could be a file being downloaded with irssi
	$DVDSTAG/download/irc/Karate Kid 1.avi

2) Once the download is completed successful, idealy your client will
   automatically move the files (or directory for BT) to a 'watch' directory.

    * download completed =>
	$DVDSTAG/download/irc -> $DVDSTAG/download/finished-watch

	e.g. completed, moved to 'watch' directory (by *client*)
	$DVDSTAG/download/irc/Karate Kid 1.avi -> $DVDSTAG/download/finished-watch

3) A "quasi"-server is running and *watching* this directory for changes
   in its structure or contents (aka newfile_auto).  When a file appears
   in this directory, a process is kicked off to generate 1% par2 file
   and a .ver (represented detailed information about the file).  Once this
   is completed, the files (4 files for every 1 file downloaded) will be moved
   to their final 'completed' directory.

    * filekeeping/par2 generated =>
	$DVDSTAG/download/finished-watch -> $DVDSTAG/download/finished

	e.g. generate par2, moved to 'finished' directory (by *client*)
	$DVDSTAG/download/finished-watch/Karate Kid 1.avi ->
		$DVDSTAG/download/finished/Karate Kid 1.avi
		$DVDSTAG/download/finished/Karate Kid 1.avi.ver
		etc.

****

4) Now, the manual part is organizing these files into something
   meaningful to you.  I am lucky there is a large support community
   available in the anime world to make much of my cataloging automatic.
   This will not be the case for generic movies and TV series.  Thus,
   you'll have to do some work at this point.

	$DVDSTAG/download/finished

   This is where $DVDSTAG/sorted directory is very useful.  You'll put
   all the files (in seperate directories which provides the "grouping"
   mechanism for us) in this sorted directory.

	$DVDSTAG/sorted
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)/Karate Kid 1.avi
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)/Karate Kid 1.avi.ver
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)/Karate Kid 1.avi.par2
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)/Karate Kid 1.avi.vol00+40.par2
	$DVDSTAG/sorted/Karate Kid 1-3 (WS, 1985)/Karate Kid 2.avi
	etc...
	
5) Over time, you'll collect a pile of these directories in your
   'finished' directory and now it is time to burn to DVD.

   Now, you use the 'burn' directory to pack and generate in-place DVD
   directory structures.

	$ cd $DVDSTAG/burn
	$ mv $DVDSTAG/sorted/* .

   Unforunately, there is usually a partial DVD left over from the
   previous DVD burn party.  I will also move those directories from
   the left over DVD structure *back* to this 'burn' directory for
   reconsideration.  This 'DVD image' directory is also what I use to
   remember where I left off on the disk ID numbering.

	$ mv $DVDSTAG/burn/movies0021/* .

   Now, we generate a list of directories that our packing tool will
   use to consider how to best pack our stuff.

	# list only one level of directories, remove . and last DVD image
	$ mkpacklst movies > dir.lst

6) This is the fun part.... you get to play a game of odds.  Unless you
   keep the the number of directories small (around 12 or so), we don't
   have enough lifespan to wait for the *optimum* answer from this program.
   It does a complete combinatory search for the best fit.  Thus, I designed
   the program to take operator hints.  I won't go into those here but we'll
   just run the program in theory and magic happens. :)

	# if this is a first run, or no 'leftover' from previous burn
	$ besteffortpacker 0 dir.lst

	# most cases of 'leftover', there's just one 'leftover' dir
	$ besteffortpacker 1 dir.lst

   It will output a 'break.lst' file which will instruct another script
   how to break up the files into DVD images.

7) Making the 'DVD images' is pretty easy at this point.  You'll run a script
   with the starting disk ID (e.g 0021 from above) and you'll redirect the file
   generate from step 6 into it.

	$ split2media 0021 movies < break.lst

   One semi small mountain of output will pour from this script detailing
   what it is doing to each file.  This is how 'movies0021' was generated and a
   corresponding v-movies0021 exists with all the .ver/.par2 files mirroring movies0021.
   It will generate how many the 'break.lst' tells it.  It can be 1 or 100
   DVD image directories.

   At this stage, you need to move the last "leftover" image out of the way because
   it isn't ready to be processed yet.

	$ mv movies0059 ../leftover

8) We are close to being ready to burn but not quite yet.  We need to add
   some files to allow *easy* file or disk verification.  The .ver will be
   used for this purpose.  Also, I kicked off the 10% par2 generation for
   each directory in each DVD image.  This process takes a very long time
   (15 minutes to 60 minutes, varies on the average file size in it).

   So, we must generate a list of directories for which be want par2 data
   generated.

	$ mkparproclst movies > parproc.lst

   Finally, we'll generate the DVD verification information and start
   par2 generation (in screen).

	$ prepmedia movies

9) Once the par2 generation proper has started (you par2create being run), it is now
   safe to burn DVD images.

	# insert blank DVD and run
	$ burnmedia movies0021
   
   15 minutes later, it will eject the disk and remount it and perform a
   media verification.  5-8 minutes later, it will beep to let you know
   how things fared.  At which point, you'll replace the disk with a new
   blank, *label* the created DVD with a name and ID number and place
   it in your binder.  Should the burn have failed. tossed the disk and
   reburn again.  Otherwise, burn the next image until sorting socks
   becomes an appealing past-time as which point a break is needed. :)

   Yay! You're got things onto DVD..... now for the cataloging.

10) Unforunately, this part must wait until the par2 generation is complete
    as these files are still used (the .ver could be used now, a possible
    near-term improvement).

    In step 8, par2 files are generated for later backup or storage as a CYA
    for *when* DVDs fail.

	$DVDSTAG/pardb/movies0021/Karate Kid 1-3 (WS, 1985)/repairdb.par2

    We will use these files to generate an XML file detailing the files,
    hash values, and other fun facts about the files.  Also, we'll make
    a directory to disk ID mapping file (hence directory naming is kinda
    important here).

	$ cd $DVDSTAG/pardb
	$ disk-map.sh movies - > partial
	$ disk-map.sh movies > full

	# do a less and double check the lists for reasonable data.
	# and update to the latest full disk mapping.

	$ mv current-movies.lst current-disk.lst.bak
	$ mv full current-movies.lst

	# generate the 'series.lst' file for the nicer query interface
	$ gen-series.sh current-movies.lst > $DVDCAT/movies.lst

	# generate the XML update fragment
	$ par2xml.sh movies < partial > flist.xml

        # now merge the XML update fragment with the master XML catalog
        $ mergeparxml.sh movies.xml flist.xml > full.xml

        # do a less and double check the xml for reasonable data
        # and update to the latest full XML catalog

        $ mv movies.xml movies.xml.bak
        $ mv full.xml movies.xml

	It is done!

11) Querying the "databases"

	$ lookup "Karate Kid"

Karate Kid 1-3 (WS, 1985) (0021 0022)

     Now you can fetch disks number 21 and 22 from your binder and watch.  :)





Typical tasks: query

There is two files the manage the disk/directory and file catalog.
I've wrote to very simple scripts to query these files.  I suspect you'll
want to customize them to your needs.

	bin/lookup  - lookup (via grep) directory and/or disk ID
	bin/flist   - query the XML file for CRC32, files, etc (via grep)

They are freeform however you can use the file structure to your
advantage at times.  For example, if you want to lookup by CRC32 then:

        $ flist crc32=<value>

Setup: the staging area

I like to have an area for all the activity involved an any multimedia
obsession.  This includes the downloading, sorting/cataloging, DVD image
preparation, DVD images and DVD par2 recovery generation and storage
(which tends to mirror this same structure a bit because I use the same
scripts for DVD preparing and burning).

So at a mimimum I would do:

export DVDSTAG=/some/fat/hdd/movies

	$DVDSTAG/burn
	$DVDSTAG/download
	$DVDSTAG/processed
	$DVDSTAG/pardb
	$DVDSTAG/pardb/burn
	$DVDSTAG/pardb/processed

Of course, you can make any structure you like but the goal is keep the
different stages of backup seperate and reasonably documented so you
can return to it *months* later and pick up without much grief.

	$DVDSTAG/download/finished-bt
	$DVDSTAG/download/finished-irc
	$DVDSTAG/download/irc
	$DVDSTAG/download/bt

And I configure my clients to download to the respective directory
*during* download and have the client move the file/directory to the
corresponding finished-<type> directory.  This makes it easy to spot what
BTs and IRC downloads which are still in progress/failed.  You'll still have
to watch out for BT seeding conditions but this is much more managable
by seperating download and completed directories.

If you wish to have auto 1% par2 generation for added protection of your
precious downloaded files.  You'll need a 'watch' directory in the
middle of this structure.  You'll configure the client to move files into
this directory instead.  [Note, the watch and download directories must
be on the same filesystem to prevent partial file processing]

Please look at newfile_auto for an idea how it works and you'll need to
"fill in the blank" for newfile_process.  My anime processing system
hooks into this very setup however it is not suitable for your needs.
So, I wrote a stub processor for you.


