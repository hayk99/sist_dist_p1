# AUTOR: Rafael Tolosana Calasanz
#Modificaciones: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos_cliente.exs
# FECHA: 22 de Octubre de 2018
# TIEMPO: -
# DESCRIPCION: coodigo para el cliente

defmodule Perfectos_cliente do
  def request(server_pid, tipo_server, numHilo) do
    time1 = :os.system_time(:millisecond)
		atomo = String.to_atom( "ClienteId" <> to_string numHilo)
		Process.register(self(), atomo)
		IO.puts("Enviando peticion a " <> to_string elem(server_pid, 1))
		IO.inspect(Node.self(), label: "Peticiendo enviada desde ")
    send(server_pid, {{atomo, Node.self()}, tipo_server})
    IO.puts "Esperando contestacion"
		receive do
			{tex, lista_perfectos} -> IO.puts "Recibido ACK" 
      					time2 = :os.system_time(:millisecond) 
								mi_pid = self()
								IO.inspect(lista_perfectos, label: "Los cuatro numeros perfectos son")
								IO.inspect(mi_pid, label: "Tiempo de ejecucion: #{tex}")
								IO.inspect(mi_pid, label: "Tiempo total: #{time2 - time1}")
								if (time2 - time1) > (tex * 2), do: IO.puts("Violacion del QoS")
    end
  end
  
  
  defp lanza_request(server_pid, 1, tipo_server,numHilo) do
  	spawn(Perfectos_cliente, :request, [server_pid, tipo_server, numHilo])
		numHilo
  end
  
  defp lanza_request(server_pid, n, tipo_server, numHilo) when n > 1 do
  	spawn(Perfectos_cliente, :request, [server_pid, tipo_server, numHilo])
		numHilo = lanza_request(server_pid, n - 1, tipo_server,numHilo+1)
		numHilo
  end
  
  def genera_workload(server_pid, tipo_escenario, numHilo) do
  	case tipo_escenario do
	  :uno -> 		lanza_request(server_pid, 1, :perfectos, numHilo+1)#; numHilo+1
	  :dos -> 		lanza_request(server_pid, System.schedulers, :perfectos,numHilo+1)#; numHilo+ System.schedulers
	  :tres -> 		lanza_request(server_pid, System.schedulers*2 + 2, :perfectos,numHilo+1)#; numHilo+ 2 + System.schedulers*2
	  :cuatro -> 	lanza_request(server_pid, System.schedulers*2 + 2, :perfectos_ht,numHilo+1)#; numHilo+ 2 + System.schedulers*2
	  _ ->			IO.puts "Error!"
	end
  end
  
  def cliente(server_pid, tipo_escenario, numHilo) do
	IO.puts "-----------------------------------------------------"
	numHilo = genera_workload(server_pid, tipo_escenario, numHilo)
	:timer.sleep(10000)
	cliente(server_pid, tipo_escenario, numHilo)
  end

  def cliente(server_pid, tipo_escenario) do
	IO.puts "-----------------------------------------------------"
	numHilo = genera_workload(server_pid, tipo_escenario, 1)
	:timer.sleep(2000)
	cliente(server_pid, tipo_escenario, numHilo)
  end
end


#Perfectos_cliente.cliente(pid, :uno)
