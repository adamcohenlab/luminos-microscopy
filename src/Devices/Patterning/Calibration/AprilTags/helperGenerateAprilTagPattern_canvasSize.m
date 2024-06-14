%Adapted from helperGenerateAprilTagPattern from MATLAB example. F. Phil
%Brooks III, 2024.
% This version generates an array of tags to fill a canvas of a given pixel
% size ([rows, columns]), with at least minPerSide tags on a side.
function calibPattern = helperGenerateAprilTagPattern_canvasSize(imdsTags,canvasSize,minPerSide,tagFamily)

aspectRatio = max(canvasSize)/min(canvasSize);
tagArrangement = [round(aspectRatio*minPerSide),minPerSide];
if canvasSize(1) < canvasSize(2)
    tagArrangement = flip(tagArrangement);
end

numTags = tagArrangement(1)*tagArrangement(2);
tagIds = zeros(1,numTags);

% Read the first image.
I = readimage(imdsTags,3); %offset because of overview image
Igray = im2gray(I);

%get info about tag size:
[tagIds(1), tagLoc] = readAprilTag(imresize(Igray,10,"nearest"),tagFamily);
tagSize = round(max(tagLoc(:,2)/10)-min(tagLoc(:,2)/10));
finalSize = max(2*tagSize,size(Igray,2));

tagScale = floor(min(canvasSize./tagArrangement)./finalSize);
finalSize = finalSize * tagScale;

% Scale up the thumbnail tag image. (nearest neighbor interpolation)
Ires = imresize(Igray,tagScale,"nearest");

% Detect the tag ID and location (in image coordinates).
[tagIds(1), tagLoc] = readAprilTag(Ires,tagFamily);

% Pad image with white boundaries (ensures the tags replace the black
% portions of the checkerboard).
% tagSize = round(max(tagLoc(:,2)) - min(tagLoc(:,2)));
% padSize = round(tagSize/2 - (size(Ires,2) - tagSize)/2);
padSize = round((finalSize-size(Ires,2))/2);
Ires = padarray(Ires,[padSize,padSize],255);

% Initialize tagImages array to hold the scaled tags.
tagImages = zeros(size(Ires,1),size(Ires,2),numTags);
tagImages(:,:,1) = Ires;

for idx = 2:numTags
   
    I = readimage(imdsTags,idx + 2);
    Igray = im2gray(I);
    Ires = imresize(Igray,tagScale,"nearest");
    Ires = padarray(Ires,[padSize,padSize],255);
    
    tagIds(idx) = readAprilTag(Ires,tagFamily);
    
    % Store the tag images.
    tagImages(:,:,idx) = Ires;
     
end

% Sort the tag images based on their IDs.
[~, sortIdx] = sort(tagIds);
tagImages = tagImages(:,:,sortIdx);

% Reshape the tag images to ensure that they appear in column-major order
% (montage function places image in row-major order).
columnMajIdx = reshape(1:numTags,tagArrangement)';
tagImages = tagImages(:,:,columnMajIdx(:));

% Create the pattern using 'montage'.
imgData = imtile(tagImages,GridSize=tagArrangement);
calibPattern = zeros(canvasSize);
row_offset = round(max(0,(canvasSize(1) - size(imgData,1)) / 2));
col_offset = round(max(0,(canvasSize(2) - size(imgData,2)) / 2));

calibPattern(row_offset+1:min(canvasSize(1),size(imgData,1))+row_offset,1+col_offset:min(canvasSize(2),size(imgData,2))+col_offset) = imgData(1:min(canvasSize(1),size(imgData,1)),1:min(canvasSize(2),size(imgData,2)));
end