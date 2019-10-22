escenario = :uno
dir_server = :"server@127.0.0.1"
num_workers = 1

import Server

case escenario do 
	:uno ->		Server.lunchServer(dir_server)
	:dos ->		Server.lunchServer(dir_server)
	:tres ->	Server.lunchServer(dir_server, num_workers)
end