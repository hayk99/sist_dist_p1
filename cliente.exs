# AUTORES: Rafael Tolosana Calasanz, modificaciones por Hayk Kocharyan y Javier Salamero Sanz
 # fuentes: 	https://fschuindt.github.io/blog/2017/09/21/concurrent-calculation-of-fibonacci-in-elixir.html
 #			https://blog.rentpathcode.com/clojure-vs-elixir-part-2-fibonacci-code-challenge-13f485f48511
 #			https://alchemist.camp/episodes/fibonacci-tail
 # FICHERO: cliente.exs
 # FECHA: 21 de octubre de 2019
 # TIEMPO: 2h
 # DESCRIPCI'ON:  	Compilaci'on de implementaciones de los n'umeros de Fibonacci para los servidores
 #			 	Las opciones de invocaci'on son: Fib.fibonacci(n), Fib.fibonacci_rt(n), Fib.of(n)
 #				M'odulo de operaciones para el cliente (generador de carga de trabajo)

defmodule Cliente do


  def launch(server_pid, op, 1) do

	pid = spawn(Cliente, :clienteRecieve, [])
	send(server_pid, {pid, op, 1..36, 1})
  end

  def launch(server_pid, op, n) when n != 1 do
	pid = spawn(Cliente, :clienteRecieve, [])
	send(server_pid, [self, op, 1..36, n])
	launch(pid, op, n - 1)
  end 
  
  def genera_workload(server_pid, pid, escenario, time) do
	cond do
		time <= 3 ->  launch(server_pid, :fib, 8); Process.sleep(2000)
		time == 4 ->  launch(server_pid, :fib, 8);Process.sleep(round(:rand.uniform(100)/100 * 2000))
		time <= 8 ->  launch(server_pid, :fib, 8);Process.sleep(round(:rand.uniform(100)/1000 * 2000))
		time == 9 -> launch(server_pid, :fib_tr, 8);Process.sleep(round(:rand.uniform(2)/2 * 2000))
	end
  	genera_workload(server_pid, escenario, rem(time + 1, 10))
  end

  def genera_workload(server_pid, pid, escenario) do
  	if escenario == 1 do
		launch(server_pid, :fib, 1)
	else
		launch(server_pid, :fib, 4)
	end

	Process.sleep(2000)
  	genera_workload(server_pid, escenario)
  end
  
  def clienteRecieve() do
  	recieve do
  		{:fin, listaFib} -> IO.inspect(listaFib, label: "Toma lista crack ")
  	end
  end

  #desde escenario llamaré a este
  #manda peticiones al worker
  def cliente(server_pid, tipo_escenario) do
  	case tipo_escenario do
  	#modifica las cabeceras
		:uno -> genera_workload(server_pid,pid, 1)
		:dos -> genera_workload(server_pid,pid, 2)
		:tres -> genera_workload(server_pid, pid, 3, 1)
	end
  end
end


#dos opciones, si creo el proceso recibir antes de generar workload, cuando vaya a medir timepos de ejecución no sabre identificar los procesos, 
#para ello tendré que llevar un id de proceso
# la otra opcion es lanzar uno por cada launch, para ello genero un pid y le mando su pid y se dónde lo recibiré

#pegar codigo del modulo en cliente de iex
#Cliete.cliente({pidServer,:uno/:dos/:tres})
#pool_-> master escucha constantemente, cuando le llega una petición lanza thread y está pendiente de las peticiones mientras tnato. 
#Cuando lanza un thread pide permiso al pool para poder usar un worker y hasta que no se lo conceda no avanza.