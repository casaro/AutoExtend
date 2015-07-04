function [T] = learnLinearMapMatrix(X, Y)

% learn linear map matrix
T = (X' * X) \ (X' * Y);

% create transformation matrix
T = [T ; zeros(1, size(T,2))];