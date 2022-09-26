using ProRF, Printf, JLD2, Statistics, DecisionTree, BioAlignments, XLSX

import DataFrames

@load "Save/seed.jld2" data_state learn_state imp_state

function load_big_dataset(dataset_name::String, excel_loc::Char='.'; val_mode::Bool=false)
    data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
        ("AB", 'B', 6, 1000, 60),
        ("avGFP", 'B', 8, 400, 270),
        ("GB1", 'C', 7, 500, 190),
        ("GB1p", 'F', 3, 1400, 14),
        ("gGB1", 'B', 10, 2000, -1),
        ("Pab1", 'C', 2, 200, 150),
        ("TDP43", 'B', 9, 200, 160),
        ("Ube4b", 'B', 2, 400, 110),
    ])

    ind_vector = findall(x -> x[1] == dataset_name, data_vector)
    if isempty(ind_vector)
        error("Check dataset name")
    elseif length(ind_vector) > 1
        eind_vector = findall(x -> x[2] == excel_loc && x[1] == dataset_name, data_vector)
        if isempty(eind_vector)
            error("Check dataset location")
        end
        ind = eind_vector[1]
    else
        ind = ind_vector[1]
    end

    dataset, col, feat, tree, mdep = data_vector[ind]
    @printf "Dataset : %s_%c\n" dataset col
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)
    @load (@sprintf "NSave/big/%s_%c.jld2" dataset col) F Y PY

    if val_mode == false
        @printf "Sample : %d\nVariable : %d\n" size(X, 1) length(get_amino_loc(L))
    end
    return R, X, Y, L, F, Y, PY
end

function load_small_dataset(dataset_name::String, excel_loc::Char='.'; val_mode::Bool=false)
    data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
        ("avGFPs", 'B', 30, 2000, -1),    
        ("avGFPs", 'C', 30, 2000, -1),
        ("avGFPs", 'F', 8, 2000, -1),
        ("eqFP578s", 'C', 12, 2000, -1),
        ("DsReds", 'C', 10, 2000, -1),
        ("RBs", 'B', 5, 2000, -1),
        ("RBs", 'C', 5, 2000, -1)
    ])
    
    ind_vector = findall(x -> x[1] == dataset_name, data_vector)
    if isempty(ind_vector)
        error("Check dataset name")
    elseif length(ind_vector) > 1
        eind_vector = findall(x -> x[2] == excel_loc && x[1] == dataset_name, data_vector)
        if isempty(eind_vector)
            error("Check dataset location")
        end
        ind = eind_vector[1]
    else
        ind = ind_vector[1]
    end

    dataset, col, feat, tree, mdep = data_vector[ind]
    @printf "Dataset : %s_%c\n" dataset col
    R = RF("Data/" * dataset)
    X, Y, L = get_data(R, col, norm=true)
    @load (@sprintf "NSave/small/%s_%c.jld2" dataset col) MZ SZ Y PY

    if val_mode == false
        @printf "Sample : %d\nVariable : %d\n" size(X)...
    end
    return R, X, Y, L, MZ, SZ, Y, PY
end

function load_dataset_model(dataset_name::String, excel_loc::Char='.')
    data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
        ("avGFPs", 'B', 30, 2000, -1),    
        ("avGFPs", 'C', 30, 2000, -1),
        ("avGFPs", 'F', 8, 2000, -1),
        ("eqFP578s", 'C', 12, 2000, -1),
        ("DsReds", 'C', 10, 2000, -1),
        ("RBs", 'B', 5, 2000, -1),
        ("RBs", 'C', 5, 2000, -1),
        ("AB", 'B', 6, 1000, 60),
        ("avGFP", 'B', 8, 400, 270),
        ("GB1", 'C', 7, 500, 190),
        ("GB1p", 'F', 3, 1400, 14),
        ("gGB1", 'B', 10, 2000, -1),
        ("Pab1", 'C', 2, 200, 150),
        ("TDP43", 'B', 9, 200, 160),
        ("Ube4b", 'B', 2, 400, 110),
    ])

    ind_vector = findall(x -> x[1] == dataset_name, data_vector)
    if isempty(ind_vector)
        error("Check dataset name")
    elseif length(ind_vector) > 1
        eind_vector = findall(x -> x[2] == excel_loc && x[1] == dataset_name, data_vector)
        if isempty(eind_vector)
            error("Check dataset location")
        end
        ind = eind_vector[1]
    else
        ind = ind_vector[1]
    end


    dataset, col, feat, tree, mdep = data_vector[ind]

    return load_model(@sprintf "NModel/%s_%c.jld2" dataset col)
end

function test_top5(R::AbstractRF, NL::Vector{String}, F::Vector{Float64})
    for loc in filter(x -> '*' ∉ x, getindex.(sort(collect(zip(NL, F)), by = x -> x[2], rev=true), 1)[1:5])
        @printf "Location : %s\n" loc
        loc_num = parse(Int, loc[1:end-1])
        cdict = [ProRF.volume, ProRF.pI, ProRF.hydrophobicity][only(loc[end]) - 'a' + 1]
    
        seq_data = ProRF._location_data(R.fasta_loc)
        loc_dict = seq_data[2][loc_num]
    
        aa_vector = collect(keys(loc_dict))
        val_vector = collect(values(loc_dict)) ./ seq_data[1]
        
        sort_idx = sortperm(val_vector, rev=true)
    
        aa_vector = aa_vector[sort_idx]
        val_vector = val_vector[sort_idx]
    
        for (aa, val) in zip(aa_vector, val_vector)
            @printf "%c (%.2f) : %.4f\n" aa cdict[aa] val
        end
        println()
    end
end

function r2(tru::Vector{Float64}, pre::Vector{Float64})
    m = mean(tru)
    sst = sum((tru .- m).^2)
    ssr = sum((pre .- m).^2)
    return 1 - (ssr / sst)
end

d123 = Dict('E' => "GLU", 'Z' => "GLX", 'X' => "XAA", 'B' => "ASX", 'C' => "CYS", 'D' => "ASP", 'A' => "ALA", 'R' => "ARG", 'G' => "GLY", 'N' => "ASN", 'Q' => "GLN", 'P' => "PRO", 'K' => "LYS", 'J' => "XLE", 'F' => "PHE", 'I' => "ILE", 'O' => "PYL", 'H' => "HIS", 'M' => "MET", 'W' => "TRP", 'T' => "THR", 'S' => "SER", 'U' => "SEC", 'L' => "LEU", 'Y' => "TYR", 'V' => "VAL")
d321 = Dict("GLN" => 'Q', "ASX" => 'B', "LYS" => 'K', "GLY" => 'G', "ASN" => 'N', "TRP" => 'W', "THR" => 'T', "VAL" => 'V', "XLE" => 'J', "HIS" => 'H', "SER" => 'S', "XAA" => 'X', "PRO" => 'P', "SEC" => 'U', "ASP" => 'D', "PHE" => 'F', "ILE" => 'I', "PYL" => 'O', "TYR" => 'Y', "ARG" => 'R', "LEU" => 'L', "ALA" => 'A', "MET" => 'M', "GLU" => 'E', "CYS" => 'C', "GLX" => 'Z')

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

function parallel_predict_b(regr::RandomForestRegressor, L::Vector{Tuple{Int, Char}}, seq_vector::Vector{String}; blosum::Int=62)
    seq_vector = map(x -> x[map(y -> y[1], L)], seq_vector)

    blo = blosum_matrix(blosum)
    test_vector = Array{Vector{Float64}}(undef, length(seq_vector))
    Threads.@threads for i in eachindex(seq_vector)
        test_vector[i] = [Float64(blo[tar, s]) for ((_, tar), s) in zip(L, seq_vector[i])]
    end
    return DecisionTree.apply_forest(regr.ensemble, Matrix{Float64}(vcat(transpose.(test_vector)...)), use_multithreading=true)
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

function seq2matrix(L::Vector{String}, seq_vector::Vector{String}; convert::Union{String, Vector{String}, T, Vector{T}}="all") where T <: Dict{Char}
    if convert isa String || convert isa Vector{String}
        convert_dict = Dict{String, Dict{Char, Float64}}("vol" => ProRF.volume, "pI" => ProRF.pI, "hyd" => ProRF.hydrophobicity)
        if convert isa String
            if convert == "all"
                convert = Vector{String}(collect(keys(convert_dict)))
            else
                convert = Vector{String}([convert])
            end
        end

        convert_dict_keys = keys(convert_dict)
        for scon in convert
            if scon ∉ convert_dict_keys
                error("Please check the keyword: all, " * join(convert_dict_keys, ", "))
            end
        end

        convert = map(x -> convert_dict[x], convert)
    else
        convert = ProRF._convert_dict(convert)
    end

    NumL = get_amino_loc(L)
    test_vector = Vector{Vector{Float64}}()
    @views for seq in seq_vector
        push!(test_vector, [con[j] for j in seq[NumL] for con in convert])
    end
    return Matrix{Float64}(vcat(transpose.(test_vector)...))
end