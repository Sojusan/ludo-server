import std.datetime;
import std.stdio;
import colorize;


/++
	Writes to console colorized message.

	Params:
		message () = The message to be written.
		color = The color of the message.
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
