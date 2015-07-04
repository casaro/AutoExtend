function [J] = costFuncColumnNorm(A)

    [~,j,values] = find(A);
    error = NaN(size(A,2),1);

    for l=1:length(j)
        if isnan(error(j(l)))
            error(j(l)) = 1 - values(l);
        else
            error(j(l)) = error(j(l)) - values(l);
        end
    end

    error(isnan(error)) = 0;
    J = sum(error.^2);
    
end

