/*********************************************************************
 *                
 * Copyright (C) 2007-2008, IBM Corporation, Project Kittyhawk
 *                
 * Description: Blue Gene driver exposing tree and torus as a NIC
 *                
 * All rights reserved
 *                
 ********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARGSTRINGSIZE 4096

extern int      optind, opterr;
extern char     *optarg;

char rangefmtstring[ARGSTRINGSIZE];
char valuefmtstring[ARGSTRINGSIZE];

 
int usage(char *pgmName)
{
  fprintf(stderr,  "Usage: %s [-r format string] [-v value format string]\n"
          " -r printf string used to format range two integer values will be passed to it\n"
          " -v printf string used to format a singular value one integer value will be passed to it\n"
          "FIXME: Yes I know I know this is a dangerous thing to do...so fix it.\n",
      pgmName);
  return 0;
}

void
processargs(int argc, char *argv[])
{
    int c,err=0;
    static char optstr[] = "r:v:";

    strncpy(rangefmtstring, "%d %d\n", ARGSTRINGSIZE);
    strncpy(valuefmtstring, "%d\n", ARGSTRINGSIZE);
    
    opterr=1;
    while ((c = getopt(argc, argv, optstr)) != EOF)
        switch (c) {
        case 'r' :
            strncpy(rangefmtstring, optarg, ARGSTRINGSIZE);
            break;
        case 'v' :
            strncpy(valuefmtstring, optarg, ARGSTRINGSIZE);
            break;
        default:
            err=1;
        }
    if (err) {
        usage(argv[0]);
        exit(1);
    }
}

int main(int argc, char *argv[])
{
    int rc;
    int val,min,max;
    int started=0;

    processargs(argc, argv);

    while (1) {
        rc = scanf("%d", &val);
        if (rc == EOF || rc == 0) break;
        if (!started) {
            min=val;
            max=val;
            started=1;
        } else {
            if (val == (max + 1)) max = val;
            else {
                if (min == max) printf(valuefmtstring, min);
                else printf(rangefmtstring, min, max);
                min=val;
                max=val;
            }
        }
    }
    if (started) {
        if (min == max) printf(valuefmtstring, min);
        else printf(rangefmtstring, min, max);
    }
    return 0;
}

