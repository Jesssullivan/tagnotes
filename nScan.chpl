use FileSystem;
use IO;
use Time;

config const V : bool=true;  // verbose logging

const dSep : string='$D ';
const tSep : string='$T ';
const hSep : string='$H ';
const hTerminate : string="$Ht";
const dInfo : string='$I ';
const dInfoTerminate : string='$It ';

const dRange = 1..8;

const tRange = 1..5;

module charMatches {
  var dates : domain(string);
}

var sync1$ : sync bool=true;

proc dateCheck(aFile, ref choice) {
    sync1$;  // closes line access to other threads
    try {
        var line : string;
        var r = openreader(aFile);
        while r.readline(line) {
            if line.find(dSep) > 0 {
                if line.find(hSep) > 0 {
                    if choice.contains(line.partition(hSep)[3].partition(hTerminate)[1]) == false {
                        if line.find(tSep) > 0 && line.find(dInfo) > 0 {
                                try {
                                    choice += line.partition(dSep)[3][dRange]
                                        + ',' + line.partition(hSep)[3].partition(hTerminate)[1]
                                        + ',' + line.partition(tSep)[3][tRange]
                                        + ',' + line.partition(dInfo)[3].partition(dInfoTerminate)[1]
                                        + '\n';
                                } catch {
                                    if V then writeln('error adding date with time, info');
                                }
                            }
                        if line.find(tSep) == 0 && line.find(dInfo) > 0 {
                            try {
                                choice += line.partition(dSep)[3][dRange]
                                    + ',' + line.partition(hSep)[3].partition(hTerminate)[1]
                                    + ',' + ' '
                                    + ',' + line.partition(dInfo)[3].partition(dInfoTerminate)[1]
                                    + '\n';
                            } catch {
                                if V then writeln('error adding date with info');
                            }
                        }
                        if line.find(tSep) > 0 && line.find(dInfo) == 0 {
                            try {
                                choice += line.partition(dSep)[3][dRange]
                                    + ',' + line.partition(hSep)[3].partition(hTerminate)[1]
                                    + ',' + line.partition(tSep)[3][tRange]
                                    + '\n';
                            } catch {
                                if V then writeln('error adding date with time');
                            }
                        }
                        if line.find(tSep) == 0 && line.find(dInfo) == 0 {
                            try {
                                choice += line.partition(dSep)[3][dRange]
                                    + ',' + line.partition(hSep)[3].partition(hTerminate)[1]
                                    + '\n';
                            } catch {
                                if V then writeln('error adding date');
                            }
                        }
                    }
                }
            }
        }
        r.close();
    } catch {
        if V then writeln("caught error iterating");
    }
    sync1$ = true;
}

coforall folder in walkdirs('check/') {
    for file in findfiles(folder) {
        dateCheck(file, charMatches.dates);
    }
}

// write information to files
proc WriteAll(N : string, content) {
    var OFile = open(N, iomode.cw);
    var Ochann = OFile.writer();
    Ochann.write(content.strip('{'));
    Ochann.close();
    OFile.close();
}

// space seperated:
WriteAll("dates.csv", charMatches.dates);
