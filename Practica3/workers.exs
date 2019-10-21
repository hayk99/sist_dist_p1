# AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 


defmodule Worker do

    def startWorker(type, id) do
        startWorker(type, String.to_atom(to_string(type) <> to_string(id + 1) <> "@127.0.0.1"), 
                    :"master@127.0.0.1", String.to_atom(to_string(type) <> "1@127.0.0.1"), id)
    end

    #si comenzado con :divisores, comienza el worker que calcula
    #la lista de divisores dado N. Si comenzado con: :sumaLista
    #comienza el worker que calcula los divisores propios de N.
    #Si comenzado con :suma, comienza el worker encargado de calcular
    #la suma de todos los numeros contenidos en una lista
    def startWorker(type, direccion, master, primary, mID) do
        Node.start direccion
		Process.register(self(), type)
		Node.set_cookie(direccion, :sisdist)
        #conexion con el master
        Node.connect(primary)
        if(direccion == primary) do
            comenzarPrimary(init(), type, mID, 
            [{0, {type, String.to_atom(to_string(type) <> "1@127.0.0.1")}}, {1, {type, String.to_atom(to_string(type) <> "2@127.0.0.1")}}, 
                {2, {type, String.to_atom(to_string(type) <> "3@127.0.0.1")}}, {3, {type, String.to_atom(to_string(type) <> "4@127.0.0.1")}}, 
                {4, {type, String.to_atom(to_string(type) <> "5@127.0.0.1")}}], master)
        else
            loopEspera(master, init(), type, mID,  
           [{0, {type, String.to_atom(to_string(type) <> "1@127.0.0.1")}}, {1, {type, String.to_atom(to_string(type) <> "2@127.0.0.1")}}, 
                {2, {type, String.to_atom(to_string(type) <> "3@127.0.0.1")}}, {3, {type, String.to_atom(to_string(type) <> "4@127.0.0.1")}}, 
                {4, {type, String.to_atom(to_string(type) <> "5@127.0.0.1")}}])
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

    #Comenzamos el nodo como primary, y a la vez el proceso que genera los latidos
    def comenzarPrimary(worker_type, type, id, nodosClase, master) do
        pidLatido = spawn(Worker, :generadorLatidos, [nodosClase, id])
        send({:master, master}, {:soyLider, id, {type, Node.self()}})
        IO.puts "Proceso de latido spawneado"
        loopI(master, worker_type, type, id, nodosClase, pidLatido)
    end

    #envia :latido a cada nodo de "nodosClase" cada 1s si no se le pide que se duerma o muera
    def generadorLatidos(nodosClase, id) do
        receive do
            {:duerme, d} -> IO.puts "Proceso de latido duermiendose"
                            Process.sleep(d)
                            Enum.each(nodosClase, fn {sId, {t, sDir}} -> if sDir == Node.self do
                                                                    else
                                                                        send({t, sDir}, {:latido, id}) 
                                                                    end 
                                                  end)
                            generadorLatidos(nodosClase, id)
                            IO.puts "[LATIDO] Enviando latido a todos los workers"
            :end -> IO.puts "Proceso de latidos terminado"
        after #continue
            1000 -> Enum.each(nodosClase, fn {sId, {t, sDir}} -> if sDir == Node.self do
                                                            else
                                                                send({t, sDir}, {:latido, id}) 
                                                            end 
                                          end)
                    IO.puts "[LATIDO] Enviando latido a todos los workers"
                    generadorLatidos(nodosClase, id)
        end
    end

    def loopI(master, worker_type, type, id, nodosClase, pidLatido) do
        delay = case worker_type do
            :crash -> if :rand.uniform(100) > 75, do: :infinity, else: 0
            :timing -> :rand.uniform(100)*1000
            _ ->  0
        end
        if delay == :infinity do
            IO.puts "He crasheado"
            send(pidLatido, :end)
        end
        if delay > 0 do 
            IO.puts "Me he dormido " <> to_string(delay) <> "ms"
            send(pidLatido, {:duerme, delay})
        end
        Process.sleep(delay)
        receive do 
            {:req, {m_pid,m}} -> IO.puts "[PETICION] Me ha llegado una peticion"
                                 if (((worker_type == :omission) and (:rand.uniform(100) < 75)) or (worker_type == :timing) or (worker_type==:no_fault) or (worker_type==:crash)) do
                                    send(m_pid, calculation(m, type)) 
                                 end
          #  {:latido, dirLatido} -> send(pidLatido, :end)
          #                          generarEleccion(type, id, nodosClase)
          #                          esperaEleccionL(master,  worker_type, type, id, nodosClase)
            {:eleccion, elId, dirPeticion} ->   IO.puts "Ha comenzado una eleccion y sigo vivo."
                                                send(pidLatido, :end)
                                                IO.puts "He matado a mi proceso latido"
                                                receive do 
                                                    {:soyLider, lId, lidDir} -> IO.puts "Ya hay un nuevo lider, dejo de ser lider"
                                                    loopEspera(master, worker_type, type, id, nodosClase)
                                                after  10000 -> IO.puts "Aun no hay lider asignado"
                                                    send(dirPeticion, {:ok, id})
                                                    generarEleccion(type, id, nodosClase)
                                                    esperaEleccionL(master,  worker_type, type, id, nodosClase)
                                                end
            {:soyLider, lId, lidDir} -> send(pidLatido, :end)
                                        IO.puts "Hay otro lider. Me quedo en espera, dejo que sea lider porque sere problematico"
                                        loopEspera(master, worker_type, type, id, nodosClase)      
            otros  -> IO.inspect otros                    
        end
        loopI(master, worker_type, type, id, nodosClase, pidLatido)
    end

    #Bucle a la espera. Mientras primary genere latidos
    def loopEspera(master, worker_type, type, id, nodosClase) do
     delay = case worker_type do
            :crash -> if :rand.uniform(100) > 75, do: :infinity, else: 0
            :timing -> :rand.uniform(100)*1000
            _ ->  0
        end
        if delay == :infinity do
            IO.puts "He crasheado"
        end
        if delay > 0 do 
            IO.puts "Me he dormido " <> to_string(delay) <> "ms"
        end
        Process.sleep(delay)
        receive do
            {:soyLider, lId, lidDir} -> loopEspera(master, worker_type, type, id, nodosClase)
            {:latido, prId} ->  IO.puts "Me ha llegado un latido"
                                loopEspera(master, worker_type, type, id, nodosClase)
            {:eleccion, elId, dirPeticion} ->   send(dirPeticion, {:ok, id})
                                                IO.puts "Se ha provocado una eleccion de lider"
                                                generarEleccion(type, id, nodosClase)
                                                esperaEleccionL(master,  worker_type, type, id, nodosClase)

        after #si ha saltado el timeout implica que el lider esta caido o existe mucha latencia, iniciamos por tanto eleccion
            5000 -> IO.puts "Ha saltado el timeout, el primary no esta disponible"
                    generarEleccion(type, id, nodosClase)
                    esperaEleccionL(master,  worker_type, type, id, nodosClase)
        end
    end

    def esperaEleccionL(master,  worker_type, type, id, nodosClase) do
    delay = case worker_type do
            :crash -> if :rand.uniform(100) > 75, do: :infinity, else: 0
            :timing -> :rand.uniform(100)*1000
            _ ->  0
        end
        if delay == :infinity do
            IO.puts "He crasheado"
        end
        if delay > 0 do 
            IO.puts "Me he dormido " <> to_string(delay) <> "ms"
        end
        Process.sleep(delay)
        receive do
            #si nos llega un mensaje de eleccion, significa que esa maquina tiene un id mayor, por lo que le contestamos con un ok para indicarle
            #que no tiene derecho a ser lider
            {:eleccion, elId, dirPeticion} ->   IO.inspect(dirPeticion, label: "Enviando :ok a ")
                                                send(dirPeticion, {:ok, id})
                                                esperaEleccionL(master,  worker_type, type, id, nodosClase)
             #si me llega un ok estando en este estado, significa que hay un nodo activo con menor id
            {:ok, sId} ->   IO.puts "Me ha llegado un :ok, ya no puedo ser lider"
                            esperaEleccionOL(master,  worker_type, type, id, nodosClase)
            {:soyLider, lId, lidDir} -> IO.puts "Estaba esperando al nuevo lider y me ha llegado :soyLider"
                                        loopEspera(master, worker_type, type, id, nodosClase)
            #{:latido, prId} ->  IO.puts "Me ha llegado un latido esperando al nuevo lider"
            #                    esperaEleccionL(master,  worker_type, type, id, nodosClase)
         after #si no ha llegado ningun mensaje de :ok, significa que somos el lider, y se lo indicamos a todos los nodos de la lista
            10000 ->  Enum.each(nodosClase, fn {sId, sDir} -> 
                                             if sId != id do
                                                 IO.inspect Node.self()
                                                send(sDir, {:soyLider, id, {type, Node.self()}}) 
                                                IO.inspect(sDir, label: "enviando Soy lider a")
                                            end end)
                    send({:master, master}, {:soyLider, id, {type, Node.self()}})
                    IO.puts "Ha saltado el timeout esperando a lider, por tanto soy el nuevo lider"
                    comenzarPrimary(worker_type, type, id, nodosClase, master)
        end
    end

    def esperaEleccionOL(master,  worker_type, type, id, nodosClase) do
        delay = case worker_type do
            :crash -> if :rand.uniform(100) > 75, do: :infinity, else: 0
            :timing -> :rand.uniform(100)*1000
            _ ->  0
        end
        if delay == :infinity do
            IO.puts "He crasheado"
        end
        if delay > 0 do 
            IO.puts "Me he dormido " <> to_string(delay) <> "ms"
        end
        Process.sleep(delay)
         receive do
            {:eleccion, elId,dirPeticion} -> send(dirPeticion, {:ok, id})
                                             IO.puts "Me ha llegado :eleccion de un nodo con indice superior cuando ya no puedo ser lider"
                                             esperaEleccionOL(master,  worker_type, type, id, nodosClase)          
            #Si alguien se proclama lider, a la espera de que fallse
            {:soyLider, lId, lidDir} -> loopEspera(master, worker_type, type, id, nodosClase)
            {:ok, sId} ->  esperaEleccionOL(master,  worker_type, type, id, nodosClase)
            #{:latido, prId} ->  IO.puts "Me ha llegado un latido esperando al nuevo lider sin poder ser lider yo"
            #                    esperaEleccionOL(master,  worker_type, type, id, nodosClase)
             after #Si t_i > timeout -> Posible nuevo lider caido
            15000 -> IO.puts "Posible nuevo lider caido, generando eleccion de nuevo"
                     generarEleccion(type, id, nodosClase)
                     esperaEleccionL(master,  worker_type, type, id, nodosClase)
        end
    end
            
    #########################################################################
    #Funciones que se encargan del calculo de los distintos tipos de workers#
    #########################################################################
    def calculation(m, type) do
        IO.puts "[PETICION] Me ha llegado una peticion y se esta calculando"
        case type do
            :divisores -> {:result, m, {:divList, divisors(m, 1)}}
            :sumaLista -> {:result, m, {:sumList, Enum.sum(m)}}
            :suma -> {:result, m, {:sum, Enum.sum(divPropios(m))}}
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