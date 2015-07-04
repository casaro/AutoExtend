function [] = testSCWS(varargin)
    
    if (nargin == 1)
        folder = varargin{1};
    else
        folder = '/mounts/data/proj/sascha/data/gn_wn21/';
    end
    
	[W , dictW] = loadTxtFile(strcat(folder, 'words.txt'));
    %[A , dictA] = loadBinaryFile('/mounts/data/proj/sascha/corpora/GoogleNews-vectors-negative300.bin');

 	[dictS, dictSID] = loadSynsetFile(folder);
	
    experiments = dir(fullfile(strcat(folder, 'norm*')));
    %experiments = dir(fullfile(strcat(folder, 'nonorm_20_20_*')));
    
    parfor i=1:size(experiments,1)
        
        experiment = experiments(i).name;
		
		% skip if theta does not exist
        if ~exist(strcat(folder, experiment, '/theta.txt'), 'file')
			continue;
        end
        if ~exist(strcat(folder, experiment, '/iota.txt'), 'file')
			continue;
        end

        for thetaWeight=0.0:0.5:1.0
            if ~exist(strcat(folder, experiment, '/SynsetSimilarity/_score_theta', num2str(thetaWeight * 100),'.txt'), 'file')
                testTheta(folder, W, dictW, dictS, dictSID, experiment, thetaWeight);
            end
        end   
    end
end

function [] = testTheta(folder, W, dictW, dictS, ~, experiment, thetaWeight)
	
	fprintf('\nTESTING %s \n', experiment);
    
    Theta = importdata(strcat(folder, experiment, '/theta.txt'), ' ');
    Iota = importdata(strcat(folder, experiment, '/iota.txt'), ' ');
    
    if strfind(experiment, 'nonorm')
        
    else
        %fprintf('\nNormalizing word vectors (euclidean)');
        %W = normr(W);
    end

    fprintf('Calculating synset vectors ... ');
	S_naiv = zeros(size(dictS, 1), size(W,2));
	S = zeros(size(dictS, 1), size(W,2));
	for l=1:size(Theta, 1)
		w = Theta(l,1);
		s = Theta(l,2);
		theta = Theta(l, 3:end);
		S_naiv(s,:) = S_naiv(s,:) + W(w,:);
		S(s,:) = S(s,:) + (W(w,:) .* theta);
	end
	fprintf('done!\n');
	
	Table = readtable('/mounts/data/proj/sascha/corpora/SCWS/ratings_synsets.txt', 'ReadVariableNames', false, 'Delimiter', '\t');
	Table2 = readtable('/mounts/data/proj/sascha/corpora/SCWS/ratings.txt', 'ReadVariableNames', false, 'Delimiter', '\t','Format','%d%s%s%s%s%s%s%f%f%f%f%f%f%f%f%f%f%f');

	testsetSize = height(Table);
    
    testsDone = 0;
    similarity_sentence1 = zeros(testsetSize, 1);
    similarity_word1 = NaN(testsetSize, 1);
    similarity_lexeme1 = NaN(testsetSize, 1);
    similarity_synset1 = NaN(testsetSize, 1);
    similarity_human1 = NaN(testsetSize, 1);
	similarity_lexemeAv = NaN(testsetSize, 1);
    similarity_synsetAv = NaN(testsetSize, 1);
    
    if (length(Theta) > 150000)
        fprintf('Starting Testset ...');
        for t = 1:testsetSize
		
            [v1, v2, v3, v4, v5, v6] = getVector(Table{t,1}{1}, Table2{t,3}{1}, Table2{t,6}{1}, W, dictW, S, dictS, Theta, Iota, thetaWeight);
            [w1, w2, w3, w4, w5, w6] = getVector(Table{t,3}{1}, Table2{t,5}{1}, Table2{t,7}{1}, W, dictW, S, dictS, Theta, Iota, thetaWeight);

            if (sum((v1 .* v2 .* v3 .* v4 .* w1 .* w2 .* w3 .* w4).^2) > 0)
                similarity_sentence1(t) = 1 - pdist2(v1,w1,'cosine');
                similarity_word1(t) = 1 - pdist2(v2,w2,'cosine');
                similarity_lexeme1(t) = 1 - pdist2(v3,w3,'cosine');
                similarity_synset1(t) = 1 - pdist2(v4,w4,'cosine');
                similarity_lexemeAv(t) = 1 - pdist2(v5,w5,'cosine');  
                similarity_synsetAv(t) = 1 - pdist2(v6,w6,'cosine');  			
                similarity_human1(t) = Table2{t,8};

                testsDone = testsDone + 1;
            else
                %fprintf('Not found (%d) %s or %s\n', t, Table{t,1}{1}, Table{t,3}{1});
            end

        end
    else
        fprintf('Starting Testset in parallel ...');
        parfor t = 1:testsetSize

            [v1, v2, v3, v4, v5, v6] = getVector(Table{t,1}{1}, Table2{t,3}{1}, Table2{t,6}{1}, W, dictW, S, dictS, Theta, Iota, thetaWeight);
            [w1, w2, w3, w4, w5, w6] = getVector(Table{t,3}{1}, Table2{t,5}{1}, Table2{t,7}{1}, W, dictW, S, dictS, Theta, Iota, thetaWeight);

            if (sum((v1 .* v2 .* v3 .* v4 .* w1 .* w2 .* w3 .* w4).^2) > 0)
                similarity_sentence1(t) = 1 - pdist2(v1,w1,'cosine');
                similarity_word1(t) = 1 - pdist2(v2,w2,'cosine');
                similarity_lexeme1(t) = 1 - pdist2(v3,w3,'cosine');
                similarity_synset1(t) = 1 - pdist2(v4,w4,'cosine');
                similarity_lexemeAv(t) = 1 - pdist2(v5,w5,'cosine');  
                similarity_synsetAv(t) = 1 - pdist2(v6,w6,'cosine');  			
                similarity_human1(t) = Table2{t,8};

                testsDone = testsDone + 1;
            else
                %fprintf('Not found (%d) %s or %s\n', t, Table{t,1}{1}, Table{t,3}{1});
            end

        end
    end
    
    fprintf(' done!\n');
	
	% create dir if not exists
	if ~exist(strcat(folder, experiment, '/SynsetSimilarity'), 'dir')
		mkdir(strcat(folder, experiment, '/SynsetSimilarity'));
	end
	
	s_sentence1 = corr(similarity_sentence1,similarity_human1,'type','Spearman', 'row', 'complete');
    s_word1 = corr(similarity_word1,similarity_human1,'type','Spearman', 'row', 'complete');
    s_lexeme1 = corr(similarity_lexeme1,similarity_human1,'type','Spearman', 'row', 'complete');
    s_synset1 = corr(similarity_synset1,similarity_human1,'type','Spearman', 'row', 'complete');
	s_lexemeAv = corr(similarity_lexemeAv,similarity_human1,'type','Spearman', 'row', 'complete');
    s_synsetAv = corr(similarity_synsetAv,similarity_human1,'type','Spearman', 'row', 'complete');
    
    % open file
    fid = fopen(strcat(folder, experiment, '/SynsetSimilarity/_score_theta', num2str(thetaWeight * 100),'.txt'), 'w');
    
    fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman sentence:     %4.3f\n', s_sentence1);
    fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman word:     %4.3f\n', s_word1);
    fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman lexeme_W:   %4.3f\n', s_lexeme1);
    fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman synset_W:   %4.3f\n', s_synset1);
	fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman lexeme_A:   %4.3f\n', s_lexemeAv);
    fprintf(fid, '%d/%d \n', testsDone, testsetSize);
    fprintf(fid, 'Spearman synset_A:   %4.3f\n', s_synsetAv);
    
    fclose(fid);
end

function [sentenceVector, wordVector, lexemeVector, synsetVector, lexemeVectorAv, synsetVectorAv] = getVector(word, pos, sentence, W, dictW, S, dictS, Theta, Iota, thetaWeight, A, dictA)

    dim = size(W,2);
    
    sentenceVector = zeros(1, dim);
	wordIndex = 0;
    wordVector = zeros(1, dim);
    lexemeVector = zeros(1, dim);
    synsetVector = zeros(1, dim);
	lexemeVectorAv = zeros(1, dim);
    synsetVectorAv = zeros(1, dim);

    word = lower(word);
    sentence = regexprep(sentence,'<b> (\w+) </b>',word);
    words = strsplit(lower(sentence), ' ')';
    [wordVectors , wordIndecies]  = getVectors(words, W, dictW);
    
    for i = 1:size(words,1)
        if (sum(wordVectors(i, :).^2) < eps)
            continue
        end

        if (strcmp(words{i}, word))
            %sentenceVector = sentenceVector + wordVectors(i, :);
            wordVector = wordVectors(i, :);
			wordIndex = wordIndecies(i);
        else
            
			if (length(words{i}) > 3)			
				sentenceVector = sentenceVector + wordVectors(i, :);
			end
        end
    end
    
    if (wordIndex == 0)
        return;
        load('/mounts/data/proj/sascha/data/gn_wn21/unknownWords.mat');
        ind = strcmp(word, unknown);
        if (any(ind))
            wordVector = unknownVectors(ind,:);
            lexemeVector = unknownVectors(ind,:);
            lexemeVectorAv = unknownVectors(ind,:);
            synsetVector = unknownVectors(ind,:);
			synsetVectorAv = unknownVectors(ind,:);
        end        
    end
    
    iotaWeight = 1 - thetaWeight; 

    for l=1:size(Theta,1)
        
        if wordIndex == Theta(l,1)
            w = Theta(l,1);
            s = Theta(l,2);
            theta = Theta(l, 3:end);

            if (sum(theta.^2) < eps)
                continue;
            end

            synset_predict = S(s,:);
            lexem_predict = W(w,:) .* theta;

            r_synset = pdist2(synset_predict,sentenceVector,'cosine');
            r_lexem = pdist2(lexem_predict,sentenceVector,'cosine');
			
			synsetVector = synsetVector + ((1 -r_synset) * synset_predict);
			synsetVectorAv = synsetVectorAv  + (synset_predict);
            
			lexemeVector = lexemeVector + (thetaWeight * (1 -r_lexem) * lexem_predict);
			lexemeVectorAv = lexemeVectorAv  + (thetaWeight * lexem_predict);
        end
        
        if thetaWeight < 1 && wordIndex == Iota(l,1)
            s = Iota(l,2);
            iota = Iota(l, 3:end);

            if (sum(iota.^2) < eps)
                continue;
            end

            lexem_predict = S(s,:) .* iota;

            r_lexem = pdist2(lexem_predict,sentenceVector,'cosine');
            
			lexemeVector = lexemeVector + (iotaWeight * (1 -r_lexem) * lexem_predict);
			lexemeVectorAv = lexemeVectorAv  + (iotaWeight * lexem_predict);
        end
    end
end