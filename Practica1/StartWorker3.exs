#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 18 de Octubre de 2018
# DESCRIPCION: Script de arranque de Workers para el escenario 3
#           Se automodifica desde Script.sh
nombre = "w2"
direccion = "192.168.43.172"
direccion_servidor = :"servidor@192.168.43.151"
EscenarioTres.arrancarWorker(nombre, direccion, direccion_servidor)