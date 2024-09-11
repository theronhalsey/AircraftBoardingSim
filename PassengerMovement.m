function [updated_p_states,c_passengersLocs,seg_aisle,waiting] = PassengerMovement(passenger,p_row,p_states,c_seatNums,c_passengersLocs,seg_aisle,i_aisle,p_withCarryOn)
%PASSENGERMOVEMENT Function for handling the passenger movements
%   ARGS:
    % passenger : passenger number that corresponds to their target seat
    % p_row : passenger row
    % p_states : array of passenger's current states
    % c_seatNums : seat numbers in the current column of interest
    % c_passengersLocs : column of the passenger numbers currently in that column
    % seg_aisle : segment of the aisle centered on the column the agent is occupying
    % i_aisle : index of the row that is the aisle
    % p_withCarryOn : percentage of passengers with carry-on baggage
%   RETURNS:
    % updated_p_states : updated passenger states
    % c_passengersLocs : updated column of passenger locations
    % seg_aisle : updated segment of the aisle
    % waiting : 1 or 0 if the agent was unable to make progress

waiting = 0; % not waiting by default
switch p_states(passenger)
    
    case P_STATES.SEARCHING % CASE 1 | Searching for seat
        if ~seg_aisle(2) && ~ismember(passenger,c_seatNums) % try to move toward back
            seg_aisle = flip(seg_aisle);
        elseif ismember(passenger,c_seatNums(i_aisle+1:end)) % found seat on low side
            if rand() < p_withCarryOn % if passenger has carry-on
                p_states(passenger) = P_STATES.STOWING_CARRYON_LOW;
            else
                p_states(passenger) = P_STATES.FOUND_LOW;
            end
        elseif ismember(passenger,c_seatNums(1:i_aisle-1)) % found seat on high side
            if rand() < p_withCarryOn % if passenger has carry-on
                p_states(passenger) = P_STATES.STOWING_CARRYON_HIGH;
            else
                p_states(passenger) = P_STATES.FOUND_HIGH;
            end     
        else % passenger cannot make progress
            waiting = 1;
        end

    case P_STATES.FOUND_LOW % CASE 2 | Found seat on low side
        r_seat = find(c_seatNums==passenger); % row of passenger's seat
        % if seats are empty up to my seat
        if ~sum(c_passengersLocs(i_aisle:r_seat))
            seg_aisle = flip(seg_aisle);
            p_states(passenger) = P_STATES.INTO_LOW;
        % if #pass in seats <= 1 and person in aisle space came from seats
        elseif seg_aisle(2) && p_states(seg_aisle(2)) == P_STATES.OUT_OF_LOW && (~~sum(c_passengersLocs(i_aisle+1:r_seat)) <= 1)
            p_states(seg_aisle(2)) = P_STATES.FOUND_LOW; % change state of person in aisle
            p_states(passenger) = P_STATES.INTO_LOW; % change passenger to INTO state
            seg_aisle = flip(seg_aisle); % swap with aisle space by seats
        else % wait for seated to get out of the way
            waiting = 1;
        end

    case P_STATES.FOUND_HIGH % CASE 3 | Found seat on high side
        r_seat = find(c_seatNums==passenger); % row of passenger's seat
        % if seats are empty up to my seat
        if ~sum(c_passengersLocs(r_seat:i_aisle))
            seg_aisle = flip(seg_aisle);
            p_states(passenger) = P_STATES.INTO_HIGH;  
        % if #pass in seats <= 1 and person in aisle space came from seats
        elseif seg_aisle(2) && p_states(seg_aisle(2)) == P_STATES.OUT_OF_HIGH && (sum(~~c_passengersLocs(r_seat:i_aisle-1)) <= 1)
            p_states(seg_aisle(2)) = P_STATES.FOUND_HIGH; % change state of person in aisle
            p_states(passenger) = P_STATES.INTO_HIGH; % change passenger to INTO state
            seg_aisle = flip(seg_aisle); % swap with aisle space by seats
        else % wait for seated to get out of the way
            waiting = 1;
        end

    case P_STATES.INTO_LOW % CASE 4 | Moving into low side seating
        if c_seatNums(p_row)==passenger % if passenger is at their seat
            p_states(passenger) = P_STATES.SITTING_DOWN; % begin sitting down
        elseif ~c_passengersLocs(p_row+1)
            c_passengersLocs(p_row:p_row+1) = flip(c_passengersLocs(p_row:p_row+1));
        else
            waiting = 1;
        end

    case P_STATES.INTO_HIGH % CASE | 5 Moving into high side seating
        if  c_seatNums(p_row)==passenger % if passenger is at their seat
            p_states(passenger) = P_STATES.SITTING_DOWN; % begin sitting down
        elseif ~c_passengersLocs(p_row-1)
            c_passengersLocs(p_row-1:p_row) = flip(c_passengersLocs(p_row-1:p_row));
        else
            waiting = 1;
        end

    case P_STATES.OUT_OF_LOW % CASE 6 | Moving out of low side seating
        if (p_row == i_aisle+1) && (~seg_aisle || (p_states(seg_aisle) == P_STATES.INTO_LOW)) % if i am next to aisle and person in aisle is in INTO state
            if seg_aisle
                p_states(passenger) = P_STATES.INTO_LOW; % enter INTO state
            end
            c_passengersLocs(p_row-1:p_row) = flip(c_passengersLocs(p_row-1:p_row)); % swap with empty seat
        elseif (p_row > i_aisle+1)  && ~c_passengersLocs(p_row-1) % if i am in seats and next seat is empty
            c_passengersLocs(p_row-1:p_row) = flip(c_passengersLocs(p_row-1:p_row)); % swap with empty seat
        else
            waiting = 1;
        end

    case P_STATES.OUT_OF_HIGH % CASE 7 | Moving out of high side seating
        if (p_row == i_aisle-1) && (~seg_aisle || (p_states(seg_aisle) == P_STATES.INTO_HIGH)) % if i am next to aisle and person in aisle is in INTO state
            if seg_aisle
                p_states(passenger) = P_STATES.INTO_HIGH; % enter INTO state
            end
            c_passengersLocs(p_row:p_row+1) = flip(c_passengersLocs(p_row:p_row+1)); % swap with empty seat
        elseif (p_row < i_aisle-1)  && ~c_passengersLocs(p_row+1) % if i am in seats and next seat is empty
            c_passengersLocs(p_row:p_row+1) = flip(c_passengersLocs(p_row:p_row+1)); % swap with empty seat
        else
            waiting = 1;
        end

    case P_STATES.SITTING_DOWN % CASE 8 | Sitting down after finding seat
        p_states(passenger) = P_STATES.SEATED;

    case P_STATES.STANDING_UP % CASE 9 | Standing up from seated
        p_states(passenger) = P_STATES.OUT_OF_LOW + uint8(p_row < i_aisle); % 6 or 7 if on low or high side

    case P_STATES.SEATED % CASE 10 | Seated
        % check if someone is trying to enter seats
        aboveAisle = p_row<i_aisle; % 0 or 1 depending on side of aisle
            if seg_aisle && ((aboveAisle && ((p_states(seg_aisle) == P_STATES.FOUND_HIGH) || (p_states(seg_aisle) == P_STATES.STOWING_CARRYON_HIGH)) && (seg_aisle > passenger)) || ((~aboveAisle) && ((p_states(seg_aisle) == P_STATES.FOUND_LOW) || (p_states(seg_aisle) == P_STATES.STOWING_CARRYON_LOW) ) && (seg_aisle < passenger)))
                p_states(passenger) = P_STATES.STANDING_UP;
            end

    case P_STATES.STOWING_CARRYON_LOW % CASE 11 | Stowing luggage on low side
        p_states(passenger) = P_STATES.FOUND_LOW;

    case P_STATES.STOWING_CARRYON_HIGH % CASE 12 | Stowing luggage on high side
        p_states(passenger) = P_STATES.FOUND_HIGH;

end

updated_p_states = p_states;