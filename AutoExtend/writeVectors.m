function [] = writeVectors(varargin)
    
    folder = varargin{1};
    experiment = varargin{2};
    
    writeWords = true;
    writeSynsets = true;
    writeLexemes = false;
    
    if (nargin == 5)   
        writeWords = varargin{3};
        writeSynsets = varargin{4};
        writeLexemes = varargin{5};
    end
    
    file = strcat(folder, experiment, '/outputVectors.txt');

    [W , dictW] = loadTxtFile(strcat(folder, 'words.txt'));
    [dictS, dictSID] = loadSynsetFile(folder);
    
    Theta = importdata(strcat(folder, experiment, '/theta.txt'), ' ');
    fprintf('Calculating synset vectors ... ');
    S = zeros(size(dictS, 1), size(W,2));
    for l=1:size(Theta, 1)
        w = Theta(l,1);
        s = Theta(l,2);
        theta = Theta(l, 3:end);
        S(s,:) = S(s,:) + (W(w,:) .* theta);
    end
    fprintf('done!\n');
        
    outputSize = 0;
    if (writeWords == true)
        outputSize = outputSize + size(dictW, 1);
    end
    if (writeLexemes == true)
        outputSize = outputSize + size(Theta, 1);
    end
    if (writeSynsets == true)
        outputSize = outputSize + size(dictS, 1);
    end
    
    fid = fopen(file, 'w');
    fprintf(fid, '%d %d\n',outputSize, size(W,2));
    fclose(fid);

    if (writeWords == true)
        fprintf('Writing word vectors ... ');
        writeToFile(file, 'a', W, dictW);
        fprintf('done!\n');
    end
    
    if (writeSynsets == true)
        
        fprintf('Writing synset vectors ... ');
        writeToFile(file, 'a', S, dictS);
        fprintf('done!\n');
    end
    
    if (writeLexemes == true)
    
        Iota = importdata(strcat(folder, experiment, '/iota.txt'), ' ');
        Theta = sortrows(Theta, [1 2]);
        Iota = sortrows(Iota, [1 2]);
        
        if (sum(sum(Theta(:,1:2)-Iota(:,1:2))) ~= 0)
            fprintf('Iota and Theta file do not match. Lexemes vector might be screwed.\n');
        end
        
        fprintf('Calculating lexeme vectors ... ');
        L = zeros(size(Theta, 1), size(W,2));
        dictL = cell(size(Theta, 1), 1);
        for l=1:size(Theta, 1)
            w = Theta(l,1);
            s = Theta(l,2);
            theta = Theta(l, 3:end);
            iota = Iota(l, 3:end);
            L(l,:) = ((W(w,:) .* theta) + (S(s,:) .* iota)) / 2;
            dictL{l} = strcat(dictW{w}, '-', dictSID{s});
        end
        fprintf('done!\n');
    
        fprintf('Writing lexeme vectors ... ');
        writeToFile(file, 'a', L, dictL);
        fprintf('done!\n');
    end

end

function [] = writeToFile(file, mode, A, dictA)

    fid = fopen(file, mode);

    for i=1:size(dictA,1)
        fprintf(fid, '%s', dictA{i});
        fprintf(fid,' %f',A(i,:));
        fprintf(fid,'\n');
    end

    fclose(fid);

end
