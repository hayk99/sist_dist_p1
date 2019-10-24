#dir_worker=:"workers@10.1.55.98"
#dir_worker=:"workers@10.1.29.86"
dir_worker=:"workers@127.0.0.1"
#dir_pool=:"pool@155.210.154.198"
#dir_pool=:"pool@10.1.29.86"
dir_pool=:"pool@127.0.0.1"
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
	def workForMe(pid_client, pid_pool,op, listaValores, inst1, resultado) do
		IO.puts "comienzo calculo..."
		inst1 = 0 
		resultado = 0
		cond do 
			op==:fib -> inst1 = Time.utc_now()
								resultado = Enum.map(listaValores, fn x -> Fib.fibonacci(x) end)
			op==:fib_tr -> inst1 = Time.utc_now()
								resultado = Enum.map(listaValores, fn x -> Fib.fibonacci_tr(x) end)
		end
		inst2 = Time.utc_now()
		IO.inspect(pid_client)
		IO.inspect(pid_pool)
		#tiempo = Time.diff(inst2,inst1, :milliseconds)
		send(pid_client, {:resul,inst1, inst2, resultado})
		IO.inspect(pid_client, label: "Sending time to: ")
		send(pid_pool, {:ready, self()})
	end
#	def calculoFib(pid_client, pid_pool, op, listaValores) do

	def start(dir_worker, dir_pool, inst1, resultado)do
		Node.start dir_worker
		Process.register(self(),:workers)
		Node.set_cookie(:cookie)
		Node.connect(dir_pool)
		send({:pool,dir_pool}, {:firstLog, dir_worker})
		IO.puts "Workers is up"
	end
end

Workers.start(dir_worker, dir_pool,0,0)
