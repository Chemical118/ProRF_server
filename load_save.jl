using ProRF, Printf, JLD2, Statistics

@load "Save/seed.jld2" data_state learn_state imp_state

function load_big_dataset(dataset_name::String, excel_loc::Char='.')
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
    @load (@sprintf "Save/big/%s_%c.jld2" dataset col) F Y PY
    return R, X, Y, L, F, Y, PY
end

function load_small_dataset(dataset_name::String, excel_loc::Char='.')
    data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
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
    @load (@sprintf "Save/small/%s_%c.jld2" dataset col) MZ SZ Y PY
    return R, X, Y, L, MZ, SZ, Y, PY
end

function load_dataset_model(dataset_name::String, excel_loc::Char='.')
    data_vector = Vector{Tuple{String, Char, Int, Int, Int}}([
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

    return load_model(@sprintf "Model/%s_%c.jld2" dataset col)
end

function r2(tru::Vector{Float64}, pre::Vector{Float64})
    m = mean(tru)
    sst = sum((tru .- m).^2)
    ssr = sum((pre .- m).^2)
    return 1 - (ssr / sst)
end
nothing