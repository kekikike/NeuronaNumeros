addpath('../utils');

[archivo, ruta] = uigetfile({'*.png;*.jpg;*.jpeg', 'Imagenes'}, 'Selecciona una imagen');

if isequal(archivo, 0)
    disp('No se selecciono ninguna imagen');
    return;
end

imagenPath = fullfile(ruta, archivo);

digito = reconocer(imagenPath);

img = imread(imagenPath);
imshow(img);
title(['Numero identificado: ' num2str(digito)]);

function digito = reconocer(imagenPath)
    redesFolder = '../redes';
    archivos = dir(fullfile(redesFolder, 'red_*.mat'));

    vec = preprocesarImagen(imagenPath);

    scores = -Inf(1,10);

    for i = 1:numel(archivos)
        data = load(fullfile(redesFolder, archivos(i).name));
        net = data.net;

        w = net.IW{1,1};
        b = net.b{1};

        scoreNormalizado = (w * vec + b) / norm(w);

        numStr = extractBetween(archivos(i).name, 'red_', '.mat');
        numDigito = str2double(numStr{1});

        scores(numDigito + 1) = scoreNormalizado;
    end

    disp('Puntajes por digito (0 a 9):');
    disp(scores);

    [~, idx] = max(scores);
    digito = idx - 1;
end