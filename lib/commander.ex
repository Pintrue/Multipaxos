# Pinchu Ye (py416) and Chuanqing Lu (cl5616)

defmodule Commander do
	def start leader, acceptors, replicas, p, monitor do
		send monitor, { :commander_spawned, leader }
		waitfor = acceptors
		for acceptor <- acceptors do
			send acceptor, { :p2a, self(), p }
		end
		next leader, acceptors, replicas, p, waitfor, monitor
	end

	def next leader, acceptors, replicas, p, waitfor, monitor do
		receive do
			{ :p2b, a, b } ->
				{ballot_num, s, c} = p
				waitfor =
				if b == ballot_num do
					waitfor = waitfor -- [a]
					if length(waitfor) < length(acceptors) / 2 do
						# IO.puts "#{inspect self} send decisions"
						for rep <- replicas do
							send rep, { :decision, s, c }
						end
						send monitor, { :commander_finished, leader }
						exit(:normal)
					end
					waitfor
				else
					send leader, { :preempted, b }
					send monitor, { :commander_finished, leader }
					exit(:normal)
				end
				next leader, acceptors, replicas, p, waitfor, monitor
		end
	end
end
