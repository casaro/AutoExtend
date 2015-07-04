function [] = gradientChecking(w, E, D, R, grad_E, grad_D, iter, weights, mode, epsilon)
            
    fprintf('Gradient checking in iteration: %3d\n', iter);

    E_epsilon = E;
    [row,column,value] = find(E);
    grad = zeros(10,2);
    e = 1;
    for l=randi(length(row),1,10)
        E_epsilon(row(l), column(l)) = value(l) + epsilon;
        J_1 = getCost(w, E_epsilon, D, R, weights, mode);
        

        E_epsilon(row(l), column(l)) = value(l) - epsilon;
        J_2 = getCost(w, E_epsilon, D, R, weights, mode);
        
        grad(e,1) = (J_1  - J_2) / (2 * epsilon); % num
        grad(e,2) = grad_E(row(l),column(l)); % analis

        E_epsilon(row(l), column(l)) = value(l);
        
        e = e + 1;
    end
    fprintf('Difference in E: %g\n', norm(grad(:,1)-grad(:,2))/norm(grad(:,1)+grad(:,2))); 

    D_epsilon = D;
    [row,column,value] = find(D);
    grad = zeros(10,2);
    e = 1;
    for l=randi(length(row),1,10)
        D_epsilon(row(l), column(l)) = value(l) + epsilon;
        J_1 = getCost(w, E, D_epsilon, R, weights, mode);

        D_epsilon(row(l), column(l)) = value(l) - epsilon;
        J_2 = getCost(w, E, D_epsilon, R, weights, mode);
        
        grad(e,1) = (J_1 - J_2) / (2 * epsilon); % num
        grad(e,2) = grad_D(row(l),column(l)); % analis

        D_epsilon(row(l), column(l)) = value(l);
        
        e = e + 1;
    end
    fprintf('Difference in D: %g\n', norm(grad(:,1)-grad(:,2))/norm(grad(:,1)+grad(:,2)));         

end

function J = getCost(w, E, D, R, weights, mode)

    if strcmp(mode, 'J1')
        J = costFunc(w, E, D, w);
    elseif strcmp(mode, 'J2')
        J = costFuncLexeme(w, E, D);
    elseif strcmp(mode, 'J3')
        J = costFunc(w, E, R, zeros(size(R,1),1));
    elseif strcmp(mode, 'J4')
        J = costFuncColumnNorm(E) + costFuncColumnNorm(D);
    elseif strcmp(mode, 'R1')
        J = costFuncR1(w, E);
    elseif strcmp(mode, 'R2')
        J = costFuncR2(w, E, D, R);
    else
        J1 = costFunc(w, E, D, w);
        J2 = costFuncLexeme(w, E, D);
        J3 = costFunc(w, E, R, zeros(size(R,1),1));
        J4 = costFuncColumnNorm(E) + costFuncColumnNorm(D);
        J = (J1 * weights(1)) + (J2 * weights(2)) + (J3 * weights(3)) + (J4 * weights(4));
    end
    
end
       
