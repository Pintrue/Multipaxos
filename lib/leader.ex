defmodule Leader do
	@time_slot 75
	def start _ do
		ballot_num = {0, self()}
		active = false
		proposals = Map.new()
		receive do
			{ :bind, acceptors, replicas } ->
				spawn Scout, :start, [self(), acceptors, ballot_num]
				next acceptors, replicas, ballot_num, active, proposals, 0
		end
	end

	def next acceptors, replicas, ballot_num, active, proposals, collisions do
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
				next acceptors, replicas, ballot_num, active, proposals, collisions
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

				collisions = if collisions == 0 do 0 else collisions - 1 end
				next acceptors, replicas, ballot_num, active, proposals, collisions
			{ :preempted, {r, _} } ->
				collisions = collisions + 1
				max_wait = (trunc(:math.pow(2, collisions)) - 1) * @time_slot
				# IO.inspect {self, max_wait}
				rand = Enum.random(0..max_wait)
				# IO.puts "#{inspect self} going to sleep for #{inspect rand} ms"
				Process.sleep(rand)

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
				next acceptors, replicas, ballot_num, active, proposals, collisions
		end
	end
end