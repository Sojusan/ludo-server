import std.datetime;
import std.stdio;

void logMessage(string message) {
	writeln("[" ~ Clock.currTime().toString ~ "] " ~ "Edit source/app.d to start your project.")
}

void main()
{
	auto currentTime = Clock.currTime();
	writeln("[" ~ currentTime.toString ~ "] " ~ "Edit source/app.d to start your project.");
}
