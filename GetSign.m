function [Part,Im] = GetSign(Im,th,n,sideMax)
% This function takes in the watch image Im
% and the other parameters then returns a 4-D
% matrix holding the parts

% % Parameters
% th = 0.01;    % threshold for image segmentation
% n  = 15;      % number of seeds per dimension
% sideMax = 600; % maximum side length in pixels 

% turn image to gray scale
if length(size(Im))>2
    Im = rgb2gray(Im);
end
% set the image size to suitable value
scale = sideMax/(max(size(Im)));
Im = imresize(Im,scale*size(Im));
% Create seeds grid
Sx = linspace(1,size(Im,2),n+2);
Sy = linspace(1,size(Im,1),n+2);
Sx = round(Sx); Sy = round(Sy);
% seeding mask
MASK = false(size(Im));
% seeds
for i = 2:n+1
    for j = 2:n+1
        MASK(Sy(j),Sx(i)) = true;
    end
end
% Image proccesing
[Sy,Sx] = find(MASK);
Parts(:,:,1,1) = false(size(Im));   % preallocation
partsNum = 0; convexity = 0;        % preallocation
% start breaking down process
while ~isempty(Sy)
    mask = false(size(Im));
    mask(Sy(1),Sx(1)) = true;
    MASK(Sy(1),Sx(1)) = false;
    % Compute the weight array based on grayscale intensity differences.
    W = graydiffweight(Im, mask);
    % Segment the image using the weights.
    BW = imsegfmm(W, mask, th);
    % segment the part out of picture
    MASK(BW) = false;
    % Detect incorrect detected shapes
    BW = bwareafilt(BW,1);
    CH = bwconvhull(BW);
    partsNum = partsNum+1;
    Peri = regionprops(BW,'Perimeter','Area');
    if Peri.Area > (numel(BW)/100)
        Peri = Peri.Perimeter;
        PeriConv = regionprops(CH,'Perimeter');
        PeriConv = PeriConv.Perimeter;
        convexity(partsNum) = PeriConv/Peri;
    else
        convexity(partsNum) = 0;
    end
    % save it in parts
    Parts(:,:,partsNum) = BW;
    [Sy,Sx] = find(MASK);
end

% Selecting part with highest convexity
[~,idx] = max(convexity);
Part = Parts(:,:,idx);



