addpath('../utils');

datasetPropio = '../datasets';
digitos = {'0','1','2','3','4','5','6','7','8','9'};
resultados = zeros(10,3);

for d = 1:numel(digitos)
    digitoActual = digitos{d};
    archivoRed = fullfile('../redes', ['red_' digitoActual '.mat']);
    if ~exist(archivoRed, 'file')
        continue;
    end
    data = load(archivoRed);
    net = data.net;

    carpetaPositivo = fullfile(datasetPropio, digitoActual);
    imdsPos = imageDatastore(carpetaPositivo, 'FileExtensions', {'.png','.jpg','.jpeg','.jfif'});
    nPos = numel(imdsPos.Files);

    filesNeg = {};
    for i = 1:numel(digitos)
        if ~strcmp(digitos{i}, digitoActual)
            carpetaOtro = fullfile(datasetPropio, digitos{i});
            if exist(carpetaOtro, 'dir')
                imdsTemp = imageDatastore(carpetaOtro, 'FileExtensions', {'.png','.jpg','.jpeg','.jfif'});
                filesNeg = [filesNeg; imdsTemp.Files];
            end
        end
    end
    idxSample = randperm(numel(filesNeg), min(nPos, numel(filesNeg)));
    filesNeg = filesNeg(idxSample);

    files = [imdsPos.Files; filesNeg];
    labels = [ones(nPos,1); zeros(numel(filesNeg),1)];

    n = numel(files);
    P = zeros(28*28, n);
    for i = 1:n
        P(:,i) = preprocesarImagen(files{i});
    end
    T = labels';

    Y = net(P) > 0.5;
    aciertos = sum(Y == T);
    porcentaje = 100 * aciertos / n;

    resultados(d,:) = [d-1, aciertos, n];
    fprintf('Digito %d: %d de %d aciertos (%.2f%%)\n', d-1, aciertos, n, porcentaje);
end

promedioGeneral = 100 * sum(resultados(:,2)) / sum(resultados(:,3));
fprintf('\nPromedio general del sistema: %.2f%%\n', promedioGeneral);