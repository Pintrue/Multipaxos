defmodule Leader do
	def start do
		ballot_num = {0, self()}
		active = false
		proposals = Map.new()
		receive do
			{ :bind, acceptors, replicas } ->
				spawn Scout, :start, [self(), acceptors, ballot_num]
				next acceptors, replicas, ballot_num, active, proposals
		end
	end

	def next acceptors, replicas, ballot_num, active, proposals do
		receive do
			{ :propose, s, c } ->
				if not Map.has_key?(proposals, s) do
					proposals = Map.put(proposals, s, c)
					if active do
						spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
					end
				end
			{ :adopted, ballot_num, pvals } ->
				pvals_list = MapSet.to_list(pvals)
				slot_group = Enum.group_by(pvals_list, fn {_,s,_} -> s end)
				pmax =
				for {k, v} <- slot_group do
					sorted_slot_group = List.keysort(v, 0)
					{_, slot, c} = List.last(sorted_slot_group)
					{slot, c}
				end
				proposals = Map.merge(proposals, Enum.into(pmax, %{}))
				
				# pvals_sorted = List.keysort(MapSet.to_list(pvals), 0)	# Map already sorted
				# {_, s, c} = List.last(pvals_sorted)	# pmax
				# proposals = 
		end
		
	end
end