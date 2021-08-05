module communication;

import std.stdio;
import std.process;
import std.string;
import std.json;
import std.random;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;
import app;

/// Start server
void startServer(GameSettings settings) {
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
                        if (got == 0) {
                            break;
                        }
                        JSONValue client_data = parseJSON(buffer[0 .. got]);

                        // client.send(buffer[0 .. got]);
                        logMessage(client_data.toString(), fg.magenta);
                        processRequest(client_data, settings);
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

                            string next_player = "Player_" ~ to!string(connectedClients.length + 1);
                            if (next_player == "")

                            switch (player) {
                                case "Player_0":
                                    new_player.color = "yellow";
                                    break;
                                case "Player_1":
                                    new_player.color = "green";
                                    break;
                                case "Player_2":
                                    new_player.color = "blue";
                                    break;
                                case "Player_3":
                                    new_player.color = "red";
                                    break;
                                default:
                                    break;
                            }

                            settings.players[player] = new_player;
                            logMessage("Added " ~ player, fg.green);
                            JSONValue data_to_send = ["action": "new_player"];
                            data_to_send.object["message"] = JSONValue(player);
                            data_to_send.object["totalPlayers"] = JSONValue(to!string(connectedClients.length + 1));
                            data_to_send.object["readyPlayers"] = JSONValue(to!string(settings.readyPlayers));
                            newSocket.send(data_to_send.toString());

                            data_to_send["action"].str = "update_players_numbers";
                            foreach(player_to_send; settings.players) {
                                logMessage(player_to_send.nickname, fg.light_blue);
                                logMessage(player_to_send.color, fg.light_blue);
                                if (player_to_send.nickname != player)
                                    player_to_send.socket.send(data_to_send.toString());
                            }

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

/// Process the Client request
void processRequest(JSONValue request, ref GameSettings settings) {
    logMessage("Got action: " ~ to!string(request["action"]), fg.red);
    switch(strip(to!string(request["action"]), "\"")) {
        case "player_ready":
            string player = strip(to!string(request["player"]), "\"");
            logMessage("Player actuall ready state: " ~ to!string(settings.players[player].ready), fg.light_yellow);
            if (!settings.players[player].ready) {
                logMessage("Player: " ~ player ~ " is ready.", fg.light_yellow);
                settings.readyPlayers += 1;
                settings.players[player].ready = true;
            }
            JSONValue data_to_send = ["action": "player_ready"];
            data_to_send.object["readyPlayers"] = JSONValue(to!string(settings.readyPlayers));
            foreach(player_to_send; settings.players) {
                player_to_send.socket.send(data_to_send.toString());
            }
            break;

        case "start_game":
            if(!settings.gameStarted) {
                logMessage("Game started.", fg.red);
                settings.gameStarted = true;
                settings.currentPlayer = "Player_0";
                settings.players["Player_0"].remainingRolls = 3;
                JSONValue data_to_send = ["action": "start_game"];
                data_to_send["players_list"] = JSONValue([""]);
                foreach(player; settings.players) {
                    data_to_send["players_list"].array ~= JSONValue(player.nickname);
                }
                foreach(player_to_send; settings.players) {
                    player_to_send.socket.send(data_to_send.toString());
                }
            }
            break;

        case "roll_request":
            const string player = strip(to!string(request["player"]), "\"");
            logMessage("Roll request.", fg.red);
            if(settings.gameStarted) {
                if (settings.currentPlayer == player) {
                    if (settings.players[player].remainingRolls != 0) {
                        settings.players[player].remainingRolls -= 1;
                        const int result = uniform(1, 7);
                        logMessage("Roll result: " ~ to!string(result), fg.green);
                        JSONValue data_to_send = ["action": "roll_result"];
                        data_to_send.object["result"] = JSONValue(result);
                        foreach(player_to_send; settings.players) {
                            player_to_send.socket.send(data_to_send.toString());
                        }
                    } else {
                        JSONValue data_to_send = ["action": "error"];
                        data_to_send.object["message"] = JSONValue("No rolls left!");
                        settings.players[player].socket.send(data_to_send.toString());
                    }
                } else {
                    JSONValue data_to_send = ["action": "error"];
                    data_to_send.object["message"] = JSONValue("It's not your turn!");
                    settings.players[player].socket.send(data_to_send.toString());
                }
            } else {
                JSONValue data_to_send = ["action": "error"];
                data_to_send.object["message"] = JSONValue("Game didn't started yet!");
                settings.players[player].socket.send(data_to_send.toString());
            }
            break;

        case "end_turn":
            const string player = strip(to!string(request["player"]), "\"");
            logMessage("End turn: " ~ player, fg.red);
            if(settings.gameStarted) {
                if (settings.currentPlayer == player) {
                        if (settings.players[player].playerCanEndTurn) {
                            JSONValue data_to_send = ["action": "next_turn"];
                            data_to_send.object["result"] = JSONValue(result);
                            foreach(player_to_send; settings.players) {
                                player_to_send.socket.send(data_to_send.toString());
                            }
                        }


                } else {
                    JSONValue data_to_send = ["action": "error"];
                    data_to_send.object["message"] = JSONValue("It's not your turn!");
                    settings.players[player].socket.send(data_to_send.toString());
                }
            } else {
                JSONValue data_to_send = ["action": "error"];
                data_to_send.object["message"] = JSONValue("Game didn't started yet!");
                settings.players[player].socket.send(data_to_send.toString());
            }
            break;

        default:
            break;
    }
}
