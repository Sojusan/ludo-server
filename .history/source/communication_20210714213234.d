module communication;

import std.stdio;
import std.process;
import std.json;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;


/// Start server
void startServer() {
    auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
	listener.bind(new InternetAddress(
		environment.get("LUDO_IP_ADDRESS", "localhost"),
		to!ushort(environment.get("LUDO_PORT", "2524"))
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
                    logMessage("New connection.", fg.yellow);
                    auto newSocket = listener.accept();

                    if (connectedClients.count )

                    newSocket.send("Hello!\n"); // say hello
                    logMessage("New connection.", fg.yellow);
                    connectedClients ~= newSocket; // add to our list
                }
            }
	    }
	}).start();
}
