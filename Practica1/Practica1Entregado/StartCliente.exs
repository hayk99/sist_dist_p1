#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 21 de Octubre de 2018
# DESCRIPCION: Script de arranque de Workers para el escenario 3
#           Se automodifica desde Script.sh
escenario = :uno
direccion_cliente = :"cliente@127.0.0.1"
direccion_servidor = :"servidor@127.0.0.1"
EscenarioUno.arrancarCliente(:server, escenario, direccion_cliente, direccion_servidor)