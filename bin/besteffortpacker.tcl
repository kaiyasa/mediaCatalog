#!/usr/bin/tclsh


proc usage {} {
    puts stdout "usage: [info script] <reserved directories> <dirlist file>"
}

if [catch { set dirresv [expr 0 + [lindex $argv 0]] }] {
    usage
    exit 1
}

#set dirresv 1
set dirlistfile [lindex $argv 1]
if {![file exists $dirlistfile]} {
    usage
    exit 1
}

set dirlist {
}

proc start {} {
    global dirlist
    global dirlistfile

    set part  $dirlistfile
    puts stdout "Working $part"
    set dirlist {}
    set fp [open $part r]
    foreach line [split [read $fp] \n] {
puts stdout "line: $line"
        if {$line != ""} {
            lappend dirlist $line
puts stdout "add $line"
        }
    }
    close $fp
    
    foreach dirn $dirlist {
        set dest "dls-[join [split $dirn /] _].lst"
        if {![file exists "$dest"]} {
            puts stdout "Generating $dirn file list"
            exec getfilelist.sh "$dirn" > "$dest"
            puts stdout "done $dirn file list"
        }
    }
    
}

### dirpacker proper
#set NN 5
# DL
set binlimit 8347540
# SL
set binlimit 4589850
set backs {}

proc reset {} {
    variable count
    variable p
    variable pi
    variable dir
    variable bestfit
    variable dirinfo
    variable dirnames
    variable batchfsize

    catch {unset p}
    catch {unset pi}
    catch {unset dir}
    catch {unset bestfit}
    catch {unset dirinfo}
    catch {unset dirnames}
    catch {unset batchfsize}

    set count 0
    set p(0) 0
    set pi(0) 0
    set dir(0) 0
    set bestfit(nr) 99999999999999
    set bestfit(frag) 99999999999999
    set batchfsize 0
}
reset

proc PrintPerm {} {
    variable NN
    variable p
    variable count
    variable dirresv
    variable dirresvidxlist

    incr count
    set idxlist $dirresvidxlist
#    puts -nonewline stdout [format {[%08d] } $count]
    for {set i 1} {$i <= $NN} {incr i} {
#        puts -nonewline stdout $p($i)
        lappend idxlist [expr $p($i) - 1 + $dirresv]
    }
    CheckPerm $idxlist
}

proc PrintTrans {x y} {
    puts stdout "    ($x $y)"
}

proc Move {x d} {
    variable p
    variable pi

#    PrintTrans $pi($x) [expr $pi($x) + $d]
    set z $p([expr $pi($x) + $d])
    set p($pi($x)) $z
    set p([expr $pi($x) + $d]) $x
    set pi($z) $pi($x)
    set pi($x) [expr $pi($x) + $d]
}

proc Perm {n} {
    variable NN
    variable dir

    if {$n > $NN} {
        PrintPerm
    } else {
        Perm [expr $n + 1]
        for {set i 1} {$i <= $n-1} {incr i} {
            Move $n $dir($n)
            Perm [expr $n + 1]
        }
        set dir($n) [expr -$dir($n)]
    }
}

proc main {} {
    variable NN
    variable p
    variable pi
    variable dir
    variable dirlist
    variable dirresv
    variable dirresvidxlist
    variable dirnames
    variable bestfit
    variable permtotal
    variable binlimit
    variable dirslice

    set dirresvidxlist ""
    for {set i 0} {$i < $dirresv} {incr i} {
        lappend dirresvidxlist $i
    }

    # load du listings
    foreach dname $dirlist {
        loaddir $dname
    }

    set dirnames [lrange $dirnames $dirresv $dirslice]
    set NN [llength $dirnames]

    set permtotal 1.0
    for {set i 1} {$i <= $NN} {incr i} {
        set dir($i) -1
        set p($i) $i
        set pi($i) $i

        if {$i <= $NN} {
            set permtotal [expr $permtotal * $i]
        }
    }

    fconfigure stdin -blocking false
    Perm 1

    puts stdout ""
    puts stdout "Writing the best fit output to break.lst"
    set fp [open "break.lst" "w"]
    fullPrint $bestfit(idxlist) $fp
    close $fp
    reorder $bestfit(idxlist)
}

variable batchfsize 0
    variable dirnames {}

proc loaddir {dir} {
    variable dirinfo
    variable dirnames
    variable batchfsize

    set fp [open dls-${dir}.lst r]
    lappend dirnames $dir
    foreach line [split [read $fp] \n] {
        if {"" != $line} {
            regexp {^([0-9]*)	(.*)$} $line junk size fname
            lappend dirinfo($dir) [list $size $fname]
            incr batchfsize $size
        }
    }
    close $fp
}

proc fullPrint {idxlist {chan stdout}} {
    variable dirinfo
    variable dirlist
    variable binlimit

    set bin 1
    set binsize 0

    foreach idx $idxlist {
        foreach item $dirinfo([lindex $dirlist $idx]) {
            set size [lindex $item 0]
            set fname [lindex $item 1]
            if {$binlimit < ($binsize + $size)} {
                puts $chan "break $binsize"
                incr bin
                set binsize $size
            } else {
                incr binsize $size
            }
            puts $chan "$size\t$fname"
        }
    }
}

proc CheckPerm {idxlist} {
    variable count
    variable dirinfo
    variable dirlist
    variable bestfit
    variable permtotal
    variable batchfsize
    variable binlimit
    variable dirslice

    set bin 1
    set binsize 0
    set binfrag 0

#    puts stdout ""
    foreach idx $idxlist {
#        puts stdout "dirname: $idx, [lindex $dirnames $idx])"
        foreach item $dirinfo([lindex $dirlist $idx]) {
            set size [lindex $item 0]
            if {$binlimit < ($binsize + $size)} {
                incr binfrag [expr $binlimit - $binsize]
#                puts stdout "full bin $bin: $binsize, [expr $binlimit - $binsize] -> $binfrag"
                lappend binstats $bin $binsize [expr $binlimit - $binsize] $binfrag
                incr bin
                set binsize $size
            } else {
                incr binsize $size
            }
        }
    }
    lappend binstats $bin $binsize [expr $binlimit - $binsize] [expr $binfrag + $binlimit - $binsize]
#    puts stdout "last bin $bin: $binsize, [expr $binlimit - $binsize] -> $binfrag"

    if {$bestfit(nr) >= $bin} {
        if {$bestfit(frag) > $binfrag} {
            set bestfit(nr) $bin
            set bestfit(frag) $binfrag
            set bestfit(idxlist) $idxlist
            puts stdout "Fewest bins possible: [expr $batchfsize / $binlimit], leftover: [expr $batchfsize % $binlimit], dir slice: $dirslice"
            puts stdout "New best at $count/$permtotal: count=$bin: leftover=$binsize, totalfrag=$binfrag"
            puts stdout "    index list: $idxlist"
            foreach {nr sz left frag} $binstats {
                puts stdout [format {      %02d: %-7d %-7d -> %-10d} $nr $sz $left $frag]
            }
            puts stdout ""
        }
    }

    if {($count % 500) == 0} {
        variable backs

        set out " Permutation: $count"
        set len [string length $out]
        puts -nonewline stdout "$out[string range $backs 0 $len]"
        flush stdout
        CheckInput $bestfit(idxlist)
    }
}

proc reorder {idxlist} {
    variable dirlist

    set remainder {}
    for {set i [llength $idxlist]} {$i < [llength $dirlist]} {incr i} {
        lappend remainder $i
    }

    puts stdout "idx order: $idxlist"
    puts stdout "rem order: $remainder"
    foreach idx [concat $idxlist $remainder] {
#puts stdout "new: [lindex $dirlist $idx]"
        lappend newdirlist [lindex $dirlist $idx]
    }
    set dirlist $newdirlist
}

proc save {} {
    variable bestfit

    puts stdout "Writing current best fit output to break.lst"
    set fp [open "break.lst" "w"]
    fullPrint $bestfit(idxlist) $fp
    close $fp
}

proc CheckInput {idxlist} {
    variable bestfit
    variable dirslice

    set ret [gets stdin val]
    if {$ret > 0} {
        if {"a" == $val} {
            save
            exit
        }
        if {"s" == $val} {
            save
        }
        if {"r" == $val} {
            save
            puts stdout "Restarting permutation algorithm"
            reorder $idxlist
            error "restart" "restart" "restart"
        }
        if {"e" == $val} {
            save
            puts stdout "Adding new dir and restarting permutation algorithm"
            catch {incr dirslice}
            reorder $idxlist
            error "restart" "restart" "restart"
        }
    }
}

start
if {[llength $dirlist] == 0} {
    exit
}

if {[llength $dirlist] < 8} {
   set calcdirslice [llength $dirlist]
} else {
   set calcdirslice 8
}
if {![info exists dirslice]} {
   set dirslice $calcdirslice
}
#   set dirslice [llength $dirlist]
#   set dirslice 20

set origdirlist $dirlist
set prelength [llength $dirlist]
while {[llength $dirlist] >= $dirslice} {
   set curlength [llength $dirlist]
   if {$curlength != $prelength} {
       puts stderr "assert failed: curlength != prelength"
       exit 1
   }
   set s1dirlist [lsort $origdirlist]
   set s2dirlist [lsort $dirlist]
   for {set i 0} {$i < [llength $s1dirlist]} {incr i} {
       if {[lindex $s1dirlist $i] != [lindex $s2dirlist $i]} {
           puts stderr "error, dirlist corrupted at $i"
           puts stderr "   orig: $origdirlist"
           puts stderr "current: $dirlist"
           exit 1
       }
   }

   if {[catch main]} {
       if {$errorCode == "restart"} {
          reset
       } else {
           puts stderr "$errorInfo"
           exit 1
       }
   } else {
       incr dirslice
       reset
   }
}

