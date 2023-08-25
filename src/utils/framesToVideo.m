function framesToVideo(frames, options)
% frames are grayscale and [x,y,frame]
arguments
    frames (:,:,:) double
    options.format (1,:) char {mustBeMember(options.format,{'avi','mp4'})} = 'avi'
end

% create video writer object
if strcmp(options.format,'avi')
    writerObj = VideoWriter('video.avi');
elseif strcmp(options.format,'mp4')
    writerObj = VideoWriter('video.mp4','MPEG-4');
end

open(writerObj);

% write frames to video
for i = 1:size(frames,3)
    writeVideo(writerObj,frames(:,:,i));
end

% close video writer object
close(writerObj);
end