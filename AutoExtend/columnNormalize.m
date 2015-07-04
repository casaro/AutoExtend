function [ A ] = columnNormalize( A )

    if issparse(A)
        A = columnNormalizeSparse( A );
    else   
        A = columnNormalizeFull( A );
    end

end

function [ A ] = columnNormalizeSparse( A )

    
    [i,j,values] = find(A);
    
    colSum = (ones(1, size(A,1)) * A)';    
    values = values ./ colSum(j);
    
    A = sparse(i,j,values,size(A,1),size(A,2));

end

function [ A ] = columnNormalizeFull( A )

    colSum = sum(A,1);

    for i=1:size(A,2)

        A(:,i) = A(:,i) ./ colSum(i);

    end

end

