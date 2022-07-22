# julia -t 3 -p 5
# Small dataset
@everywhere include("setting.jl") 
@everywhere using ProRF, Printf
@everywhere function small_dataset(data::Tuple{String, Char, Int, Int, Int})
    dataset, col, feat, tree, mdep = data
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)
    MZ, SZ = iter_get_reg_importance(R, X, Y, L, feat, tree, 500, 1, max_depth=mdep, data_state_seed=data_state, learn_state_seed=learn_state, imp_state=imp_state, memory_usage=25, val_mode=true)
    M = rf_model(X, Y, feat, tree, data_state=data_state, learn_state=learn_state, max_depth=mdep, val_mode=true)
    PY = parallel_predict(M, X)
    @save (@sprintf "Save/small/%s_%c.jld2" dataset col) MZ SZ Y PY
end


# (Dataset name, excel column, feat, tree, max depth)
data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
    ("avGFPs", 'C', 30, 2000, -1),
    ("eqFP578s", 'C', 12, 2000, -1),
    ("DsReds", 'C', 10, 2000, -1),
    ("RBs", 'B', 5, 2000, -1),
    ("RBs", 'C', 5, 2000, -1),
])

pmap(small_dataset, data_vector)