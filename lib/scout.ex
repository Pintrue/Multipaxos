defmodule Scout do
	def start leader, acceptors, ballot_num do
		waitfor = acceptors
		pvalues = MapSet.new()
		for acceptor <- acceptors do
			send acceptor, { :p1a, self(), ballot_num }
		end
		next leader, acceptors, ballot_num, waitfor, pvalues
	end

	def next leader, acceptors, ballot_num, waitfor, pvalues do
		receive do
			{ :p1b, a, b, r } ->
			if b == ballot_num do
				pvalues = MapSet.union(pvalues, MapSet.new([r]))
				waitfor = waitfor -- [a]
				if length(waitfor) < length(acceptors) / 2 do
					send leader, { :adopted, ballot_num, pvalues }
					exit(:normal)
				end
			else
				send leader, { :preempted, b }
				exit(:normal)
			end
			next leader, acceptorsm ballot_num, ballot_num, waitfor, pvalues
		end
		
	end
end