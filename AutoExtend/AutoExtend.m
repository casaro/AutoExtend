function [] = AutoExtend(varargin)

    if (nargin == 8)
        folder = varargin{1};
        normalizeWeights = varargin{2};
        sWeight = varargin{3};
        lWeight = varargin{4};
		rWeight = varargin{5};
		nWeight = varargin{6};
        experiment = varargin{7};
        RelationFiles = varargin{8};
        
        settings = [true false false];
        weights = [sWeight lWeight rWeight nWeight];
        
    elseif (nargin == 10)
        folder = varargin{1};
        normalizeWeights = varargin{2};
        sWeight = varargin{3};
        lWeight = varargin{4};
        rWeight = varargin{5};
        startNormalizedED = varargin{6};
        normWhenPossibleED = varargin{7};
        endWhenNotED = varargin{8};
        experiment = varargin{9};
        RelationFiles = varargin{10};
        
        settings = [startNormalizedED normWhenPossibleED endWhenNotED];
        weights = [sWeight lWeight rWeight 0];
        
    else
        folder = '[...]';
        normalizeWeights = true;
        sWeight = 0.20;
        lWeight = 0.20;
        rWeight = 0.60;
        startNormalizedED = false;
        normWhenPossibleED = false;
        endWhenNotED = false;  
        experiment = 'naive';
        RelationFiles = cell(4,1);
        RelationFiles{1} = 'hypernym.txt';
        RelationFiles{2} = 'verbGroup.txt';
        RelationFiles{3} = 'similar.txt';
        RelationFiles{4} = 'antonym.txt';
        RelationFiles = [];
        
        settings = [startNormalizedED normWhenPossibleED endWhenNotED];
        weights = [sWeight lWeight rWeight 0];
    end
    
    normalizeVectors = false;
    
    if ~exist(strcat(folder, experiment), 'dir')
        fprintf('Folder does not exist. Created %s\n', strcat(folder, experiment));
        mkdir(strcat(folder, experiment));
    end
    
    if exist(strcat(folder, experiment, '/iota.txt'), 'file')
        fprintf('Model %s already exists. Skipped\n', experiment);
        return;
    end
    
    [W , ~] = loadTxtFile(strcat(folder, 'words.txt'));
    dim = size(W,2); %dim = 1;    
    num_iters = 1000; %num_iters = 0;
    
    [DictS, DictSID] = loadSynsetFile(folder);

    countSynsets = length(DictSID);
    countWords = length(W);
    
    save(strcat(folder, experiment, '/settings.mat'), '-regexp', '^[^WD]');
    
    if (normalizeVectors == true)
        W = normr(W);
    end

    Table = readtable(strcat(folder, 'lexemes.txt'), 'ReadVariableNames', false, 'Delimiter', ' ');
    ThetaMap = table2array(Table(:, 1:2));
    Iota = sparse(ThetaMap(:,1),ThetaMap(:,2),ones(size(ThetaMap,1),1),countWords,countSynsets);
    Theta = Iota'; 

    % create relation matrix - will do a squared error of relation pairs
    RelationMap = [];
    for i=1:size(RelationFiles, 1)
        Table = readtable(strcat(folder, RelationFiles{i}), 'ReadVariableNames', false, 'Delimiter', ' ');
        if isempty(Table)
            continue;
        end
        RelationMap = [RelationMap ; table2array(Table(:, 1:2))];
    end

    if (~isempty(RelationMap))
        fprintf('Creating Relation Matrix. %d relations found.\n', length(RelationMap));
        rFrom = [(1:length(RelationMap))'; (1:length(RelationMap))'];
        rTo = [RelationMap(:,1); RelationMap(:,2)];
        rValue = [ones(length(RelationMap),1); (-1 * ones(length(RelationMap),1))];
        R = sparse(rFrom,rTo,rValue,length(RelationMap),countSynsets);
    else
        fprintf('Relation Matrix is empty.\n');
        R = zeros(1, countSynsets);
    end
    
    if (normalizeWeights == true)
        sWeight = sWeight / countWords;
        lWeight = lWeight / nnz(Theta);
        rWeight = rWeight / length(RelationMap);
        weights(1:3) = [sWeight lWeight rWeight];
        weights = weights / norm(weights,1);
    end 
    
    trainModel(folder, dim, num_iters, countSynsets, countWords, W, Theta, Iota, R, weights, settings, experiment);
end

function [] = trainModel(folder, dim, num_iters, countSynsets, countWords, W, Theta, Iota, R, weights, settings, experiment)
   
    if ~exist(strcat(folder, experiment, '/debug'), 'dir')
        mkdir(strcat(folder, experiment, '/debug'));
    end
    %delete(strcat(folder, experiment, '/debug/dim_finished_*'));
	
    J_history = zeros(num_iters,5);
    lastNormIter = 0;

    fprintf('Starting parallel computation on %d dimensions.\n', dim);
    %poolobj = parpool('local',30);
    ThetaValues = NaN(nnz(Theta),dim);
    IotaValues = NaN(nnz(Iota),dim);
 
    for d=1:dim %parfor
        
        dimFilename = strcat(folder, experiment, '/debug/ThetaIota_', num2str(d), '.mat');
        
        if exist(dimFilename, 'file')
            [Theta_dim, Iota_dim, J_history_dim, lastNormIter_dim] = loadVariables(dimFilename);
        else
            Theta_dim = NaN;
            Iota_dim = NaN;
            J_history_dim = NaN; 
            lastNormIter_dim = NaN;
            saveVariables(dimFilename, Theta_dim, Iota_dim, J_history_dim, lastNormIter_dim);
            
            w = W(:,d);

            debugFilename = strcat(folder, experiment, '/debug/dim_', num2str(d),  '.txt');
            debugFilenameFinished = strcat(folder, experiment, '/debug/dim_finished_', num2str(d),  '.txt');
            debugFile = fopen(debugFilename, 'w');

            [Theta_dim, Iota_dim, J_history_dim, lastNormIter_dim] = trainDimension(num_iters, countSynsets, countWords, w, Theta, Iota, R, weights, settings, debugFile);
            saveVariables(dimFilename, Theta_dim, Iota_dim, J_history_dim, lastNormIter_dim);
            
            fclose(debugFile);
            movefile(debugFilename,debugFilenameFinished);
        end
        
        if (length(Theta_dim) == nnz(Theta) && length(Iota_dim) == nnz(Iota))
            ThetaValues(:,d) = Theta_dim;
            IotaValues(:,d) = Iota_dim;
            J_history = J_history + (J_history_dim ./ dim);
            lastNormIter = lastNormIter + (lastNormIter_dim / dim);
        end
    end
    
    fprintf('Parallel computation completed.\n');
    
    % looking for missing values
    for d=1:dim        
        if (any(isnan(ThetaValues(:,d))) || any(isnan(IotaValues(:,d))))        
            dimFilename = strcat(folder, experiment, '/debug/ThetaIota_', num2str(d), '.mat');
        
            if exist(dimFilename, 'file')
                [Theta_dim, Iota_dim, J_history_dim, lastNormIter_dim] = loadVariables(dimFilename);
            end

            if (length(Theta_dim) == nnz(Theta) && length(Iota_dim) == nnz(Iota))
                ThetaValues(:,d) = Theta_dim;
                IotaValues(:,d) = Iota_dim;
                J_history = J_history + (J_history_dim ./ dim);
                lastNormIter = lastNormIter + (lastNormIter_dim / dim);
            end
        end
    end
    
    % if still not all values available
    if (any(isnan(ThetaValues(:))) || any(isnan(IotaValues(:))))
        fprintf('Not all values available (process not master). Process ended.\n');
        return;
    end
    
    fprintf('Saving values ...');
    
    %load(strcat(folder, experiment, '/debug/ThetaIota.mat'));
    save(strcat(folder, experiment, '/debug/ThetaIota.mat'),'ThetaValues', 'IotaValues');
    delete(strcat(folder, experiment, '/debug/ThetaIota_*'));    

	% print convergence matrix
	fName = strcat(folder, experiment, '/convergence.mat');
	save(fName,'J_history','lastNormIter');

    % print theta matrix
    [synset, word, ~] = find(Theta);
    mat1 = [word synset ThetaValues];
    fName = strcat(folder, experiment, '/theta.txt');
    dlmwrite(fName,mat1,'delimiter',' ','newline','pc','precision',6);
    
    % print iota matrix
    [word, synset, ~] = find(Iota);
    mat2 = [word synset IotaValues];
    fName = strcat(folder, experiment, '/iota.txt');
    dlmwrite(fName,mat2,'delimiter',' ','newline','pc','precision',6);
    
    % Plot the convergence graph
    for i=2:num_iters
        if (J_history(i,:) == J_history(i-1,:))
            num_iters = i;
            break;
        end
    end    
    h=figure('Visible','off');
    hax = axes;
    hold on;    
    plot(1:num_iters, (J_history(1:num_iters,1) / max(J_history(:,1))), '-', 'Color', [0 0.8 1], 'LineWidth', 2);
    plot(1:num_iters, (J_history(1:num_iters,2) / max(J_history(:,2))), '-', 'Color', [1 0.4 0], 'LineWidth', 2);
	plot(1:num_iters, (J_history(1:num_iters,3) / max(J_history(:,3))), '-', 'Color', [0 0.5 0], 'LineWidth', 2);
    plot(1:num_iters, (J_history(1:num_iters,4) / max(J_history(:,4))), '-', 'Color', [0.7 0 0.7], 'LineWidth', 2);
    plot(1:num_iters, (J_history(1:num_iters,5) / max(J_history(:,5))), '-', 'Color', [0.3 0.3 0.3]);
    line([lastNormIter lastNormIter],get(hax,'YLim'),'Color',[0.7 0 0.7]);
    legend('autoencoder','lexeme', 'relations', 'norm', 'learning rate');
    xlabel('iteration');
    ylabel('average error');
    fName = strcat(folder, experiment, '/convergence.jpg');
    saveas(h,fName);  % here you save the figure
    close(h);
    
    fprintf(' done!\n');

end

function [var1, var2, var3, var4] = loadVariables(filename)
    load(filename);
end

function saveVariables(filename, var1, var2, var3, var4)
    save(filename,'var1', 'var2', 'var3', 'var4');
end

function [EValues, DValues, J_history, lastNormIter] = trainDimension(num_iters, ~, countWords, w, E, D, R, weights, settings, debugFile)

    learningRate = 0.00005;
    fprintf(debugFile, 'Starting computation with learning rate %f\n',learningRate);
    
    J_history = zeros(num_iters,5);
    
    if (settings(1) == true)
        % normalize matrizes
        fprintf(debugFile, 'Normalizing matrices at start.\n');
        E = columnNormalize(E);    
        D = columnNormalize(D);
    end
    
    lastNormIter = 0;
    iter = 1;
    while iter <= num_iters
        
        fprintf(debugFile, 'Iteration %d/%d\n', iter, num_iters);
        
        grad_E = sparse(size(E,1),size(E,2));
        grad_D = sparse(size(D,1),size(D,2));        
        J1 = 0;
        J2 = 0;
        J3 = 0;
        J4 = 0;
        
        % update with respect to autoencoder
        if (weights(1) > 0)
            [J1, grads_E, grads_D] = gradient(w, E, D, w, 'both');
            %gradientChecking(w, E, D, R, grads_E, grads_D, iter, weights, 'J1', 0.00001);
            grad_E = grad_E + (weights(1) * grads_E);
            grad_D = grad_D + (weights(1) * grads_D);
        end
        
        % update with respect to lexeme
        if (weights(2) > 0)
            [J2, gradl_E, gradl_D] = gradientLexeme(w, E, D);
            %gradientChecking(w, E, D, R, gradl_E, gradl_D, iter, weights, 'J2', 0.00001);
            grad_E = grad_E + (weights(2) * gradl_E);
            grad_D = grad_D + (weights(2) * gradl_D);
        end
        
        
        % update with respect to relations
        if (weights(3) > 0)
            [J3, gradr_E, ~] = gradient(w, E, R, zeros(size(R,1),1) , 'onlyE');
            %gradientChecking(w, E, D, R, gradr_E, grad_D, iter, weights, 'J3', 0.00001);
            grad_E = grad_E + (weights(3) * gradr_E);
        end
        
        
        % update with respect to column norm
        if (weights(4) > 0)
            [J4_E, gradn_E] = gradientColumnNorm(E);
            [J4_D, gradn_D] = gradientColumnNorm(D);
            J4 = J4_E + J4_D;
            %gradientChecking(w, E, D, R, gradn_E, gradn_D, iter, weights, 'J4', 0.00001);
            grad_E = grad_E + (weights(4) * gradn_E);
            grad_D = grad_D + (weights(4) * gradn_D);
        end
        
        J = (J1 * weights(1)) + (J2 * weights(2)) + (J3 * weights(3)) + (J4 * weights(4));
        J_history(iter,1) = J1 / countWords;
        J_history(iter,2) = J2 / nnz(E);
        J_history(iter,3) = J3 / size(R, 1);
		J_history(iter,4) = J4 / (size(E,2) + size(D,2));
        J_history(iter,5) = learningRate;
        
        fprintf(debugFile, 'Error J:  %8.3f\n', J);
        fprintf(debugFile, 'Error J1: %5.4f %8.3f %5.4f\n', J1 * weights(1)/J, J1 * weights(1), J_history(iter,1));
        fprintf(debugFile, 'Error J2: %5.4f %8.3f %5.4f\n', J2 * weights(2)/J, J2 * weights(2), J_history(iter,2));
        fprintf(debugFile, 'Error J3: %5.4f %8.3f %5.4f\n', J3 * weights(3)/J, J3 * weights(3), J_history(iter,3));
        fprintf(debugFile, 'Error J4: %5.4f %8.3f %5.4f\n', J4 * weights(4)/J, J4 * weights(4), J_history(iter,4));
        
        E_new = E - (learningRate * grad_E);
        E_new = keepSparsity(E, E_new);

        D_new = D - (learningRate * grad_D);
        D_new = keepSparsity(D, D_new);
        
        % get new cost
        if (weights(1) > 0)
            J1 = costFunc(w, E_new, D_new, w);
        end         
        if (weights(2) > 0)
            J2 = costFuncLexeme(w, E_new, D_new);
        end
        if (weights(3) > 0)
            J3 = costFunc(w, E_new, R, zeros(size(R,1),1)); 
        end
        if (weights(4) > 0)
            J4 = costFuncColumnNorm(E_new) + costFuncColumnNorm(D_new);
        end
        J_new = (J1 * weights(1)) + (J2 * weights(2)) + (J3 * weights(3)) + (J4 * weights(4));
        
        fprintf(debugFile, 'New Error J:  %8.3f\n', J_new);
        fprintf(debugFile, 'New Error J1: %5.4f %8.3f\n', J1 * weights(1)/J_new, J1 * weights(1));
        fprintf(debugFile, 'New Error J2: %5.4f %8.3f\n', J2 * weights(2)/J_new, J2 * weights(2));
        fprintf(debugFile, 'New Error J3: %5.4f %8.3f\n', J3 * weights(3)/J_new, J3 * weights(3));
        fprintf(debugFile, 'New Error J4: %5.4f %8.3f\n', J4 * weights(4)/J_new, J4 * weights(4));
        
        % check if error increased
        if J_new > J
            
            fprintf(debugFile, 'Error increased\n');
            
            % reduce learning rate
            learningRate = learningRate / 3;
            fprintf(debugFile, 'New Learning Rate: %f\n', learningRate);
            
            if learningRate < 0.000001
                
                fprintf(debugFile, 'Learning Rate to small. Calculation stopped\n\n');
                
                for i=iter+1:num_iters
                    J_history(i,:) = J_history(iter,:);
                end
                
                break;
            end
            
        else
            
            fprintf(debugFile, 'Error decreased\n');
            
            % increasing learning rate
            learningRate = learningRate * 1.1;
            fprintf(debugFile, 'New Learning Rate: %f\n', learningRate);
            
            % update matrix
            E = E_new;            
            D = D_new;
            
            if (settings(2) == true)
                
                fprintf(debugFile, 'Trying to normalize matrices\n');
                
                % normalize matrizes
                E_new = columnNormalize(E_new);
                E_new = keepSparsity(E, E_new);
                D_new = columnNormalize(D_new);
                D_new = keepSparsity(D, D_new);

                % get new cost
                if (weights(1) > 0)
                    J1 = costFunc(w, E_new, D_new, w);
                end         
                if (weights(2) > 0)
                    J2 = costFuncLexeme(w, E_new, D_new);
                end
                if (weights(3) > 0)
                    J3 = costFunc(w, E_new, R, zeros(size(R,1),1)); 
                end
                if (weights(4) > 0)
                    J4 = costFuncColumnNorm(E_new) + costFuncColumnNorm(D_new);
                end
                J_norm = (J1 * weights(1)) + (J2 * weights(2)) + (J3 * weights(3)) + (J4 * weights(4));
                
                fprintf(debugFile, 'Norm Error J: %f\n', J_norm);
                fprintf(debugFile, 'Norm Error J1: %5.4f %8.3f\n', J1 * weights(1)/J_norm, J1 * weights(1));
                fprintf(debugFile, 'Norm Error J2: %5.4f %8.3f\n', J2 * weights(2)/J_norm, J2 * weights(2));
                fprintf(debugFile, 'Norm Error J3: %5.4f %8.3f\n', J3 * weights(3)/J_norm, J3 * weights(3));
                fprintf(debugFile, 'Norm Error J4: %5.4f %8.3f\n', J4 * weights(4)/J_norm, J4 * weights(4));

                if J_norm < J

                    fprintf(debugFile, 'Error decreased. Matrix normalized\n');
                    
                    % update matrix
                    E = E_new;            
                    D = D_new;
                     
                    lastNormIter = iter;
                else
                    fprintf(debugFile, 'Error increased. Matrix not normalized\n');
                    
                    % if only as long as normalization possible
                    if settings(3) == true
                        
                        fprintf(debugFile, 'Normalization not possible. Calculation stopped\n\n');
                
                        for i=iter+1:num_iters
                            J_history(i,:) = J_history(iter,:);
                        end

                        break;
                    end
                end
                
            end
            
            fprintf(debugFile, 'Iteration finished.\n\n');
            
            % do next iteration
            iter = iter + 1;
            
        end
    end
    
    fprintf(debugFile, 'Calculation finished. Learned values will be returned');
    
    EValues = nonzeros(E);
    DValues = nonzeros(D);

end

function [E_new] = keepSparsity(E, E_new)

    while (nnz(E) ~= nnz(E_new))
        [r1,c1,~] = find(E);
        [r2,c2,~] = find(E_new);
        for l=1:length(r1)
            if (r1(l) ~= r2(l) || c1(l) ~= c2(l))
                E_new(r1(l),c1(l)) = eps;
                break; 
            end
        end
    end
end