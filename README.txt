Notes on model:

%% Prefixes for variables:
% n_ - count of something
% s_ - size of something
% l_ - length
% w_ - width
% i_ - index of something
% c_ - column
% r_ - row
% p_ - something regarding passengers
% m_ - modifier due to some condition
% seg_ - segment of something

%% General statements about language describing the model
% rows: narrow dimension of the aircraft
% columns: the long dimension of the aircraft

%% Passengers in groups:
% Passengers who are in a group are only considered as 2 or 3 because any
% larger groups will have to be divided into subgroups of 3+1, 3+2, 3+3,
% 3+3+1 and so on.
% Passengers in groups will enter such that they will be in seating order
% before they enter the aircraft