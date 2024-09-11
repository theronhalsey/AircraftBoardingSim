%% Aircraft Model - A320-200
% 7x39 matrix
% row 4 is aircraft aisle
% rows 1-3, 5-7 are seats
% seats are number such that 1A = 1, 1B = 2, and so on

function [waitingMoments,cycles] = A320_Boarding(boarding_method,n_sections,p_groupMin,pref_WinAisle,p_withCarryOn,plotting_on)
%A320_BOARDING Function for handling the boarding of passengers onto A320
%   ARGS:
    % boarding_method:
        % 0: front-to-back
        % 1: back-to-front
        % 2: Southwest
    % n_sections : number of boarding groups to divide the passengers into
    % p_groupMin - percentages of travels who are pairs or trios
        % p_groupMin(1) - minimum percentage are a pair
        % p_groupMin(2) - minimum percentage are a trio
    % pref_WinAisle - percenteges of passengers who prefer window or aisle seat
        % pref_WinAisle(1) - prefer window
        % pref_WinAisle(2) - prefer aisle
    % p_withCarryOn - percentage of passengers with carry-on baggage
%   RETURNS:
    % waitingMoments : number of time any passenger is in a waiting state
    % cycles : number of cycles until everyone is seated

%% Setup
% performance variables
cycles = 0; % the number of loops until all are seated
MAX_CYCLES = 2000;
waitingMoments = 0; % the number of times any individual agent is in a waiting state

% aircraft dimensions
l_aircraft = 29; % number of rows of seats
w_aircraft = 7; % numbers of colums of seats, plus the aisle
i_aisle = 4; % which row index is the aisle

% Matrix for seat numbers
Seats = -Inf*ones(w_aircraft-1,l_aircraft+1);
Seats(:,2:end) = flipud(reshape(1:(w_aircraft-1)*l_aircraft,w_aircraft-1,l_aircraft));
Seats = [Seats(1:i_aisle-1,:); zeros(1,l_aircraft+1); Seats(i_aisle:end,:)];

% Matrix for seat numbers
PassengerLocations = zeros(w_aircraft,l_aircraft+1); % Spirit A320-200 all economy layout
PassengerLocations(:,1) = -Inf; % add one extra aisle space at the very front
PassengerLocations(i_aisle,:) = 0; % make sure all initial aisle spaces are 0

% process variables
n_passengers = l_aircraft*(w_aircraft-1);
n_unseated = n_passengers;
p_states = zeros(1,n_passengers); % vector to store passengers behavior state
p_waiting = zeros(1,n_passengers); % vector to store the number of passengers in waiting state

% setup for if plotting is on
if plotting_on
    switch boarding_method
        case BOARDING_METHODS.BACK_TO_FRONT
            title = "BACK_TO_FRONT";
        case BOARDING_METHODS.FRONT_TO_BACK
            title = "FRONT_TO_BACK";
        case BOARDING_METHODS.SOUTHWEST
            title = "SOUTHWEST";
    end
    video = VideoWriter(title);
    video.FrameRate = 5;
    open(video);
end

% get the boarding queue based on the boarding method
switch boarding_method
    case {BOARDING_METHODS.BACK_TO_FRONT,BOARDING_METHODS.FRONT_TO_BACK}
        boardingQueue = ShufflePassengers_AssignedSeats(n_passengers,n_sections,l_aircraft,w_aircraft-1,p_groupMin,i_aisle,boarding_method);
    case BOARDING_METHODS.SOUTHWEST
        boardingQueue = ShufflePassengers_Southwest(n_passengers,l_aircraft,w_aircraft-1,i_aisle,p_groupMin,pref_WinAisle);
end
processingOrder = boardingQueue;

%% Model
while n_unseated % while there are unseated passengers
    cycles = cycles+1; % increase the cycle count  
    if cycles >= MAX_CYCLES
        waitingMoments = 0;
        cycles = 0;
        return
    end
    queueMoved = isempty(boardingQueue); % boolean tracking if queue moved. always true once queue is empty
    for i=1:n_passengers % loop over all the passengers
        currentPassenger = processingOrder(i);
        if ismember(currentPassenger,boardingQueue) % passenger is in boardingQueue
            % try to bring passenger out of queue if previous movement made space
            if ~PassengerLocations(i_aisle,1) % if first aisle space is empty
                PassengerLocations(i_aisle,1) = boardingQueue(1); % pull passenger from queue into aisle
                p_states(currentPassenger) = 1; % enters in searching state
                boardingQueue = boardingQueue(2:end); % reduce the boarding queue
                queueMoved = true; % if queue moves, none will be marked as in waiting
            end
        else % passenger is in Aircraft
            [p_row,p_col] = find(PassengerLocations==currentPassenger); % column the current passenger occupies
            switch p_states(currentPassenger) % switch on passenger's state
                case {P_STATES.SEARCHING,P_STATES.FOUND_LOW,P_STATES.FOUND_HIGH}
                    % column of interest is passenger's column +1
                    seg_aisle = PassengerLocations(i_aisle,p_col:p_col+1);
                    c_seatNums = Seats(:,p_col+1);
                    c_passengersLocs = PassengerLocations(:,p_col+1);
                case {P_STATES.INTO_LOW,P_STATES.INTO_HIGH,P_STATES.OUT_OF_LOW,P_STATES.OUT_OF_HIGH,P_STATES.SITTING_DOWN,P_STATES.STANDING_UP,P_STATES.STOWING_CARRYON_LOW,P_STATES.STOWING_CARRYON_HIGH}
                    seg_aisle = PassengerLocations(i_aisle,p_col);
                    c_seatNums = Seats(:,p_col);
                    c_passengersLocs = PassengerLocations(:,p_col);
                case P_STATES.SEATED
                    seg_aisle = PassengerLocations(i_aisle,p_col-1);
                    c_seatNums = Seats(:,p_col);
                    c_passengersLocs = PassengerLocations(:,p_col);
            end
            % once all set do the thing
            [updated_p_states,c_passengersLocs,seg_aisle,waiting] = PassengerMovement(currentPassenger,p_row,p_states,c_seatNums,c_passengersLocs,seg_aisle,i_aisle,p_withCarryOn);
            if ~waiting
                % update aisle and column
                switch p_states(currentPassenger) % switch on passenger's state
                    case {P_STATES.SEARCHING,P_STATES.FOUND_LOW,P_STATES.FOUND_HIGH}
                        PassengerLocations(i_aisle,p_col:p_col+1) = seg_aisle(:);
                    case {P_STATES.INTO_LOW,P_STATES.INTO_HIGH,P_STATES.OUT_OF_LOW,P_STATES.OUT_OF_HIGH}
                        PassengerLocations(:,p_col) = c_passengersLocs;
                end
            end
            p_states = updated_p_states;
            p_waiting(currentPassenger) = waiting;
        end
    end
    % if queue did not move mark all in queue as waiting
    if ~queueMoved
        p_waiting(boardingQueue) = 1;
    end
    waitingMoments = waitingMoments + sum(p_waiting); % sum up all the waiting and add to wait count
    n_unseated = n_passengers - sum(p_states==P_STATES.SEATED); % count up all the number seated
    
    % generate plot if plotting is on
    if plotting_on
        WaitingLocations = -ones(w_aircraft,l_aircraft+1);
        WaitingLocations([1:i_aisle-1 i_aisle+1:end],1) = 3;
        boarded = processingOrder(~ismember(processingOrder,boardingQueue));
        for i=1:length(boarded)
            currentPassenger = boarded(i);
            [p_row,p_col] = find(PassengerLocations==currentPassenger);
            WaitingLocations(p_row,p_col) = p_waiting(currentPassenger) + 2*(p_states(currentPassenger) == P_STATES.SEATED);
        end
        clf
        set(gcf,'position',[10,10,1160,394])
        xlim([1 l_aircraft+2])
        ylim([1 w_aircraft+1])
        xline(1:l_aircraft+2)
        yline(1:w_aircraft+1)
        hold on
        i = w_aircraft+1;
        for y=1:w_aircraft
            i = i-1;
            for x=1:l_aircraft+1
                j = x;
                status = WaitingLocations(i,j);
                alpha = 0.5;
                switch status
                    case -1
                        c = 'white';     
                    case 0
                        c = 'green';
                    case 1
                        c = 'red';
                    case 2
                        c = 'blue';
                    case 3
                        c = 'black';
                        alpha = 1;
                end
                X = [x x+1 x+1 x  ];
                Y = [y y   y+1 y+1];
                fill(X,Y,c,'FaceAlpha',alpha);
                text(x+.15,y+.5,num2str(PassengerLocations(i,j)),"FontWeight","bold")
            end
        end
        axis off
        hold off
        drawnow
        frame = getframe(gcf);
        writeVideo(video, frame);
    end
end

% close file if plotting is on
if plotting_on
    close(video)
end