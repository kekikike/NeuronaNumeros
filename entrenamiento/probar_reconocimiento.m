addpath('../utils');
[archivo, ruta] = uigetfile({'*.png;*.jpg;*.jpeg;*.jfif', 'Imagenes'}, 'Selecciona una imagen');
if isequal(archivo, 0)
    disp('No se selecciono ninguna imagen');
    return;
end
imagenPath = fullfile(ruta, archivo);
[digito, scores] = reconocer(imagenPath);
vec = preprocesarImagen(imagenPath);

fig = figure('Name', 'Reconocimiento', 'NumberTitle', 'off', ...
    'Position', [80 80 1200 650], 'Color', [0.94 0.94 0.94]);

axImg = axes('Parent', fig, 'Position', [0.03 0.22 0.38 0.75]);
img = imread(imagenPath);
if size(img, 3) == 3
    imgGray = rgb2gray(img);
else
    imgGray = img;
end
hImg = imagesc(axImg, double(imgGray));
colormap(axImg, gray);
axis(axImg, 'image');
axis(axImg, 'off');
title(axImg, ['Numero identificado: ' num2str(digito)], 'FontSize', 16, 'FontWeight', 'bold', 'Units', 'normalized', 'Position', [0.5 1.05 0]);

axGraf = axes('Parent', fig, 'Position', [0.45 0.15 0.52 0.78]);
colores = repmat([0.3 0.6 0.9], 10, 1);
colores(digito+1, :) = [0.9 0.3 0.3];
barra = bar(axGraf, 0:9, scores, 'FaceColor', 'flat');
barra.CData = colores;
xlabel(axGraf, 'Digito', 'FontSize', 12);
ylabel(axGraf, 'Puntaje', 'FontSize', 12);
title(axGraf, 'Puntaje por digito', 'FontSize', 14, 'FontWeight', 'bold');
grid(axGraf, 'on');
axGraf.FontSize = 11;

uicontrol(fig, 'Style', 'text', 'String', '¿Este es tu numero?', ...
    'Units', 'normalized', 'Position', [0.03 0.13 0.35 0.07], ...
    'FontSize', 15, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 1 0.85]);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Si', ...
    'Units', 'normalized', 'Position', [0.08 0.03 0.15 0.08], ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6 1 0.6], ...
    'Callback', @(src, evt) confirmar_Callback(src, evt, fig));

uicontrol(fig, 'Style', 'pushbutton', 'String', 'No', ...
    'Units', 'normalized', 'Position', [0.25 0.03 0.15 0.08], ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 0.6 0.6], ...
    'Callback', @(src, evt) negar_Callback(src, evt, fig, vec, imagenPath));

function confirmar_Callback(~, ~, fig)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text', 'Tag', ''));
    uicontrol(fig, 'Style', 'text', 'String', '¡Correcto!', ...
        'Units', 'normalized', 'Position', [0.05 0.03 0.3 0.1], ...
        'FontSize', 22, 'FontWeight', 'bold', ...
        'ForegroundColor', [0 0.6 0], 'BackgroundColor', [0.94 0.94 0.94]);
end

function negar_Callback(~, ~, fig, vec, imagenPath)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text', 'Tag', ''));

    uicontrol(fig, 'Style', 'text', 'String', '¿Cual es tu numero?', ...
        'Units', 'normalized', 'Position', [0.03 0.17 0.35 0.06], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [1 1 0.85]);

    for d = 0:9
        fila = floor(d / 5);
        columna = mod(d, 5);
        bx = 0.04 + columna * 0.07;
        by = 0.1 + fila * 0.06;
        uicontrol(fig, 'Style', 'pushbutton', 'String', num2str(d), ...
            'Units', 'normalized', 'Position', [bx by 0.06 0.06], ...
            'FontSize', 14, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.85 0.85 1], ...
            'Callback', @(src, evt) seleccionar_Callback(src, evt, fig, vec, d, imagenPath));
    end

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Ninguno', ...
        'Units', 'normalized', 'Position', [0.12 0.02 0.18 0.06], ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'Callback', @(src, evt) ninguno_Callback(src, evt, fig));
end

function ninguno_Callback(~, ~, fig)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text', 'Tag', ''));
    uicontrol(fig, 'Style', 'text', 'String', 'Imagen descartada. No se guardo.', ...
        'Units', 'normalized', 'Position', [0.02 0.03 0.4 0.1], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.5 0.5 0.5], 'BackgroundColor', [0.94 0.94 0.94]);
end

function seleccionar_Callback(~, ~, fig, vec, digitoCorrecto, imagenPath)
    delete(findall(fig, 'Style', 'pushbutton'));
    delete(findall(fig, 'Style', 'text', 'Tag', ''));

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
        'Units', 'normalized', 'Position', [0.02 0.03 0.4 0.1], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'ForegroundColor', [0 0.4 0.8], 'BackgroundColor', [0.94 0.94 0.94]);

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
