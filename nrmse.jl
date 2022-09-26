# nohup julia -p 2 -t 8 nrmse.jl 1>/dev/null 2>&1 &
@everywhere using ProRF, XLSX, BioAlignments, Printf, DataFrames, JLD2, Statistics, Random

@everywhere begin
function blosum_matrix(num::Int)
    if num == 45
        return BLOSUM45
    elseif num == 50
        return BLOSUM50
    elseif num == 62
        return BLOSUM62
    elseif num == 80
        return BLOSUM80
    elseif num == 90
        return BLOSUM90
    else
        error(@sprintf "There are no Matrix such as BLOSUM%d" num)
    end
end

function _find_key(dict::Dict{Char, Int}, tar::Int)
    for k in keys(dict)
        if dict[k] == tar
            return k
        end
    end
end

function get_data_b(R::AbstractRF, excel_col::Char; blosum::Int=62, norm::Bool=false, sheet::String="Sheet1", title::Bool=true)
    excel_data = DataFrames.DataFrame(XLSX.readtable(R.data_loc, sheet, infer_eltypes=title))
    excel_select_vector = excel_data[!, Int(excel_col) - Int('A') + 1]
    data_idx = findall(!ismissing, excel_select_vector)
    excel_select_vector = Vector{Float64}(excel_select_vector[data_idx])
    if norm == true
        excel_select_vector = min_max_norm(excel_select_vector)
    end

    data_len, loc_dict_vector, seq_matrix = ProRF._location_data(R.fasta_loc, data_idx)
    blo = blosum_matrix(blosum)
    x_col_vector = Vector{Vector{Float64}}()
    loc_vector = Vector{Tuple{Int, Char}}()
    for (ind, (dict, col)) in enumerate(zip(loc_dict_vector, eachcol(seq_matrix)))
        max_val = maximum(values(dict))
        max_amino = _find_key(dict, max_val)
        if '-' ∉ keys(dict) && 1 ≤ data_len - max_val 
            push!(x_col_vector, [blo[max_amino, i] for i in col])
            push!(loc_vector, (ind, max_amino))
        end
    end
    
    x = Matrix{Float64}(hcat(x_col_vector...))
    y = Vector{Float64}(excel_select_vector)
    l = Vector{Tuple{Int, Char}}(loc_vector)
    return x, y, l
end

function get_nrmse(dict_sel)
    dict_nrmse_vector = Vector{Float64}()
    for (dataset, col, tree) in data_vector
        R = RF("Data/" * dataset)
        X, Y, L = (dict_sel == "BLOSUM62" ? get_data_b(R, col) : get_data(R, col, convert=dict_sel))

        data_state_vector = Vector{UInt64}(rand(MersenneTwister(data_state), UInt64, 100))
        pa_nrmse_vector = [rf_nrmse(X, Y, trunc(Int, size(X, 2)^0.5), tree,
            data_state=d,
            learn_state=learn_state,
            val_mode=true)[2] for d in data_state_vector]

        push!(dict_nrmse_vector, mean(pa_nrmse_vector))
    end
    return dict_nrmse_vector
end

@load "Save/seed.jld2" data_state learn_state imp_state

data_vector = Vector{Tuple{String, Char, Int}}([
    ("GB1", 'C', 150),    
    ("AB", 'B', 1000),
    ("avGFP", 'B', 300),
    ("GB1p", 'F', 300),
    ("gGB1", 'B', 400),
    ("Pab1", 'C', 200),
    ("TDP43", 'B', 200),
    ("Ube4b", 'B', 200),
    ("avGFPs", 'B', 1000),    
    ("avGFPs", 'C', 1000),
    ("avGFPs", 'F', 1000),
    ("eqFP578s", 'C', 1000),
    ("DsReds", 'C', 1000),
    ("RBs", 'B', 1000),
    ("RBs", 'C', 1000),
])
end # everywhere end

nrmse_vector = Vector{Vector{Float64}}(pmap(get_nrmse, ["BLOSUM62", "vol", "pI", "hyd", ["vol", "pI"], ["vol", "hyd"], ["pI", "hyd"], "all"]))

nrmse_matrix = Matrix{Float64}(hcat(nrmse_vector...))

@save "AData/save_nrmse.jld2" nrmse_matrix