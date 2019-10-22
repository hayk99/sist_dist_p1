dir_worker=:"workers@10.1.55.98"
dir_master=:"master@10.1.55.98"
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
	def calculoFib(pid, listaValores) do
		IO.puts "comienzo calculo..."
		inst1 = Time.utc_now()
		resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
		inst2 = Time.utc_now()
		IO.inspect(pid, label: "Sending time to: ")
		tiempo = Time.diff(inst2,inst1)
		send(pid, {:fin, tiempo, resultado})
	end
	def start(dir, dir_master)do
		Node.start dir
		Process.register(self(),:workers)
		Node.set_cookie(:cookie)
		Node.connect(dir_master)
		IO.puts "Workers is up"
	end
end

Workers.start(dir_worker, dir_master)