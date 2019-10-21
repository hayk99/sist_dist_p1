#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 15 de Octubre de 2018
# DESCRIPCION: Modulo Escenario 1

defmodule EscenarioUno do
	def arrancar(direccion) do
		Node.start direccion
		Process.register(self(), :server)
		Node.set_cookie(:sisdist)
		IO.puts("Servidor arriba con direccion " <> to_string direccion)
		Perfectos.servidor()
	end

	def arrancarCliente(server_name, escenario, direccion, direccion_server) do
		Node.start direccion
		Process.register(self(), :cliente)
		Node.set_cookie(:sisdist)
		Node.connect(direccion_server)
		Perfectos_cliente.cliente({server_name, direccion_server}, escenario ) #:"servidor@127.0.0.1"
	end
end