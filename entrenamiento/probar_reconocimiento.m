addpath('../utils');    
[archivo, ruta] = uigetfile({'*.png;*.jpg;*.jpeg;*.jfif', 'Imagenes'}, 'Selecciona una imagen');
if isequal(archivo, 0)
    disp('No se selecciono ninguna imagen');
    return;
end
imagenPath = fullfile(ruta, archivo);
[digito, scores] = reconocer(imagenPath);

figure;
subplot(1,2,1);
img = imread(imagenPath);
imshow(img);
title(['Numero identificado: ' num2str(digito)]);

subplot(1,2,2);
colores = repmat([0.3 0.6 0.9], 10, 1);
colores(digito+1, :) = [0.9 0.3 0.3];
barra = bar(0:9, scores, 'FaceColor', 'flat');
barra.CData = colores;
xlabel('Digito');
ylabel('Puntaje');
title('Puntaje por digito');
grid on;

function [digito, scores] = reconocer(imagenPath)
    redesFolder = '../redes';
    archivos = dir(fullfile(redesFolder, 'red_*.mat'));
    vec = preprocesarImagen(imagenPath);
    scores = -Inf(1,10);

    for i = 1:numel(archivos)
        data = load(fullfile(redesFolder, archivos(i).name));
        net = data.net;

        numStr = extractBetween(archivos(i).name, 'red_', '.mat');
        numDigito = str2double(numStr{1});

        salida = net(vec);
        scoreNormalizado = salida - 0.5;

        scores(numDigito + 1) = scoreNormalizado;
    end

    disp('Puntajes por digito (0 a 9):');
    disp(scores);

    [~, idx] = max(scores);
    digito = idx - 1;
end