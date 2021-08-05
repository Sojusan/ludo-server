import std.datetime;
import std.stdio;
import colorize;


///
void logMessage(string message, color_type color) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
	cwriteln("Test".color(color));
	cwritefln("[%s] %s".color(color), Clock.currTime().toString, message);
}


void main()
{
	logMessage("Test message.", fg.green);
}
