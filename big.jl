# julia -t 16
# Big dataset
include("setting.jl") 
using ProRF, Printf
function big_dataset(data::Tuple{String, Char, Int, Int, Int})
    dataset, col, feat, tree, mdep = data
    printm(dataset)
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)
    M, F = get_reg_importance(R, X, Y, L, feat, tree, max_depth=mdep, data_state=data_state, learn_state=learn_state, imp_state=imp_state, val_mode=true, imp_iter=1)
    PY = parallel_predict(M, X)
    @save (@sprintf "Save/big/%s_%c.jld2" dataset col) F Y PY
    printm(dataset * " end")
end


# (Dataset name, excel column, feat, tree, max depth)
data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
    ("AB", 'B', 6, 1000, 60),
    ("avGFP", 'B', 8, 400, 270),
    ("GB1", 'C', 7, 500, 190),
    ("GB1p", 'F', 3, 1400, 14),
    ("gGB1", 'B', 10, 2000, -1),
    ("Pab1", 'B', 2, 200, 150),
    ("TDP43", 'B', 9, 200, 160),
    ("Ube4b", 'B', 2, 400, 110),
])

map(big_dataset, data_vector)