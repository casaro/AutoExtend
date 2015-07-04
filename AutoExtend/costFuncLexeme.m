function [J] = costFuncLexeme(w, E, D)

    if (nnz(E) ~= nnz(D))
        msgID = 'MY:BadLengthED';
        msg = 'Sparsity of encode and decode not matching.';
        baseException = MException(msgID,msg);
        throw(baseException);
    end
    
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

end