datasetPropio = '../datasets';
digitoPositivo = '0';
imdsPos = imageDatastore(fullfile(datasetPropio, digitoPositivo));
nPos = numel(imdsPos.Files);
datasetMatlab = fullfile(matlabroot,'toolbox','nnet','nndemos','nndatasets','DigitDataset');
imdsDemo = imageDatastore(datasetMatlab, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
imdsNeg = subset(imdsDemo, imdsDemo.Labels ~= digitoPositivo);
idxNeg = randperm(numel(imdsNeg.Files), nPos);
imdsNegBal = subset(imdsNeg, idxNeg);
files = [imdsPos.Files; imdsNegBal.Files];
labels = [ones(nPos,1); zeros(nPos,1)];
n = numel(files);
P = zeros(28*28, n);
for i = 1:n
img = imread(files{i});
if size(img,3) == 3
img = rgb2gray(img);
end
img = imresize(img, [28 28]);
P(:,i) = double(img(:)) / 255;
end
T = labels';
idx = randperm(n);
P = P(:, idx);
T = T(idx);
net = perceptron;
net = configure(net, P, T);
net = train(net, P, T);
if ~exist('../redes', 'dir')
mkdir('../redes');
end
save('../redes/red_0.mat', 'net');
disp('Entrenamiento terminado, red guardada en redes/red_0.mat');