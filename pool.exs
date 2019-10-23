freeWorkers = [:"wk1@10.1.0.0", :"wk2@10.1.0.0", :"wk3@10.1.0.0", :"wk4@10.1.0.0"]
bloqueds = []
defmodule pool do
	def pool() do
		receive do
			{pid_master, :fib, op, listaValores} -> IO.puts "Request from master: "
													int len = length(freeWorkers)
													cond do
														len == 0 -> 
															IO.puts "No tengo nada libre"
															bloqueados ++ [{pid_master,:fib, op, listaValores}]
														len > 0 ->
															IO.puts "Tengo workers"
															[head | tail]=freeWorkers
															Node.spawn(head, Worker, :calculoFib, [pid_master, self(), op, listaValores])
															freeWorkers = tail
													end
			{:worker, dir_wk} -> IO.puts "Un worker esta libre"
								cond do
									length(bloqueados) > 0 -> 
										IO.puts "Tengo procesos bloqueados, despierto en FIFO"
										[head_b| tail_b]=desbloqueados
										Node.spawn(dir_Wk, Worker, :calculoFib, [pid_master, op, listaValores])
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