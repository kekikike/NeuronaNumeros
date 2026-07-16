addpath('../utils');

digitoPositivo = '1';
datasetPropio = '../datasets';

imdsPos = imageDatastore(fullfile(datasetPropio, digitoPositivo), 'FileExtensions', {'.png','.jpg','.jpeg'});
nPos = numel(imdsPos.Files);

carpetas = dir(datasetPropio);
carpetas = carpetas([carpetas.isdir]);
digitosPropios = {};
for i = 1:numel(carpetas)
    nombre = carpetas(i).name;
    if ~strcmp(nombre, '.') && ~strcmp(nombre, '..') && ~strcmp(nombre, digitoPositivo)
        digitosPropios{end+1} = nombre;
    end
end

filesNeg = {};
for i = 1:numel(digitosPropios)
    carpetaDigito = fullfile(datasetPropio, digitosPropios{i});
    contenido = dir(fullfile(carpetaDigito, '*.png'));
    contenido = [contenido; dir(fullfile(carpetaDigito, '*.jpg'))];
    contenido = [contenido; dir(fullfile(carpetaDigito, '*.jpeg'))];
    if isempty(contenido)
        continue;
    end
    imdsTemp = imageDatastore(carpetaDigito, 'FileExtensions', {'.png','.jpg','.jpeg'});
    filesNeg = [filesNeg; imdsTemp.Files];
end

nNegPropios = numel(filesNeg);

if nNegPropios < nPos
    faltan = nPos - nNegPropios;
    datasetMatlab = fullfile(matlabroot,'toolbox','nnet','nndemos','nndatasets','DigitDataset');
    imdsDemo = imageDatastore(datasetMatlab, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

    digitosExcluir = [digitosPropios, {digitoPositivo}];
    idxDemoValidos = true(numel(imdsDemo.Files), 1);
    for i = 1:numel(digitosExcluir)
        idxDemoValidos = idxDemoValidos & (imdsDemo.Labels ~= digitosExcluir{i});
    end
    imdsDemoValidos = subset(imdsDemo, idxDemoValidos);

    idxDemoSample = randperm(numel(imdsDemoValidos.Files), min(faltan, numel(imdsDemoValidos.Files)));
    imdsDemoBal = subset(imdsDemoValidos, idxDemoSample);

    filesNeg = [filesNeg; imdsDemoBal.Files];
else
    idxSample = randperm(nNegPropios, nPos);
    filesNeg = filesNeg(idxSample);
end

files = [imdsPos.Files; filesNeg];
labels = [ones(nPos,1); zeros(numel(filesNeg),1)];

n = numel(files);
P = zeros(28*28, n);
for i = 1:n
    P(:,i) = preprocesarImagen(files{i});
end
T = labels';

idx = randperm(n);
P = P(:, idx);
T = T(idx);

net = perceptron;
net = configure(net, P, T);
net = train(net, P, T);

Y = net(P);
aciertos = sum(Y == T);
disp(['Aciertos en su propio entrenamiento: ' num2str(aciertos) ' de ' num2str(n)]);

if ~exist('../redes', 'dir')
    mkdir('../redes');
end
save('../redes/red_1.mat', 'net');

disp('Entrenamiento terminado, red guardada en redes/red_1.mat');