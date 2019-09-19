# Google Calendar API with Chapel & Python

Despite Chapel's many quirks and annoyances surrounding string handling, its efficiency and ease of running in parallel are always welcome.  The idea here is a Chapel script that may need to weed through enormous numbers of files while looking for a date tag ($D + other tags currently) is probably a better choice overall than a pure Python version.  (the intent is to test this properly later.)

As of 9/19/19, there is still a laundry list of things to add- control flow (for instance, “don't add the event over and over”) less brittle syntax, annotations, actual error handling, etc.  It does find and upload calendar entries though!

I am using Python with the Google Calendar API (see here: https://developers.google.com/calendar/v3/reference/)  in a looping Daemon thread.  All the sifting for tags is managed with the Chapel binary, which dumps anything it finds into a csv from which the daemon will push calendar entries with proper formatting.  FWIW, Google’s dates (datetime.datetime) adhere to RFC3339 (https://tools.ietf.org/html/rfc3339) which conveniently is the default of the datetime.isoformat() method.  

**Some pesky things to keep in mind:**

This script uses a sync$ variable to lock other threads out of an evaluation during concurrency.
So far I think the easiest way to manage the resulting domain is from within a module like so:
```
module charMatches {
  var dates : domain(string);
}
```
Here, domain charMatches.dates will need to accessed as a reference variable from any procedures that need it.
```
proc dateCheck(aFile, ref choice) {
    ...
}
... 
...
coforall folder in walkdirs('check/') {
    for file in findfiles(folder) {
        dateCheck(file, charMatches.dates);
    }
}
```

errors like:
```
error: unresolved call '_ir_split__ref_string.size'

unresolved call 'norm(promoted expression)'

...or other variants of:
string.split().size  (length, etc)
```
...Tie into a Chapel Specification issue.

https://github.com/chapel-lang/chapel/issues/7982

The short solution is do not use .split; instead, I have been chopping strings with .partition().
```
// like so:
...
if choice.contains(line.partition(hSep)[3].partition(hTerminate)[1]) == false {
    ...process string...
    ...
}

```
