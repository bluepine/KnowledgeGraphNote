using KnowledgeGraphNote
using Test
include("notes.jl")

@testset "KnowledgeGraphNote.jl" begin
    # println("testing functions: $(names(KnowledgeGraphNote)[2:end])")
    # KnowledgeGraphNote.print_concepts(math_notes)
    @test Set(["affinely independent", "measure", "limit point", "empty set", "power set", "neighborhood", "set closure", "compact set"]) == Set(KnowledgeGraphNote.get_missing_concepts(math_notes))
    @test Dict("a"=>2) == KnowledgeGraphNote.get_duplicate_concepts(duplicate_notes)
    @test length(KnowledgeGraphNote.get_duplicate_concepts(math_notes)) == 0
    @test Set(["a", "b"]) == Set(KnowledgeGraphNote.get_known_concepts(duplicate_notes))
    mathkg = KnowledgeGraphNote.init_knowledge_graph(math_notes)
    @test length(KnowledgeGraphNote.find_cycles(mathkg)) == 0
    cyclickg = KnowledgeGraphNote.init_knowledge_graph(cyclic_notes)
    @test [["a", "b", "c"]] == KnowledgeGraphNote.find_cycles(cyclickg)


    # # it's not a good idea to write files in unit tests. i'll have to come up with something else to unittest these two functions
    # KnowledgeGraphNote.export_knowledge_graph(mathkg, "./math.dot")
    # KnowledgeGraphNote.export_knowledge_graph_towards_target(mathkg, "borel sigma-algebra", "./mathradonmeasure.dot")
    
#    println(KnowledgeGraphNote.generate_learning_plan(mathkg, math_notes,  "Borel measure"))
end
