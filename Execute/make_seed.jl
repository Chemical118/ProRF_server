using ProRF, JLD2

data_state, learn_state, imp_state = @seed, @seed, @seed

@save "Save/seed.jld2" data_state learn_state imp_state