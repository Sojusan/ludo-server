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
	/// If Player has moved a Pawn
	bool playerMovedPawn = false;
	/// If Player can end a turn
	bool playerCanEndTurn = false;
	/// Player Pawn locations
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
	/// Roll result
	int rollResult = 0;
}


void main()
{
	GameSettings game_settings;

	/// Yellow base
	game_settings.fields["yellow_base_1"].nextField = BoardField("yellow_start";
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
	/// Green end gate
	game_settings.fields["gray_2"].nextField = "green_start";
	game_settings.fields["gray_2"].greenNextField = "green_end_1";
	/// Game fields
	game_settings.fields["green_start"].nextField = "gray_3";
	game_settings.fields["gray_3"].nextField = "gray_4";
	game_settings.fields["gray_4"].nextField = "gray_5";
	game_settings.fields["gray_5"].nextField = "gray_6";
	game_settings.fields["gray_6"].nextField = "gray_7";
	game_settings.fields["gray_7"].nextField = "gray_8";
	game_settings.fields["gray_8"].nextField = "gray_9";
	game_settings.fields["gray_9"].nextField = "gray_10";
	game_settings.fields["gray_10"].nextField = "gray_11";
	/// Red end gate
	game_settings.fields["gray_11"].nextField = "red_start";
	game_settings.fields["gray_11"].redNextField = "red_end_1";
	/// Game fields
	game_settings.fields["red_start"].nextField = "gray_12";
	game_settings.fields["gray_12"].nextField = "gray_13";
	game_settings.fields["gray_13"].nextField = "gray_14";
	game_settings.fields["gray_14"].nextField = "gray_15";
	game_settings.fields["gray_15"].nextField = "gray_16";
	game_settings.fields["gray_16"].nextField = "gray_17";
	game_settings.fields["gray_17"].nextField = "gray_18";
	game_settings.fields["gray_18"].nextField = "gray_19";
	game_settings.fields["gray_19"].nextField = "gray_20";
	/// Blue end gate
	game_settings.fields["gray_20"].nextField = "blue_start";
	game_settings.fields["gray_20"].blueNextField = "blue_end_1";
	/// Game fields
	game_settings.fields["blue_start"].nextField = "gray_21";
	game_settings.fields["gray_21"].nextField = "gray_22";
	game_settings.fields["gray_22"].nextField = "gray_23";
	game_settings.fields["gray_23"].nextField = "gray_24";
	game_settings.fields["gray_24"].nextField = "gray_25";
	game_settings.fields["gray_25"].nextField = "gray_26";
	game_settings.fields["gray_26"].nextField = "gray_27";
	game_settings.fields["gray_27"].nextField = "gray_28";
	game_settings.fields["gray_28"].nextField = "gray_29";
	/// Yellow end gate
	game_settings.fields["gray_29"].nextField = "yellow_start";
	game_settings.fields["gray_29"].yellowNextField = "yellow_end_1";
	/// Game fields
	game_settings.fields["yellow_start"].nextField = "gray_30";
	game_settings.fields["gray_30"].nextField = "gray_31";
	game_settings.fields["gray_31"].nextField = "gray_32";
	game_settings.fields["gray_32"].nextField = "gray_33";
	game_settings.fields["gray_33"].nextField = "gray_34";
	game_settings.fields["gray_34"].nextField = "gray_35";
	game_settings.fields["gray_35"].nextField = "gray_36";
	game_settings.fields["gray_36"].nextField = "gray_1";
	/// Yellow ends
	game_settings.fields["yellow_end_1"].nextField = "yellow_end_2";
	game_settings.fields["yellow_end_2"].nextField = "yellow_end_3";
	game_settings.fields["yellow_end_3"].nextField = "yellow_end_4";
	/// Green ends
	game_settings.fields["green_end_1"].redNextField = "green_end_2";
	game_settings.fields["green_end_2"].redNextField = "green_end_3";
	game_settings.fields["green_end_3"].redNextField = "green_end_4";
	/// Blue ends
	game_settings.fields["blue_end_1"].redNextField = "blue_end_2";
	game_settings.fields["blue_end_2"].redNextField = "blue_end_3";
	game_settings.fields["blue_end_3"].redNextField = "blue_end_4";
	/// Red ends
	game_settings.fields["red_end_1"].redNextField = "red_end_2";
	game_settings.fields["red_end_2"].redNextField = "red_end_3";
	game_settings.fields["red_end_3"].redNextField = "red_end_4";

	startServer(game_settings);
}