defmodule Servidores do
	
	def arrancar1(direccion) do
		Node.start String.to_atom("servidor@" <> direccion)
		Process.register(self(), :server)
		Perfectos.servidor()
	end

	def arrancar2(direccion) do
		Node.start String.to_atom("servidor@" <> direccion)
		Process.register(self(), :server)
		Perfectos.servidorConcurrente()
	end

	def arrancarWorker(nombre, direccion) do
		Node.start String.to_atom(nombre <> "@" <> direccion)
		Process.register(self(), String.to_atom(nombre))
		IO.puts("Conectado")
		Node.connect(String.to_atom("servidor@" <> direccion))
		Perfectos.servidorConcurrente()
	end

	def itera(maquina, hilo) do
		n = "w" <> to_string maquina
		receive do
      		{pid, :perfectos} -> send({String.to_atom(n), String.to_atom( n <> "@127.0.0.1")}, {pid, :perfectos})			
		end
		if hilo + 1 > System.schedulers do
			if maquina + 1 > 3 do
				itera(1, 1)
			else
				itera(maquina+1,1)
			end
		else
			itera(maquina, hilo + 1)
		end 
	end
	
	def arrancar3(direccion) do
		Node.start String.to_atom("servidor@" <> direccion)
		Process.register(self(), :server)
		itera(1,1)
	end

	def arrancarWorker4(nombre, direccionServidor, direccion) do
		Node.start String.to_atom(nombre <> "@" <> direccion)
		Process.register(self(), String.to_atom(nombre))
		IO.puts("Conectado")
		Node.connect(String.to_atom("servidor@" <> direccion))
		Perfectos.servidorWorker()
	end

	#Modifica la lista de procesos terminados para reducir el numero de procesos
	#que faltan si hubiere llegado una respuesta de algun worker, o para eliminar
	#por completo, y asi liberar memoria, si se sabe que el ultimo worker dedicado
	#a id_peticion ha terminado

	def resolver_peticion({id, num}, cola, id_peticion, pid, msg) do
		if id == id_peticion do
			if num == 1 do
				IO.inspect(id_peticion, label: "Mensaje Borrado ")
				cola
			else 
				IO.inspect(id_peticion, label: "Mensaje Descartado ")
				[{id, num-1}] ++ cola
			end
		else
			if cola == [] do
				send(pid, msg)
				[{id, num},{id_peticion, 2}]
			else
				[{id,num}] ++ resolver_peticion(hd(cola), tl(cola), id_peticion, pid, msg)
			end
		end
	end


	#Atiende las peticiones de los clientes y las replica tres veces, cada replicacion en un worker distinto
	def atender_cliente(pid_rrw, i, id) do
		#IO.puts("Escuchando clientes")
		n = "w" <> to_string i
		n2 = "w" <> to_string i+1
		n3 = "w" <> to_string i+2
		receive do
      		{pid, :perfectos} -> #IO.puts("Peticion recibida de ")
			  					send({String.to_atom(n), String.to_atom( n <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos})
			  					send({String.to_atom(n2), String.to_atom( n2 <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos})
								send({String.to_atom(n3), String.to_atom( n3 <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos})			 	
			{pid, :perfectos_ht} ->	#IO.puts("Peticion recibida de ")
								send({String.to_atom(n), String.to_atom( n <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos_ht})
								send({String.to_atom(n2), String.to_atom( n2 <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos_ht})
								send({String.to_atom(n3), String.to_atom( n3 <> "@127.0.0.1")}, {pid_rrw, pid, id, :perfectos_ht})			 	
		end
		#round robin que selecciona el siguiente grupo de workers al que mandar la peticion del proximo cliente
		i = if i+3 > 9 do
			1
		else
			i+3
		end
		#llamada recursiva para atender al siguiente cliente
		atender_cliente(pid_rrw, i, id+1)
	end

	def atender_workers(listaPendientes) do
		receive do
      		{pid, id, tex, lista_perfectos} -> 	if listaPendientes == [] do
													send(pid, {tex, lista_perfectos})
													atender_workers([{id, 2}])
												else
													atender_workers(resolver_peticion(hd(listaPendientes), tl(listaPendientes), id, pid, {tex, lista_perfectos}))
												end
		end
	end

	def arrancar4(direccion) do
		Node.start String.to_atom("servidor@" <> direccion)
		Process.register(self(), :server)
		IO.puts("Servidor conectado")
		pid_rrw = spawn(Servidores, :atender_workers, [[]])
		IO.puts("Servidor escuchando workers")
		atender_cliente(pid_rrw, 1, 1)
	end

	def arrancarCliente(server_name, escenario, dirServer, dirCliente) do
		Node.start String.to_atom("cliente@" <> dirCliente)
		Process.register(self(), :cliente)
		Node.set_cookie(:sisdist)
		pid = Node.connect(String.to_atom("servidor@" <> dirServer))
	#	Perfectos_cliente.cliente({server_name, String.to_atom("servidor@" <> dirServer)}, escenario, dirServer)
	end
end