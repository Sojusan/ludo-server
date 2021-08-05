import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color(fg.green));
	cwritefln("[%s]Test".color(fg.green), Clock.currTime().toString);
}


void main()
{
	logMessage("Test message.");
}
