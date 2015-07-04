function [A, dictA, dictPOS] = loadTxtFile( filename )

	fprintf('Reading word vectors ... ');
    
    fileID = fopen(filename);
    line = fgetl(fileID);
    dim = length(strfind(line,' '));
    
    frewind(fileID);
    
    textformat = ['%s', repmat(' %f',1,dim)];
    Table = textscan(fileID,textformat);
    dictA = Table{1,1}(:, 1);
    A = zeros(length(dictA),dim);
    for d=1:dim
        A(:,d) = table2array(Table(:, d+1));
    end
    
    fclose(fileID);
    
    if nargout > 2
        
        [dictA, dictPOS] = strtok(dictA_, '%');
        dictPOS = strrep(dictPOS, '%', '');
    
    else
        
        dictA = strrep(dictA, '%n', '');
        dictA = strrep(dictA, '%v', '');
        dictA = strrep(dictA, '%a', '');
        dictA = strrep(dictA, '%r', '');
        dictA = strrep(dictA, '%u', '');
        
    end

	fprintf('done!\n');

end