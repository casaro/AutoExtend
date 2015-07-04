function [J, grad_E, grad_D] = gradientLexeme(w, E, D)

    [synset,word,value] = find(E);
    %L1 = sortrows([word synset value],[1 2]);
    L1 = [word synset value];
    lexeme1 = L1(:,3) .* w(L1(:,1));
    
    s = E * w;
    %[word,synset,value] = find(D);
    %L2 = sortrows([word synset value],[1 2]);
    [synset,word,value] = find(D');
    L2 = [word synset value];
    lexeme2 = L2(:,3) .* s(L2(:,2));
    
    diff = lexeme1 - lexeme2;
    J = sum(diff.^2);
    
	%new
	%d = (D' * x_diff);
	%grad1 = 2 * w(L1(:,1)) .* d(row);
	%old
    grad1 = 2 * w(L1(:,1)) .* diff;
    %end
	grad2 = -2 * s(L2(:,2)) .* diff;
    
    grad_E = sparse(L1(:,2),L1(:,1),grad1,size(E,1),size(E,2));
    grad_D = sparse(L2(:,1),L2(:,2),grad2,size(D,1),size(D,2));
end
