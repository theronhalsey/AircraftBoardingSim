function boardingOrder = ShufflePassengers_Southwest(n_passengers,l_seats,w_seats,i_aisle,p_groupMin,pref_WinAisle)
%SHUFFLEPASSENGERS_ASSIGNEDSEATS Shuffle the passengers' boarding order based on the
%loading method.

% ARGUMENTS:
% n_passengers - number of sections of divide the aricraft into
% l_seats - number of columns of seats in the aircraft
% w_seats - number of rows of seats in the aircraft
% array of two values of passengers who are traveling together
% i_aisle - index of the row of the aisle
% p_groupMin - percentages of travels who are pairs or trios
% p_groupMin(1) - minimum percentage are a pair
% p_groupMin(2) - minimum percentage are a trio
% pref_WinAisle - percenteges of passengers who prefer window or aisle seat
% pref_WinAisle(1) - prefer window
% pref_WinAisle(2) - prefer aisle

% RETURNS: a shuffled array of passengers to use as the boarding order

%% setup
PassengerLocations = zeros(w_seats,l_seats);
boardingOrder = 1:n_passengers;
Seats = flipud(reshape(boardingOrder,w_seats,l_seats));
n_groups = round((p_groupMin*n_passengers)./[2 3]);
n_benches = l_seats*2;
benches_with_groups = knuth_S(1:n_benches,n_benches,sum(n_groups));
benches_with_trio = knuth_S(benches_with_groups,length(benches_with_groups),n_groups(2));
benches_with_pairs = benches_with_groups(~ismember(benches_with_groups,benches_with_trio));
nextGroup = benches_with_groups(1);
looking_for_first_pref = true;
looking_for_second_pref = true;
looking_for_unblocked = true;
seatPref = 0;

i = 1;
while i <= n_passengers
    seated_by_pref = false; % flag for if passenger was seated according to their preference
    seated_a_group = false;
    
    % get passenger's seat preference or switch to second preference
    if ~seatPref
        seatPref = getSeatTypePref(pref_WinAisle); % get passenger's seat type pref
    elseif seatPref == P_SEAT_PREF.WINDOW
        seatPref = P_SEAT_PREF.AISLE;
    elseif seatPref == P_SEAT_PREF.AISLE
        seatPref = P_SEAT_PREF.WINDOW;  
    end

    % if seatPref == P_SEAT_PREF.AISLE
    %     looking_for_unblocked = false;
    % end

    for j=1:l_seats
        if ismember(nextGroup,[2*j 2*j-1]) % check if a bench in the column should have a group
            seated_by_pref = true;
            seated_a_group = true;
            benches_with_groups = benches_with_groups(2:end); % remove bench number from vector
            if ~isempty(benches_with_groups) % if a  group remains, set next group
                nextGroup = benches_with_groups(1);
            else
                nextGroup = 0;
            end
            % Check if group is trio
            if ~isempty(benches_with_trio)
                if 2*j-1 == benches_with_trio(1) % if low side has trio
                    benches_with_trio = benches_with_trio(2:end); % remove bench number from vector
                    PassengerLocations(i_aisle:end,j) = [i+2 i+1 i]'; % fill whole bench in order
                    i = i+3;
                    seatPref = 0;
                    break % move on to next passenger
                elseif 2*j == benches_with_trio(1) % if high side has trio
                    benches_with_trio = benches_with_trio(2:end); % remove bench number from vector
                    PassengerLocations(1:i_aisle-1,j) = [i i+1 i+2]'; % fill whole bench in order
                    i = i+3;
                    seatPref = 0;
                    break % move on to next passenger
                end
            end

            % Check if group is duo
            if 2*j-1 == benches_with_pairs(1) % if low side has pair
                benches_with_pairs = benches_with_pairs(2:end); % remove current bunch number from vector
                if seatPref == P_SEAT_PREF.WINDOW % if passenger prefers windows -> window + middle pair
                    PassengerLocations(end-1:end,j) = [i+1 i]'; % fill window and middle
                else % middle + aisle pair
                    PassengerLocations(i_aisle:i_aisle+1,j) = [i+1 i]'; % fill aisle and middle
                end
                i = i+2;
                seatPref = 0;
                break % move on to next passenger
            elseif 2*j == benches_with_pairs(1) % if high side has pair
                benches_with_pairs = benches_with_pairs(2:end); % remove current bunch number from vector
                if seatPref == P_SEAT_PREF.WINDOW % if passenger prefers windows -> window + middle pair
                    PassengerLocations(1:2,j) = [i i+1]'; % fill window and middle
                else % middle + aisle pair
                    PassengerLocations(i_aisle-2:i_aisle-1,j) = [i i+1]'; % fill aisle and middle
                end
                i = i+2;
                seatPref = 0;
                break % move on to next passenger
            end
        end

        % If not in group treat as individual traveler
        [avail_Low,avail_High] = prefSeatAvailable(seatPref,PassengerLocations(:,j),i_aisle);
        if looking_for_unblocked
            if seatPref == P_SEAT_PREF.WINDOW
                unblocked_low = ~PassengerLocations(i_aisle,j) & ~PassengerLocations(i_aisle+1,j);
                unblocked_high = ~PassengerLocations(i_aisle-1,j) & ~PassengerLocations(i_aisle-2,j);
            elseif seatPref == P_SEAT_PREF.MIDDLE
                unblocked_low = ~PassengerLocations(i_aisle,j);
                unblocked_high = ~PassengerLocations(i_aisle-1,j);
            else
                unblocked_low = ~PassengerLocations(i_aisle+1,j);
                unblocked_high = ~PassengerLocations(i_aisle-2,j);
            end
        end
        if (avail_Low && (~looking_for_unblocked || unblocked_low)) && (avail_High && (~looking_for_unblocked || unblocked_high))
            if rand() >= .5 % seat them on the low side
                switch seatPref
                    case P_SEAT_PREF.WINDOW
                        PassengerLocations(end,j) = i;
                    case P_SEAT_PREF.AISLE
                        PassengerLocations(i_aisle,j) = i;
                    case P_SEAT_PREF.MIDDLE
                        PassengerLocations(i_aisle+1,j) = i;
                end
            else % seat them on the high side
                switch seatPref
                    case P_SEAT_PREF.WINDOW
                        PassengerLocations(1,j) = i;
                    case P_SEAT_PREF.AISLE
                        PassengerLocations(i_aisle-1,j) = i;
                    case P_SEAT_PREF.MIDDLE
                        PassengerLocations(i_aisle-2,j) = i;
                end
            end
            seated_by_pref = true;
            break
        elseif (avail_Low && (~looking_for_unblocked || unblocked_low))
            switch seatPref
                case P_SEAT_PREF.WINDOW
                    PassengerLocations(end,j) = i;
                case P_SEAT_PREF.AISLE
                    PassengerLocations(i_aisle,j) = i;
                case P_SEAT_PREF.MIDDLE
                    PassengerLocations(i_aisle+1,j) = i;
            end
            seated_by_pref = true;
            break
        elseif (avail_High && (~looking_for_unblocked || unblocked_high))
            switch seatPref
                case P_SEAT_PREF.WINDOW
                    PassengerLocations(1,j) = i;
                case P_SEAT_PREF.AISLE
                    PassengerLocations(i_aisle-1,j) = i;
                case P_SEAT_PREF.MIDDLE
                    PassengerLocations(i_aisle-2,j) = i;
            end
            seated_by_pref = true;
            break
        end
    end

    if seated_a_group
        continue
    end

    if seated_by_pref
        looking_for_first_pref = true;
        looking_for_second_pref = true;
        looking_for_unblocked = true;
        i = i+1;
        seatPref = 0;
        continue
    end

    if looking_for_first_pref && ~looking_for_unblocked
        looking_for_first_pref = false;
        looking_for_unblocked = true;
    elseif looking_for_second_pref && ~looking_for_unblocked
        looking_for_second_pref = false;
        looking_for_unblocked = true;
    elseif looking_for_unblocked
        looking_for_unblocked = false;
    end

    % If not seated by pref, put them in the last open seat
    if ~looking_for_second_pref
        PassengerLocations(find(PassengerLocations(:)==0,1,'last')) = i;
        i = i+1;
    end
end
boardingOrder(PassengerLocations(:)) = Seats(:);
end

%% helper function for assigning a passenger a seat type preference
function preference = getSeatTypePref(pref_WinAisle)
% randomly assign window preference
if rand() <= pref_WinAisle(1)
    preference = P_SEAT_PREF.WINDOW;
    return
end
% if not window then randomly assign aisle preference
if rand() <= pref_WinAisle(1)/(1-sum(pref_WinAisle))
    preference = P_SEAT_PREF.AISLE;
    return
end
% else middle preference
preference = P_SEAT_PREF.MIDDLE;
end

%% helper function to determine if a prefered seat is available in column
function [avail_Low, avail_High] = prefSeatAvailable(pref,seats,i_aisle)
switch pref
    case P_SEAT_PREF.WINDOW
        avail_High = (seats(1) == 0);
        avail_Low = (seats(end) == 0);
    case P_SEAT_PREF.AISLE
        avail_High = (seats(i_aisle-1) == 0);
        avail_Low = (seats(i_aisle) == 0);
    case P_SEAT_PREF.MIDDLE
        avail_High = (seats(i_aisle-2) == 0);
        avail_Low = (seats(end-1) == 0);
end
end