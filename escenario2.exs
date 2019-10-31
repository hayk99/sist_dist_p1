#AUTORES: HAYK KOCHARYAN Y JAVIER SALAMERO
#NIAs: 757715 - 756868
#FICHERO: escenario2.exs
#FECHA: 31/10/2019
#TIEMPO: 5h
#DESCRIPCION: fichero del escenario 2, contiene el código de cliente y servidor, 
#para lanzarlo se han usado otros scripts de elixir que se incluyen en el zip


dir_server = :"server@155.210.154.209"
dir_client = :"client@155.210.154.208"


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

defmodule Server do
	def calculoFib(pid, listaValores) do
		inst1 = Time.utc_now()
		resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
		inst2 = Time.utc_now()
		tiempo = Time.diff(inst2,inst1, :milliseconds)
		send(pid, {:resul, tiempo, resultado})
	end

	def server() do
		receive do
			{pid, :fib, listaValores, _n} ->	spawn(Server, :calculoFib, [pid, listaValores])
		end
		server() 
	end

	def lunchServer(dirs) do
		Node.start dirs
		Process.register(self(), :server)
		Node.set_cookie(:cookie)
		IO.puts("Server is up: ")
		Server.server()
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

 	def lunchClient(server_name, escenario, dir_server, dir_client) do
 		Node.start dir_client
		Process.register(self(), :client)
		Node.set_cookie(:cookie)
		Node.connect(dir_server)
		IO.puts "Conection done"
		Cliente.cliente({server_name, dir_server}, escenario)
	end
end


Cliente.lunchClient(:server, :dos, dir_server, dir_client)
Server.lunchServer(dir_server)