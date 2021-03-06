import std.stdio;
import std.process;
import std.json;
import std.socket;
import core.thread;
import std.conv;

import colorize;

import utils;
import communication;


/// Player information
struct Player {
	/// Player nickname
	string nickname;
	/// Next player
	string nextPlayer;
	/// If player ready to play
	bool ready = false;
	/// Connection socket
	Socket socket;
	/// Player color
	string color;
	/// Player roll counter
	int remainingRolls;
	/// If player should have three chances
	bool threeChances = true;
	/// If Player can end a turn
	bool playerCanEndTurn = false;
	/// Player Pawn locations
	string[string] pawns;
}

/// Board field
struct BoardField {
	/// Name of the next field
	string nextField = null;
	/// Yellow next field
	string yellowNextField = null;
	/// Green next field
	string greenNextField = null;
	/// Blue next field
	string blueNextField = null;
	/// Red next field
	string redNextField = null;
}

/// Game settings
struct GameSettings {
	/// Check if game is already started
	bool gameStarted = false;
	/// Table of Players with linked sockets
	Player[string] players;
	/// Number of players that are ready to play
	int readyPlayers = 0;
	/// Current player
	string currentPlayer = "";
	/// Board pieces connections
	BoardField[string] fields;
	/// Roll result
	int rollResult = 0;
}

void main()
{
	GameSettings game_settings;

	/// Yellow base
	game_settings.fields["yellow_base_1"] = BoardField("yellow_start");
	game_settings.fields["yellow_base_2"] = BoardField("yellow_start");
	game_settings.fields["yellow_base_3"] = BoardField("yellow_start");
	game_settings.fields["yellow_base_4"] = BoardField("yellow_start");
	/// Green base
	game_settings.fields["green_base_1"] = BoardField("green_start");
	game_settings.fields["green_base_2"] = BoardField("green_start");
	game_settings.fields["green_base_3"] = BoardField("green_start");
	game_settings.fields["green_base_4"] = BoardField("green_start");
	/// Blue base
	game_settings.fields["blue_base_1"] = BoardField("blue_start");
	game_settings.fields["blue_base_2"] = BoardField("blue_start");
	game_settings.fields["blue_base_3"] = BoardField("blue_start");
	game_settings.fields["blue_base_4"] = BoardField("blue_start");
	/// Red base
	game_settings.fields["red_base_1"] = BoardField("red_start");
	game_settings.fields["red_base_2"] = BoardField("red_start");
	game_settings.fields["red_base_3"] = BoardField("red_start");
	game_settings.fields["red_base_4"] = BoardField("red_start");
	/// Game fields
	game_settings.fields["gray_1"] = BoardField("gray_2");
	/// Green end gate
	game_settings.fields["gray_2"] = BoardField("green_start", null, "green_end_1");
	/// Game fields
	game_settings.fields["green_start"] = BoardField("gray_3");
	game_settings.fields["gray_3"] = BoardField("gray_4");
	game_settings.fields["gray_4"] = BoardField("gray_5");
	game_settings.fields["gray_5"] = BoardField("gray_6");
	game_settings.fields["gray_6"] = BoardField("gray_7");
	game_settings.fields["gray_7"] = BoardField("gray_8");
	game_settings.fields["gray_8"] = BoardField("gray_9");
	game_settings.fields["gray_9"] = BoardField("gray_10");
	game_settings.fields["gray_10"] = BoardField("gray_11");
	/// Red end gate
	game_settings.fields["gray_11"] = BoardField("red_start", null, null, null, "red_end_1");
	/// Game fields
	game_settings.fields["red_start"] = BoardField("gray_12");
	game_settings.fields["gray_12"] = BoardField("gray_13");
	game_settings.fields["gray_13"] = BoardField("gray_14");
	game_settings.fields["gray_14"] = BoardField("gray_15");
	game_settings.fields["gray_15"] = BoardField("gray_16");
	game_settings.fields["gray_16"] = BoardField("gray_17");
	game_settings.fields["gray_17"] = BoardField("gray_18");
	game_settings.fields["gray_18"] = BoardField("gray_19");
	game_settings.fields["gray_19"] = BoardField("gray_20");
	/// Blue end gate
	game_settings.fields["gray_20"] = BoardField("blue_start", null, null, "blue_end_1");
	/// Game fields
	game_settings.fields["blue_start"] = BoardField("gray_21");
	game_settings.fields["gray_21"] = BoardField("gray_22");
	game_settings.fields["gray_22"] = BoardField("gray_23");
	game_settings.fields["gray_23"] = BoardField("gray_24");
	game_settings.fields["gray_24"] = BoardField("gray_25");
	game_settings.fields["gray_25"] = BoardField("gray_26");
	game_settings.fields["gray_26"] = BoardField("gray_27");
	game_settings.fields["gray_27"] = BoardField("gray_28");
	game_settings.fields["gray_28"] = BoardField("gray_29");
	/// Yellow end gate
	game_settings.fields["gray_29"] = BoardField("yellow_start", "yellow_end_1");
	/// Game fields
	game_settings.fields["yellow_start"] = BoardField("gray_30");
	game_settings.fields["gray_30"] = BoardField("gray_31");
	game_settings.fields["gray_31"] = BoardField("gray_32");
	game_settings.fields["gray_32"] = BoardField("gray_33");
	game_settings.fields["gray_33"] = BoardField("gray_34");
	game_settings.fields["gray_34"] = BoardField("gray_35");
	game_settings.fields["gray_35"] = BoardField("gray_36");
	game_settings.fields["gray_36"] = BoardField("gray_1");
	/// Yellow ends
	game_settings.fields["yellow_end_1"] = BoardField("yellow_end_2");
	game_settings.fields["yellow_end_2"] = BoardField("yellow_end_3");
	game_settings.fields["yellow_end_3"] = BoardField("yellow_end_4");
	game_settings.fields["yellow_end_4"] = BoardField();
	/// Green ends
	game_settings.fields["green_end_1"] = BoardField("green_end_2");
	game_settings.fields["green_end_2"] = BoardField("green_end_3");
	game_settings.fields["green_end_3"] = BoardField("green_end_4");
	game_settings.fields["green_end_4"] = BoardField();
	/// Blue ends
	game_settings.fields["blue_end_1"] = BoardField("blue_end_2");
	game_settings.fields["blue_end_2"] = BoardField("blue_end_3");
	game_settings.fields["blue_end_3"] = BoardField("blue_end_4");
	game_settings.fields["blue_end_4"] = BoardField();
	/// Red ends
	game_settings.fields["red_end_1"] = BoardField("red_end_2");
	game_settings.fields["red_end_2"] = BoardField("red_end_3");
	game_settings.fields["red_end_3"] = BoardField("red_end_4");
	game_settings.fields["red_end_4"] = BoardField();

	startServer(game_settings);
}
