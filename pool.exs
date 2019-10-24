
#dir_pool=:"pool@155.210.154.198"
#dir_pool=:"pool@10.1.29.86"
dir_pool=:"pool@127.0.0.1"
defmodule Pool do
	def pool(freeWorkers, bloqueados) do
		receive do
			{pid_hilo_master, :req__wk}  -> IO.puts "Master needs a worker"
										len = length(freeWorkers)
										IO.puts len
										cond do
											len==0 ->#IO.puts "No tengo nada libre"
												bloqueados = bloqueados ++ [pid_hilo_master]
											len>0 ->#IO.puts "Tengo workers"
												[head | tail]=freeWorkers
												send(pid_hilo_master, {:wk_free, head, self()})
												IO.puts "enviado"
												freeWorkers = tail
										end
										pool(freeWorkers, bloqueados)

			{:ready, dir_wk} -> IO.puts "Un worker esta libre"
								cond do
									length(bloqueados) > 0 -> 
										IO.puts "Tengo procesos bloqueados, despierto en FIFO"
										[head| tail]= bloqueados
										send(head, {:wk_free, dir_wk})
										bloqueados = tail
									length(bloqueados) == 0 ->
										IO.puts "No tengo bloqueados, añado wk a la lista"
										freeWorkers = freeWorkers ++ [dir_wk]
								end
								pool(freeWorkers, bloqueados)
			{:firstLog, dir_wk} -> IO.puts "Worker machine is up, log 4 cores..."
						freeWorkers = freeWorkers ++ [dir_wk] ++ [dir_wk] ++ [dir_wk] ++ [dir_wk]
						len = length(freeWorkers)
						IO.puts len
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
