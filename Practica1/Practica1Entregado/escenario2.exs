#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 15 de Octubre de 2018
# DESCRIPCION: Modulo Escenario 2
defmodule EscenarioDos do
  def servidorConcurrente() do
    receive do
      {pid, :perfectos} -> 	spawn(fn ->
                    time1 = :os.system_time(:millisecond)
      							perfectos = Perfectos.encuentra_perfectos({1, 10000})
      							time2 = :os.system_time(:millisecond)    
      							send(pid, {time2 - time1, perfectos})
                    end)
      {pid, :perfectos_ht} ->	time1 = :os.system_time(:millisecond)
      							if :rand.uniform(100)>60, do: Process.sleep(round(:rand.uniform(100)/100 * 2000))
								perfectos = Perfectos.encuentra_perfectos({1, 10000})
								time2 = :os.system_time(:millisecond)			
								send(pid, {time2 - time1, perfectos})
    end    
    servidorConcurrente()
  end



	def arrancar(direccion) do
		Node.start direccion
		Process.register(self(), :server)
		Node.set_cookie(:sisdist)
		servidorConcurrente()
	end
end