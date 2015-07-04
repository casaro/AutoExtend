function [dictS, dictSID] = loadSynsetFile(folder)
    
    fileID = fopen(strcat(folder, 'synsets.txt'));
    Table = textscan(fileID, '%s\t%s\n', 'CollectOutput',1);
    dictSID = Table{1,1}(:, 1);
    dictS = Table{1,1}(:, 2);
    
end