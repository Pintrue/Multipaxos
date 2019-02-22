defmodule Scout do
    def start leader, acceptors, b do
        waitfor = acceptors
        pvalues = MapSet.new()
        next leader, acceptors, b, waitfor, pvalues
        for acceptor <- acceptors do
            send acceptor, { :p1a, self(), b }
        end
    end

    def next leader, acceptors, b, waitfor, pvalues do
        
    end
end