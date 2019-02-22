defmodule Acceptor do
    def start do
        # magic number ordered before any ballot sent by leaders
        ballot_num = {-999, nil}
        accepted = MapSet.new()
        next ballot_num, accepted
    end

    def next ballot_num, accepted do
        receive do
            { :p1a, leader, b } ->
                if b > ballot_num do
                    ballot_num = b
                end
                send leader, { :p1b, self(), ballot_num, accepted }
                next ballot_num, accepted
            { :p2a, leader, {b, s, c} } ->
                if b == ballot_num do
                    MapSet.put(accepted, {b, s, c})
                end
                send leader, { :p2b, self(), ballot_num }
                next ballot_num, accepted
        end
    end
end