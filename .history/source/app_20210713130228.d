import std.datetime;
import std.stdio;
import colorize;


/++
        Writes to console colorized message.

        Params:
            message = The messa
            tz = The time zone for the SysTime that's returned.

        Throws:
            $(REF DateTimeException,std,datetime,date) if it fails to get the
            time.
      +/
void logMessage(string message, fg color) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color(color));
	cwritefln("[%s] %s".color(color), Clock.currTime().toString, message);
}


void main()
{
	logMessage("Test message.", fg.green);
}
