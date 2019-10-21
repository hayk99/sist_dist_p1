# AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 


# Compilar y cargar ficheros con modulos necesarios
Code.require_file("nodo_remoto.exs", __DIR__)
Code.require_file("servidor_gv.exs", __DIR__)
Code.require_file("cliente_gv.exs", __DIR__)

#Poner en marcha el servicio de tests unitarios con :
# timeout : ajuste de tiempo máximo de ejecución de todos los tests, en miliseg.
# seed: 0 , para que la ejecucion de tests no tenga orden aleatorio
# exclusion de ejecución de aquellos tests que tengan el tag :deshabilitado
ExUnit.start([timeout: 10000, seed: 0, exclude: [:deshabilitado]])

defmodule  GestorVistasTest do

    use ExUnit.Case

    # @moduletag timeout 100  para timeouts de todos lo test de este modulo

    # Preparación de contexto de tests de integración
    # Para gestionar nodos y maquinas
    setup_all do
        # Poner en marcha los servidores, obtener nodos
        #maquinas = ["127.0.0.1", "155.210.154.196", 
        #            "155.210.154.197", "155.210.154.198"] 
        maquinas = ["127.0.0.1"]
            # devuelve una mapa de nodos del servidor y clientes
        nodos = startServidores(maquinas)
        
        on_exit fn ->
                    #eliminar_nodos Elixir y epmds en maquinas
                    #stopServidores(nodos, maquinas)
                    stopServidores(nodos, maquinas)
                end

        {:ok, nodos}
    end


    # Test 1 : No deberia haber primario
    #@tag :deshabilitado
    test "No deberia haber primario", %{c1: c1} do
        IO.puts("Test: No deberia haber primario ...")

        p = ClienteGV.primario(c1)

        assert p == :undefined

        IO.puts(" ... Superado")
    end


    # Test 2 : primer primario
   # @tag :deshabilitado
    test "Primer primario", %{c1: c} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: Primer primario ...")

        primer_primario(c, ServidorGV.latidos_fallidos() * 2)
        comprobar_tentativa(c, c, :undefined, 1)
        
        IO.puts(" ... Superado")
    end


    # Test 3 : primer nodo copia
    #@tag :deshabilitado
    test "Primer nodo copia", %{c1: c1, c2: c2} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: Primer nodo copia ...")

        {vista, _} = ClienteGV.latido(c1, -1)  # Solo interesa vista tentativa
        primer_nodo_copia(c1, c2, ServidorGV.latidos_fallidos() * 2)

        # validamos nueva vista por estar completa
        ClienteGV.latido(c1, vista.num_vista + 1)

        comprobar_valida(c1, c1, c2, vista.num_vista + 1)

        IO.puts(" ... Superado")
    end


    ## Test 4 : Después, Copia (C2) toma el relevo si Primario falla.,
   # @tag :deshabilitado
    test "Copia releva primario", %{c2: c2} do
         IO.puts("\n\n............................................\n")
        IO.puts("Test: copia toma relevo si primario falla ...")

        {vista, _} = ClienteGV.latido(c2, 2)

        copia_releva_primario(c2, vista.num_vista,
                                            ServidorGV.latidos_fallidos() * 2)
        comprobar_tentativa(c2, c2, :undefined, vista.num_vista + 1)

        IO.puts(" ... Superado")        
    end

    ## Test 5 : Servidor rearrancado (C1) se convierte en copia.
    #@tag :deshabilitado
    test "Servidor rearrancado se convierte en copia", %{c1: c1, c2: c2} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: Servidor rearrancado se conviert en copia ...")

        {vista, _} = ClienteGV.latido(c2, 2)   # vista tentativa
        servidor_rearranca_a_copia(c1, c2, 2, ServidorGV.latidos_fallidos() * 2)

        # validamos nueva vista por estar DE NUEVO completa
        # vista valida debería ser 4
        ClienteGV.latido(c2, vista.num_vista + 1)

        comprobar_valida(c2, c2, c1, vista.num_vista + 1)

        IO.puts(" ... Superado")
    end

    ## Test 6 : Servidor en espera (C3) se convierte en copia si primario falla.
    #@tag :deshabilitado
    test "Servidor en espera se convierte en copia", %{c1: c1, c3: c3} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: Servidor en espera se convierte en copia ...")

        ClienteGV.latido(c3, 0) # nuevo servidor en espera
        {vista, _} = ClienteGV.latido(c1, 4)   # vista tentativa
        IO.inspect espera_pasa_a_copia(c1, c3, 4, ServidorGV.latidos_fallidos() * 2)
        
        # validamos nueva vista por estar DE NUEVO completa
        # vista valida debería ser 5
        ClienteGV.latido(c1, vista.num_vista + 1)
        
        comprobar_valida(c1, c1, c3, vista.num_vista + 1)        
        
        IO.puts(" ... Superado")
    end
 
    # Test 7 : Primario rearrancado (C2) tratado como caido y 
    #           es convertido en nodo en espera.
    #       rearrancado_caido(C1, C3),
    test "Primario rearrancado (c2) convertido en espera", %{c1: c1, c2: c2, c3: c3} do
         IO.puts("\n\n............................................\n")
        IO.puts("Test: Primario rearrancado como espera")
        #Enviamos fallo en primario, o reinicio
        {vista, _} = ClienteGV.latido(c2, 0)
        #Comprobamos que el estado sea correcto
        rearrancado_caido(c1, c2, c3)
        #Se genera un fallo por timeout en primario y se verifica
        rearrancado_caido2(c1, c2, c3, 5)
        #Como resultado se han comprobado las distintas casuisticas de caida del primario
        IO.puts " ... Superado"
    end



    ## Test 8 : Servidor de vistas espera a que primario confirme vista
    ##          pero este no lo hace.
    ##          Poner C3 como Primario, C1 como Copia, C2 para comprobar
    ##          - C3 no confirma vista en que es primario,
    ##          - Cae, pero C1 no es promocionado porque C3 no confimo !
    # primario_no_confirma_vista(C1, C2, C3),
    test "Primario no confirma vista y cae", %{c1: c1, c2: c2, c3: c3} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: primario nunca confirma vista")
        primario_no_confirma_vista(c1, c2, c3)
    end



    ## Test 9 : Si anteriores servidores caen (Primario  y Copia),
    ##       un nuevo servidor sin inicializar no puede convertirse en primario.
    # sin_inicializar_no(C1, C2, C3),
     test "Anteriores servidores caen, nuevo servidor sin inicializar", %{sv: sv, c1: c1, c2: c2, c3: c3} do
        IO.puts("\n\n............................................\n")
        IO.puts("Test: No se reinicia el servidor")
        verificar_inconsistente(c1, c2, c3,9, 4)
        reiniciaServicio(sv, c1,c2,c3)
        primarioCopiaTirados(c3, ServidorGV.latidos_fallidos()+1)
        #C1 = primario, c2 = copia, c3= espera
        verificar_inconsistente(c1, c3, c2, 2, 4)
        #Cae primario por timeout antes que copia
        reiniciaServicio(sv, c1,c2,c3)
        ClienteGV.latido(c2, 2)
        Process.sleep(ServidorGV.intervalo_latidos())
        primarioCopiaTirados(c3, ServidorGV.latidos_fallidos()+1)
        verificar_inconsistente(c1, c3, c2, 2, 4)
    end
    
    # ------------------ FUNCIONES DE APOYO A TESTS ------------------------
    #Caso base de la recursividad de primarioCopiaTirados
    #Verifica que el estado es el esperado (ambos caidos)
    defp primarioCopiaTirados(c3, 0) do
        {vista,_} = ClienteGV.latido(c3, 2)
        comprobar_tentativa(c3, :undefined, :undefined, vista.num_vista)

    end

    #Funcion que provoca una caida en el primario y en la copia por timeouts
    defp primarioCopiaTirados(c3, n) do
        {vista,_} = ClienteGV.latido(c3, 2)
        Process.sleep(ServidorGV.intervalo_latidos())
        primarioCopiaTirados(c3, n-1)
    end

    #Reinicia el gestor de vistas con tres nodos comprobando entre el proceso
    #que la vista que se genera es primario: c1, copia: c2, y c3 en espera
    defp reiniciaServicio(sv, c1,c2,c3) do
        NodoRemoto.stop(sv)
        svn = ServidorGV.startNodo("sv", "127.0.0.1")
        ServidorGV.startService(svn)
        ClienteGV.latido(c1, 0)
        ClienteGV.latido(c2, 0)
        {vista,_} = ClienteGV.latido(c3, 0)
        Process.sleep(ServidorGV.intervalo_latidos())
        ClienteGV.latido(c2, 2)
        ClienteGV.latido(c1, 2)
        {vista,_} = ClienteGV.latido(c3, 2)
        comprobar(c1, c2, 2, vista)
        comprobar_valida(c3, c1, c2, 2)
    end


    defp verificar_inconsistente(_primario,_c2,_copia, _numV, 0), do: :fin
    defp verificar_inconsistente(primario, c2, copia, numV,n) do
        {vista,_} = ClienteGV.latido(primario, 0)
        {vista,_} = ClienteGV.latido(c2, 0)
        {vista,_} = ClienteGV.latido(copia, 0)
        comprobar_tentativa(primario, :undefined, :undefined, vista.num_vista)
        comprobarUltimaValida(c2, primario, copia, numV)
        Process.sleep(ServidorGV.intervalo_latidos())
        verificar_inconsistente(primario,c2,copia, numV,n-1)
    end


    defp primario_no_confirma_vista(c1, c2, c3) do
        #C1 = primario, C3 = copia, C2 = espera, num_vista = 5
        {vistaV,_} = ClienteGV.latido(c1, 0)
        #C3 = primario, C2 = copia, C1 = espera, tentativa.num_vista = 6
        {vista1,_} = ClienteGV.latido(c3, vistaV.num_vista - 1)
        #C3 = primario, C2 = copia, C1 = espera, tentativa.num_vista = 6
        {vista1,_} = ClienteGV.latido(c2, 0) #7???
        #C3 = primario, C1 = copia, C2 espera, Vista_valida != vista_tentativa
        Process.sleep(ServidorGV.intervalo_latidos())
        comprobar_tentativa(c3, c3, c1, vista1.num_vista)
        IO.puts "\n\n... Tentativa correcta...\nCayendo primario sin confirmar tentantiva\n"

       {vista,_} = ClienteGV.latido(c2, vistaV.num_vista-1)
       {vista,_} = ClienteGV.latido(c1, vistaV.num_vista-1)
       {vista,_} = ClienteGV.latido(c3, 0)
       comprobar_tentativa(c1, :undefined, c1, vista.num_vista)
       comprobarUltimaValida(c2, c1, c3, vistaV.num_vista-1)
    end

    #Funcion que obtiene la lista de espera en ese momento del gestor de vistas
    defp obtenerListaEspera() do
        send({:servidor_gv, :"sv@127.0.0.1"},
               {:obten_lista_espera, self()} )
        receive do
            {:lista_espera, lista_espera} -> lista_espera
        end
    end

    #Funcion que comprueba la vista adecuada cuando el primario se ha caido
    defp rearrancado_caido(c1, c2, c3) do
        {vista1,_} = ClienteGV.latido(c1, 5)
        {vista3,_} = ClienteGV.latido(c3, 5)
        comprobar(c1, c3, 5, vista3)
        #Comprobamos que la lista de espera sea la esperada
        comprobarListaEspera(obtenerListaEspera(), [c2], c2)
    end

    #Caso final de rearrancado_caido2
    defp rearrancado_caido2(c1, c2, c3, 0) do
        #Primario rearranca
        {vista1,_} = ClienteGV.latido(c1, 0)
        #Mandamos latido de actual primario y copia sin haber confirmado
        {vista1,_} = ClienteGV.latido(c2, 5)
        {vista3,_} = ClienteGV.latido(c3, 5)
        #Comprobamos que la lista de espera es la adecuada y la vista actual
        comprobarListaEspera(obtenerListaEspera(), [c1], c1)
        comprobar(c3, c2, 6, vista3)

        #Dejamos el estado como lo encontramos antes de ser llamados
        #cae copia
        {vista1,_} = ClienteGV.latido(c2, 0)
        #primario confirma
        {vista3,_} = ClienteGV.latido(c3, vista1.num_vista)
        #cae primario
        {vista3,_} = ClienteGV.latido(c3, 0)
        #nuevo primario confirma
        {vista3,_} = ClienteGV.latido(c1, vista3.num_vista)
        {vista3,_} = ClienteGV.latido(c3, 0)
        {vista3,_} = ClienteGV.latido(c2, 0)
        {vista3,_} = ClienteGV.latido(c1, vista3.num_vista)
        comprobar(c1, c3, 9, vista3)
        Process.sleep(ServidorGV.intervalo_latidos())
    end

    defp rearrancado_caido2(c1, c2, c3, n) do
        #mandamos latidos de copia y espera para que caiga el primario
        #pero la copia no
        {vista1,_} = ClienteGV.latido(c2, 5)
        {vista3,_} = ClienteGV.latido(c3, 5)
        #Comprobamos en cada iteracion el estado esperado
        comprobar(c1, c3, 5, vista3)
        Process.sleep(ServidorGV.intervalo_latidos())
        rearrancado_caido2(c1, c2, c3, n-1)
    end

    defp startServidores(maquinas) do
        tiempo_antes = :os.system_time(:milli_seconds)
        # Poner en marcha nodos servidor gestor de vistas y clientes
        # startNodos(%{tipoNodo: %{maquina: list(nombres)}})
        numMaquinas = length(maquinas)
        sv = ServidorGV.startNodo("sv", Enum.at(maquinas, 0))
        clientes = for i <- 1..3 do
                       if numMaquinas == 4 do
                           ClienteGV.startNodo("c" <> Integer.to_string(i),
                                               Enum.at(maquinas, i))
                       else # solo una máquina : la máquina local
                           ClienteGV.startNodo("c" <> Integer.to_string(i),
                                               Enum.at(maquinas, 0))
                       end
                   end
        
        # Poner en marcha servicios de cada uno
        # startServices(%{tipo: [nodos]})
        ServidorGV.startService(sv)
        c1 = ClienteGV.startService(Enum.at(clientes,0), sv)
        c2 = ClienteGV.startService(Enum.at(clientes,1), sv)
        c3 = ClienteGV.startService(Enum.at(clientes,2), sv)
    
        #Tiempo de puesta en marcha de nodos
        t_total = :os.system_time(:milli_seconds) - tiempo_antes
        IO.puts("Tiempo puesta en marcha de nodos  : #{t_total}")
        
        [sv: sv, c1: c1, c2: c2, c3: c3]   
    end
    
    defp stopServidores(servidores, maquinas) do
        IO.puts "Finalmente eliminamos nodos"
        Enum.each(servidores, fn ({ _ , nodo}) -> NodoRemoto.stop(nodo) end)
        
        # Eliminar epmd en cada maquina con nodos Elixir                            
        Enum.each(maquinas, fn(m) -> NodoRemoto.killEpmd(m) end)
    end
    
    defp primer_primario(_c, 0), do: :fin
    defp primer_primario(c, x) do

        {vista, _} = ClienteGV.latido(c, 0)

        if vista.primario != c do
            Process.sleep(ServidorGV.intervalo_latidos())
            primer_primario(c, x - 1)
        end
    end

    defp primer_nodo_copia(_c1, _c2, 0), do: :fin
    defp primer_nodo_copia(c1, c2, x) do

        # el primario : != 0 para no dar por nuevo y < 0 para no validar
        ClienteGV.latido(c1, -1)  
        {vista, _} = ClienteGV.latido(c2, 0)

        if vista.copia != c2 do
            Process.sleep(ServidorGV.intervalo_latidos())
            primer_nodo_copia(c1, c2, x - 1)
        end
    end

    def copia_releva_primario( _, _num_vista_inicial, 0), do: :fin
    def copia_releva_primario(c2, num_vista_inicial, x) do

        {vista, _} = ClienteGV.latido(c2, num_vista_inicial)

        if (vista.primario != c2) or (vista.copia != :undefined) do
            Process.sleep(ServidorGV.intervalo_latidos())
            copia_releva_primario(c2, num_vista_inicial, x - 1)
        end
    end

    defp servidor_rearranca_a_copia(_c1, _c2, _num_vista_valida, 0), do: :fin
    defp servidor_rearranca_a_copia(c1, c2, num_vista_valida, x) do

        ClienteGV.latido(c1, 0)
        {vista, _} = ClienteGV.latido(c2, num_vista_valida)

        if vista.copia != c1 do
            Process.sleep(ServidorGV.intervalo_latidos())
            servidor_rearranca_a_copia(c1, c2, num_vista_valida, x - 1)
        end
    end

    defp espera_pasa_a_copia(_c1, _c3, _num_vista_valida, 0), do: :fin
    defp espera_pasa_a_copia(c1, c3, num_vista_valida, x) do
    
        ClienteGV.latido(c3, num_vista_valida)
        {vista, _} = ClienteGV.latido(c1, num_vista_valida)
        
        if (vista.primario != c1) or (vista.copia != c3) do
            Process.sleep(ServidorGV.intervalo_latidos())
            espera_pasa_a_copia(c1, c3, num_vista_valida, x - 1)
        end
    end

    defp comprobar_tentativa(nodo_cliente, nodo_primario, nodo_copia, n_vista) do
        # Solo interesa vista tentativa
        {vista, _} = ClienteGV.latido(nodo_cliente, -1) 

        comprobar(nodo_primario, nodo_copia, n_vista, vista)        
    end


    defp comprobar_valida(nodo_cliente, nodo_primario, nodo_copia, n_vista) do
        {vista, _ } = ClienteGV.obten_vista(nodo_cliente)

        comprobar(nodo_primario, nodo_copia, n_vista, vista)

        assert ClienteGV.primario(nodo_cliente) == nodo_primario
    end


    defp comprobar(nodo_primario, nodo_copia, n_vista, vista) do
        assert vista.primario == nodo_primario 

        assert vista.copia == nodo_copia 

        assert vista.num_vista == n_vista 
    end


    defp comprobarListaEspera(lista_Recibida, lista_prueba, nodo) do
        assert lista_Recibida == lista_prueba

        assert Enum.member?(lista_Recibida, nodo)
    end

    defp comprobarUltimaValida(nodo_cliente, primario, copia, num_vista) do
        {vista, _} = ClienteGV.obten_vista(nodo_cliente)

        comprobar(primario, copia, num_vista, vista)
    end


end
