# AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 


defmodule Cliente do
    
    def startCliente(client_ip, server_ip) do
        Node.start client_ip
		Process.register(self(), :cliente)
		Node.set_cookie(client_ip, :sisdist)
        loopCliente(client_ip, server_ip, 1)
    end

    def startCliente() do
        Node.start :"cliente@127.0.0.1"
		Process.register(self(), :cliente)
		Node.set_cookie(:"cliente@127.0.0.1", :sisdist)
        loopCliente(:"cliente@127.0.0.1", :"master@127.0.0.1", 1)
    end

    def loopCliente(client_ip, server_ip, num_intento) do
        send({:master, server_ip}, {{:cliente, client_ip}, :calculaAmigos, 1, 10000})
        IO.inspect(num_intento, label: "Enviada peticion numero ")
        receive do
            {:amigos, listaAmigos} -> if listaAmigos == nil do
                                        IO.puts "El servidor ha tenido un error y no ha podido responder la peticion"
                                      else
                                        IO.inspect(listaAmigos, label: to_string(num_intento) <> "La lista de amigos entre 1 a 1000000 son ")
                                        loopCliente(client_ip, server_ip, num_intento+1)
                                      end
        end
    end
end