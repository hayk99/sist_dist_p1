defmodule InteractionProtocol do
    #abstraccion del protocolo de interaccion para mayor transparencia del
    #master, y evitar tener que hardwire el codigo en el master
    #Esta funcion devuelve una tupla que contiene el modo de ejecucion/protocolo de interaccion
    #que se ha logrado utilizar en la ultima peticion, y la suma de los divisores propios del
    #numero N
    def sendRequest(master, workerSumDiv, workerDivs, workerSumList, n, executionMode) do
        if executionMode == :primario do
                send(workerSumDiv, {:req, {master, n}})
                receive do
                    {:result, {:sum, sum}} -> {:primario, sum}
                after
                    5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, executionMode, 0)
                end
        else
            if workerDivs == nil or workerSumList == nil do
                {:fallo, nil}
            else
                send(workerDivs, {:req, {master, n}})
                receive do
                    #cuando recibimos la lista de divisores, eliminamos n de esta, y enviamos
                    #la lista, ahora de divisores propios al worker que calcula la suma de una
                    #lista dada
                    {:result, {:divList, divList}} ->   send(workerSumList, {:req, {master, List.delete(divList, n)}})
                                                        receive do
                                                            #devolvemos la suma
                                                            {:result, {:sumList, sumList}} -> {:secundario, sumList}
                                                        after
                                                            5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, :secundario, 0)
                                                        end
                after
                    5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, :secundario, 0)
                    #si salta el timeout, reintentamos durante maximo cuatro veces
                end
            end
        end
    end

    def retry(master, workerSumDiv, workerDivs, workerSumList, n, executionMode, numTry) do
        if numTry < 4 do
            if executionMode == :primario do
                send(workerSumDiv, {:req, {master, n}})
                receive do
                    {:result, {:sum, sum}} -> {:primario, sum}
                after
                    5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, executionMode, numTry+1)
                end
            else
                send(workerDivs, {:req, {master, n}})
                receive do
                    #cuando recibimos la lista de divisores, eliminamos n de esta, y enviamos
                    #la lista, ahora de divisores propios al worker que calcula la suma de una
                    #lista dada
                    {:result, {:divList, divList}} ->   send(workerSumList, {:req, {master, List.delete(divList, n)}})
                                                        receive do
                                                            #devolvemos la suma
                                                            {:result, {:sumList, sumList}} -> {:secundario, sumList}
                                                        after
                                                            5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, executionMode, numTry+1)
                                                        end
                after
                    5000 -> retry(master, workerSumDiv, workerDivs, workerSumList, n, executionMode, numTry+1)
                end
            end
        else
            if executionMode == :primario do
                if workerDivs == nil or workerSumList == nil do
                    {:fallo, nil}
                else
                    retry(master, workerSumDiv, workerDivs, workerSumList, n, :secundario, 0)
                end
            else
                {:fallo, nil} #han fallado todos los workers, no podemos servir la peticion del cliente
            end
        end
    end
end