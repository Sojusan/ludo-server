import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color(fg.green));
	cwriteln("Test %s".color(fg.green), Clock.currTime().toString);
}


void main()
{
	logMessage("Test message.");
}
