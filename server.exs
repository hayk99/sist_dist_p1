escenario = :dos
dir_server = :"server@10.1.55.98"
num_workers = 4
dir_worker = :"workers@10.1.63.216"

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
#	def calculoFib(pid, listaValores) do
#		inst1 = Time.utc_now()
#		resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
#		inst2 = Time.utc_now()
#		IO.inspect(pid, label: "Sending time to: ")
#		tiempo = Time.diff(inst2,inst1)
#		send(pid, {:fin, tiempo, resultado})
#	end

	def master(dir_worker) do
		receive do
			{pid, :fib, listaValores, n} -> IO.inspect(pid, label: "nada from client with pid: ")
											IO.puts "mando faena"
											Node.spawn(dir_worker, Workers,  :calculoFib, [pid, listaValores])
											IO.puts "faena mandada"

		end
		master(dir_worker)
	end

	def server() do
		receive do
			{pid, :fib, listaValores, 1} -> IO.inspect(pid, label: "Request from client with pid: ")
											# tenemos la disponibilidad y tenemos que lanzar el thread
											#spawn(Server, :calculoFib, [pid, listaValores])

		end
		server()
	end

	def lunchServer(dirs) do
		Node.start dirs
		Process.register(self(), :server)
		Node.set_cookie(:cookie)
		IO.puts("Server is up")
		Server.server()
	end

	def lunchMaster(dirs, dir_worker) do
		Node.start dirs
		Process.register(self(), :server)
		Node.set_cookie(:cookie)
		IO.puts("Master is up")
		Server.master(dir_worker)
	end
end

case escenario do 
	:uno ->		Server.lunchServer(dir_server)
	:dos ->		Server.lunchMaster(dir_server, dir_worker)
	:tres ->	Server.lunchServer(dir_server, num_workers)
end