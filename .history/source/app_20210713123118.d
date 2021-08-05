import std.datetime;
import std.stdio;

void log

void main()
{
	auto currentTime = Clock.currTime();
	writeln("[" ~ currentTime.toString ~ "] " ~ "Edit source/app.d to start your project.");
}
