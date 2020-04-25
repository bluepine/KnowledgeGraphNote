using KnowledgeGraphNote
using Test
include("notes.jl")

@testset "KnowledgeGraphNote.jl" begin

######################### testing library api
    # KnowledgeGraphNote.print_concepts(math_notes)
    @test Set(KnowledgeGraphNote.get_missing_concepts(math_notes)) == Set(["affinely independent", "measure", "limit point", "empty set", "power set", "neighborhood", "set closure", "compact set"])
    @test KnowledgeGraphNote.get_duplicate_concepts(duplicate_notes) == Dict("a"=>2)
    @test length(KnowledgeGraphNote.get_duplicate_concepts(math_notes)) == 0
    @test Set(KnowledgeGraphNote.get_known_concepts(duplicate_notes)) == Set(["a", "b"])
    
    mathkg = KnowledgeGraphNote.init_knowledge_graph(math_notes)
    @test length(KnowledgeGraphNote.find_cycles(mathkg)) == 0
    cyclickg = KnowledgeGraphNote.init_knowledge_graph(cyclic_notes)
    @test [["a", "b", "c"]] == KnowledgeGraphNote.find_cycles(cyclickg)
    # println(KnowledgeGraphNote.generate_learning_plan(mathkg, math_notes,  "Borel measure"))
    
    # # it's not a good idea to write files in unit tests. i'll have to come up with something else to unittest these two functions
    # KnowledgeGraphNote.export_knowledge_graph(mathkg, "./math.dot")
    # KnowledgeGraphNote.export_knowledge_graph_towards_target(mathkg, "borel sigma-algebra", "./mathradonmeasure.dot")
    





    
######################### testing library internal functions
    dfs_postordering_test1_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test1)
    KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test1_kg, "./dfs_postordering_test1.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test1_kg.graph, 1)
    @test ["d", "b", "e", "c", "t", "a"] == dfs_postordering_test1_kg.idtoname[postorder]

    dfs_postordering_test2_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test2)
    KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test2_kg, "./dfs_postordering_test2.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test2_kg.graph, 1)
    @test ["d", "b", "c", "a"] == dfs_postordering_test2_kg.idtoname[postorder]

    dfs_postordering_test3_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test3)
    KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test3_kg, "./dfs_postordering_test3.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test3_kg.graph, 1)
    @test ["f", "e", "b", "d", "c", "a"] == dfs_postordering_test3_kg.idtoname[postorder]
    

end
