addpath('../utils');
tic;

datasetPropio = '../datasets';
digitos = {'0','1','2','3','4','5','6','7','8','9'};

fprintf('=== RECOLECTANDO IMAGENES ===\n');
archivosPorDigito = cell(1,10);
for d = 1:numel(digitos)
    carpeta = fullfile(datasetPropio, digitos{d});
    if ~exist(carpeta, 'dir')
        fprintf('Carpeta %s no encontrada, se omite.\n', digitos{d});
        archivosPorDigito{d} = {};
        continue;
    end
    imds = imageDatastore(carpeta, 'FileExtensions', {'.png','.jpg','.jpeg','.jfif'});
    archivosPorDigito{d} = imds.Files;
    fprintf('Digito %s: %d imagenes\n', digitos{d}, numel(imds.Files));
end

fprintf('\n=== ENTRENANDO 10 REDES独立 ===\n');
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
        fprintf('Digito %s: sin negativos, se omite.\n', digitoPositivo);
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

    net = patternnet([128 64]);
    net.trainFcn = 'trainscg';
    net.trainParam.epochs = 300;
    net.trainParam.goal = 1e-6;
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    net.divideParam.trainRatio = 0.80;
    net.divideParam.valRatio = 0.15;
    net.divideParam.testRatio = 0.05;
    net.performFcn = 'crossentropy';

    net = train(net, P, T);

    Y = net(P) > 0.5;
    aciertos = sum(Y == T);
    porcentaje = 100 * aciertos / n;
    fprintf('Digito %s: %d de %d (%.2f%%)\n', digitoPositivo, aciertos, n, porcentaje);

    resumen(d,:) = [d-1, aciertos, n];

    if ~exist('../redes', 'dir')
        mkdir('../redes');
    end
    save(fullfile('../redes', ['red_' digitoPositivo '.mat']), 'net');
end

promedioGeneral = 100 * sum(resumen(:,2)) / sum(resumen(:,3));
fprintf('\n=== RESUMEN ===\n');
fprintf('Promedio general: %.2f%%\n', promedioGeneral);
toc;
