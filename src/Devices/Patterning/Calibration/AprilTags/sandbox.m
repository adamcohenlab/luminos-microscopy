tagFamily = "tagCustom48h12";
tagImageFolder = fullfile("C:\Updated_Control_Software\luminos-private\src\Devices\Patterning\Calibration\AprilTags",...
    tagFamily);
imdsTags = imageDatastore(tagImageFolder);
%%
tagArrangement = [5,4];
calibPattern = helperGenerateAprilTagPattern(imdsTags,tagArrangement,tagFamily);

%%
% Read and localize the tags in the calibration pattern.
[tagIds, tagLocs] = readAprilTag(calibPattern,tagFamily);

% Sort the tags based on their ID values.
[~, sortIdx] = sort(tagIds);
tagLocs = tagLocs(:,:,sortIdx);

% Reshape the tag corner locations into an M-by-2 array.
tagLocs = reshape(permute(tagLocs,[1,3,2]),[],2);

% Convert the AprilTag corner locations to checkerboard corner locations.
%In other words, instead of grouping four corners per tag, then going to
%next tag, sort corner locations as if we just have a grid of corners
%without caring about which tag the corners go to (column major).

%checkerIdx = helperAprilTagToCheckerLocations(tagArrangement);
%imagePoints = tagLocs(checkerIdx(:),:);
imagePoints = tagLocs;

% Display corner locations.
figure; imshow(calibPattern); hold on
plot(imagePoints(:,1),imagePoints(:,2),"ro-",MarkerSize=15)