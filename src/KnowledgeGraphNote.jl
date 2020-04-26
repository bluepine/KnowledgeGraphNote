module KnowledgeGraphNote

using LightGraphs
using UUIDs

struct Concept
    name::String
    link::String    
    dependency::Array{String, 1}
    text::String
end

struct KnowledgeGraph
    graph::SimpleDiGraph
    nametoid::Dict{String,Int} # normalized concept name => vertex id in graph
    idtoname::Array{String} # vertex id in graph => normalized concept name
end

function print_concepts(concepts::Array{Concept, 1})
    if isnothing(concepts)
        return
    end
    for concept in concepts
        println("name: $(concept.name)")
        println("link: $(concept.link)")
        if length(concept.dependency) > 0
            println("prerequisites: $(concept.dependency)")
        end
        println(concept.text)
        println("")
    end
end

normalize_concept_name(name) = lowercase(strip(name))

get_concept_index(concepts) = Dict([(normalize_concept_name(concept.name), findfirst(x->x.name == concept.name, concepts)) for concept in concepts])

function get_digraph(concepts)
    g = SimpleDiGraph(length(concepts))
    concept_index = get_concept_index(concepts)
    for (index, concept) in enumerate(concepts)
        if length(concept.dependency) > 0
            for prerequisite in concept.dependency
                nprerequisite = normalize_concept_name(prerequisite)
                if haskey(concept_index, nprerequisite)
                    # ignore missing concepts for now
                    add_edge!(g, index, concept_index[nprerequisite])
                end
            end
        end
    end
    return (g, concept_index, [normalize_concept_name(concept.name) for concept in concepts])
end

# use an struct to hold the knowledge graph in memory so we don't have to recreate it as long as the concepts are not changed.
# it is advised to check duplicate concepts before creating knowledge graph.
function init_knowledge_graph(concepts::Array{Concept, 1})
    g, nametoid, idtoname = get_digraph(concepts)
    return KnowledgeGraph(g, nametoid, idtoname)
end

get_known_concepts(concepts) = unique(normalize_concept_name.(getfield.(concepts, :name)))


function get_duplicate_concepts(concepts::Array{Concept, 1})
    known_concepts = get_known_concepts(concepts)
    concept_occurrences = [(concept,count(c->normalize_concept_name(c.name)==concept, concepts)) for concept in known_concepts]
    duplicate_occurrences = Dict(filter(item -> item[2] > 1, concept_occurrences))
    return duplicate_occurrences
end

function get_missing_concepts(concepts::Array{Concept, 1})
    known_concepts = get_known_concepts(concepts)
    dependencies = reduce(concepts; init = Set()) do acc, concept
        acc = union(acc, Set(concept.dependency))
    end
    ret = setdiff(normalize_concept_name.(dependencies), known_concepts)    
    return ret
end

function find_cycles(kg::KnowledgeGraph)
    #    savegraph("test.gml", kg.graph, "graph_name", GMLFormat())
    cycles = simplecycles(kg.graph)
    return [kg.idtoname[cycle] for cycle in cycles]
end

function generate_dot_string(graph::SimpleDiGraph, idtoname::Array{String}, name::String)
    dot = ["DiGraph $(name) {"]
    for v in vertices(graph)
        push!(dot, "$(v) [label=\"$(idtoname[v])\"];")        
    end
    for e in edges(graph)
        push!(dot, "$(e.src) -> $(e.dst);")
    end
    push!(dot, "}")
    return join(dot, "\n")    
end

write_string_to_file(str::String, path::String) =  open(path, "w") do io
    write(io, str)
end

function export_knowledge_graph(kg::KnowledgeGraph, path::String)
    dot = generate_dot_string(kg.graph, kg.idtoname, "KnowledgeGraph")
    write_string_to_file(dot, path)
end


function export_knowledge_graph_towards_target(kg::KnowledgeGraph, target::String, path::String)
    ntarget = normalize_concept_name(target)
    subgraph_vertices = dfs_preordering(kg.graph, kg.nametoid[ntarget])
    # println(subgraph_vertices)
    subgraph, vmap = induced_subgraph(kg.graph, subgraph_vertices)    
    dot = generate_dot_string(subgraph, kg.idtoname[vmap], filter(c-> (c>='a' && c<='z'), ntarget))
    write_string_to_file(dot, path)
end

"""
please make sure there are no loops in the graph before calling this function.
return value: postordering ordered vector of vertices traversed by by dfs

using the non-recursive dfs pseudocode from https://en.wikipedia.org/wiki/Depth-first_search#Pseudocode

procedure DFS-iterative(G, v) is
    let S be a stack
    S.push(v)
    while S is not empty do
        v = S.pop()
        if v is not labeled as discovered then
            label v as discovered
            for all edges from v to w in G.adjacentEdges(v) do 
                S.push(w)

this method is not recursive, because having the knowledge graph size limited by julia call stack size limit is not ok.

this method will use a function to sort a vertex's neighbors before traversing them to guarantee deterministic ordering. notice that neighbors_sort_fn needs to output the reverse of your intended traverse order because we are using a stack to hold the sorted vertex list. you can supply nothing to neighbors_sort_fn to slightly speed up the program.
"""
function dfs_postordering(graph::SimpleDiGraph, start::Int; neighbors_sort_fn = reverse ∘ sort)
    S = [start]
    n = nv(graph)
    recursive_postorder_callstack = Array{Tuple{Int, Int}}(undef, 0) # dfs post order is much easier to understand in recursive traversal. so we try to picture what would happen in recursive traversal to compute post order
    postorder = Array{Int}(undef, 0)
    # preorder = Array{Int}(undef, 0)    
    discovered = BitArray(undef, n) .& 0 # a hash optimized for worst case senario

    while length(S) > 0
        v = pop!(S)
        if discovered[v] == 0
            discovered[v] = 1
            # push!(preorder, v)
            v_neighbors = neighbors(graph, v)
            if nothing != neighbors_sort_fn
                v_neighbors = neighbors_sort_fn(v_neighbors)
            end
            # println("v $(v)'s sorted neighbors: $(v_neighbors)")
            v_neighbors_discovered = 0
            v_first_undiscovered_neighbor = 0
            for w in v_neighbors
                if discovered[w] == 0
                    # only push undiscovered neighbors
                    push!(S, w)
                    if 0 == v_first_undiscovered_neighbor
                        v_first_undiscovered_neighbor = w
                    end
                else
                    v_neighbors_discovered += 1
                end
            end

            if v_neighbors_discovered == length(v_neighbors)
                # all of v's neighbors have been discovered. this is the last time we'll visit v
                push!(postorder, v)
                # now check if v is it's parent's first undiscovered neighbor
                while length(recursive_postorder_callstack) > 0 && recursive_postorder_callstack[end][2] == v
                    v_parent = recursive_postorder_callstack[end][2]
                    #all of v's parent's neighbors have been pushed to postorder.
                    while length(recursive_postorder_callstack) > 0 && recursive_postorder_callstack[end][2] == v
                        frame = pop!(recursive_postorder_callstack)
                        # println("poping $(frame) from recursive_postorder_callstack for v: $(v)")
                        v_parent = frame[1]
                        push!(postorder, v_parent)
                    end
                    v = v_parent #important! let's move on to check v's parent's parent
                end
            else
                # some of v's neighbors have not been discovered. they are pushed to S.
                # println("pushing to recursive_postorder_callstack: $((v, v_first_undiscovered_neighbor))")
                push!(recursive_postorder_callstack, (v, v_first_undiscovered_neighbor))
            end
        end
    end
    # println("preorder: $(preorder)")
    # println("postorder: $(postorder)")
    # println("recursive_postorder_callstack: $(recursive_postorder_callstack)")
    return postorder
end


"""
using the non-recursive dfs pseudocode from https://en.wikipedia.org/wiki/Depth-first_search#Pseudocode

procedure DFS-iterative(G, v) is
    let S be a stack
    S.push(v)
    while S is not empty do
        v = S.pop()
        if v is not labeled as discovered then
            label v as discovered
            for all edges from v to w in G.adjacentEdges(v) do 
                S.push(w)

why dfs_preordering when i already coded dfs_postordering? because dfs_preordering is more efficient when computing the collection of vertexes in the start vertexes' subgraph.
"""
function dfs_preordering(graph::SimpleDiGraph, start::Int)
    S = [start]
    n = nv(graph)
    preorder = Array{Int}(undef, 0)    
    discovered = BitArray(undef, n) .& 0 # a hash optimized for worst case senario

    while length(S) > 0
        v = pop!(S)
        if discovered[v] == 0
            discovered[v] = 1
            push!(preorder, v)
            v_neighbors = neighbors(graph, v)
            for w in v_neighbors
                if discovered[w] == 0
                    # only push undiscovered neighbors
                    push!(S, w)
                end
            end
        end
    end
    # println("preorder: $(preorder)")
    return preorder
end


"""
given a target concept, compute a sequence to learn all of its prerequisite concepts. every concept in this sequence will have its own prerequisites placed before it.

given the above definition, the result sequence is a reverse of the topological sort (https://en.wikipedia.org/wiki/Topological_sorting) of the subgraph induced by target.

please make sure the knowledge graph contains no cycles before calling this function. in other words, please make sure the input knowledge graph is a dag.

since reverse postordering of dfs travsersal of dag produces a topological sorting (https://en.wikipedia.org/wiki/Depth-first_search#Vertex_orderings), we'll just use dfs postordering to produce the result sequence.

dfs postordering ensures that every vertex is placed adjacent to its descendants. i think this is good for maintaining relevenance concepts in working memory while learning.

however dfs postordering might not be unqiue for a dag. i would use a special sorting function to determine the order in which a vertex's children is visited in dfs.

this sorting function will prioritize the children that have smaller induced subgraph. the rationale is that we'll try to make the most progress towards the target concept as early as possible, by picking the lowest hanging fruit first.

dfs traversal can provide the size of induced subgraph for a vertex. however i haven't found a way to compute induced subgraph size for all vertexes in a graph efficiently. so for now i'm using brutal force approach, doing a dfs for every single vertex concerned.
"""
function generate_learning_plan(kg::KnowledgeGraph, target::String)
    ntarget = normalize_concept_name(target)
    if !haskey(kg.nametoid, ntarget)
        println("$(target) is not in knowledge graph.")
        return []
    end
    targetid = kg.nametoid[ntarget]
    subgraph_size_dict = Dict{Int, Int}()
    subgraph_vertexes = dfs_preordering(kg.graph, targetid)
    subgraph_size_dict[targetid] = length(subgraph_vertexes)
    deleteat!(subgraph_vertexes, 1)
    for vertex in subgraph_vertexes
        subgraph_size_dict[vertex] = length(dfs_preordering(kg.graph, vertex))
    end
    
    # println("subgraph size:")
    # for (k, v) in subgraph_size_dict
    #     println("  $(kg.idtoname[k]): $(v)")
    # end

    sort_fn = children -> sort(children, lt=(x, y)->subgraph_size_dict[x] > subgraph_size_dict[y])
    learning_order = dfs_postordering(kg.graph, targetid, neighbors_sort_fn=sort_fn)
    return learning_order
    
end

"""
perhaps we can also code a function to write all notes to a file, ordered by generate_learning_plan. that requires us to identify all the root concepts (concepts which no other concepts depends on) in the knowledge graph.
but i don't think i need that. i think it's good to always have a target concept in mind when reading notes.
"""

function write_notes_for_target_concept_to_md_file(kg::KnowledgeGraph, concepts::Array{Concept, 1}, target::String, path::String)
    ntarget = normalize_concept_name(target)
    lines = ["# notes for $(target)"]
    learning_plan = generate_learning_plan(kg, ntarget)
    idtouuid = Dict{Int, UUID}()
    missing_concept_set = get_missing_concepts(concepts)
    for id in learning_plan
        concept = concepts[id]
        uuid = uuid4()
        idtouuid[id] = uuid
        push!(lines, "## <a name=\"$(uuid)\"></a>$(concept.name)")
        push!(lines, "### link: [$(concept.link)]($(concept.link))")

        if length(concept.dependency) > 0
            push!(lines, "### prerequisites")
            prerequisite_lines = []
            for prerequisite_concept in concept.dependency
                nprerequisite = normalize_concept_name(prerequisite_concept)
                if nprerequisite in missing_concept_set
                    push!(prerequisite_lines, "missing: $(prerequisite_concept)")
                else
                    prerequisite_uuid = idtouuid[kg.nametoid[nprerequisite]]
                    push!(prerequisite_lines, "[$(prerequisite_concept)](#$(prerequisite_uuid))")    
                end
            end
            push!(lines, join(prerequisite_lines, " | \n"))
        end
        push!(lines, "\n### definition  ")
        push!(lines, concept.text)
        push!(lines, "\n  \n--------------------------------  \n")
    end

    md_text = join(lines, "\n")
    write_string_to_file(md_text, path)
end

export init_analyer, print_concepts, get_missing_concepts, get_duplicate_concepts, get_known_concepts, find_cycles, init_knowledge_graph, export_knowledge_tree, export_knowledge_graph_towards_target, generate_learning_plan, write_notes_for_target_concept_to_md_file
end # module
