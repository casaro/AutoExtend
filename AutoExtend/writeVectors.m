function [] = writeVectors(varargin)
    
	folder = varargin{1};
	experiment = varargin{2};
	
	writeWords = true;
	writeSynsets = true;
	
    if (nargin == 4)   
		writeWords = varargin{3};
		writeSynsets = varargin{4};
    end
	
	file = strcat(folder, experiment, '/synsetsAndWordVectors.txt');

    [W , dictW] = loadTxtFile(strcat(folder, 'words.txt'));
    [dictS, dictSID] = loadSynsetFile(folder);
	
	outputSize = 0;
	if (writeWords == true)
		outputSize = outputSize + size(dictW, 1);
	end
	if (writeSynsets == true)
		outputSize = outputSize + size(dictS, 1);
	end
	
	fid = fopen(file, 'w');
    fprintf(fid, '%d %d\n',outputSize, size(W,2));
    fclose(fid);

    if (writeWords == true)
		fprintf('Writing vectors ... ');
		writeToFile(file, 'a', W, dictW);
		fprintf('done!\n');
	end
	
	if (writeLexeme == true)
		fprintf('Writing vectors ... ');
		writeToFile(file, 'a', W, dictW);
		fprintf('done!\n');
	end
	
	if (writeSynsets == true)
	
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
	
		fprintf('Writing vectors ... ');
		writeToFile(file, 'a', S, dictS);
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