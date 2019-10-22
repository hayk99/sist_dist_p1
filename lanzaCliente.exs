escenario = :uno
dir_server = :"server@127.0.0.1"
dir_client = :"client@127.0.0.1"
direccion_workers = "n"


Escenario.lunchClient(:server, escenario, dir_server, dir_client)
case escenario do
	  :uno -> 		Escenario.lunchServer(dir_server)
	  :dos -> 		Escenario.lunchServer(dir_server)
	  :tres -> 		Escenario.lunchServer(dir_server, direccion_workers)
	  #_ ->			IO.inspect (escenario, label: "No existe el escenario: ")
end