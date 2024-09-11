function boardingOrder = ShufflePassengers_AssignedSeats(n_passengers,n_boardingGroups,l_seats,w_seats,p_groupMin,i_aisle,direction)
%SHUFFLEPASSENGERS_ASSIGNEDSEATS Shuffle the passengers' boarding order based on the
%loading method.

% ARGUMENTS:
% n_passengers - number of passengers
% n_boardingGroups - number of sections of divide the aricraft into
% l_seats - number of columns of seats in the aircraft
% w_seats - number of rows of seats in the aircraft
% array of two values of passengers who are traveling together
% p_groupMin(1) - minimum percentage of passengers that are a pair
% p_groupMin(2) - minimum percentage of passengers that are a trio
% i_aisle - index of the row of the aisle
% direction:
    % 0 - back to front
    % 1 - front to back

% RETURNS: a shuffled array of passengers to use as the boarding order

%% setup
shuffle = @(section,l_section) section(randperm(l_section)); % function for shuffling a section
boardingOrder = 1:n_passengers; % start with passengers in order
Seats = flipud(reshape(boardingOrder,w_seats,l_seats));
boardingGroupMinMax = zeros(n_boardingGroups,2); % first and last seat numbers in a section

%% get the sizes of each boarding group
s_boardingGroup = floor(l_seats/n_boardingGroups)*ones(1,n_boardingGroups); % find a size of each section in columns
rem = mod(l_seats,n_boardingGroups); % number of sections to add an extra column to
s_boardingGroup(1:rem) = s_boardingGroup(1:rem)+1; % final section sizes
if direction
    s_boardingGroup = flip(s_boardingGroup);
end

%% loop for shuffling each section
last = 0; % initialize that last passenger to 0
for i=1:n_boardingGroups
    begin = last+1;
    n_inSection = s_boardingGroup(i)*w_seats;
    last = last + n_inSection;
    boardingGroupMinMax(i,:) = [begin,last];
    boardingOrder(begin:last) = shuffle(boardingOrder(begin:last),n_inSection);
end

%% ensure proper number of passenger pairs and trios
n_groups = round((p_groupMin*n_passengers)./[2 3]);
PassengerLocations = flipud(reshape(boardingOrder,w_seats,l_seats));
PairMap = FindPairsTrios(PassengerLocations,w_seats,l_seats,i_aisle);

%% get the current number of pairs and trios
[n_pairs,n_trios] = FindNumPairsTrios(PairMap);
hasTrioCandidates = ones(2,l_seats); % mark all pairs as having potential trio candidates

%% pair up random passengers and make trios from random pairs
while (n_pairs < n_groups(1)) || (n_trios < n_groups(2))
    hasPairCandidates = ones(2,l_seats); % mark all middle passengers as having potential candidates
    while n_pairs < n_groups(1) % make a pair from random un-paired
        upperHalf = rand>.5;
        if upperHalf % make a pair on random side of aircraft
            middle = 2;
        else
            middle = 5;
        end

        i_notPaired = ~PairMap(middle,:); % get the indexes of the unpaired
        [~,j_toSwapOut] = max((i_notPaired & hasPairCandidates(2-upperHalf,:)).*rand(1,l_seats)); % pick one at random

        % search for middle +/- 1 in unpaired rows
        toPair = PassengerLocations(middle,j_toSwapOut); % the value we look to pair with
        i_boardingGroup = find(toPair > boardingGroupMinMax(:,1) & toPair < boardingGroupMinMax(:,2)); % find boarding group of toSwap
        i_plusOne = [0 0]; % location of of toPair+1
        i_minusOne = [0 0]; % location of of toPair-1

        % make sure swap candidates are in the same boarding group
        if toPair+1 < boardingGroupMinMax(i_boardingGroup,2)
            i_plusOne = ValidateSwapable(PassengerLocations,PairMap,toPair,j_toSwapOut,1);
        end
        if toPair-1 > boardingGroupMinMax(i_boardingGroup,1)
            i_minusOne = ValidateSwapable(PassengerLocations,PairMap,toPair,j_toSwapOut,-1);
        end

        swapped = false;
        if (~i_plusOne(1) && ~i_minusOne(1)) % if both not available to pair
            hasPairCandidates(2-upperHalf,j_toSwapOut) = 0; % flag passenger so we don't randomly try the same thing again
        else % swap with window or aisle at random
            winOrAisle = 1-(2*(rand>.5));
            if i_plusOne(1)
                PassengerLocations(middle+winOrAisle,j_toSwapOut) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_plusOne(1),i_plusOne(2)));
                PassengerLocations(i_plusOne(1),i_plusOne(2)) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_plusOne(1),i_plusOne(2)));
                PassengerLocations(middle+winOrAisle,j_toSwapOut) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_plusOne(1),i_plusOne(2)));
                % ensure they are in proper order for boarding
                swapped = true;
            elseif i_minusOne(1)
                PassengerLocations(middle+winOrAisle,j_toSwapOut) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_minusOne(1),i_minusOne(2)));
                PassengerLocations(i_minusOne(1),i_minusOne(2)) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_minusOne(1),i_minusOne(2)));
                PassengerLocations(middle+winOrAisle,j_toSwapOut) = bitxor(PassengerLocations(middle+winOrAisle,j_toSwapOut),PassengerLocations(i_minusOne(1),i_minusOne(2)));
                swapped = true;
            end
            if swapped
                % set the indices of the new pair to 1
                PairMap(middle,j_toSwapOut) = 1;
                PairMap(middle+winOrAisle,j_toSwapOut) = 1;
                % recalculate the number of pairs and trios
                [n_pairs,n_trios] = FindNumPairsTrios(PairMap);
            end
        end
    end

    % make a trio from random pair
    if n_trios < n_groups(2)
        % get the indices of the pairs
        upperHalf = rand>.5;
        if upperHalf
            i_pairs = sum(PairMap(1:i_aisle-1,:))==2;
            rows = [1 i_aisle-1];
        else
            i_pairs = sum(PairMap(i_aisle:end,:))==2;
            rows = [i_aisle w_seats];
        end

        % pick one at random
        [~,j_toSwapOut] = max((i_pairs & hasTrioCandidates(2-upperHalf,:)).*rand(1,l_seats));

        % get the index of the non-pair
        i_toSwapOut = find(PairMap(rows(1):rows(2),j_toSwapOut)==0)-1+(rows(1));
        [i_boardingGroup,~] = find(PassengerLocations(i_toSwapOut,j_toSwapOut) >= boardingGroupMinMax(:,1) & PassengerLocations(i_toSwapOut,j_toSwapOut)  <= boardingGroupMinMax(:,2));

        % find locations of min-1 and max+1
        s = PassengerLocations(rows(1):rows(2),j_toSwapOut);
        minMinus = min(s(PairMap(rows(1):rows(2),j_toSwapOut)==1))-1;
        maxPlus = minMinus+2;

        % randomly choose one and swap
        i_toSwapIn = 0;
        j_toSwapIn = 0;

        % if the minus value is valid
        if minMinus >= boardingGroupMinMax(i_boardingGroup,1)
            [i_toSwapIn,j_toSwapIn] = find(PassengerLocations==minMinus);
            if (sum(PairMap(:,j_toSwapIn))==3) || (j_toSwapIn==j_toSwapOut)
                i_toSwapIn = 0;
                j_toSwapIn = 0;
            end
        end

        % if minus value was invalid and plus value is valid
        if (isempty(i_toSwapIn) || (i_toSwapIn==0)) && (maxPlus <= boardingGroupMinMax(i_boardingGroup,2))
            [i_toSwapIn,j_toSwapIn] = find(PassengerLocations==maxPlus);
            if (sum(PairMap(:,j_toSwapIn))==3) || (j_toSwapIn==j_toSwapOut)
                i_toSwapIn = 0;
                j_toSwapIn = 0;
            end
        end

        if i_toSwapIn
            PassengerLocations(i_toSwapOut,j_toSwapOut) = bitxor(PassengerLocations(i_toSwapOut,j_toSwapOut),PassengerLocations(i_toSwapIn,j_toSwapIn));
            PassengerLocations(i_toSwapIn,j_toSwapIn) = bitxor(PassengerLocations(i_toSwapOut,j_toSwapOut),PassengerLocations(i_toSwapIn,j_toSwapIn));
            PassengerLocations(i_toSwapOut,j_toSwapOut) = bitxor(PassengerLocations(i_toSwapOut,j_toSwapOut),PassengerLocations(i_toSwapIn,j_toSwapIn));
            % update pair map
            PairMap = FindPairsTrios(PassengerLocations,w_seats,l_seats,i_aisle);
            % recalculate the number of pairs and trios
            [n_pairs,n_trios] = FindNumPairsTrios(PairMap);
        else % all candidates ourside of boarding group or already in another trio
            hasTrioCandidates(2-upperHalf,j_toSwapOut) = 0;
        end
    end
end

%% ensure the passenger groups are on the proper order
i_toSortHigh = find(sum(PairMap(1:i_aisle-1,:))~=0);
for i=1:length(i_toSortHigh)
    if direction
        PassengerLocations(1:i_aisle-1,i_toSortHigh(i)) = sort(PassengerLocations(1:i_aisle-1,i_toSortHigh(i)),'ascend');
    else
        PassengerLocations(1:i_aisle-1,i_toSortHigh(i)) = sort(PassengerLocations(1:i_aisle-1,i_toSortHigh(i)),'descend');
    end
end

i_toSortLow = find(sum(PairMap(i_aisle:end,:))~=0);
for i=1:length(i_toSortLow)
    if direction
        PassengerLocations(i_aisle:end,i_toSortLow(i)) = sort(PassengerLocations(i_aisle:end,i_toSortLow(i)),'descend');
    else
        PassengerLocations(i_aisle:end,i_toSortLow(i)) = sort(PassengerLocations(i_aisle:end,i_toSortLow(i)),'ascend');
    end
end

boardingOrder(PassengerLocations(:)) = Seats(:);
if ~direction
    boardingOrder = flip(boardingOrder);
end

end

%% helper function for finding the number of pairs and trio passengers
function [n_pairs, n_trios] = FindNumPairsTrios(pairMap)
colSums = sum(pairMap,1);
n_pairs = sum((colSums==2) + (colSums==5) + 2*(colSums==4));
n_trios = sum((colSums==3) + (colSums==5));
end

%% helper function to validate swap candidates
function [i] = ValidateSwapable(Seats,PairMap,toPair,j_toSwapOut,plusMinus)
[i,j] = find(Seats==(toPair+plusMinus));
i = [i j];
if isempty(i) || (j_toSwapOut==j) ||PairMap(i(1),i(2))
    i = [0 0];
end
end

%% helper function fo find pairs and trios
function PairMap = FindPairsTrios(Seats,w_seats,l_seats,aisleNumber)
PairMap = zeros(w_seats,l_seats);
for i=1:aisleNumber-2 % for loop for seats above the aisle
    PairMap(i+1,:) =  abs(Seats(i,:)-Seats(i+1,:)) == 1;
    PairMap(i,:) = PairMap(i,:) | PairMap(i+1,:);
end

for i=aisleNumber:w_seats-1 % for loop for seats below the aisle
    PairMap(i+1,:) =  abs(Seats(i,:)-Seats(i+1,:)) == 1;
    PairMap(i,:) = PairMap(i,:) | PairMap(i+1,:);
end
end