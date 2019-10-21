#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 21 de Octubre de 2018
# DESCRIPCION: Script de arranque de Workers para el escenario 4
#           Se automodifica desde Script.sh

nombre = "w9"
direccion = "192.168.43.172"
direccion_servidor = :"servidor@192.168.43.151"
EscenarioCuatro.arrancarWorker(nombre, direccion, direccion_servidor)