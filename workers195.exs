dir_worker=:"workers7@155.210.154.195"
dir_pool=:"pool@155.210.154.209"

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
		dir_worker=:"workers7@155.210.154.195"
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

Workers.start(dir_worker, dir_pool)
