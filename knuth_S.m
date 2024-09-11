function rand_selections = knuth_S(options,N_options,M_toChoose)
% uses Knuth's Algorithm S to select M items from a list of N options with
% equal probability
n_chosen = 0;
r_toChoose = M_toChoose;
r_options = N_options;
rand_selections = zeros(1,M_toChoose);
for i=1:N_options   
    rand_int = randi(r_options);
    r_options = r_options - 1;
    if rand_int <= r_toChoose
        n_chosen = n_chosen + 1;
        r_toChoose = r_toChoose - 1;
        rand_selections(n_chosen) = options(i);
    end
    if ~r_toChoose
        break;
    end
end