# AUTORES: Rafael Tolosana Calasanz, modificaciones por Hayk Kocharyan y Javier Salamero Sanz
 # fuentes: 	https://fschuindt.github.io/blog/2017/09/21/concurrent-calculation-of-fibonacci-in-elixir.html
 #			https://blog.rentpathcode.com/clojure-vs-elixir-part-2-fibonacci-code-challenge-13f485f48511
 #			https://alchemist.camp/episodes/fibonacci-tail
 # FICHERO: cliente.exs
 # FECHA: 21 de octubre de 2019
 # TIEMPO: 2h
 # DESCRIPCI'ON:		Compilaci'on de implementaciones de los n'umeros de Fibonacci para los servidores
 #			 	Las opciones de invocaci'on son: Fib.fibonacci(n), Fib.fibonacci_rt(n), Fib.of(n)
 #				M'odulo de operaciones para el cliente (generador de carga de trabajo)

escenario = :uno
dir_server = :"server@127.0.0.1"
dir_client = :"client@127.0.0.1"

defmodule Cliente do


	def launch(server_pid, op, 1) do
		pid=spawn(Cliente, :clienteReceive, [Time.utc_now()])
		send(server_pid, {pid, op, 1..36, 1})
	end

	def launch(server_pid, op, n) when n != 1 do
		pid=spawn(Cliente, :clienteReceive, [Time.utc_now()])
		send(server_pid, {pid, op, 1..36, n})
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
											IO.inspect(time_ex, label: "El tiempo de ejecucion: ")
                                			IO.inspect(Time.diff(inst2, inst1, :millisecond), label: "El tiempo total: ")
											IO.puts "--------------------"
                                			IO.inspect(result, label: "Toma lista crack \n\n")
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

Cliente.lunchClient(:server, escenario, dir_server, dir_client)
