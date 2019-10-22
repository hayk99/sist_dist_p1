#fichero del escenario1


defmodule Escenario do
	def lunchServer (dirs) do
		Process.register(self(), :server)
		Node.set_cookie(self(), :galleta)
		IO.puts("Server is up")
		Server.server()
	end
	def lunchClient(server_name, escenario, dir_server, dir_client) do
		Process.register(self(), :client)
		Node.set_cookie(Node.self(),:galleta)
		Node.connect(dir_server)
		Cliente.cliente({server_name, dir_server}, escenario)
	end
end