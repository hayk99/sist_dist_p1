#AUTORES: HAYK KOCHARYAN Y JAVIER SALAMERO
#NIAs: 757715 - 756868
#FICHERO: escenario3.exs
#FECHA: 31/10/2019
#TIEMPO: 5h
#DESCRIPCION: fichero del escenario 3, contiene el código de cliente,servidor,master y pool 
#para lanzarlo se han usado otros scripts de elixir que se incluyen en el zip

dir_server = :"server@155.210.154.209"
dir_client = :"client@155.210.154.208"
dir_worker=:"workers11@155.210.154.194"

defmodule Fib do
	def fibonacci(0), do: 0
	def fibonacci(1), do: 1
	def fibonacci(n) when n >= 2 do
		fibonacci(n - 2) + fibonacci(n - 1)
	end
	def fibonacci_tr(n), do: fibonacci_tr(n, 0, 1)
	defp fibonacci_tr(0, _acc1, _acc2), do: 0
	defp fibonacci_tr(1, _acc1, acc2), do: acc2
	defp fibonacci_tr(n, acc1, acc2) do
		fibonacci_tr(n - 1, acc2, acc1 + acc2)
	end

	@golden_n :math.sqrt(5)
  	def of(n) do
 		(x_of(n) - y_of(n)) / @golden_n
	end
 	defp x_of(n) do
		:math.pow((1 + @golden_n) / 2, n)
	end
	def y_of(n) do
		:math.pow((1 - @golden_n) / 2, n)
	end
end	

defmodule Workers do
	def workForMe(pid_client, dir_pool, op, listaValores) do
		dir_worker=:"workers7@155.210.154.194"
		resultado=0
		inst1 = Time.utc_now()
		if op==:fib do	
			IO.puts "hago fib"
			resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
			inst2 = Time.utc_now()
			send(pid_client, {:resul, Time.diff(inst2,inst1, :microseconds), resultado})
			send(dir_pool, {:ready, dir_worker})
		end
		if op==:fib_tr do
			IO.puts "hago fib_tr"	
			resultado = Enum.map(listaValores, fn x -> Fib.fibonacci_tr(x) end)
			inst2 = Time.utc_now()
			send(pid_client, {:resul, Time.diff(inst2,inst1, :microseconds), resultado})
			send(dir_pool, {:ready, dir_worker})
		end
	end


	def start(dir_worker, dir_pool)do
		Node.start dir_worker
		Process.register(self(),:workers)
		Node.set_cookie(:cookie)
		Node.connect(dir_pool)
		send({:pool,dir_pool}, {:firstLog, dir_worker})
		IO.puts "Workers is up"
	end
end

defmodule Server do

	def peticionPool(pid_client, dir_pool, listaValores, op) do
		send({:pool,dir_pool}, {:req__wk, self()})
		receive do
			{:wk_free, dir_worker, pid_pool} -> Node.spawn(dir_worker, Workers, :workForMe, [pid_client, pid_pool, op, listaValores])
		end

	end

	def master(dir_pool) do
		dir_pool = :"pool@155.210.154.209"
		receive do
			{:client_rq, pid_client, op, listaValores, _n} -> 	spawn(Server, :peticionPool, [pid_client, dir_pool, listaValores, op])
								IO.puts("Recibo mensaje")							
								#peticionPool(pid_client, dir_pool, listaValores, op)
		end
		master(dir_pool)
	end

	def lunchMaster(dirs, dir_pool) do
		Node.start dirs
		Process.register(self(), :server)
		Node.set_cookie(:cookie)
		Node.connect(dir_pool)
		IO.puts("Master is up")
		Server.master(dir_pool)
	end
end

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


defmodule Cliente do


	def launch(server_pid, op, 1) do
		pid=spawn(Cliente, :clienteReceive, [Time.utc_now()])
		send(server_pid, {:client_rq, pid, op, 1..36, 1})
	end

	def launch(server_pid, op, n) when n != 1 do
		pid=spawn(Cliente, :clienteReceive, [Time.utc_now()])
		send(server_pid, {:client_rq, pid, op, 1..36, n})
		launch(server_pid, op, n - 1)
	end 
	
	def genera_workload(server_pid, escenario, time) do
		cond do
			time <= 3 ->	launch(server_pid, :fib, 8); Process.sleep(2000)
			time == 4 ->	launch(server_pid, :fib, 8); Process.sleep(round(:rand.uniform(100)/100 * 2000))
			time <= 8 ->	launch(server_pid, :fib, 8); Process.sleep(round(:rand.uniform(100)/1000 * 2000))
			time == 9 -> launch(server_pid, :fib_tr, 8); Process.sleep(round(:rand.uniform(2)/2 * 2000))
		end
			genera_workload(server_pid, escenario, rem(time + 1, 10))
		end

	def genera_workload(server_pid, escenario) do
		if escenario == 1 do
			launch(server_pid, :fib, 1)
		else
			launch(server_pid, :fib, 4)
	end

		Process.sleep(2000)
		genera_workload(server_pid, escenario)
	end
	
	def clienteReceive(inst1) do
		#send(server_pid, {self(), op, rango, n, :para_m})		
		receive do
			{:resul, time_ex, result} ->	inst2 = Time.utc_now()
											#IO.inspect(time_ex, label: "El tiempo de ejecucion: ")
							#IO.inspect(a)
							IO.inspect("#{time_ex} #{Time.diff(inst2, inst1, :microseconds)}")
                                			#IO.inspect(Time.diff(inst2, inst1, :microseconds), label: "El tiempo total: ")
							if Time.diff(inst2, inst1, :microseconds) > 1.5*time_ex, do: IO.puts "QoS incumplido"
							#				IO.puts "--------------------"
                                			#IO.inspect(result, label: "Toma lista crack \n\n")
		end
	end

	def cliente(server_pid, tipo_escenario) do
		case tipo_escenario do
			:uno -> genera_workload(server_pid, 1)
			:dos -> genera_workload(server_pid, 2) 
			:tres -> genera_workload(server_pid, 3, 1)
		end
	end

end

Pool.start(dir_pool)
Server.lunchMaster(dir_server, dir_pool)
Workers.start(dir_worker, dir_pool)
Cliente.lunchClient(:server, :tres, dir_server, dir_client)