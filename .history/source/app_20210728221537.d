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

/// Board piece
struct BoardField {
	/// Name of the next field
	string nextField;
	/// Yellow next field
	string yellowNextField;
	/// Green next field
	string greenNextField;
	/// Blue next field
	string blueNextField;
	/// Red next field
	string redNextField;
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
	BoardPiece[string] fields;
}


void main()
{
	GameSettings game_settings;
	startServer(game_settings);
}
