import std.stdio;
import std.socket;

void main()
{
	const ip = "127.0.0.1";
	const port = 9988;
	writeln("Edit source/app.d to start your project.");
	auto server = new TcpSocket;
	server.blocking = false;
	server.bind(new Internet)
}
