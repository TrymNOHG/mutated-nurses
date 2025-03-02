module Dequeue

mutable struct TrivialDeque
    myDeque::Vector{Int}   # Vector to store the elements
    indexFront::Int        # Index of the front element
    indexBack::Int         # Index of the back element
end

# Constructor: allocates a vector of given size and initializes the first element.
function TrivialDeque(nbElements::Int, firstNode::Int)
    vec = Vector{Int}(undef, nbElements)
    vec[1] = firstNode
    return TrivialDeque(vec, 1, 1)
end

# Remove the front element by incrementing the front index.
function pop_front!(td::TrivialDeque)
    td.indexFront += 1
end

# Remove the back element by decrementing the back index.
function pop_back!(td::TrivialDeque)
    td.indexBack -= 1
end

# Add an element to the back.
function push_back!(td::TrivialDeque, i::Int)
    td.indexBack += 1
    td.myDeque[td.indexBack] = i
end

# Get the front element.
function get_front(td::TrivialDeque)
    return td.myDeque[td.indexFront]
end

# Get the element immediately after the front.
function get_next_front(td::TrivialDeque)
    return td.myDeque[td.indexFront + 1]
end

# Get the back element.
function get_back(td::TrivialDeque)
    return td.myDeque[td.indexBack]
end

# Reset the deque to a single element.
function reset!(td::TrivialDeque, firstNode::Int)
    td.myDeque[1] = firstNode
    td.indexFront = 1
    td.indexBack = 1
end

# Return the current size of the deque.
function size(td::TrivialDeque)
    return td.indexBack - td.indexFront + 1
end
end