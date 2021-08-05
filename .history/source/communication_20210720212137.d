module communication;

import std.stdio;
import std.process;
import std.json;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;
import app;


/// Start server
void startServer(shared(GameSettings) settings) {
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

                    if (connectedClients.length > 3) {
                        logMessage("Server full.", fg.red);
                        JSONValue data_to_send = ["action": "error"];
                        data_to_send.object["message"] = JSONValue(
                            "There is already 4 players. Try again later."
                        );
                        newSocket.send(data_to_send.toString());
                    } else {
                        if (!settings.gameStarted) {
                            logMessage("Connection accepted.", fg.green);
                            string player = "Player_" ~ to!string(connectedClients.length);
                            Player new_player;
                            new_player.nickname = player;
                            new_player.socket = newSocket;
                            settings.players[player] = cast(shared)new_player;
                            logMessage("Added " ~ player, fg.green);
                            JSONValue data_to_send = ["action": "new_player"];
                            data_to_send.object["message"] = JSONValue(player);
                            data_to_send.object["totalPlayers"] = JSONValue(to!string(connectedClients.length + 1));
                            data_to_send.object["readyPlayers"] = JSONValue(to!string(settings.readyPlayers));
                            newSocket.send(data_to_send.toString());

                            foreach(player; se)

                            connectedClients ~= newSocket; // add to our list
                        } else {
                            logMessage("Game already started.", fg.red);
                            JSONValue data_to_send = ["action": "error"];
                            data_to_send.object["message"] = JSONValue("Game already started.");
                            newSocket.send(data_to_send.toString());
                        }
                    }
                }
            }
	    }
	}).start();
}
