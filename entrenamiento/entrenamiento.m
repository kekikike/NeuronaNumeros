addpath('../utils');
tic;

datasetPropio = '../datasets';
rutaMnistConvertido = fullfile(datasetPropio, 'numbers', 'mnist_convertido');
digitos = {'0','1','2','3','4','5','6','7','8','9'};

fprintf('=== Recolectando archivos por digito ===\n');
archivosPorDigito = cell(1,10);
for d = 1:numel(digitos)
    digitoActual = digitos{d};

    carpetaPropia = fullfile(datasetPropio, digitoActual);
    filesPropios = {};
    if exist(carpetaPropia, 'dir')
        imdsTemp = imageDatastore(carpetaPropia, 'FileExtensions', {'.png','.jpg','.jpeg','.jfif'});
        if numel(imdsTemp.Files) > 0
            filesPropios = imdsTemp.Files;
        end
    end

    carpetaMnist = fullfile(rutaMnistConvertido, digitoActual);
    filesMnist = {};
    if exist(carpetaMnist, 'dir')
        imdsMnist = imageDatastore(carpetaMnist, 'FileExtensions', {'.png'});
        if numel(imdsMnist.Files) > 0
            filesMnist = imdsMnist.Files;
        end
    end

    archivosPorDigito{d} = [filesPropios; filesMnist];
    fprintf('Digito %s: %d propias + %d mnist = %d total\n', ...
        digitoActual, numel(filesPropios), numel(filesMnist), numel(archivosPorDigito{d}));
end

totalGeneral = sum(cellfun(@numel, archivosPorDigito));
if totalGeneral == 0
    error('No se encontro ninguna imagen. Revisa las rutas de datasetPropio y rutaMnistConvertido.');
end

fprintf('\n=== Entrenando redes ===\n');
resumen = zeros(10,3);

for d = 1:numel(digitos)
    digitoPositivo = digitos{d};
    filesPos = archivosPorDigito{d};
    nPos = numel(filesPos);
    if nPos == 0
        fprintf('Digito %s: sin imagenes, se omite.\n', digitoPositivo);
        continue;
    end

    filesNeg = {};
    for i = 1:numel(digitos)
        if i ~= d
            filesNeg = [filesNeg; archivosPorDigito{i}];
        end
    end
    if isempty(filesNeg)
        fprintf('Digito %s: sin negativos disponibles, se omite.\n', digitoPositivo);
        continue;
    end

    idxSample = randperm(numel(filesNeg), min(nPos, numel(filesNeg)));
    filesNeg = filesNeg(idxSample);

    files = [filesPos; filesNeg];
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

    net = patternnet(30);
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    net.divideParam.trainRatio = 0.85;
    net.divideParam.valRatio = 0.15;
    net.divideParam.testRatio = 0;

    net = train(net, P, T);

    Y = net(P) > 0.5;
    aciertos = sum(Y == T);
    porcentaje = 100 * aciertos / n;
    fprintf('Digito %s: %d de %d aciertos (%.2f%%)\n', digitoPositivo, aciertos, n, porcentaje);

    resumen(d,:) = [d-1, aciertos, n];

    if ~exist('../redes', 'dir')
        mkdir('../redes');
    end
    save(fullfile('../redes', ['red_' digitoPositivo '.mat']), 'net');
end

promedioGeneral = 100 * sum(resumen(:,2)) / sum(resumen(:,3));
fprintf('\n=== Resumen final ===\n');
fprintf('Promedio general del sistema: %.2f%%\n', promedioGeneral);

toc;
disp('Entrenamiento completo terminado.');