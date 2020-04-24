using KnowledgeGraphNote
using Test
include("notes.jl")

@testset "KnowledgeGraphNote.jl" begin
    # println("testing functions: $(names(KnowledgeGraphNote)[2:end])")
    # KnowledgeGraphNote.print_concepts(math_notes)
    @test Set(["affinely independent", "measure", "limit point", "empty set", "power set", "neighborhood", "set closure", "compact set"]) == Set(KnowledgeGraphNote.missing_concepts(math_notes))
    @test Dict("a"=>2) == KnowledgeGraphNote.get_duplicate_concepts(duplicate_notes)
    @test Set(["a", "b"]) == Set(KnowledgeGraphNote.get_known_concepts(duplicate_notes))
    mathkg = KnowledgeGraphNote.init_knowledge_graph(math_notes)
    @test length(KnowledgeGraphNote.find_cycles(mathkg)) == 0
    cyclickg = KnowledgeGraphNote.init_knowledge_graph(cyclic_notes)
    @test [["a", "b", "c"]] == KnowledgeGraphNote.find_cycles(cyclickg)
end
