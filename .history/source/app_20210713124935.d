import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message, int color) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color(color));
	cwritefln("[%s] %s".color(fg.green), Clock.currTime().toString, message);
}


void main()
{
	logMessage("Test message.");
}
