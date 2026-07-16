function digito = reconocer(imagenPath)
redesFolder = '../redes';
archivos = dir(fullfile(redesFolder, 'red_*.mat'));
img = imread(imagenPath);
if size(img,3) == 3
    img = rgb2gray(img);
end
img = imresize(img, [28 28]);
vec = double(img(:)) / 255;

mejorScore = -Inf;
digito = -1;

for i = 1:numel(archivos)
    data = load(fullfile(redesFolder, archivos(i).name));
    net = data.net;

    score = net.IW{1,1} * vec + net.b{1};

    numStr = extractBetween(archivos(i).name, 'red_', '.mat');
    numDigito = str2double(numStr{1});

    if score > mejorScore
        mejorScore = score;
        digito = numDigito;
    end
end
end