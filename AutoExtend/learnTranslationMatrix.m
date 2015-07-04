function [T] = learnTranslationMatrix(X, Y)

% learn translation vector
t = mean(Y - X,1);

% create transformation matrix
T = eye(size(X,2), size(Y,2));
T = [T ; t];