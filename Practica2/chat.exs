# AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 5 de Noviembre de 2018
# DESCRIPCION: Modulo de Chat con Richard-Agrawala


defmodule Chat do

	def sharedDB(variables) do

		receive do
									
					#Acceso a CS = true, actualizar numero secuencia, reiniciar replys
			{:waitInitME, pidT} -> 	Map.update!(variables, :Requesting_Critical_Section, &(&1 = true))
									Map.update!(variables, :Our_Sequence_Number, &(&1 = variables[:Highest_Sequence_Number] + 1))
									send(pidT, {:ack, variables[:Our_Sequence_Number]})
					
					#Marca que se ha salido de la seccion critica y envia la lista de nodos a contestar                           
			:SaliendoEM -> Map.update!(variables, :Requesting_Critical_Section, &(&1 = false))
							send({:IME,Node.self()}, {:defer, variables[:Reply_Deferred_List]})

		  		#Envia Flase si pidReq tiene mayor prioridad
				  #Envia True si pidReq tiene menor prioridad y se almacena pidReq en Reply_Deferred_List
				  #	para contestar mas tarde
			{:waitRquest, pidReq, numSeqReq, idReq} -> if variables[:Highest_Sequence_Number] < numSeqReq do
														Map.update!(variables, :Highest_Sequence_Number, &(&1 = numSeqReq))
													end
													if checkDeferIt(variables, numSeqReq, idReq) do
														Map.update!(variables, :Reply_Deferred_List, &(&1 = variables[:Reply_Deferred_List] ++ [pidReq]))
														send({:ReqProcess, Node.self()}, :ackTrue)
													else
														send({:ReqProcess, Node.self()}, :ackFalse)
													end
		end

		sharedDB(variables)
	end

	def invokeMutualExclusion(me,listNodos, msg) do
		#TODO: darle una pensada a esto
		send({:sDB, Node.self()}, {:waitInitME, {:IME, Node.self()}})
		send({:pidReply, Node.self()}, :resetNumNodos)
		receive do
			{:ack, seqNum} -> Enum.each(listNodos, 
										fn x ->  if x != Node.self() do
											send({:ReqProcess, x}, 
												{:request,me, Node.self(),seqNum})
											end end)
		end
		
		#Waitfor + envio de mensaje
		receive do                      
			:Continue -> Enum.each(listNodos, fn x ->#if x != Node.self() do
														 	send({:showMSG, x}, {:msg, msg})
														 end
														 # end
														 )
		end
		# Finalizar la exclusion mutua
		send({:sDB, Node.self()}, :SaliendoEM)
		
		#contestar a pendientes
		receive do
			{:defer, deferred_List} -> Enum.each(deferred_List, fn x -> send({:pidReply, x}, :reply) end)
		end
	end

	# lee de consola un mensaje y lo envia a otros nodos
	def chatInput(me, listNodos) do
		invokeMutualExclusion(me, listNodos, IO.gets "/>")
		chatInput(me, listNodos)
	end

	# consume una lista de mensajes. Puede quedarse dormido entre envio y envio
	def chatInput(me, listNodos, msgs) do
		if msgs != [] do
			Process.sleep(round(:rand.uniform(100)/100 * 1000))	
			invokeMutualExclusion(me, listNodos, hd msgs)
			chatInput(me, listNodos, tl msgs)
		else
			chatInput(me, listNodos)
		end
	end

	# devuelve quien tiene mas prioridad
	def checkDeferIt(variables, numSeqReq, idReq) do
		(variables[:Requesting_Critical_Section] and 
			((numSeqReq > variables[:Our_Sequence_Number]) or 
				((numSeqReq == variables[:Our_Sequence_Number]) 
					and idReq > variables[:me])))
	end

	#Funcion que recibe las peticiones de otros clientes para entrar en la seccion critica
	#y que se encarga de responder a esas peticiones segun la especificacion del algoritmo
	#de Ricart-Agrawala
	def requestReceiver() do
		receive do
			{:request, idReq, pidReq, numSeqReq} -> send({:sDB, Node.self()}, {:waitRquest, pidReq, numSeqReq, idReq})                    
													receive do 
															 :ackFalse -> Process.sleep(round(:rand.uniform(100)/100 * 1000))
															 		send({:pidReply, pidReq}, :reply)

															 :ackTrue 
													 end  
		end
		requestReceiver()
	end

	#Funcion que recibe las respuestas y decrementa 
	#Outstanding_Reply_Count en 1 por cada respuesta
	#recibida. Es parte de la implementacion del algoritmo
	#de Ricart-Agrawala
	def replyReceiver(outstanding_Reply_Count, numNodos) do
		receive do
			:resetNumNodos -> replyReceiver(numNodos-1, numNodos)
			:reply ->  if outstanding_Reply_Count == 1 do
							send({:IME, Node.self()}, :Continue)
						end
						replyReceiver(outstanding_Reply_Count-1, numNodos)
		end
	end

	def chatMostrar() do
		receive do
			{:msg, mensaje} -> IO.puts(mensaje)
								chatMostrar()
		end
	end

	def spawnear(modulo, funcion, parametros, nombre) do
		Process.register(self(), nombre)
		apply(modulo, funcion, parametros)
	end

	def conectarNodo(node) do
		Node.connect node
	end

	def generarListaMSG(me, n) do
		case n do
		1 -> [to_string(me) <> " envia mensaje num: " <>  to_string(n)]
		_ ->
			generarListaMSG(me, n-1) ++ [to_string(me) <> " envia mensaje num: " <>  to_string(n)]
		end
	end

	#Funcion que inicializa el cliente del chat
	def comenzarChat(numNodos, me) do
		nodeList = [:"1@127.0.0.1", :"2@127.0.0.1", :"3@127.0.0.1"]
		Enum.each(nodeList, fn x -> conectarNodo(x) end)
		variables = %{:me => me, :NumNodos => numNodos, 
					:Our_Sequence_Number => 1, :Highest_Sequence_Number => 0, 
					:Outstanding_Reply_Count => 0, :Requesting_Critical_Section => false,
					:Reply_Deferred_List => []}
		#:sDB
		spawn(Chat, :spawnear, [Chat, :sharedDB, [variables], :sDB])
		#:showMSG
		spawn(Chat, :spawnear, [Chat, :chatMostrar, [], :showMSG])
		#:ReqProcess
		spawn(Chat, :spawnear, [Chat, :requestReceiver, [], :ReqProcess])
		#:pidReply
		spawn(Chat, :spawnear, [Chat, :replyReceiver, [0,numNodos], :pidReply])
		#:IME    
		Process.register(self(), :IME)	
		:timer.sleep(2000 + me)
		chatInput(me, nodeList, generarListaMSG(me, 300))	    
		#chatInput(me, nodeList)
		
	end
end


