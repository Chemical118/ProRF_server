# nohup julia -t 16 big.jl 1>/dev/null 2>&1 &
# Big dataset
include("setting.jl") 
using ProRF, Printf
function big_dataset(data::Tuple{String, Char, Int, Int, Int, Int})
    dataset, col, feat, tree, mdep, mem = data
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)

    M, F = get_reg_importance(R, X, Y, L,
        feat, tree, max_depth=mdep,
        data_state=data_state,
        learn_state=learn_state,
        imp_state=imp_state,
        memory_usage=mem, val_mode=true)

    PY = parallel_predict(M, X)
    @save (@sprintf "Save/big/%s_%c.jld2" dataset col) F Y PY
end


# (Dataset name, excel column, feat, tree, max depth)
data_vector = Vector{Tuple{String, Char, Int, Int, Int, Int}}([
    ("AB", 'B', 6, 1000, 60, 16),
    ("avGFP", 'B', 8, 400, 270, 16),
    ("GB1", 'C', 7, 500, 190, 8),
    ("GB1p", 'F', 3, 1400, 14, 16),
    ("gGB1", 'B', 10, 2000, -1, 16),
    ("Pab1", 'B', 2, 200, 150, 16),
    ("TDP43", 'B', 9, 200, 160, 16),
    ("Ube4b", 'B', 2, 400, 110, 16),
])

map(big_dataset, data_vector)