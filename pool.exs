
dir_pool=:"pool@155.210.154.198"
defmodule Pool do
	def pool(freeWorkers, bloqueados) do
		receive do
			{pid_hilo, :req_wk}  -> IO.puts "Master needs a worker"
								len = length(freeWorkers)
								cond do
									len == 0 -> 
										IO.puts "No tengo nada libre"
										bloqueados ++ [pid_hilo]
									len > 0 ->
										IO.puts "Tengo workers"
										[head | tail]=freeWorkers
										send(pid_hilo, {:wk_free, head})
										freeWorkers = tail
								end

			{:ready, dir_wk} -> IO.puts "Un worker esta libre"
								cond do
									length(bloqueados) > 0 -> 
										IO.puts "Tengo procesos bloqueados, despierto en FIFO"
										[head| tail]= bloqueados
										send(head, {:wk_free, dir_wk})
										bloqueados = tail
									length(bloqueados) == 0 ->
										IO.puts "No tengo bloqueados, añado wk a la lista"
										freeWorkers ++ [dir_wk]
								end
			{:firstLog, dir_wk} -> IO.puts "Worker machine is up, log 4 cores..."
						freeWorkers ++ [dir_wk] ++ [dir_wk] ++ [dir_wk] ++ [dir_wk]
		end
		pool(freeWorkers, bloqueados)
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
