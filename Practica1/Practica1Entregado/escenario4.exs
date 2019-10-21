#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 22 de Octubre de 2018
# DESCRIPCION: Modulo Escenario 4

defmodule EscenarioCuatro do

	def servidorWorker() do
      receive do
        {pid_rrw, pid, id, :perfectos_ht} ->  IO.puts "Peticion recibida"
					time1 = :os.system_time(:millisecond)
                      if :rand.uniform(100)>60, do: Process.sleep(round(:rand.uniform(100)/100 * 2000))
                  perfectos = Perfectos.encuentra_perfectos({1, 10000})
                  time2 = :os.system_time(:millisecond)
				  IO.inspect(pid_rrw)
                  send(pid_rrw, {pid, id, time2 - time1, perfectos})
		_ -> IO.puts ("Error al recibir parametros en Worker")
      end    
      servidorWorker()
  	end

	def arrancarWorker(nombre, direccion, direccion_server, n) do
		a = String.to_atom(to_string(n) <> nombre)
		Process.register(self(), a)
		send({:server, direccion_server}, {{a, Node.self()}, :soyWorker})
		IO.puts("Conectado " <> nombre <> to_string(n))
		if n > 0 do
			spawn(EscenarioCuatro, :arrancarWorker, [nombre, direccion, direccion_server, n-1])
		end
		servidorWorker()
	end

	def arrancarWorker(nombre, direccion, direccion_server) do
		IO.puts("Soy " <> nombre <> "@" <> direccion)
		Node.start String.to_atom(nombre <> "@" <> direccion)
		Node.set_cookie(:sisdist)
		Node.connect(direccion_server)
		Process.register(self(), String.to_atom(nombre <> to_string System.schedulers))
		#IO.puts(direccion_server)
		IO.puts "conectado"
		spawn(EscenarioCuatro, :arrancarWorker, [nombre, direccion, direccion_server, System.schedulers-1])
		send({:server, direccion_server}, {{String.to_atom(nombre), Node.self()}, :soyWorker})
		servidorWorker()
	end

	#Modifica la lista de procesos terminados para reducir el numero de procesos
	#que faltan por responder o para elimina si no falta ningun proceso por contestar
	#si la peticion no se halla en la cola o en {id}, se enviara un mensaje al cliente con el 
	#resultado de la ejecucion y se añade a la cola como pendiente de eliminar repetidos

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
				IO.inspect(pid, label: "Tratando Mensaje de")
				send(pid, msg)
				[{id, num},{id_peticion, 2}]
			else
				[{id,num}] ++ resolver_peticion(hd(cola), tl(cola), id_peticion, pid, msg)
			end
		end
	end


	def gestionarPeticiones(pid_rrw, pid, id, listaWorkers, n) do
		IO.inspect(hd(listaWorkers))
		send(hd(listaWorkers), {pid_rrw, pid, id, :perfectos_ht})
		
		if n > 0 do
			gestionarPeticiones(pid_rrw, pid, id, tl(listaWorkers) ++ [hd(listaWorkers)],n-1)
		else
			listaWorkers
		end
	end

#Atiende las peticiones de los clientes y las replica tres veces, cada replicacion en un worker distinto
#num workers debe ser multiplo de tres ya que la carga de trabajo se replica en tres workers distintos
	def atender_cliente(pid_rrw, id, listaWorkers) do
		receive do
      		{pid, :perfectos_ht} -> IO.puts "Peticion Recibida al master" 
			  					atender_cliente(pid_rrw,  id+3, gestionarPeticiones(pid_rrw, pid, id, listaWorkers, 2))
			  					# send({String.to_atom(n2), String.to_atom( n2 <> "@" <> direccion_workers)}, {pid_rrw, pid, id, :perfectos})
								# send({String.to_atom(n3), String.to_atom( n3 <> "@" <> direccion_workers)}, {pid_rrw, pid, id, :perfectos})			 	
			{pid, :soyWorker} -> IO.inspect(pid, label: "Añadiendo worker")
				if listaWorkers == [] do
					atender_cliente(pid_rrw, id, [pid])
				else
					atender_cliente(pid_rrw, id, [pid] ++ listaWorkers)
				end
								
		end
	end

	def atender_workers(listaPendientes) do
		receive do
      		{pid, id, tex, lista_perfectos} -> 	IO.puts "consulta finalizada"
			  									if listaPendientes == [] do
													send(pid, {tex, lista_perfectos})
IO.puts "enviada con cola vacia"
													atender_workers([{id, 2}])
												else
IO.puts "Entrar en resolver peticion"
													atender_workers(resolver_peticion(hd(listaPendientes), tl(listaPendientes), id, pid,{tex, lista_perfectos}))
												end
			_ -> IO.puts ("Error al recibir parametros en RRW")
		end
	end

	#Registrar Proceso
	def atender_workers() do
		Process.register(self(), :rrw)
		atender_workers([])
	end

	def arrancar(direccion, direccion_workers) do
		Node.start direccion
		Process.register(self(), :server)
		Node.set_cookie(:sisdist)
		spawn(EscenarioCuatro, :atender_workers, [])
		atender_cliente({:rrw, Node.self()}, 1, [])
	end
end