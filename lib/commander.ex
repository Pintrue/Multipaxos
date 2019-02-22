defmodule Commander do
	def start leader, acceptors, replicas, p do
		waitfor = acceptors
		for acceptor <- acceptors do
			send acceptor, { :p2a, self(), p }
		end
		next leader, acceptors, replicas, p, waitfor
	end

	def next leader, acceptors, replicas, p, waitfor do
		receive do
			{ :p2b, a, b } ->
				{ballot_num, s, c} = p
				if b == ballot_num do
					waitfor = waitfor -- [a]
					if length(waitfor) < length(acceptors) / 2 do
						for rep <- replicas do
							send rep, { :decision, s, c }
						end
						exit(:normal)
					end
				else
					send leader, { :preempted, b }
					exit(:normal)
				end
				next leader, acceptors, replicas, p, waitfor
		end
	end
end