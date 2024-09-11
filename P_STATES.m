%% ENUM for encoding passenger states

% 1 : searching for seat
% 2 : found seat on low side
% 3 : found seat on high side
% 4 : moving into low side seating
% 5 : moving into high side seating
% 6 : moving out of low side seating
% 7 : moving out of high side seating
% 8 : sitting down after finding seat
% 9 : standing up from seated
% 10 : seated
% 11 : stowing their carry-on bag on low side
% 12 : stowing their carry-on bag on low side

classdef P_STATES < uint8
    enumeration
        SEARCHING (1)
        FOUND_LOW  (2)
        FOUND_HIGH (3)
        INTO_LOW (4)
        INTO_HIGH (5)
        OUT_OF_LOW (6)
        OUT_OF_HIGH (7)
        SITTING_DOWN (8)
        STANDING_UP (9)
        SEATED (10)
        STOWING_CARRYON_LOW (11)
        STOWING_CARRYON_HIGH (12)
    end
end