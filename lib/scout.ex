# Pinchu Ye (py416) and Chuanqing Lu (cl5616)

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
			{pvalues, waitfor} =
			if b == ballot_num do
				pvalues = MapSet.union(pvalues, r)
				waitfor = waitfor -- [a]
				if length(waitfor) < length(acceptors) / 2 do
					send leader, { :adopted, ballot_num, pvalues }
					exit(:normal)
				end
				{pvalues, waitfor}
			else
				send leader, { :preempted, b }
				exit(:normal)
			end
			next leader, acceptors, ballot_num, waitfor, pvalues
		end

	end
end
