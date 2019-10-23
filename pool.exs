freeWorkers = []
bloqueds = []
dir_pool=:"pool@"
defmodule pool do
	def Pool() do
		receive do
			{pid_hilo, :req_wk}  -> IO.puts "Master needs a worker"
								int len = length(freeWorkers)
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
										[head_b| tail_b]=desbloqueados
										send(head, {:wk_free, head})
										bloqueados = tail_b
									length(bloqueados) == 0 ->
										IO.puts "No tengo bloqueados, añado wk a la lista"
										freeWorkers ++ [dir_wk]
								end
			{:firstLog, dir_wk} -> IO.puts "Worker machine is up, log 4 cores..."
									freeWorkers ++ [dir_wk] ++ [dir_wk] ++ [dir_wk] ++ [dir_wk]
		end
		pool()
	end
	def start(dir_pool) do
		Node.start dir_pool
		Process.register(self(),:pool)
		Node.set_cookie(:cookie)
		IO.puts "Pool is up"
		Pool.pool()
	end
end
Pool.start(dir_pool)