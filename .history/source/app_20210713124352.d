import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color);
}


void main()
{
	logMessage("Test message.");
}
