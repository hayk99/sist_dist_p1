dir_pool=:"pool@155.210.152.177"

defmodule Pool do
	def pool(freeWorkers, bloqueados) do
		receive do
			{:ready, dir_wk} -> IO.puts "Un worker esta libre"
								cond do
									length(bloqueados) > 0 -> 
										IO.puts "=========================================="
										IO.inspect(freeWorkers, label: "freewk")
										IO.inspect(bloqueados, label: "bloq antes de desbloc")
										[head | tail]= bloqueados
										send(head, {:wk_free, dir_wk, self()})
										bloqueados = tail
										IO.inspect(bloqueados, label: "bloq despues de modif")
										IO.puts "habia un block y lo he despertado"
										pool(freeWorkers, bloqueados)
										IO.puts "=========================================="
									length(bloqueados) == 0 ->
										IO.puts "=========================================="
										IO.inspect(bloqueados, label: "bloqueados: ")
										IO.inspect(freeWorkers, label: "freewk antes de añadir")
										freeWorkers = freeWorkers ++ [dir_wk]
										IO.inspect(freeWorkers, label: "freewk despues de añadir")
										IO.puts "no habia bloqueados"
										pool(freeWorkers, bloqueados)
										IO.puts "=========================================="
								end
			{:req__wk, pid_hilo_master}  -> IO.puts "Master needs a worker"
											len = length(freeWorkers)
											IO.puts len
											cond do
												len == 0 -> ##
														IO.puts "=========================================="
														IO.inspect(freeWorkers, label: "freeWorkers: ")
														IO.inspect(bloqueados, label: "bloq antes de bloc")
														bloqueados = bloqueados ++ [pid_hilo_master]
														IO.inspect(bloqueados, label: "bloq despues de bloc")
														IO.puts "bloqueo"
														pool(freeWorkers, bloqueados)
														IO.puts "=========================================="
												len > 0 ->  ##
														IO.puts "=========================================="
														IO.inspect(bloqueados, label: "bloqueados: ")
														IO.inspect(freeWorkers, label: "freewk antes de eliminar")
														[head | tail]=freeWorkers
														send(pid_hilo_master, {:wk_free, head, self()})
														IO.puts "enviado"
														freeWorkers = tail
														IO.inspect(freeWorkers, label: "freewk despues de eliminar")
														pool(freeWorkers, bloqueados)
														IO.puts "=========================================="
											end

			{:firstLog, dir_wk} ->	IO.puts "Worker machine is up, log 4 cores..."
									freeWorkers = freeWorkers ++ [dir_wk] ++ [dir_wk] ++ [dir_wk] ++ [dir_wk]
									len = length(freeWorkers)
									pool(freeWorkers, bloqueados)
		end
	end
	def start(dir_pool) do
		Node.start dir_pool
		Process.register(self(),:pool)
		Node.set_cookie(:cookie)
		IO.puts "Pool is up"
		Pool.pool([], [])
	end
end
Pool.start(dir_pool)
