addpath('../utils');
[archivo, ruta] = uigetfile({'*.png;*.jpg;*.jpeg;*.jfif', 'Imagenes'}, 'Selecciona una imagen');
if isequal(archivo, 0)
    disp('No se selecciono ninguna imagen');
    return;
end
imagenPath = fullfile(ruta, archivo);
[digito, scores] = reconocer(imagenPath);
vec = preprocesarImagen(imagenPath);

fig = figure('Name', 'Reconocimiento', 'NumberTitle', 'off', 'Position', [200 200 900 450]);

subplot(1,2,1);
img = imread(imagenPath);
imshow(img);
title(['Numero identificado: ' num2str(digito)]);

axGrafico = subplot(1,2,2);
colores = repmat([0.3 0.6 0.9], 10, 1);
colores(digito+1, :) = [0.9 0.3 0.3];
barra = bar(0:9, scores, 'FaceColor', 'flat');
barra.CData = colores;
xlabel('Digito');
ylabel('Puntaje');
title('Puntaje por digito');
grid on;

posGrafico = get(axGrafico, 'Position');
cx = posGrafico(1) + posGrafico(3)/2;
cy = posGrafico(2) + posGrafico(4)/2;

uicontrol(fig, 'Style', 'text', 'String', '¿Este es tu numero?', ...
    'Units', 'normalized', 'Position', [cx-0.12 cy+0.08 0.24 0.06], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 1 0.8]);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Si', ...
    'Units', 'normalized', 'Position', [cx-0.12 cy-0.02 0.1 0.06], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6 1 0.6], ...
    'Callback', @(src, evt) confirmar_Callback(src, evt, fig));

uicontrol(fig, 'Style', 'pushbutton', 'String', 'No', ...
    'Units', 'normalized', 'Position', [cx+0.02 cy-0.02 0.1 0.06], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 0.6 0.6], ...
    'Callback', @(src, evt) negar_Callback(src, evt, fig, vec, imagenPath, posGrafico));

function confirmar_Callback(~, ~, fig)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text'));
    uicontrol(fig, 'Style', 'text', 'String', '¡Correcto!', ...
        'Units', 'normalized', 'Position', [0.35 0.45 0.3 0.1], ...
        'FontSize', 18, 'FontWeight', 'bold', ...
        'ForegroundColor', [0 0.6 0], 'BackgroundColor', [1 1 1]);
end

function negar_Callback(~, ~, fig, vec, imagenPath, posGrafico)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text'));

    cx = posGrafico(1) + posGrafico(3)/2;
    cy = posGrafico(2) + posGrafico(4)/2;

    uicontrol(fig, 'Style', 'text', 'String', '¿Cual es tu numero?', ...
        'Units', 'normalized', 'Position', [cx-0.15 cy+0.15 0.3 0.06], ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'BackgroundColor', [1 1 0.8]);

    for d = 0:9
        fila = floor(d / 5);
        columna = mod(d, 5);
        bx = cx - 0.15 + columna * 0.06;
        by = cy + 0.02 - fila * 0.1;
        uicontrol(fig, 'Style', 'pushbutton', 'String', num2str(d), ...
            'Units', 'normalized', 'Position', [bx by 0.05 0.08], ...
            'FontSize', 14, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.85 0.85 1], ...
            'Callback', @(src, evt) seleccionar_Callback(src, evt, fig, vec, d, imagenPath));
    end
end

function seleccionar_Callback(~, ~, fig, vec, digitoCorrecto, imagenPath)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text'));

    redesFolder = '../redes';

    for d = 0:9
        archivoRed = fullfile(redesFolder, ['red_' num2str(d) '.mat']);
        if ~exist(archivoRed, 'file')
            continue;
        end
        data = load(archivoRed);
        net = data.net;

        if d == digitoCorrecto
            target = 1;
        else
            target = 0;
        end

        [net, ~, ~] = adapt(net, vec, target);
        save(archivoRed, 'net');
    end

    uicontrol(fig, 'Style', 'text', ...
        'String', ['Guardado como numero ' num2str(digitoCorrecto) '. Red actualizada.'], ...
        'Units', 'normalized', 'Position', [0.2 0.45 0.6 0.1], ...
        'FontSize', 15, 'FontWeight', 'bold', ...
        'ForegroundColor', [0 0.4 0.8], 'BackgroundColor', [1 1 1]);

    fprintf('Imagen "%s" guardada como numero %d. Redes actualizadas.\n', imagenPath, digitoCorrecto);
end

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