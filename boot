#!/bin/bash

NAME=boot
VERSION=0.1.3
CONSOLE=mmcs_db_console
CONIP=9.2.132.209
GSA=/gsa/yktgsa/projects/k/kittyhawk/pub/nightly/boot

function help()
{
    echo -e "\`$NAME' boots a Blue Gene/P block\n"                        \
	    "\n"                                                          \
	    "Usage: $NAME [OPTIONS] BLOCKINFO [BLOCKID]\n"                \
	    " -?, --help          Show this help statement\n"             \
	    "     --version       Show version statement\n"               \
	    " -l, --list          Display list of saved blockinfos\n"     \
	    " -c, --console ADDR  Use ADDR as console IP\n"               \
	    "\n"                                                          \
            "Note: BLOCKINFO is a saved blockinfo file that is either\n"  \
            "      passed as a pathname or implicitly looked up in\n"     \
            "      ~/.boot or ~kittyhawk/pub/nightly/boot\n"              \
            "\n"                                                          \
	    "Examples: $NAME -l                  ; List available\n"      \
	    "          $NAME sshd                ; Show values\n"         \
	    "          $NAME sshd r001n04-c32i1  ; Execute a boot\n";
}

function work()
{
    local blockinfo="$1";
    local blockid="$2";

    if test -r $blockinfo; then
        file=$blockinfo;
    elif test -r ~/.boot/$blockinfo; then
        file=~/.boot/$blockinfo;
    elif test -r $GSA/$blockinfo; then
        file=$GSA/$blockinfo;
    fi

    INFO=$(eval echo $(cat $file));

    test -z "$INFO" && {
       return 1;
    }

    test -z "$blockid" && {
        echo $INFO | sed 's/[,]/\n/g' | sed 's/ /\n\n/g';
        return 0;
    }

    cat | $CONSOLE --consoleip $CONIP <<- STOP
        free $blockid
        setblockinfo $blockid $INFO
        allocate_block $blockid no_connect
        connect no_ras_disconnect
        redirect $blockid on
        boot_block 
STOP

    return 0;
}

function main()
{
    local blockinfo;
    local blockid;

    while [ $# -gt 0 ]; do
        case $1 in
        -\? | --help)
            help; return 1;
            ;;
        --version)
            echo $VERSION; return 1;
            ;;
	-c | --console)
	    CONIP=$2;
	    echo console: $CONIP;
	    shift; shift;
	    ;;
        -l | --list)
            test -d ~/.boot || mkdir ~/.boot || return 1;
            cd ~/.boot || return 1;
            ls -1;
            cd $GSA || return 1;
            ls -1;
            return $?;
            ;;
        *)
            if [ -z "$blockinfo" ]; then
	    	blockinfo="$1";
            elif [ -z "$blockid" ]; then
	    	blockid="$1";
	    else
	        echo "$NAME: too many arguments: $1"; return 1;
	    fi
	    shift;
            ;;
        esac
    done

    [  -z "$blockinfo" ] && {
    	help; return 1;
    }

    work "$blockinfo" "$blockid" || { 
    	echo "$NAME: bailing out because of errors"; return 1;
    }

    return 0;
}

main "$@";
exit $?;
