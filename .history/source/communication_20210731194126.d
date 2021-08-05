module communication;

import std.stdio;
import std.process;
import std.string;
import std.algorithm;
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
                            new_player.nextPlayer = "Player_0";

                            if (player == "Player_1") {
                                settings.players["Player_0"].nextPlayer = player;
                            }
                            if (player == "Player_2") {
                                settings.players["Player_1"].nextPlayer = player;
                            }
                            if (player == "Player_3") {
                                settings.players["Player_2"].nextPlayer = player;
                            }

                            switch (player) {
                                case "Player_0":
                                    new_player.color = "yellow";
                                    new_player.pawns["yellow_pawn_1"] = "yellow_base_1";
                                    new_player.pawns["yellow_pawn_2"] = "yellow_base_2";
                                    new_player.pawns["yellow_pawn_3"] = "yellow_base_3";
                                    new_player.pawns["yellow_pawn_4"] = "yellow_base_4";
                                    break;
                                case "Player_1":
                                    new_player.color = "green";
                                    new_player.pawns["green_pawn_1"] = "green_base_1";
                                    new_player.pawns["green_pawn_2"] = "green_base_2";
                                    new_player.pawns["green_pawn_3"] = "green_base_3";
                                    new_player.pawns["green_pawn_4"] = "green_base_4";
                                    break;
                                case "Player_2":
                                    new_player.color = "blue";
                                    new_player.pawns["blue_pawn_1"] = "blue_base_1";
                                    new_player.pawns["blue_pawn_2"] = "blue_base_2";
                                    new_player.pawns["blue_pawn_3"] = "blue_base_3";
                                    new_player.pawns["blue_pawn_4"] = "blue_base_4";
                                    break;
                                case "Player_3":
                                    new_player.color = "red";
                                    new_player.pawns["red_pawn_1"] = "red_base_1";
                                    new_player.pawns["red_pawn_2"] = "red_base_2";
                                    new_player.pawns["red_pawn_3"] = "red_base_3";
                                    new_player.pawns["red_pawn_4"] = "red_base_4";
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
                logMessage("Game started.", fg.cyan);
                settings.gameStarted = true;
                settings.currentPlayer = "Player_0";
                settings.players["Player_0"].remainingRolls = 3;
                settings.players["Player_0"].threeChances = true;
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
            logMessage("Roll request.", fg.cyan);
            if(settings.gameStarted) {
                if (settings.currentPlayer == player) {
                    if (settings.players[player].remainingRolls != 0) {
                        settings.players[player].remainingRolls -= 1;
                        const int result = uniform(1, 7);
                        settings.rollResult = result;
                        if (result == 6) {
                            settings.players[player].remainingRolls = 1;
                        } else {
                            if (settings.players[player].threeChances) {
                                if (settings.players[player].remainingRolls == 0) {
                                    settings.players[player].playerCanEndTurn = true;
                                }
                            }
                        }
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
            logMessage("End turn: " ~ player, fg.cyan);
            if(settings.gameStarted) {
                if (settings.currentPlayer == player) {
                        if (settings.players[player].playerCanEndTurn) {
                            string next_player = settings.players[player].nextPlayer;
                            logMessage("Next Player: " ~ next_player, fg.cyan);
                            if (settings.players[next_player].threeChances) {
                                settings.players[next_player].remainingRolls = 3;
                            } else {
                                settings.players[next_player].remainingRolls = 1;
                            }
                            settings.currentPlayer = next_player;
                            JSONValue data_to_send = ["action": "next_turn"];
                            data_to_send.object["next_player"] = JSONValue(next_player);
                            settings.players[player].playerCanEndTurn = false;
                            foreach(player_to_send; settings.players) {
                                player_to_send.socket.send(data_to_send.toString());
                            }
                        } else {
                            JSONValue data_to_send = ["action": "error"];
                            data_to_send.object["message"] = JSONValue("You can't end turn yet!");
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

        case "pawn_clicked":
            const string player = strip(to!string(request["player"]), "\"");
            if (settings.gameStarted) {
                const string field_clicked = strip(to!string(request["field"]), "\"");
                logMessage("Field: " ~ field_clicked ~ " clicked by: " ~ player, fg.cyan);
                string pawn_clicked = null;
                foreach (pawn, field; settings.players[player].pawns) {
                    if (field == field_clicked) {
                        pawn_clicked = pawn;
                        break;
                    }
                }
                if (pawn_clicked is null) {
                    JSONValue data_to_send = ["action": "error"];
                    data_to_send.object["message"] = JSONValue("There is no pawn of your color on this field!");
                    settings.players[player].socket.send(data_to_send.toString());
                } else {
                    if (settings.players[player].playerCanEndTurn) {
                        JSONValue data_to_send = ["action": "error"];
                        data_to_send.object["message"] = JSONValue("Nothing to do. Please end turn!");
                        settings.players[player].socket.send(data_to_send.toString());
                    } else {
                        if (settings.rollResult == 0) {
                            JSONValue data_to_send = ["action": "error"];
                            data_to_send.object["message"] = JSONValue(
                                "You need to roll a value in order to move a pawn!"
                            );
                            settings.players[player].socket.send(data_to_send.toString());
                        } else {
                            if (clickedEnemyBaseField(field_clicked, settings.players[player].color)) {
                                JSONValue data_to_send = ["action": "error"];
                                data_to_send.object["message"] = JSONValue(
                                    "It's not a field in your color!"
                                );
                                settings.players[player].socket.send(data_to_send.toString());
                            } else {
                                if (clickedEndField(field_clicked)) {
                                    string destinationField = field_clicked;
                                    if (settings.rollResult != 0) {
                                        foreach(_; 0 .. settings.rollResult) {
                                            destinationField = getNextField(destinationField, player, settings);
                                            logMessage("CurrentField: " ~ destinationField, fg.light_magenta);
                                            /// If non existing field is reached
                                            if (destinationField is null) {
                                                break;
                                            }
                                        }

                                        if (!(destinationField is null)) {
                                            /// Check if this field is free
                                            string field_owner = null;
                                            foreach (pawn, field; settings.players[player].pawns) {
                                                if (field == destinationField) {
                                                    field_owner = pawn;
                                                    break;
                                                }
                                            }
                                            if (field_owner is null) {
                                                JSONValue data_to_send = ["action": "move_player_pawn"];
                                                data_to_send.object["source_field"] = JSONValue(
                                                    settings.players[player].pawns[pawn_clicked]
                                                );
                                                data_to_send.object["destination_field"] = JSONValue(
                                                    destinationField
                                                );
                                                data_to_send.object["to_delete_pawns"] = JSONValue("");
                                                settings.players[player].pawns[pawn_clicked] = destinationField;
                                                settings.rollResult = 0;
                                                foreach(player_to_send; settings.players) {
                                                    player_to_send.socket.send(data_to_send.toString());
                                                }
                                                if (settings.players[player].remainingRolls == 0) {
                                                    settings.players[player].playerCanEndTurn = true;
                                                }
                                                logMessage(
                                                    "Remaining rolls: "
                                                    ~ to!string(settings.players[player].remainingRolls),
                                                    fg.cyan
                                                );
                                            } else {
                                                JSONValue data_to_send = ["action": "error"];
                                                data_to_send.object["message"] = JSONValue(
                                                    "The finished line is already taken!"
                                                );
                                                settings.players[player].socket.send(data_to_send.toString());
                                            }
                                        } else {
                                            JSONValue data_to_send = ["action": "error"];
                                            data_to_send.object["message"] = JSONValue(
                                                "You can't move this pawn for "
                                                ~ to!string(settings.rollResult) ~ " fields!"
                                            );
                                            settings.players[player].socket.send(data_to_send.toString());
                                        }
                                    } else {
                                        JSONValue data_to_send = ["action": "error"];
                                        data_to_send.object["message"] = JSONValue(
                                            "Roll the dice first!"
                                        );
                                        settings.players[player].socket.send(data_to_send.toString());
                                    }
                                } else {
                                    if (clickedCorrectBaseField(field_clicked, settings.players[player].color)) {
                                        string destinationField = getStartField(player);
                                        if (destinationField is null) {
                                            JSONValue data_to_send = ["action": "error"];
                                            data_to_send.object["message"] = JSONValue(
                                                "Error during getting `start_field` value!"
                                            );
                                            settings.players[player].socket.send(data_to_send.toString());
                                        } else {
                                            if (settings.rollResult == 6) {
                                                JSONValue data_to_send = ["action": "move_player_pawn"];
                                                data_to_send.object["source_field"] = JSONValue(
                                                    settings.players[player].pawns[pawn_clicked]
                                                );
                                                data_to_send.object["destination_field"] = JSONValue(destinationField);
                                                settings.players[player].pawns[pawn_clicked] = destinationField;
                                                data_to_send.object["to_delete_pawns"] = JSONValue("");
                                                settings.players[player].threeChances = false;
                                                settings.players[player].remainingRolls = 1;
                                                settings.rollResult = 0;
                                                foreach(player_to_send; settings.players) {
                                                    player_to_send.socket.send(data_to_send.toString());
                                                }
                                            } else {
                                                JSONValue data_to_send = ["action": "error"];
                                                data_to_send.object["message"] = JSONValue(
                                                    "You can't move pawn from base. You didn't get 6 on dice!"
                                                );
                                                settings.players[player].socket.send(data_to_send.toString());
                                            }
                                        }
                                    } else {
                                        string destinationField = field_clicked;
                                        if (settings.rollResult != 0) {
                                            foreach(_; 0 .. settings.rollResult) {
                                                destinationField = getNextField(destinationField, player, settings);
                                                logMessage("CurrentField: " ~ destinationField, fg.light_magenta);

                                                if (destinationField is null) {
                                                    break;
                                                }
                                            }
                                            /// Pawn on end field
                                            if (clickedEndField(destinationField)) {
                                                /// Check if this field is free
                                                string field_owner = null;
                                                foreach (pawn, field; settings.players[player].pawns) {
                                                    if (field == destinationField) {
                                                        field_owner = pawn;
                                                        break;
                                                    }
                                                }
                                                if (field_owner is null) {
                                                    JSONValue data_to_send = ["action": "move_player_pawn"];
                                                    data_to_send.object["source_field"] = JSONValue(
                                                        settings.players[player].pawns[pawn_clicked]
                                                    );
                                                    data_to_send.object["destination_field"] = JSONValue(
                                                        destinationField
                                                    );
                                                    settings.players[player].pawns[pawn_clicked] = destinationField;
                                                    data_to_send.object["to_delete_pawns"] = JSONValue("");
                                                    settings.rollResult = 0;
                                                    foreach(player_to_send; settings.players) {
                                                        player_to_send.socket.send(data_to_send.toString());
                                                    }
                                                    if (settings.players[player].remainingRolls == 0) {
                                                        settings.players[player].playerCanEndTurn = true;
                                                        /// Check if player has other pawns on game board
                                                        bool should_be_3_rolls = false;
                                                        foreach (pawn, field; settings.players[player].pawns) {
                                                            if (checkPawnOnPlayBoard(field)) {
                                                                should_be_3_rolls = true;
                                                                break;
                                                            }
                                                        }
                                                        settings.players[player].threeChances = should_be_3_rolls;
                                                    }
                                                } else {
                                                    JSONValue data_to_send = ["action": "error"];
                                                    data_to_send.object["message"] = JSONValue(
                                                        "The finished line is already taken!"
                                                    );
                                                    settings.players[player].socket.send(data_to_send.toString());
                                                }
                                            } else {
                                                /// Pawn on normal field
                                                /// Check if this field is taken
                                                if (!(destinationField is null)) {
                                                    string[] field_owners = [];
                                                    string player_field_owner = null;
                                                    foreach (nickname, _player; settings.players) {
                                                        foreach (pawn, field; _player.pawns) {
                                                            if (field == destinationField) {
                                                                field_owners ~= pawn;
                                                                player_field_owner = nickname;
                                                            }
                                                        }
                                                        if (!(player_field_owner is null)) {
                                                            break;
                                                        }
                                                    }
                                                    logMessage("Field pawns: " ~ to!string(field_owners), fg.red);
                                                    logMessage("Field owner: " ~ to!string(player_field_owner), fg.red);
                                                    JSONValue data_to_send = ["action": "move_player_pawn"];
                                                        data_to_send.object["source_field"] = JSONValue(
                                                            settings.players[player].pawns[pawn_clicked]
                                                        );
                                                        data_to_send.object["destination_field"] = JSONValue(
                                                            destinationField
                                                        );
                                                        settings.players[player].pawns[pawn_clicked] = destinationField;
                                                        data_to_send.object["to_delete_pawns"] = JSONValue("");
                                                    if (!(player_field_owner is null)) {
                                                        /// Check if field owner is a current player
                                                        if (player_field_owner == player) {
                                                            data_to_send.object["to_delete_pawns"] = JSONValue("");
                                                        } else {
                                                            data_to_send.object["to_delete_pawns"] = JSONValue(
                                                                field_owners
                                                            );
                                                            /// Check if `field owner` has other pawns on game board
                                                            bool should_be_3_rolls = false;
                                                            foreach (
                                                                pawn, field; settings.players[player_field_owner].pawns
                                                            ) {
                                                                if (checkPawnOnPlayBoard(field)) {
                                                                    should_be_3_rolls = true;
                                                                    break;
                                                                }
                                                            }
                                                            settings.players[player_field_owner].threeChances = (
                                                                should_be_3_rolls
                                                            );
                                                            /// Update `field owner pawns`
                                                            foreach (
                                                                pawn, field; settings.players[player_field_owner].pawns
                                                            ) {
                                                                foreach (field_pawn; field_owners) {
                                                                    if (pawn == field_pawn) {
                                                                        settings.players[player_field_owner].pawns[
                                                                            pawn
                                                                        ] = (getPawnBaseField(pawn));
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    foreach(player_to_send; settings.players) {
                                                        player_to_send.socket.send(data_to_send.toString());
                                                    }
                                                    settings.rollResult = 0;
                                                    if (settings.players[player].remainingRolls == 0) {
                                                        settings.players[player].playerCanEndTurn = true;
                                                    }
                                                } else {
                                                    JSONValue data_to_send = ["action": "error"];
                                                    data_to_send.object["message"] = JSONValue(
                                                        "The field you are trying to move to, doesn't exist!"
                                                    );
                                                    settings.players[player].socket.send(data_to_send.toString());
                                                    /// Check if player has other pawns to move
                                                    foreach (pawn, field; settings.players[player].pawns) {
                                                        if (pawn_clicked == pawn) {
                                                            continue;
                                                        } else {
                                                            if (checkPawnOnPlayBoard(field)) {
                                                                if (!pawnCanMove(
                                                                    field, player, settings.rollResult, settings
                                                                )) {
                                                                    settings.rollResult = 0;
                                                                    settings.players[player].playerCanEndTurn = true;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            JSONValue data_to_send = ["action": "error"];
                                            data_to_send.object["message"] = JSONValue(
                                                "Roll the dice first!"
                                            );
                                            settings.players[player].socket.send(data_to_send.toString());
                                        }

                                    }
                                }
                            }
                            if (playerWin(player, settings)) {
                                JSONValue data_to_send = ["action": "player_win"];
                                data_to_send.object["player"] = JSONValue(player);
                                foreach(player_to_send; settings.players) {
                                    player_to_send.socket.send(data_to_send.toString());
                                }
                            }
                        }
                    }
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

/// Check basic errors

/// Check if player won a game
bool playerWin(string player, ref GameSettings settings) {
    int counter = 0;
    foreach (pawn, field; settings.players[player].pawns) {
        if (player == "Player_0") {
            if (canFind(["yellow_end_1", "yellow_end_2", "yellow_end_3", "yellow_end_4"], field)) {
                counter += 1;
            }
        }
        if (player == "Player_1") {
            if (canFind(["green_end_1", "green_end_2", "green_end_3", "green_end_4"], field)) {
                counter += 1;
            }
        }
        if (player == "Player_2") {
            if (canFind(["blue_end_1", "blue_end_2", "blue_end_3", "blue_end_4"], field)) {
                counter += 1;
            }
        }
        if (player == "Player_3") {
            if (canFind(["red_end_1", "red_end_2", "red_end_3", "red_end_4"], field)) {
                counter += 1;
            }
        }
    }
    if (counter == 4) {
        return true;
    } else {
        return false;
    }
}

/// Check if pawn can move for specified number of fields
bool pawnCanMove(string field, string player, int number_of_fields, ref GameSettings settings) {
    string next_field = null;
    foreach (i; 0 .. number_of_fields) {
        next_field = getNextField(field, player, settings);

        if (next_field is null) {
            break;
        }
    }
    if (!(next_field is null)) {
        return true;
    }
    return false;
}

/// Get pawn base field
string getPawnBaseField(string pawn) {
    if (pawn == "yellow_pawn_1") {
        return "yellow_base_1";
    }
    if (pawn == "yellow_pawn_2") {
        return "yellow_base_2";
    }
    if (pawn == "yellow_pawn_3") {
        return "yellow_base_3";
    }
    if (pawn == "yellow_pawn_4") {
        return "yellow_base_4";
    }
    if (pawn == "green_pawn_1") {
        return "green_base_1";
    }
    if (pawn == "green_pawn_2") {
        return "green_base_2";
    }
    if (pawn == "green_pawn_3") {
        return "green_base_3";
    }
    if (pawn == "green_pawn_4") {
        return "green_base_4";
    }
    if (pawn == "blue_pawn_1") {
        return "blue_base_1";
    }
    if (pawn == "blue_pawn_2") {
        return "blue_base_2";
    }
    if (pawn == "blue_pawn_3") {
        return "blue_base_3";
    }
    if (pawn == "blue_pawn_4") {
        return "blue_base_4";
    }
    if (pawn == "red_pawn_1") {
        return "red_base_1";
    }
    if (pawn == "red_pawn_2") {
        return "red_base_2";
    }
    if (pawn == "red_pawn_3") {
        return "red_base_3";
    }
    if (pawn == "red_pawn_4") {
        return "red_base_4";
    }
    return null;
}

/// Check if pawn on play board
bool checkPawnOnPlayBoard(string field) {
    if (canFind([
        "yellow_base_1", "yellow_base_2", "yellow_base_3", "yellow_base_4",
        "green_base_1", "green_base_2", "green_base_3", "green_base_4",
        "blue_base_1", "blue_base_2", "blue_base_3", "blue_base_4",
        "red_base_1", "red_base_2", "red_base_3", "red_base_4",
        "yellow_end_1", "yellow_end_2", "yellow_end_3", "yellow_end_4",
        "green_end_1", "green_end_2", "green_end_3", "green_end_4",
        "blue_end_1", "blue_end_2", "blue_end_3", "blue_end_4",
        "red_end_1", "red_end_2", "red_end_3", "red_end_4",
    ], field)) {
        return false;
    }
    return true;
}

/// Get next field
string getNextField(string field_clicked, string player, ref GameSettings settings) {
    if (field_clicked == "gray_29" && player == "Player_0") {
        return settings.fields[field_clicked].yellowNextField;
    }
    if (field_clicked == "gray_2" && player == "Player_1") {
        return settings.fields[field_clicked].greenNextField;
    }
    if (field_clicked == "gray_11" && player == "Player_2") {
        return settings.fields[field_clicked].redNextField;
    }
    if (field_clicked == "gray_20" && player == "Player_3") {
        return settings.fields[field_clicked].blueNextField;
    }
    if (field_clicked is null) {
        return null;
    }
    return settings.fields[field_clicked].nextField;
}

/// Get a player start field
string getStartField(string player) {
    if (player == "Player_0") {
        return "yellow_start";
    }
    if (player == "Player_1") {
        return "green_start";
    }
    if (player == "Player_2") {
        return "blue_start";
    }
    if (player == "Player_3") {
        return "red_start";
    }
    return null;
}

/// Check if correct base field clicked
bool clickedCorrectBaseField(string field, string player_color) {
    if (player_color == "yellow") {
        if (canFind(["yellow_base_1", "yellow_base_2", "yellow_base_3", "yellow_base_4"], field)) {
            return true;
        }
    }
    if (player_color == "green") {
        if (canFind(["green_base_1", "green_base_2", "green_base_3", "green_base_4"], field)) {
            return true;
        }
    }
    if (player_color == "blue") {
        if (canFind(["blue_base_1", "blue_base_2", "blue_base_3", "blue_base_4"], field)) {
            return true;
        }
    }
    if (player_color == "red") {
        if (canFind(["red_base_1", "red_base_2", "red_base_3", "red_base_4"], field)) {
            return true;
        }
    }
    return false;
}

/// Check if clicked enemy base field
bool clickedEnemyBaseField(string field, string player_color) {
    if (player_color == "yellow") {
        if (canFind([
            "green_base_1", "green_base_2", "green_base_3", "green_base_4", "blue_base_1", "blue_base_2", "blue_base_3",
            "blue_base_4", "red_base_1", "red_base_2", "red_base_3", "red_base_4"
        ], field)) {
            return true;
        }
    }
    if (player_color == "green") {
        if(canFind([
            "yellow_base_1", "yellow_base_2", "yellow_base_3", "yellow_base_4", "blue_base_1", "blue_base_2",
            "blue_base_3", "blue_base_4", "red_base_1", "red_base_2", "red_base_3", "red_base_4"
        ], field)) {
            return true;
        }
    }
    if (player_color == "blue") {
        if(canFind([
            "green_base_1", "green_base_2", "green_base_3", "green_base_4", "yellow_base_1", "yellow_base_2",
            "yellow_base_3", "blue_base_4", "red_base_1", "red_base_2", "red_base_3", "red_base_4"
        ], field)) {
            return true;
        }
    }
    if (player_color == "red") {
        if(canFind([
            "green_base_1", "green_base_2", "green_base_3", "green_base_4", "blue_base_1", "blue_base_2", "blue_base_3",
            "blue_base_4", "yellow_base_1", "yellow_base_2", "yellow_base_3", "yellow_base_4"
        ], field)) {
            return true;
        }
    }
    return false;
}

/// Check if clicked one of the end fields
bool clickedEndField(string field) {
    if (canFind([
        "yellow_end_1", "yellow_end_2", "yellow_end_3", "yellow_end_4",
        "green_end_1", "green_end_2", "green_end_3", "green_end_4",
        "blue_end_1", "blue_end_2", "blue_end_3", "blue_end_4",
        "red_end_1", "red_end_2", "red_end_3", "red_end_4",
    ], field)) {
        return true;
    }
    return false;
}
