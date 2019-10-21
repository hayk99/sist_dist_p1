#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 18 de Octubre de 2018
# DESCRIPCION: Modulo Escenario 3

defmodule EscenarioTres do
	# Pone en funcionamiento un worker que mandará su {registro, direccion} al master
	# y se pondrá a la escucha
	def arrancarWorker(nombre, direccion, direccion_servidor) do
		IO.puts("Soy " <> nombre <> "@" <> direccion)
		Node.start String.to_atom(nombre <> "@" <> direccion)
		Process.register(self(), String.to_atom(nombre))
		Node.set_cookie(:sisdist)
		Node.connect(direccion_servidor)
		IO.puts("Conectado")
		send({:server, direccion_servidor}, {{String.to_atom(nombre), Node.self()}, System.schedulers,:soyWorker})
		Perfectos.servidorConcurrente()
	end

	#Cuando recibe un mensaje de un cliente, habrá mandado a un worker con al menos 1 hilo
	#disponible para procesar la peticion
	#
	#Cuando recibe un mensaje de un worker, este se habrá añadido en listaWorker con el numero
	# de hilos disponibles
	def repartir_carga(maquina, hilo, listaWorkers, turnoMaster) do
		IO.inspect(maquina, label: "maquina a ejecutar")
		receive do
	  		{pid, :perfectos} -> cond do
									turnoMaster > (System.schedulers - 2) ->
										IO.inspect(maquina, label: "Enviando a")
										IO.inspect(listaWorkers, laber: "Workers")
										send(maquina, {pid, :perfectos})	
										if hilo == 1 do
											listaWorkers = tl(listaWorkers) ++ [hd(listaWorkers)]
											{maquina, hilo} = hd(listaWorkers)
											repartir_carga(maquina,hilo, listaWorkers, turnoMaster-1)
										else
											repartir_carga(maquina,hilo-1, listaWorkers, turnoMaster-1)
										end

									turnoMaster == 0 ->
										spawn(fn ->
                    						time1 = :os.system_time(:millisecond)
      										perfectos = Perfectos.encuentra_perfectos({1, 10000})
      										time2 = :os.system_time(:millisecond)    
      										send(pid, {time2 - time1, perfectos})
                    					end)
										repartir_carga(maquina, hilo, listaWorkers, System.schedulers*2)


									true ->
										spawn(fn ->
                    						time1 = :os.system_time(:millisecond)
      										perfectos = Perfectos.encuentra_perfectos({1, 10000})
      										time2 = :os.system_time(:millisecond)    
      										send(pid, {time2 - time1, perfectos})
                    					end)
										repartir_carga(maquina, hilo, listaWorkers, turnoMaster-1)
								end
			{pid, numHilos,:soyWorker} -> IO.inspect(pid, label: "Añadiendo worker")
							if listaWorkers == [] do
								repartir_carga(pid, numHilos, [{pid,numHilos}], turnoMaster)
							else
								repartir_carga(maquina, hilo, [{pid,numHilos}] ++ listaWorkers, turnoMaster)
							end
								
		end
	end

	# Levanta el Master generando un nuevo nodo
	def arrancar(direccion, direccion_worker) do
		Node.start direccion #:"servidor@127.0.0.1"
		Process.register(self(), :server)
		Node.set_cookie(:sisdist)
		repartir_carga(1, 1, [],1)
	end
end