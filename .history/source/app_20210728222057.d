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
	/// If player ready to play
	bool ready = false;
	/// Connection socket
	Socket socket;
	/// Player color
	string color;
	/// Player roll counter
	int remainingRolls;
	/// If Player has moved a Pawn
	bool playerMovedPawn = false;
	/// If Player can end a turn
	bool playerCanEndTurn = false;
	/// Player PAwn locations
	string[string] pawns;
}

/// Board field
struct BoardField {
	/// Name of the next field
	string nextField;
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
}


void main()
{
	GameSettings game_settings;

	/// Yellow base
	game_settings.fields["yellow_base_1"].nextField = "yellow_start";
	game_settings.fields["yellow_base_2"].nextField = "yellow_start";
	game_settings.fields["yellow_base_3"].nextField = "yellow_start";
	game_settings.fields["yellow_base_4"].nextField = "yellow_start";
	/// Green base
	game_settings.fields["green_base_1"].nextField = "green_start";
	game_settings.fields["green_base_2"].nextField = "green_start";
	game_settings.fields["green_base_3"].nextField = "green_start";
	game_settings.fields["green_base_4"].nextField = "green_start";
	/// Blue base
	game_settings.fields["blue_base_1"].nextField = "blue_start";
	game_settings.fields["blue_base_2"].nextField = "blue_start";
	game_settings.fields["blue_base_3"].nextField = "blue_start";
	game_settings.fields["blue_base_4"].nextField = "blue_start";
	/// Red base
	game_settings.fields["red_base_1"].nextField = "red_start";
	game_settings.fields["red_base_2"].nextField = "red_start";
	game_settings.fields["red_base_3"].nextField = "red_start";
	game_settings.fields["red_base_4"].nextField = "red_start";
	/// Game fields
	game_settings.fields["gray_1"].nextField = "gray_2";
	game_settings.fields["gray_2"].nextField = "gray_2";

	startServer(game_settings);
}
