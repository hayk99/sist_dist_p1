#fichero del escenario1

import fibonaccis.exe


defmodule Escenario do
	def lunchServer
	def lunchClient(server_name, escenario, dir_server, dir_client) do
		Process.register(self(), :client)
		Node.set_cookie(:cookie)
		Node.connect(dir_server)
		Cliente.cliente({server_name, dir_server}, escenario)
	end
end