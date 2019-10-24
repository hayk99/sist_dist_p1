escenario = :tres
dir_server = :"server@155.210.154.199"
#dir_server = :"server@10.1.29.86"
#dir_server = :"server@127.0.0.1"
num_workers = 4
dir_pool = :"pool@155.210.154.197"
#dir_pool = :"pool@10.1.29.86"
#dir_pool = :"pool@127.0.0.1"

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

	def peticionPool(pid_client, dir_pool, listaValores, op) do
		send({:pool,dir_pool}, {self() , :req__wk})
		receive do
			{:wk_free, dir_worker, pid_pool} -> Node.spawn(dir_worker, Workers, :workForMe, [pid_client, pid_pool, op, listaValores])
		end

	end

	def master(dir_pool) do
		receive do
			{pid_client, op, listaValores, n, :para_m} -> #spawn(Server, :peticionPool, [pid_client, dir_pool, listaValores, op])
							IO.puts("Recibo mensaje")							
							peticionPool(pid_client, dir_pool, listaValores, op)
		end
		master(dir_pool)
	end

	def server() do
		receive do
			{pid, :fib, listaValores, n} ->	spawn(Server, :calculoFib, [pid, listaValores])
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

	def lunchMaster(dirs, dir_pool) do
		Node.start dirs
		Process.register(self(), :server)
		Node.set_cookie(:cookie)
		Node.connect(dir_pool)
		IO.puts("Master is up")
		Server.master(dir_pool)
	end
end

case escenario do 
	:uno ->		Server.lunchServer(dir_server)
	:dos ->		Server.lunchServer(dir_server)
	:tres ->	Server.lunchMaster(dir_server, dir_pool)
end
