defmodule Master do

	def startMaster(master_ip) do
		Node.start master_ip
		Process.register(self(), :master)
		Node.set_cookie(master_ip, :sisdist)
		master(nil, nil, nil, {:master, master_ip})
	end
	def startMaster() do
		Node.start :"master@127.0.0.1"
		Process.register(self(), :master)
		Node.set_cookie(:"master@127.0.0.1", :sisdist)
		master(nil, nil, nil, {:master, :"master@127.0.0.1"})
	end


   	def master(workerSum, workerDivs, workerSumList, master_ip) do
	    IO.puts "Comenzando iteracion master"
		receive do
			{pidCLT, :calculaAmigos, min, max} -> 	IO.puts "Me ha llegado una peticion de un cliente"
													send(pidCLT, {:amigos, calculaAmigos(min, max, workerSum, workerDivs, workerSumList, :primario, master_ip)})
												  	master(workerSum, workerDivs, workerSumList, master_ip)
			{:newWorker,{type, dir}} ->  case type do
											:suma -> if (workerSum == nil) do
														IO.puts "Primer worker de suma total conectado, es primary"
														send({type, dir}, {:eresPrimary, 0})
														master({type, dir}, workerDivs, workerSumList, master_ip)
													 else
													 	IO.puts "Worker de suma total conectado"
													 	send({type, dir}, {:primary, workerSum})
														master(workerSum, workerDivs, workerSumList, master_ip)	
													 end
											:divisores -> if (workerDivs == nil) do
														IO.puts "Primer worker de calculo de divisores conectado, es primary"
														send({type, dir}, {:eresPrimary, 0})
														master(workerSum, {type, dir}, workerSumList, master_ip)
													 else
													 	IO.puts "Worker de calculo de divisores conectado"
													 	send({type, dir}, {:primary, workerDivs})
														master(workerSum, workerDivs, workerSumList, master_ip)	
													 end
											:sumList -> if (workerSumList == nil) do
														IO.puts "Primer worker de suma de lista conectado, es primary"
														send({type, dir}, {:eresPrimary, 0})
														master(workerSum, workerDivs, {type, dir}, master_ip)
													 else
													 	IO.puts "Worker de suma de lista conectado"
													 	send({type, dir}, {:primary, workerSumList})
														master(workerSum, workerDivs, workerSumList, master_ip)	
													 end
										 end
			{:soyLider, not_interested_in_this, {type, dir}} -> IO.puts "Ha habido un cambio de lider"
																case type do
																	:suma ->IO.puts "Se ha cambiado el lider de los workers de suma" 
																			master({type, dir}, workerDivs, workerSum, master_ip)
																			
																	:divisores -> 	IO.puts "Se ha cambiado el lider de los workers de divisores"
																					master(workerSum, {type, dir}, workerSum, master_ip)
																				
																	:sumList -> IO.puts "Se ha cambiado el lider de los workers de suma de lista"
																				master(workerSum, workerDivs, {type, dir}, master_ip)		
																end
		end
		
   	end 

	def calculaAmigos(min, max, workerSum, workerDivs, workerSumList, executionMode, master_ip) do
		if(min < max) do
			#nos devuelven la tupla que contiene el ultimo protocolo de interaccion valido, asi como la suma
			#En la siguiente llamada a calculaAmigos, usaremos el nuevo protocolo de interaccion para evitar
			#un timeout del protocolo de interaccion primario
			result = InteractionProtocol.sendRequest(master_ip, workerSum, workerDivs, workerSumList, min, executionMode)
			if elem(result, 0) == :fallo do
				nil
			else
				resultHasFriend = tieneAmigo(min, max, elem(result,1), workerSum, workerDivs, workerSumList, elem(result,0), master_ip)
				if resultHasFriend == nil do
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
		end
	end
	def tieneAmigo(min, max, sum, workerSum, workerDivs, workerSumList, executionMode, master_ip) do
		if (min < sum) && (sum <= max) do
			#dejamos al protocolo de interaccion que hable con los
			#workers para calcular la suma, y la comparamos con min
			#para saber si tiene una pareja amiga
			result = InteractionProtocol.sendRequest(master_ip, workerSum, workerDivs, workerSumList, min, executionMode)
			if elem(result, 0) == :fallo do
				nil
			else
				elem(result, 1) == min
			end
		else
			false
		end
	
	end
end