freeWorkers = []
bloqueds = []
defmodule pool do
	def pool() do
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
		end
		pool()
	end
end
#he pensado que podemos lanzar threads internos en pool para que se encarguen de añadir o quitar de las listas y de esta forma no saturar el receive principal del pool