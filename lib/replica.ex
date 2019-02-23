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
				body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor
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

	def perform slot_out, decisions, database, cmd do
		decisions_l = Map.to_list(decisions)
		d = List.keyfind(decisions_l, cmd, 1)
		if not (d != nil and Enum.at(Tuple.to_list(d), 0) < slot_out) do
			{_, _, op} = cmd
			send database, { :execute, op }
		end
		slot_out + 1
	end

	def body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor do
		{slot_out, decisions, proposals, requests} =
		receive do
			{ :client_request, c } ->
				requests = MapSet.put(requests, c)
				send monitor, { :client_request, self() }
				{slot_out, decisions, proposals, requests}
			{ :decision, s, c } ->
				decisions = Map.put(decisions, s, c)
				{slot_out, proposals, requests} = while_perform decisions, slot_out, proposals, requests, database
				{slot_out, decisions, proposals, requests}
		end
		{slot_in, requests, proposals} = propose slot_in, slot_out, requests, proposals, decisions, leaders
		body slot_in, slot_out, requests, proposals, decisions, leaders, database, monitor
	end


	def while_perform decisions, slot_out, proposals, requests, database do
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
			slot_out = perform slot_out, decisions, database, c_dec
			while_perform decisions, slot_out, proposals, requests, database
		else
			{slot_out, proposals, requests}
		end
	end
end