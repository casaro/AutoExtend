function [J] = costFunc(x, E, D, x_expected)

x_predict = (D * (E * x));
x_diff = x_predict - x_expected;
J = sum(x_diff.^2);

end