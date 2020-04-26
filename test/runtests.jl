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
    
    
    target = "borel sigma-algebra"    
    @test mathkg.idtoname[KnowledgeGraphNote.generate_learning_plan(mathkg, target)] == ["set", "sigma-algebra", "metric", "metric space", "open set", "closed set", "topological space", "borel sigma-algebra"]

    #### the dot file format is described here: https://en.wikipedia.org/wiki/DOT_(graph_description_language). you can find a viewer from there.
    #### it's not a good idea to write files in unit tests. uncommment these lines locally to see what they do.
    # KnowledgeGraphNote.export_knowledge_graph(mathkg, "./math.dot")
    # KnowledgeGraphNote.export_knowledge_graph_towards_target(mathkg, target, "./target.dot")
    # KnowledgeGraphNote.write_notes_for_target_concept_to_md_file(mathkg, math_notes, target, "./target.md")

    
    ######################### testing library internal functions
    dfs_postordering_test1_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test1)
    # KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test1_kg, "./dfs_postordering_test1.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test1_kg.graph, 1)
    @test ["d", "b", "e", "c", "t", "a"] == dfs_postordering_test1_kg.idtoname[postorder]

    dfs_postordering_test2_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test2)
    # KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test2_kg, "./dfs_postordering_test2.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test2_kg.graph, 1)
    @test ["d", "b", "c", "a"] == dfs_postordering_test2_kg.idtoname[postorder]

    dfs_postordering_test3_kg = KnowledgeGraphNote.init_knowledge_graph(dfs_postordering_test3)
    # KnowledgeGraphNote.export_knowledge_graph(dfs_postordering_test3_kg, "./dfs_postordering_test3.dot")
    postorder = KnowledgeGraphNote.dfs_postordering(dfs_postordering_test3_kg.graph, 1)
    @test ["f", "e", "b", "d", "c", "a"] == dfs_postordering_test3_kg.idtoname[postorder]
    

end
