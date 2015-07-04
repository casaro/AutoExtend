function [J, grad_A] = gradientColumnNorm(A)

    [i,j,values] = find(A);
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
    
    for l=1:length(j)
        values(l) = -2 * error(j(l));
    end
    
    grad_A = sparse(i,j,values,size(A,1),size(A,2));

end

