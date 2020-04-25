module KnowledgeGraphNote

using LightGraphs


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
    parent_vector = bfs_parents(kg.graph, kg.nametoid[ntarget])
    subgraph_vertices = [index for (index, parent) in enumerate(parent_vector) if parent > 0]
    println(subgraph_vertices)
    subgraph, vmap = induced_subgraph(kg.graph, subgraph_vertices)    
    dot = generate_dot_string(subgraph, kg.idtoname[vmap], filter(c-> (c>='a' && c<='z'), ntarget))
    write_string_to_file(dot, path)
end


function generate_learning_plan(kg::KnowledgeGraph, concepts::Array{Concept, 1}, target::String)
    ntarget = normalize_concept_name(target)
    if haskey(kg.nametoid, ntarget)
        missing_concepts = Set(get_missing_concepts(concepts))
        learning_order = []
        return (missing_concepts, learning_order)
    else
        println("$(target) is not in knowledge graph.")
        return ()
    end
end

export init_analyer, print_concepts, get_missing_concepts, get_duplicate_concepts, get_known_concepts, find_cycles, init_knowledge_graph, export_knowledge_tree, export_knowledge_graph_towards_target, generate_learning_plan
end # module
