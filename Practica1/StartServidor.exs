#AUTORES: Victor Lafuente, Enrique Torres
# NIAs: 747325 734980 
# FICHERO: para_perfectos.exs
# FECHA: 17 de Octubre de 2018
# DESCRIPCION: Script de arranque de escenarios
escenario = :tres
direccion = :"servidor@192.168.43.151"
direccion_workers = "192.168.43.172"
case escenario do
	  :uno -> 		EscenarioUno.arrancar(direccion)
	  :dos -> 		EscenarioDos.arrancar(direccion)
	  :tres -> 		EscenarioTres.arrancar(direccion, direccion_workers)
	  :cuatro -> 	EscenarioCuatro.arrancar(direccion, direccion_workers)
	  _ ->			IO.puts "No existe el escenario"
end