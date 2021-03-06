module utils;

import std.datetime;

import colorize;


/++
	Writes to console colorized message.

	Params:
		message = The message to be written.
		color = The color of the message.
+/
void logMessage(string message, fg color) {
	cwritefln("[%s] %s".color(color), Clock.currTime().toString, message);
}
