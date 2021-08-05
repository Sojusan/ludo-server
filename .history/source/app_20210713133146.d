import std.stdio;
import std.process;
import std.json;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;


void main()
{
	// logMessage("Test message.", fg.green);
	auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
	listener.bind(new InternetAddress(
		environment.get("LUDO_IP_ADDRESS", "localhost"),
		to!int(environment.get("LUDO_PORT", "2524")
	));
	listener.listen(10);
	auto readSet = new SocketSet();
	Socket[] connectedClients;
	char[1024] buffer;
	const bool isRunning = true;
	new Thread({
		while(isRunning) {
		readSet.reset();
		readSet.add(listener);

		foreach(client; connectedClients)
			readSet.add(client);

		if(Socket.select(readSet, null, null)) {
			foreach(client; connectedClients) {
				if(readSet.isSet(client)) {
					// read from it and echo it back
					auto got = client.receive(buffer);
					client.send(buffer[0 .. got]);
				}
			}
			if(readSet.isSet(listener)) {
				// the listener is ready to read, that means
				// a new client wants to connect. We accept it here.
				auto newSocket = listener.accept();
				newSocket.send("Hello!\n"); // say hello
				logMessage("New connection.", fg.yellow);
				connectedClients ~= newSocket; // add to our list
			}
		}
	}
	}).start();
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
