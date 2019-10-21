defmodule Worker do

    def startWorker(type, direccion) do
        startWorker(type, direccion, :"master@127.0.0.1")
    end

    #si comenzado con :divisores, comienza el worker que calcula
    #la lista de divisores dado N. Si comenzado con: :sumaLista
    #comienza el worker que calcula los divisores propios de N.
    #Si comenzado con :suma, comienza el worker encargado de calcular
    #la suma de todos los numeros contenidos en una lista
    def startWorker(type, direccion, master) do
        #inicializacion del nodo programaticamente
        Node.start direccion
		Process.register(self(), type)
		Node.set_cookie(direccion, :sisdist)
        #conexion con el master
        Node.connect(master)
        #mandamos al master una peticion conforme nos hemos conectado, y pedimos nos informe de la situacion de los workers
        send({:master, master}, {:newWorker, {type, direccion}})
        IO.puts "Mandada peticion de conexion al master"
        receive do
            #en caso de que ya exista un primary al iniciar, nos quedaremos a la espera
            {:primary, {tipo, dir}} ->  IO.puts "Me quedo a la espera porque no soy pirimary"
                                        IO.inspect Node.list
                                        send({tipo, dir}, {:newWorker, {type, direccion}})
                                        receive do
                                            {:nuevaId, mID, nodosConectados} -> IO.inspect(mID, label: "El ID que me han asignado es: ")
                                                                                loopEspera(master, init(), type, mID, nodosConectados)
                                        after
                                            5000 -> Enum.each(Node.list, fn x -> send({type, x}, {:buscoLider, {type, direccion}}) 
                                                                                    IO.inspect(x, label: "Mandado :buscoLider a ") end)
                                                    receive do
                                                        {:nuevaId, mID, nodosConectados} -> IO.inspect(mID, label: "El ID que me han asignado es: ")
                                                                                            loopEspera(master, init(), type, mID, nodosConectados)
                                                    after
                                                        10000 -> send({:master, master}, {:soyLider, 0, {type, Node.self()}})
                                                        IO.puts "Ha saltado el timeout esperando a lider, por tanto soy el nuevo lider"
                                                        comenzarPrimary(init(), type, 0, [], master)
                                                    end
                                        end          
            #si no existia nigun worker, tendremos id 0 y seremos primary              
            {:eresPrimary, id} ->   IO.puts "Soy primary dentro de mi grupo"
                                   # comenzarPrimary(init(), type, id, [], master)              
                                    comenzarPrimary(:no_faul, type, id, [], master)
        end
    end



    #Bucle para nodos de reserva
    def loopEspera(master, worker_type, type, id, nodosClase) do
        receive do
            #si ha entrado un nuevo worker al sistema, nos enviara a todos los workers quien es para que lo anyadamos a la lista
            {:identificar, direccionNuevo, sId} ->  IO.puts "Estoy en espera y se ha conectado un nuevo worker"
                                                    loopEspera(master, worker_type, type, id, nodosClase ++ [{sId, direccionNuevo}])
                                                    
            #en caso de que algun worker se haya dado cuenta que el primary se ha caido, enviara :eleccion, y se trata aqui
            {:eleccion, elId, dirPeticion} ->   send(dirPeticion, :ok)
                                                IO.puts "Se ha provocado una eleccion de lider"
                                                generarEleccion(type, id, nodosClase)
                                                esperaEleccionL(master,  worker_type, type, id, nodosClase)
            #si ya se ha elegido lider, se indica aqui
            {:soyLider, lId, lidDir} -> if lId < id do
                                            IO.puts "El lider elegido es correcto y tiene menor ID que yo"
                                            #si la eleccion es correcta, y el id del lider es menor que el nuestro, nos quedamos en espera
                                            loopEspera(master, worker_type, type, id, nodosClase)
                                        else
                                            IO.puts "Algo ha ido mal en la eleccion de lider, reiniciando"
                                            #si no, debemos volver a elegir lider porque algo ha ido mal
                                            generarEleccion(type, id, nodosClase)
                                            esperaEleccionL(master,  worker_type, type, id, nodosClase)
                                        end
            #si nos llega el latido, cancelamos por tanto el timeout y se vuelve a iniciar la funcion de espera
            {:latido, prId} ->  IO.puts "Me ha llegado un latido"
                                loopEspera(master, worker_type, type, id, nodosClase)
        after #si ha saltado el timeout implica que el lider esta caido o existe mucha latencia, iniciamos por tanto eleccion
            5000 -> IO.puts "Ha saltado el timeout, el primary no esta disponible"
                    generarEleccion(type, id, nodosClase)
                    esperaEleccionL(master,  worker_type, type, id, nodosClase)
        end
    end

    #Genera tipo de worker para Worker-i
    def init do 
        case :rand.uniform(100) do
            random when random > 80 ->  IO.puts "Soy de tipo crash"
                                        :crash                               
            random when random > 50 ->  IO.puts "Soy de tipo omission"
                                        :omission
            random when random > 25 ->  IO.puts "Soy de tipo timing"
                                        :timing              
                                  _ ->  IO.puts "Soy de tipo sin fallos"
                                        :no_fault
        end
    end

    #Comenzamos el nodo como primary, y a la vez el proceso que genera los latidos
    def comenzarPrimary(worker_type, type, id, nodosClase, master) do
        pidLatido = spawn(Worker, :generadorLatidos, [nodosClase, id])
        IO.puts "Proceso de latido spawneado"
        loopI(master, worker_type, type, id, nodosClase, pidLatido)
    end

    #Envia a todos los nodos con menor id la peticion de nueva eleccion de lider
    def generarEleccion(type, id, nodosClase) do
            #Propagamos el mensaje a cada uno de los nodos con id menor
            IO.puts "Nodos dentro de la lista:"
            IO.inspect nodosClase
            Enum.each(nodosClase, fn {sId, sDir} ->  
                if sId < id do
                    IO.inspect(elem(sDir, 1), label: "Generando eleccion. He mandado :eleccion a ")
                    send(sDir, {:eleccion, id, {type, Node.self()}})
                end
            end)
    end

    def esperaEleccionL(master,  worker_type, type, id, nodosClase) do
        receive do
            #si nos llega un mensaje de eleccion, significa que esa maquina tiene un id mayor, por lo que le contestamos con un ok para indicarle
            #que no tiene derecho a ser lider
            {:eleccion, elId, dirPeticion} ->   send(dirPeticion, :ok)
                                                IO.puts "Me ha llegado :eleccion de un nodo de indice superior esperando a nuevo lider"
                                                esperaEleccionL(master,  worker_type, type, id, nodosClase)
            #si me llega un ok estando en este estado, significa que hay un nodo activo con menor id
            {:ok, sId} ->   IO.puts "Me ha llegado un :ok, ya no puedo ser lider"
                            esperaEleccionOL(master,  worker_type, type, id, nodosClase)
            #Si alguien se proclama lider, se verifica si tiene derecho
            {:soyLider, lId, lidDir} -> if lId < id do
                                            IO.puts "El lider ha sido elegido correctamente"
                                            loopEspera(master, worker_type, type, id, nodosClase)
                                        else
                                            IO.puts "Algo ha ido mal esperando lider, generando eleccion de nuevo"
                                            generarEleccion(type, id, nodosClase)
                                            esperaEleccionL(master,  worker_type, type, id, nodosClase)
                                        end
            {:latido, prId} ->  IO.puts "Me ha llegado un latido esperando al nuevo lider"
                                esperaEleccionL(master,  worker_type, type, id, nodosClase)
        after #si no ha llegado ningun mensaje de :ok, significa que somos el lider, y se lo indicamos a todos los nodos de la lista
            5000 -> send({:master, master}, {:soyLider, id, {type, Node.self()}})
                    Enum.each(nodosClase, fn {sId, sDir} -> 
                                            send(sDir, {:soyLider, id, {type, Node.self()}}) 
                                            	IO.inspect(sDir, label: "enviando SoyLider a ")
                                        end)
                    IO.puts "Ha saltado el timeout esperando a lider, por tanto soy el nuevo lider"
                    comenzarPrimary(worker_type, type, id, nodosClase, master)
        end
    end
    
    #Esperar eleccion de lider. Worker-id no sera lider
    def esperaEleccionOL(master,  worker_type, type, id, nodosClase) do
         receive do
            {:eleccion, elId,dirPeticion} -> send(dirPeticion, :ok)
                                             IO.puts "Me ha llegado :eleccion de un nodo con indice superior cuando ya no puedo ser lider"
                                             esperaEleccionOL(master,  worker_type, type, id, nodosClase)          
            #Si alguien se proclama lider, se le consiente
            {:soyLider, lId, lidDir} -> if lId < id do
                                            IO.puts "Lider elegido adecuadamente, estaba esperando lider sin poder serlo"
                                            loopEspera(master, worker_type, type, id, nodosClase)
                                        else
                                            IO.puts "Eleccion de lider incorrecta, generando eleccion de nuevo"
                                            generarEleccion(type, id, nodosClase)
                                            esperaEleccionL(master,  worker_type, type, id, nodosClase)
                                        end
            {:latido, prId} ->  IO.puts "Me ha llegado un latido esperando al nuevo lider sin poder ser lider yo"
                                esperaEleccionOL(master,  worker_type, type, id, nodosClase)
        after #Si t_i > timeout -> Posible nuevo lider caido
            10000 -> IO.puts "Posible nuevo lider caido, generando eleccion de nuevo"
                     generarEleccion(type, id, nodosClase)
                     esperaEleccionL(master,  worker_type, type, id, nodosClase)
        end
    end

    def generadorLatidos(nodosClase, id) do
        receive do
            {:duerme, d} -> IO.puts "Proceso de latido duermiendose"
                            Process.sleep(d)
                            Enum.each(nodosClase, fn x -> send(elem(x, 1), {:latido, id}) end)
                            generadorLatidos(nodosClase, id)
            {:newWorker, dir} ->IO.puts "Proceso de latidos ha recibido un nuevo worker"
                                generadorLatidos(nodosClase ++ [dir], id)
            :end -> IO.puts "Proceso de latidos terminado"
        after #continue
            1000 -> IO.inspect nodosClase
                    Enum.each(nodosClase, fn x -> send(elem(x, 1), {:latido, id}) end)
                    IO.puts "[LATIDO] Enviando latido a todos los workers"
                    generadorLatidos(nodosClase, id)
        end
    end

    #Loop de Worker-primary
    defp loopI(master, worker_type, type, id, nodosClase, pidLatido) do
        delay = case worker_type do
            :crash -> if :rand.uniform(100) > 75, do: :infinity, else: 0
            :timing -> :rand.uniform(100)*1000
            _ ->  0
        end
            #mata o duerme al proceso latido
        if delay == :infinity do
            IO.puts "He crasheado"
            send(pidLatido, :end)
        end
        if delay > 0 do 
            IO.puts "Me he dormido"
            send(pidLatido, {:duerme, delay})
        end
        IO.inspect Node.list
        Process.sleep(delay)
        receive do 
            {:soyLider, lId, lidDir} -> IO.puts "Hay otro lider..."
                                        send(pidLatido, :end)
                                        loopEspera(master, worker_type, type, id, nodosClase)
        after 
            10 -> IO.puts "Sigo siendo el lider"
            #ponemos after 0 para asegurarnos que solo recibimos si tenemos algo en la bandeja de entrada
            #De este modo, el receive deja de ser bloqueante
        end
        receive do
            #si se une un nuevo worker a la red, lo metemos a la lista de nodos de nuestra misma clase
            {:newWorker, direccionNuevo} -> send(pidLatido, {:newWorker, {id+1, direccionNuevo}})
                                            if nodosClase == [] do
                                                IO.puts "Se ha conectado un nuevo worker a la red"
                                                send(direccionNuevo, {:nuevaId, id+1, [{id, {type, Node.self()}}]})
                                                loopI(master, worker_type, type, id, [{id+1, direccionNuevo}], pidLatido)
                                            else
                                                loopI(master, worker_type, type, id, calcularNuevaID(direccionNuevo, hd(nodosClase), tl(nodosClase), nodosClase), pidLatido)
                                            end
            #si nos llega un latido, quiere decir que ahora mismo hay otro primary activo, por tanto paramos el proceso latido y comenzamos eleccion
            {:latido, dirLatido} -> send(pidLatido, :end)
                                    generarEleccion(type, id, nodosClase)
                                    esperaEleccionL(master,  worker_type, type, id, nodosClase)
            #gestionamos la peticion del master
            {:req, {m_pid,m}} -> IO.puts "[PETICION] Me ha llegado una peticion"
                                 if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault) or (worker_type==:crash)) do
                                    send(m_pid, calculation(m, type)) 
                                 end
            {:buscoLider, direccionNuevo} -> if nodosClase != [] do
                                                if verificarBusca(direccionNuevo, hd(nodosClase), tl(nodosClase)) do
                                                    send(pidLatido, {:newWorker, {id+1, direccionNuevo}})
                                                    loopI(master, worker_type, type, id, calcularNuevaID(direccionNuevo, hd(nodosClase), tl(nodosClase), nodosClase), pidLatido)
                                                end
                                             else
                                                IO.puts "Se ha conectado un nuevo worker a la red a traves de :buscoLider"
                                                send(direccionNuevo, {:nuevaId, id+1, [{id, {type, Node.self()}}]})
                                                loopI(master, worker_type, type, id, [{id, direccionNuevo}], pidLatido)
                                             end
            {:identificar, direccionNuevo, sId} -> IO.puts "Me ha llegado un :identificar siendo primary. Sera un mensaje viejo?"
        end
        #reiniciamos el bucle
        loopI(master, worker_type, type, id, nodosClase, pidLatido)
    end

    def verificarBusca({typeN, direccionNuevo}, {id, {type, direccion}}, cola) do
        if direccionNuevo == direccion do
            false
        else
            if cola == [] do
                true
            else
                verificarBusca({typeN, direccionNuevo}, hd(cola), tl(cola))
            end
        end
    end
 
    #Calcula el siguiente ID de un nuevo worker y se le envia 
    #Devuelve lista de Workers con el nuevo Worker
    def calcularNuevaID(pidNuevo, {num, pidhd}, tail, nodosClase) do
        if tail == [] do
            #si hemos llegado al final de la lista, enviamos a todos los nodos la informacion del nuevo worker
            #y enviamos al nuevo worker la lista de nodos conectados a la red ahora mismo
            send(pidNuevo, {:nuevaId, num+1, nodosClase})
            Enum.each(nodosClase, fn {idNodo, dirNodo} -> send(dirNodo, {:identificar, pidNuevo, num+1}) end)
            IO.inspect({num+1, pidNuevo}, label: "Anyadido nuevo worker a la lista con tupla identificativa: ")
            [{num+1, pidNuevo}]
        else
            [{num, pidhd}] ++ calcularNuevaID(pidNuevo, hd(tail), tl(tail), nodosClase)
        end
    end

    #########################################################################
    #Funciones que se encargan del calculo de los distintos tipos de workers#
    #########################################################################
    def calculation(m, type) do
        IO.puts "[PETICION] Me ha llegado una peticion y se esta calculando"
        case type do
            :divisores -> {:result, {:divList, divisors(m, 1)}}
            :sumaLista -> {:result, {:sumList, Enum.sum(m)}}
            :suma -> {:result, {:sum, Enum.sum(divPropios(m))}}
            _ -> m
        end
    end

    def divPropios(n) do
        List.delete(divisors(n,1), n)
    end

    def divisors(n, i) do
        case n do
            0 -> [0]
            1 -> [1]
            n ->    if n == i do
                        [n]
                    else
                        if rem(n,i) == 0, do: [i] ++ divisors(n, i + 1), else: divisors(n, i + 1)
                    end
        end
    end

end