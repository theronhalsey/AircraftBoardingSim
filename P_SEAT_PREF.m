%% ENUM for encoding passenger seat type preference

% 1 : window seat
% 2 : aisle seat
% 3 : middle seat

classdef P_SEAT_PREF < uint8
    enumeration
        WINDOW (1)
        AISLE  (2)
        MIDDLE (3)
    end
end