using KnowledgeGraphNote
using Test
include("notes.jl")

@testset "KnowledgeGraphNote.jl" begin
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
    

    dfs_postordering_test1_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test1)
    KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test1_kg, "./dfs_postordering_test1.dot")
    (postorder, subgraph_size) = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test1_kg.graph, 1)
    @test ["d", "b", "e", "c", "t", "a"] == dfs_postordering_test1_kg.idtoname[postorder]

    dfs_postordering_test2_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test2)
    KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test2_kg, "./dfs_postordering_test2.dot")
    (postorder, subgraph_size) = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test2_kg.graph, 1)
    @test ["d", "b", "c", "a"] == dfs_postordering_test2_kg.idtoname[postorder]

    #    println(KnowledgeGraphNote.generate_learning_plan(mathkg, math_notes,  "Borel measure"))
end
