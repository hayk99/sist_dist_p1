#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 17 de Octubre de 2018
# DESCRIPCION: Script de cualquier escenario
#     USO: numero_escenario, nodo_cliente, nodo_servidor/Master, ip_worker


#pasar como parametro el escenario
epmd -daemon

if [ "$#" -ne 4 ]; then
    echo "El numero de parametros no es correcto"
    echo "El orden correcto de parametros es: num_escenario, nodo_cliente, nodo_servidor/Master, ip_workers"
    exit 1
fi

#cambiamos la direccion en la que comenzara el servidor/master al tercer parametro
sed -i "/direccion =/c\direccion = $3" "$PWD/StartServidor.exs"
#cambiamos la direccion en la que se encontraran los workers al cuarto parametro
sed -i "/direccion_workers =/c\direccion_workers = \"$4\"" "$PWD/StartServidor.exs"
#cambiamos la direccion de los propios workers en los escenarios 3 y 4
sed -i "/direccion =/c\direccion = \"$4\"" "$PWD/StartWorker3.exs"
sed -i "/direccion =/c\direccion = \"$4\"" "$PWD/StartWorker4.exs"
#indicamos la direccion del servidor a los workers
sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartWorker3.exs"
sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartWorker4.exs"

#arrancar escenario 1 cliente-servidor
if [ $1 -eq 1 ]
then
    sed -i '/escenario =/c\escenario = :uno' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :uno' "$PWD/StartCliente.exs"
    xterm -hold -e bash -c "elixir StartServidor.exs" &
        #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    sleep 1
    elixir StartCliente.exs
#arrancar escenario 2 cliente-servidor concurrente
elif [ $1 -eq 2 ]
then
    sed -i '/escenario =/c\escenario = :dos' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :dos' "$PWD/StartCliente.exs"
    xterm -hold -e bash -c "elixir StartServidor.exs" &
        #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    sleep 1
    elixir StartCliente.exs
#arrancar escenario 3 con workers, master y cliente en la maquina local
elif [ $1 -eq 3 ]
then
    sed -i '/escenario =/c\escenario = :tres' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :tres' "$PWD/StartCliente.exs"
    xterm -hold -e bash -c "elixir StartServidor.exs" &
    sleep 1
    for i in {1..3}
    do
        sed -i "/nombre =/c\nombre = \"w$i\"" "$PWD/StartWorker3.exs"
        xterm -hold -e bash -c "elixir StartWorker3.exs" &
        sleep 1
    done
        #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    elixir StartCliente.exs
#arrancar escenario 4 con workers, master y cliente en la maquina local
elif [ $1 -eq 4 ]
then
    sed -i '/escenario =/c\escenario = :cuatro' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :cuatro' "$PWD/StartCliente.exs"
    xterm -hold -e bash -c "elixir StartServidor.exs" &
    sleep 1
    for i in {1..9}
    do
        sed -i "/nombre =/c\nombre = \"w$i\"" "$PWD/StartWorker4.exs"
        xterm -hold -e bash -c "elixir StartWorker4.exs" &
        sleep 1
    done
        #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    elixir StartCliente.exs
#empezar solo servidor y cliente del escenario tres
elif [ $1 -eq 5 ]
then
    sed -i '/escenario =/c\escenario = :tres' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :tres' "$PWD/StartCliente.exs"
    xterm -hold -e bash -c "elixir StartServidor.exs" &
	sleep 5
    #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    elixir StartCliente.exs
#empezar solo servidor y cliente del escenario cuatro
elif [ $1 -eq 6 ]
then
    sed -i '/escenario =/c\escenario = :cuatro' "$PWD/StartServidor.exs"
    sed -i '/escenario =/c\escenario = :cuatro' "$PWD/StartCliente.exs"
    (xterm -hold -e bash -c "elixir StartServidor.exs") > "$PWD/logserver.log" &
    sleep 25
    #sustituye las direcciones por los parametros 2 y 3
    sed -i "/direccion_cliente =/c\direccion_cliente = $2" "$PWD/StartCliente.exs"
    sed -i "/direccion_servidor =/c\direccion_servidor = $3" "$PWD/StartCliente.exs"
    elixir StartCliente.exs
#arrancar solo los workers del escenario 3
elif [ $1 -eq 7 ]
then
    for i in {1..3}
    do
        sed -i "/nombre =/c\nombre = \"w$i\"" "$PWD/StartWorker3.exs"
        xterm -hold -e bash -c "elixir StartWorker3.exs" &
        sleep 1
    done
#arrancar solo los workers del escenario 4
elif [ $1 -eq 8 ]
then
    for i in {1..3}
    do
        sed -i "/nombre =/c\nombre = \"w$i\"" "$PWD/StartWorker4.exs"
        xterm -hold -e bash -c "elixir StartWorker4.exs" &
        sleep 3
    done
elif [ $1 -eq 9 ]
then
    for i in {4..6}
    do
        sed -i "/nombre =/c\nombre = \"w$i\"" "$PWD/StartWorker4.exs"
        xterm -hold -e bash -c "elixir StartWorker4.exs" &
        sleep 1
    done
else
    echo "Error, escenario desconocido"
fi