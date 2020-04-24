module KnowledgeGraphNote

using LightGraphs

struct Concept
    name::String
    link::String    
    dependency::Array{String, 1}
    text::String
end

function print_concepts(concepts)
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

get_known_concepts(concepts) = unique(normalize_concept_name.(getfield.(concepts, :name)))

function get_duplicate_concepts(concepts)
    known_concepts = get_known_concepts(concepts)
    concept_occurrences = [(concept,count(c->normalize_concept_name(c.name)==concept, concepts)) for concept in known_concepts]
    duplicate_occurrences = Dict(filter(item -> item[2] > 1, concept_occurrences))
    return duplicate_occurrences
end

function missing_concepts(concepts)
    known_concepts = get_known_concepts(concepts)
    dependencies = reduce(concepts; init = Set()) do acc, concept
        acc = union(acc, Set(concept.dependency))
    end
    ret = setdiff(normalize_concept_name.(dependencies), known_concepts)    
    return ret
end

# function digraph(concepts)
#     g = SimpleDiGraph(length(concepts))

# end

# function find_cycles(concepts)

#     savegraph("test.gml", g, "graph_name", GraphIO.GML.GMLFormat())    
# end

export print_concepts, missing_concepts, get_duplicate_concepts, get_known_concepts
end # module
