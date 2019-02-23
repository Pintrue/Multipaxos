defmodule Leader do
	def start _ do
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
				proposals =
				if not Map.has_key?(proposals, s) do
					proposals = Map.put(proposals, s, c)
					if active do
						spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
					end
					proposals
				else
					proposals
				end
				next acceptors, replicas, ballot_num, active, proposals
			{ :adopted, ballot_num, pvals } ->
				pvals_list = MapSet.to_list(pvals)	
				slot_group = Enum.group_by(pvals_list, fn {_,s,_} -> s end)
				pmax =
				for {_, v} <- slot_group do
					sorted_slot_group = List.keysort(v, 0)
					{_, slot, c} = List.last(sorted_slot_group)
					{slot, c}
				end
				proposals = Map.merge(proposals, Enum.into(pmax, %{}))
				for {s, c} <- proposals do
					spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
				end
				active = true
				next acceptors, replicas, ballot_num, active, proposals
			{ :preempted, {r, _} } ->
				{b, _} = ballot_num
				{active, ballot_num} =
				if r >= b do
					active = false
					ballot_num = {r + 1, self()}
					spawn Scout, :start, [self(), acceptors, ballot_num]
					{active, ballot_num}
				else
					{active, ballot_num}
				end
				rand = Enum.random(0..100)
				Process.sleep(rand)
				next acceptors, replicas, ballot_num, active, proposals
		end
	end
end