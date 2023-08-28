dmdStopSeq(device, seq)

img = zeros(768, 1024, 'uint8');
rPts = [530, 110; 490, 140; 600, 140];
bPts = [380, 460; 340, 490; 450, 490];
bPts = flip(bPts, 2);

bPts = [100, 812] / 2;
% for i=1:size(bPts, 1)
%     img((bPts(i,1)-10):bPts(i,1), (bPts(i,2)-10):bPts(i,2)) = 255;
%     img(bPts(i,1):(bPts(i,1)+10), bPts(i,2):(bPts(i,2)+10)) = 255;
% end
img = imread('C:\Users\labmember\Desktop\Labview Codes\DMD registration\checkboard32.png');
seq = dmdWriteStaticImage(api, device, img);