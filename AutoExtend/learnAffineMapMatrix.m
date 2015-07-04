function [T] = learnAffineMapMatrix(X, Y)

% add biased term
X = [X ones(size(X,1), 1)];

% learn affine map matrix
T = (X' * X) \ (X' * Y);