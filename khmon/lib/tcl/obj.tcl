#####################################
#
#  IBM Coporation 
#  Project kittyhawk
#
#  khmon
#  A crude visualization tool for 
#  demonstrating kittyhawk state
#  
#####################################

proc BasicObjSupport {} {
	proc setupBasicObjSupport {} {
            global objFD lastObjs
            set lastObjs {}
            return 1
	}

#	proc getObjects {} {
#            global objDir
#            return [glob -nocomplain -directory $objDir -types {d} -- *\[0-9\]]
#	}

        proc allDirs  { e retlist } { 
            upvar $retlist retval 
            foreach dir [ glob -nocomplain  -directory $e -types {d } -- * ] { 
                allDirs $dir retval 
            }
            lappend retval $e 
        } 

#	proc getObjects {} {
#            global objDir
#            set rc {}
#            return [allDirs $objDir rc]
#	}

        proc openObjectStream {} {
            global objFD objServerUser objServer objServerCmd
            set objFD [open "|ssh $objServerUser@$objServer $objServerCmd | cat" r+]
            fconfigure $objFD -blocking no -buffering line -translation binary
            return 1
	}

        proc getObjects {} {
            global objFD lastObjs
            set line ""
            set response {}
            set start 0

            while { 1 } {
                set rc [gets $objFD line]
                if { $rc < 0 } {
                    if { [eof $objFD] } {
                        puts "Error: getObjects failed rc=$rc line=$line"
                        break;
                    }
                    return $lastObjs
                    break;
                }
                if { $line == "KHMON START" } {
                    set start 1
                    continue
                }
                if { $line =="KHMON END" && $start == 1 } {
                    set lastObjs $response
                    return $response
                } 
                if { $start == 1 } {
                    lappend response $line
                }
            }
            return {}
        }
	
	proc doPeriodic {time func} {
		$func
		after $time doPeriodic $time $func
	}

	proc prettyPrint {c r t} {
		puts "coid=$c root=$r type=$t"
		return "$c $r $t"
	}
       
	proc processObjs {filter func} {
            set retval {}
            foreach obj [getObjects] {
                if { [regexp $filter $obj] } {
                    set ans [$func $obj]
                    if {[string compare $ans ""]} {
                        lappend retval $ans
                    }
                }
            }
            #puts "\n$kount entities" 
            if [info exists retval] {
                return $retval
            }
	}

	set helpDB(printObjs) "Prints all  currently objects"

        proc rtnObj {obj} { return "$obj" }

	proc printObjs {filter} {
            processObjs $filter puts
	}

	proc onCreate {type func} {
		puts "onCreate $type $func"
	}

	proc onDestroy {type func} {
		puts "onDestroy $type $func"
	}
	setupBasicObjSupport
}

BasicObjSupport
 