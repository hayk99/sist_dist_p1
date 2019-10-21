#fichero del escenario1

import fibonaccis.exe

defmodule servidor do
	def request (pid, op, lista) do
		Node.fibonacci()


end

defmodule Escenario1 do
	def lunchClient(server_name, escenario, dir_server, dir_client)
	Process.register(self(), :client)
	Node.set_cookie(:cookie)
	Node.connect(dir_server)
	Cliente.cliente({server_name, dir_server}, escenario)
	