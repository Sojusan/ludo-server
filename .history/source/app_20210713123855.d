import std.datetime;
import std.stdio;
import colo


///
void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ message);
}


void main()
{
	logMessage("Test message.");
}
