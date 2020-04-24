using KnowledgeGraphNote
using Test
include("notes.jl")

@testset "KnowledgeGraphNote.jl" begin
    # println("testing functions: $(names(KnowledgeGraphNote)[2:end])")
    # KnowledgeGraphNote.print_concepts(math_notes)
    @test Set(["affinely independent", "measure", "limit point", "empty set", "power set", "neighborhood", "set closure", "compact set"]) == Set(KnowledgeGraphNote.missing_concepts(math_notes))
    @test Dict("a"=>2) == KnowledgeGraphNote.get_duplicate_concepts(duplicate_notes)
    @test Set(["a", "b"]) == Set(KnowledgeGraphNote.get_known_concepts(duplicate_notes))
    @test length(KnowledgeGraphNote.find_cycles(math_notes)) == 0
    @test [["a", "b", "c"]] == KnowledgeGraphNote.find_cycles(cyclic_notes)
end
