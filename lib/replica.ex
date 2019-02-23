defmodule Replica do
	@WINDOW 5
	def start config, database, monitor do
		state = database
		slot_in = 1
		slot_out = 1
		requests = MapSet.new()
		proposals = Map.new()
		decisions = Map.new()
		receive do
			{ :bind, leaders } ->

		end
	end

	def propose slot_in, slot_out, requests, decisions, leaders do
		if slot_in < slot_out + WINDOW and MapSet.size(requests) != 0 do
			requests_l = MapSet.to_list(requests)
			{request, requests_l} = List.pop_at(requests_l, 0)
			if not Map.has_key?(decisions, slot_in) do
				requests = MapSet.new(requests_l)
				proposals = Map.put(proposals, slot_in, request)
				for leader <- leaders do
					send leader, { :propose, slot_in, request }
				end
				slot_in = slot_in + 1
			end
			propose slot_in, slot_out, requests, decisions, leaders
		end
	end

	def perform request do
		{k, cid, op} = request
		all_requests = Map.values(decisions)
		# if Enum.member?(all_requests, request) and do
			
		# end
		# all_slots = Map.keys(decisions)
		# if Enum.any?(all_slots, fn s -> s < slot_out end) do
		# 	slot_out = slot_out + 1
		# else

		# end
	end
end