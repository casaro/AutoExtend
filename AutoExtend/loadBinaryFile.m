function [A, dictA ] = loadBinaryFile( varargin )

if (nargin == 1)
    filename = varargin{1};
    max = -1;
    fprintf('Reading word vectors ... ');
elseif (nargin == 2)    
    filename = varargin{1};
    max = varargin{2};
    fprintf('Reading word vectors (up to %d) ... ', max);
else
    fprintf('Reading word vectors - Error in number of arguments');
    return;
end

fid = fopen(filename);

stringbuffer = blanks(300);

for j=1:300;
    c = fread(fid,1,'uchar');

    if c == 10 || c == 32
        break;
    end

    stringbuffer(j) = c;
end  
words = str2double(stringbuffer(1:j-1));

for j=1:300;
    c = fread(fid,1,'uchar');

    if c == 10 || c == 32
        break;
    end

    stringbuffer(j) = c;
end  
dim = str2double(stringbuffer(1:j-1));

if (max > 0)
    words = max;
end
dictA = cell(words, 1);
A = zeros(words,dim);

for i=1:words;
    
    for j=1:300;
        c = fread(fid,1,'uchar');
        
        if c == 10
            c = fread(fid,1,'uchar');
        end
        
        if c == 32
            break;
        end
        
        stringbuffer(j) = c;
    end    
    dictA{i} = stringbuffer(1:j-1);
    
    A(i,:) = fread(fid,dim,'single');
    
end

fprintf('done!\n');