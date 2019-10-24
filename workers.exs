dir_worker=:"workers@10.1.55.98"
dir_pool=:"pool@155.210.154.198"
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
	def workForMe(pid_master,op, listaValores) do
		IO.puts "comienzo calculo..."
		cond do 
			op == "fibonacci" ->
				inst1 = Time.utc_now()
				resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
			op == "fibonacci_tr" ->
				inst1 = Time.utc_now()
				resultado = Enum.map(listaValores, fn x -> Fib.fibonacci_tr(x) end)
		end
		inst2 = Time.utc_now()
		IO.inspect(pid_master, label: "Sending time to: ")
		tiempo = Time.diff(inst2,inst1)
		send(pid_master, {:resul, tiempo, resultado})
		send(dir_pool, {:ready, self()})
	end
#	def calculoFib(pid_master, pid_pool, op, listaValores) do

	def start(dir, dir_pool)do
		Node.start dir
		Process.register(self(),:workers)
		Node.set_cookie(:cookie)
		Node.connect(dir_pool)
		Node.connect(dir_master)
		send(dir_pool, {:firstLog, dir_worker})
		IO.puts "Workers is up"
	end
end

Workers.start(dir_worker, dir_pool)
