import std.datetime;
import std.stdio;


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
}


void main()
{
	logMessage()''
}