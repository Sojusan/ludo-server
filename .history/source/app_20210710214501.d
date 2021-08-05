import std.stdio;
import std.socket;

void main()
{
	const ip = "127.0.0.1";
	const port = 9988;
	writeln("Edit source/app.d to start your project.");
	auto server = new TcpSocket;
	server.blocking = false;
	server.bind(new InternetAddress(ip, port));
	server.listen(2);

	Socket[] clients;
	auto serverSet = new SocketSet;
	auto clientSet = new SocketSet;

	while (true)
	{
		serverSet.reset();
		clientSet.reset();

		serverSet.add(server);
		if (clients)
		{
			foreach (client; clients)
			{
				clientSet.add(client);
			}
		}

		auto serverResult = Socket.select(serverSet, null, null);

		if (serverResult > 0)
		{
			auto client = server.accept();

			if (client)
			{
				clients ~= client;
			}
		}

		auto clientResult = Socket.select(clientSet, null, null);

		if (clientSet < 1)
		{
		continue;
		}
	}
}
