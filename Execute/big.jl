# nohup julia -t 16 big.jl 1>/dev/null 2>&1 &
# Big dataset
include("setting.jl") 
using ProRF, Printf
function big_dataset(data::Tuple{String, Char, Int, Int, Int, Int})
    dataset, col, feat, tree, mdep, mem = data
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)

    feat, tree, mdep = get_rf_value(X, Y,
        iter=5,
        memory_usage=mem,
        val_mode=true)

    open("big.txt", "a") do io
        write(io, @sprintf "%d %d %d\n" feat tree mdep)
    end

    M, F = get_reg_importance(R, X, Y, L,
        feat, tree, max_depth=mdep,
        data_state=data_state,
        learn_state=learn_state,
        imp_state=imp_state,
        memory_usage=mem, val_mode=true)

    PY = parallel_predict(M, X)
    @save (@sprintf "NSave/big/%s_%c.jld2" dataset col) F Y PY
end


# (Dataset name, excel column, feat, tree, max depth, memory)
data_vector = Vector{Tuple{String, Char, Int, Int, Int, Int}}([
    ("AB", 'B', 6, 1000, 60, 8),
    ("avGFP", 'B', 8, 400, 270, 8),
    ("GB1", 'C', 7, 500, 190, 8),
    ("GB1p", 'F', 3, 1400, 140, 8),
    ("gGB1", 'B', 10, 2000, -1, 8),
    ("Pab1", 'C', 2, 200, 150, 8),
    ("TDP43", 'B', 9, 200, 160, 8),
    ("Ube4b", 'B', 2, 400, 110, 8),
])

open("big.txt", "w") do io
end

map(big_dataset, data_vector)