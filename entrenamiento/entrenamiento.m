addpath('../utils');
datasetPropio = '../datasets';
digitos = {'0','1','2','3','4','5','6','7','8','9'};

for d = 1:numel(digitos)
    digitoPositivo = digitos{d};
    carpetaPositivo = fullfile(datasetPropio, digitoPositivo);
    if ~exist(carpetaPositivo, 'dir')
        continue;
    end
    contenidoPos = dir(fullfile(carpetaPositivo, '*.png'));
    contenidoPos = [contenidoPos; dir(fullfile(carpetaPositivo, '*.jpg'))];
    contenidoPos = [contenidoPos; dir(fullfile(carpetaPositivo, '*.jpeg'))];
    if isempty(contenidoPos)
        continue;
    end

    imdsPos = imageDatastore(carpetaPositivo, 'FileExtensions', {'.png','.jpg','.jpeg'});
    nPos = numel(imdsPos.Files);

    digitosPropios = {};
    for i = 1:numel(digitos)
        if ~strcmp(digitos{i}, digitoPositivo)
            carpetaOtro = fullfile(datasetPropio, digitos{i});
            if exist(carpetaOtro, 'dir')
                digitosPropios{end+1} = digitos{i};
            end
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
    fprintf('Digito %s: aciertos %d de %d\n', digitoPositivo, aciertos, n);

    if ~exist('../redes', 'dir')
        mkdir('../redes');
    end
    save(fullfile('../redes', ['red_' digitoPositivo '.mat']), 'net');
end

disp('Entrenamiento de todos los digitos disponibles terminado.');