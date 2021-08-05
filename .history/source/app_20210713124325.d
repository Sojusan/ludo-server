import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwr
}


void main()
{
	logMessage("Test message.");
}
