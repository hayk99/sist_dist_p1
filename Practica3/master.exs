defmodule Master do

	def startMaster(master_ip) do
		Node.start master_ip
		Process.register(self(), :master)
		Node.set_cookie(master_ip, :sisdist)
		spawn(Master, :comEsperarPet, [nil, nil, nil, :"master@127.0.0.1"])
		master(nil, nil, nil, {:master, :"master@127.0.0.1"})
	end
	def startMaster() do
		Node.start :"master@127.0.0.1"
		Process.register(self(), :master)
		Node.set_cookie(:"master@127.0.0.1", :sisdist)
		spawn(Master, :comEsperarPet, [nil, nil, nil, :"master@127.0.0.1"])
		master(nil, nil, nil, {:master, :"master@127.0.0.1"})
	end


   	def master(workerSum, workerDivs, workerSumList, master_ip) do
	    IO.puts "Comenzando iteracion master"
		receive do
			{pidCLT, :calculaAmigos, min, max} -> 	IO.puts "Me ha llegado una peticion de un cliente"
												   #send(pidCLT, {:amigos, calculaAmigos(min, max, workerSum, workerDivs, workerSumList, :primario, master_ip)})
													send({:hiloMaster, Node.self}, {:amigos, pidCLT, min, max})
												  	master(workerSum, workerDivs, workerSumList, master_ip)
			{:soyLider, not_interested_in_this, {type, dir}} -> IO.puts "Ha habido un cambio de lider"
																case type do
																	:suma ->IO.puts "Se ha cambiado el lider de los workers de suma" 
																			send({:hiloMaster, Node.self}, {:primWS, {type, dir}})
																			master({type, dir},  workerDivs, workerSumList, master_ip)
																			
																	:divisores -> 	IO.puts "Se ha cambiado el lider de los workers de divisores"
																					send({:hiloMaster, Node.self}, {:primD, {type, dir}})
																					master(workerSum, {type, dir}, workerSumList, master_ip)
																				
																	:sumaLista -> IO.puts "Se ha cambiado el lider de los workers de suma de lista"
																				send({:hiloMaster, Node.self}, {:primSM, {type, dir}})
																				master(workerSum, workerDivs, {type, dir}, master_ip)		
																	_ -> IO.puts "tipo no reconocido"
																end
		end
		
   	end 

	def calcularAmigo3(min, max, sum, workerSum, workerDivs, workerSumList, master_ip, nTries) do
		if nTries < 3 do
			if (min < sum) && (sum <= max) do
				#dejamos al protocolo de interaccion que hable con los
				#workers para calcular la suma, y la comparamos con min
				#para saber si tiene una pareja amiga
				IO.puts "coprobando amigo"
				result1 = InteractionProtocol.sendIterationPrimary(master_ip, workerSum, sum, 0)
				if elem(result1, 0) == :fallo do
					result1 = InteractionProtocol.sendIterationSecundary(master_ip, workerDivs, workerSumList, sum, 0)
					if elem(result1, 0) == :fallo do
						calcularAmigo3(min, max, sum, workerSum, workerDivs, workerSumList, master_ip, nTries+1)
					else
						elem(result1, 1) == min
					end
				else 
					elem(result1, 1) == min
				end
			else
				false
			end
		else 
			nil
		end
	end

	def calculaAmigos2(min, max, workerSum, workerDivs, workerSumList, master_ip, nTries) do
		IO.puts "CalculandoAmigos2"
		receive do
				{:primWS, w} -> calculaAmigos2(min, max, w, workerDivs, workerSumList, master_ip, nTries)
				{:primD, w} -> calculaAmigos2(min, max, workerSum, w, workerSumList, master_ip, nTries)
				{:primSM, w} -> calculaAmigos2(min, max, workerSum, workerDivs, w, master_ip, nTries)
		after 10 -> true
			#no bloqueante
		end
		if min == max do
			[]
		else
			if nTries < 3 do
				IO.inspect(min,label: "Realizando calculo para numero")
				result1 = InteractionProtocol.sendIterationPrimary(master_ip, workerSum, min, 0)
				if elem(result1, 0) == :fallo do
					result1 = InteractionProtocol.sendIterationSecundary(master_ip, workerDivs, workerSumList, min, 0)
					IO.inspect(result1, label: "result1")
					if elem(result1, 0) == :fallo do
							IO.puts "reintentar conexion"
							calculaAmigos2(min, max, workerSum, workerDivs, workerSumList, master_ip, nTries+1)
					else
						tiene = calcularAmigo3(min, max, elem(result1, 1), workerSum, workerDivs, workerSumList, master_ip, 0)
						if tiene == nil do
							nil
						else 
							if (tiene) do
								IO.inspect([{min, elem(result1,1)}], label: "Pareja de amigos encontrada: ")
								[{min, elem(result1,1)}] ++ calculaAmigos2(min + 1, max, workerSum, workerDivs, workerSumList, master_ip,0)
							else
								calculaAmigos2(min + 1, max, workerSum, workerDivs, workerSumList, master_ip,0) 
							end
						end
					end
				else 
					IO.inspect(result1, label: "result1")
					if elem(result1, 0) == :fallo do
							IO.puts "reintentar conexion"
							calculaAmigos2(min, max, workerSum, workerDivs, workerSumList, master_ip, nTries+1)
					else
						tiene = calcularAmigo3(min, max, elem(result1, 1), workerSum, workerDivs, workerSumList, master_ip, 0)
						if tiene == nil do
							nil
						else 
							if (tiene) do
								IO.inspect([{min, elem(result1,1)}], label: "Pareja de amigos encontrada: ")
								[{min, elem(result1,1)}] ++ calculaAmigos2(min + 1, max, workerSum, workerDivs, workerSumList, master_ip,0)
							else
								calculaAmigos2(min + 1, max, workerSum, workerDivs, workerSumList, master_ip,0) 
							end
						end
					end
				end
			else 
				IO.puts "Fallo en la primera request"
				nil
			end
		end
	end

	def calculaAmigos(min, max, workerSum, workerDivs, workerSumList, executionMode, master_ip) do
		if(min < max) do
			#nos devuelven la tupla que contiene el ultimo protocolo de interaccion valido, asi como la suma
			#En la siguiente llamada a calculaAmigos, usaremos el nuevo protocolo de interaccion para evitar
			#un timeout del protocolo de interaccion primario
			IO.inspect(min,label: "Realizando calculo para numero")
			result = InteractionProtocol.sendRequest(master_ip, workerSum, workerDivs, workerSumList, min, executionMode)
			if elem(result, 0) == :fallo do
				IO.puts "Fallo en la primera request"
				nil
			else
				resultHasFriend = tieneAmigo(min, max, elem(result,1), workerSum, workerDivs, workerSumList, elem(result,0), master_ip)
				if resultHasFriend == nil do
					IO.puts "Fallo en tieneAmigo"
					nil
				else
					if(resultHasFriend) do
						IO.inspect([{min, elem(result,1)}], label: "Pareja de amigos encontrada: ")
						[{min, elem(result,1)}] ++ calculaAmigos(min+1, max, workerSum, workerDivs, workerSumList, elem(result,0), master_ip) 
					else
						calculaAmigos(min+1, max, workerSum, workerDivs, workerSumList, elem(result,0), master_ip) 
					end
				end
			end
		else
			[]
		end
	end


	def tieneAmigo(min, max, sum, workerSum, workerDivs, workerSumList, executionMode, master_ip) do
		if (min < sum) && (sum <= max) do
			#dejamos al protocolo de interaccion que hable con los
			#workers para calcular la suma, y la comparamos con min
			#para saber si tiene una pareja amiga
			result = InteractionProtocol.sendRequest(master_ip, workerSum, workerDivs, workerSumList, sum, executionMode)
			if elem(result, 0) == :fallo do
				nil
			else
				elem(result, 1) == min
			end
		else
			false
		end
	end

	def comEsperarPet(workerSum, workerDivs, workerSumList, master_ip) do
		Process.register(self(), :hiloMaster)
		esperarPet(workerSum, workerDivs, workerSumList, master_ip)
	end
	def esperarPet(workerSum, workerDivs, workerSumList, master_ip) do
		IO.puts "esperando peticiones"
		receive do
			{:amigos, pidCLT, min, max} -> IO.puts "Peticion recibida en hilo secundario"
										send(pidCLT, {:amigos, calculaAmigos2(min, max, workerSum, workerDivs, workerSumList, {:hiloMaster, master_ip}, 0)})
			{:primWS, w} -> IO.puts "workerWS recibido"
							esperarPet(w, workerDivs, workerSumList, master_ip)
			{:primD, w} -> IO.puts "workerWS recibido"
							esperarPet(workerSum, w, workerSumList, master_ip)
			{:primSM, w} -> IO.puts "workerWS recibido"
							esperarPet(workerSum, workerDivs, w, master_ip)
			otro -> IO.inspect(otro, label: "mensaje no entendido")
					esperarPet(workerSum, workerDivs, workerSumList, master_ip)
		
		end
	end
end