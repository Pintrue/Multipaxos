# Pinchu Ye (py416) and Chuanqing Lu (cl5616)
defmodule Acceptor do
	def start _ do
		# magic number ordered before any ballot sent by leaders
		ballot_num = {-999, nil}
		accepted = MapSet.new()
		next ballot_num, accepted
	end

	def next ballot_num, accepted do
		receive do
			{ :p1a, leader, b } ->
				ballot_num =
				if b > ballot_num do
					b
				else
					ballot_num
				end
				send leader, { :p1b, self(), ballot_num, accepted }
				next ballot_num, accepted
			{ :p2a, leader, {b, s, c} } ->
				accepted =
				if b == ballot_num do
					MapSet.put(accepted, {b, s, c})
				else
					accepted
				end
				send leader, { :p2b, self(), ballot_num }
				next ballot_num, accepted
		end
	end
end
