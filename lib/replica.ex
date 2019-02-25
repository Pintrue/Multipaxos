# Pinchu Ye (py416) and Chuanqing Lu (cl5616)

defmodule Replica do
	@window 5
	def start _, database, monitor do
		slot_in = 1
		slot_out = 1
		requests = MapSet.new()
		proposals = Map.new()
		decisions = Map.new()
		receive do
			{ :bind, leaders } ->
				body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor, MapSet.new
		end
	end

	def propose slot_in, slot_out, requests, proposals, decisions, leaders do
		if slot_in < slot_out + @window and MapSet.size(requests) != 0 do
			requests_l = MapSet.to_list(requests)
			{request, requests_l} = List.pop_at(requests_l, 0)
			{proposals, requests} =
			if not Map.has_key?(decisions, slot_in) do
				proposals = Map.put(proposals, slot_in, request)
				requests = MapSet.new(requests_l)
				for leader <- leaders do
					send leader, { :propose, slot_in, request }
				end
				{proposals, requests}
			else
				{proposals, requests}
			end
			propose slot_in + 1, slot_out, requests, proposals, decisions, leaders
		else
			{slot_in, requests, proposals}
		end
	end

	def perform slot_out, decisions, database, cmd, exe do
		decisions_l = Map.to_list(decisions)

		sorted = decisions_l |> List.keysort(0)
		# IO.inspect sorted
		# IO.puts "Looking for command #{inspect cmd}"

		exe =
		if not MapSet.member?(exe, cmd) do
			d = List.keyfind(decisions_l, cmd, 1)
			if not (d != nil and Enum.at(Tuple.to_list(d), 0) < slot_out) do
				# IO.puts "Found command #{inspect d} with slot out #{slot_out}"
				{_, _, op} = cmd
				send database, { :execute, op }
				MapSet.put(exe, cmd)
			else
				exe
			end
		else
			exe
		end

		{slot_out + 1, exe}
	end

	def body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor, exe do
		{slot_out, decisions, proposals, requests, exe} =
		receive do
			{ :client_request, c } ->
				requests = MapSet.put(requests, c)
				send monitor, { :client_request, self() }
				{slot_out, decisions, proposals, requests, exe}
			{ :decision, s, c } ->
				# if Map.has_key?(decisions, s) and decisions[s] == c do
				# 	IO.puts "Duplicate"
				# end
				decisions = Map.put(decisions, s, c)
				{slot_out, proposals, requests, exe} = while_perform decisions, slot_out, proposals, requests, database, exe
				{slot_out, decisions, proposals, requests, exe}
		end
		{slot_in, requests, proposals} = propose slot_in, slot_out, requests, proposals, decisions, leaders
		body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor, exe
	end


	def while_perform decisions, slot_out, proposals, requests, database, exe do
		all_d_slots = Map.keys(decisions)
		if Enum.member?(all_d_slots, slot_out) do
			c_dec = Map.get(decisions, slot_out)
			all_p_slots = Map.keys(proposals)
			{proposals, requests} =
			if Enum.member?(all_p_slots, slot_out) do
				c_prop = Map.get(proposals, slot_out)
				proposals = Map.delete(proposals, slot_out)
				requests =
				if c_dec != c_prop do
					MapSet.put(requests, c_prop)
				else
					requests
				end
				{proposals, requests}
			else
				{proposals, requests}
			end
			{slot_out, exe} = perform slot_out, decisions, database, c_dec, exe
			while_perform decisions, slot_out, proposals, requests, database, exe
		else
			{slot_out, proposals, requests, exe}
		end
	end
end
