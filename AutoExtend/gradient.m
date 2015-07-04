function [J, grad_E, grad_D] = gradient(x, E, D, x_expected, mode)

    % precalculations
    x_predict = (D * (E * x));
    x_diff = x_predict - x_expected;
    d = (D' * x_diff);
    e = E * x;
    
    % calculate error
    J = sum(x_diff.^2);
    
    if ~strcmp(mode,'onlyD')

        % calculate derivate for E
        [row,column,~] = find(E);
        %for l=1:size(row)
        %    i = row(l);
        %    j = column(l);
        %    grad_values(l) = 2 * d(i) * x(j); %((x_predict - x_expected)' * D(:,i)) * x(j); but we use precalculations
        %end
        grad_values = 2 * d(row) .* x(column);
        grad_E = sparse(row,column,grad_values,size(E,1),size(E,2));
    else
        grad_E = NaN;
    end

    if ~strcmp(mode,'onlyE')
        
         % calculate derivate for D
        [row,column,~] = find(D);
        %for l=1:size(row)
        %    i = row(l);
        %    j = column(l);
        %    grad_values(l) = 2 * x_diff(i) * e(j); %(x_predict(i) - x_expected(i)) * (E(j,:) * x); but we use precalculations
        %end
        grad_values = 2 * x_diff(row) .* e(column);
        grad_D = sparse(row,column,grad_values,size(D,1),size(D,2));
    else
        grad_D = NaN;
    end
    


end
