import std.stdio;
import std.process;
import std.json;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;

shared socket[]

void main()
{
	// logMessage("Test message.", fg.green);

	foreach(line; stdin.byLine) {
		writeln("Line: " ~ line);
		foreach(client; connectedClients) {
		//    client.send(line);
			JSONValue data_to_send = ["test2": "Test"];
			data_to_send.object["test"] = JSONValue(2.2);
			data_to_send.object["username"] = JSONValue("Testowy");
			data_to_send.object["rolls"] = JSONValue([2, 3, 4]);
			client.send(data_to_send.toString);
			// client.send(`{"test": 2.2, "username": "Test"}`);
		}
	//    socket.send(line);
	//    writeln("Server said: ", buffer[0 .. socket.receive(buffer)]);
	}
}
