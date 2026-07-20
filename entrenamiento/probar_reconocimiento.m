function probar_reconocimiento()
addpath('../utils');

tamanoLienzo = 600;
lienzo = uint8(255 * ones(tamanoLienzo, tamanoLienzo));

fig = figure('Name', 'Reconocimiento', 'NumberTitle', 'off', ...
    'Position', [50 50 1350 850], 'Color', [0.94 0.94 0.94], ...
    'Resize', 'off');

axDibujo = axes('Parent', fig, 'Units', 'pixels', 'Position', [50 250 600 550]);
imgObj = imshow(lienzo, 'Parent', axDibujo);
title(axDibujo, 'Dibuja aqui con el mouse', 'FontSize', 13);

axGraf = axes('Parent', fig, 'Units', 'pixels', 'Position', [700 200 600 600]);
axGraf.Visible = 'off';

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Reconocer', ...
    'Position', [50 195 140 45], 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.7 0.85 1], ...
    'Callback', @revisarCallback);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Limpiar', ...
    'Position', [210 195 140 45], 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.9 0.9 0.9], ...
    'Callback', @limpiarCallback);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cargar Imagen', ...
    'Position', [370 195 140 45], 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.9 0.95 0.7], ...
    'Callback', @cargarImagenCallback);

lblPregunta = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Position', [50 140 300 35], 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.94 0.94 0.94], 'Visible', 'off');

btnSi = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Si', ...
    'Position', [100 95 100 40], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6 1 0.6], 'Visible', 'off', ...
    'Callback', @confirmar_Callback);

btnNo = uicontrol(fig, 'Style', 'pushbutton', 'String', 'No', ...
    'Position', [230 95 100 40], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 0.6 0.6], 'Visible', 'off', ...
    'Callback', @negar_Callback);

lblInfo = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Position', [50 30 300 60], 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.94 0.94 0.94], 'Visible', 'off');

estado.lienzo = lienzo;
estado.dibujando = false;
estado.grosorPincel = 4;
estado.ultimoX = -1;
estado.ultimoY = -1;
estado.vecGuardado = [];
estado.tamanoLienzo = tamanoLienzo;
estado.imgObj = imgObj;
estado.axDibujo = axDibujo;
estado.axGraf = axGraf;
estado.fig = fig;
estado.lblPregunta = lblPregunta;
estado.btnSi = btnSi;
estado.btnNo = btnNo;
estado.lblInfo = lblInfo;
guidata(fig, estado);

set(fig, 'WindowButtonDownFcn', @empezarDibujo);
set(fig, 'WindowButtonUpFcn', @terminarDibujo);
set(fig, 'WindowButtonMotionFcn', @moverPincel);

    function empezarDibujo(~, ~)
        e = guidata(fig);
        pt = get(e.axDibujo, 'CurrentPoint');
        x = round(pt(1,1));
        y = round(pt(1,2));
        tam = e.tamanoLienzo;
        if x >= 1 && x <= tam && y >= 1 && y <= tam
            e.dibujando = true;
            e.ultimoX = x;
            e.ultimoY = y;
            guidata(fig, e);
            pintarLinea(x, y);
        end
    end

    function terminarDibujo(~, ~)
        e = guidata(fig);
        e.dibujando = false;
        guidata(fig, e);
    end

    function moverPincel(~, ~)
        e = guidata(fig);
        if e.dibujando
            pt = get(e.axDibujo, 'CurrentPoint');
            x = round(pt(1,1));
            y = round(pt(1,2));
            pintarLinea(x, y);
        end
    end

    function pintarLinea(x, y)
        e = guidata(fig);
        tam = e.tamanoLienzo;
        g = e.grosorPincel;

        if x < 1 || x > tam || y < 1 || y > tam
            return;
        end

        px = e.ultimoX;
        py = e.ultimoY;

        if px < 1
            px = x;
            py = y;
        end

        dist = max(abs(x - px), abs(y - py));
        pasos = max(dist, 1);
        xs = round(linspace(px, x, pasos + 1));
        ys = round(linspace(py, y, pasos + 1));

        for k = 1:numel(xs)
            xi = xs(k);
            yi = ys(k);
            r1 = max(1, yi - g);
            r2 = min(tam, yi + g);
            c1 = max(1, xi - g);
            c2 = min(tam, xi + g);
            e.lienzo(r1:r2, c1:c2) = 0;
        end

        e.ultimoX = x;
        e.ultimoY = y;
        set(e.imgObj, 'CData', e.lienzo);
        guidata(fig, e);
        drawnow limitrate;
    end

    function cargarImagenCallback(~, ~)
        e = guidata(fig);

        [archivo, ruta] = uigetfile({ ...
            '*.png;*.jpg;*.jpeg;*.bmp;*.gif', 'Imagenes (*.png, *.jpg, *.jpeg, *.bmp, *.gif)'; ...
            '*.*', 'Todos los archivos (*.*)'}, ...
            'Selecciona una imagen');

        if isequal(archivo, 0)
            return;
        end

        rutaCompleta = fullfile(ruta, archivo);
        img = imread(rutaCompleta);

        if size(img, 3) == 4
            img = img(:,:,1:3);
        end

        imgGray = rgb2gray(img);
        [alto, ancho] = size(imgGray);
        tam = e.tamanoLienzo;

        if alto > ancho
            escala = tam / alto;
        else
            escala = tam / ancho;
        end

        nuevoAlto = round(alto * escala);
        nuevoAncho = round(ancho * escala);

        imgResized = imresize(imgGray, [nuevoAlto, nuevoAncho]);

        lienzoNuevo = uint8(255 * ones(tam, tam));
        filaInicio = round((tam - nuevoAlto) / 2) + 1;
        colInicio = round((tam - nuevoAncho) / 2) + 1;
        lienzoNuevo(filaInicio:filaInicio+nuevoAlto-1, colInicio:colInicio+nuevoAncho-1) = imgResized;

        e.lienzo = lienzoNuevo;
        e.ultimoX = -1;
        e.ultimoY = -1;
        set(e.imgObj, 'CData', e.lienzo);
        guidata(fig, e);

        e.lblInfo.String = ['Imagen cargada: ' archivo];
        e.lblInfo.ForegroundColor = [0.3 0.3 0.7];
        e.lblInfo.Visible = 'on';
    end

    function limpiarCallback(~, ~)
        e = guidata(fig);
        e.lienzo = uint8(255 * ones(e.tamanoLienzo, e.tamanoLienzo));
        e.ultimoX = -1;
        e.ultimoY = -1;
        set(e.imgObj, 'CData', e.lienzo);
        cla(e.axGraf);
        e.axGraf.Visible = 'off';
        e.lblPregunta.Visible = 'off';
        e.lblInfo.Visible = 'off';
        e.btnSi.Visible = 'off';
        e.btnSi.Enable = 'off';
        e.btnNo.Visible = 'off';
        e.btnNo.Enable = 'off';
        e.vecGuardado = [];
        guidata(fig, e);
        delete(findall(fig, 'Style', 'pushbutton', '-and', 'Tag', 'numbtn'));
        delete(findall(fig, 'Style', 'text', '-and', 'Tag', 'infobtn'));
    end

    function revisarCallback(~, ~)
        e = guidata(fig);

        if all(e.lienzo(:) == 255)
            return;
        end

        e.lblInfo.Visible = 'off';
        guidata(fig, e);

        archivoTemp = fullfile(tempdir, 'dibujo_temp.png');
        imwrite(e.lienzo, archivoTemp);

        e.vecGuardado = preprocesarImagen(archivoTemp);

        scores = -Inf(1,10);
        redesFolder = '../redes';
        archivos = dir(fullfile(redesFolder, 'red_*.mat'));

        for i = 1:numel(archivos)
            data = load(fullfile(redesFolder, archivos(i).name));
            net = data.net;
            numStr = extractBetween(archivos(i).name, 'red_', '.mat');
            numDigito = str2double(numStr{1});
            salida = net(e.vecGuardado);
            scoreNormalizado = salida - 0.5;
            scores(numDigito + 1) = scoreNormalizado;
        end

        [~, idx] = max(scores);
        digito = idx - 1;

        e.axGraf.Visible = 'on';
        cla(e.axGraf);
        colores = repmat([0.3 0.6 0.9], 10, 1);
        colores(digito+1, :) = [0.9 0.3 0.3];
        barra = bar(e.axGraf, 0:9, scores, 'FaceColor', 'flat');
        barra.CData = colores;
        xlabel(e.axGraf, 'Digito', 'FontSize', 12);
        ylabel(e.axGraf, 'Puntaje', 'FontSize', 12);
        title(e.axGraf, sprintf('Identificado: %d', digito), 'FontSize', 15, 'FontWeight', 'bold');
        grid(e.axGraf, 'on');
        e.axGraf.FontSize = 11;

        e.lblPregunta.String = '¿Este es tu numero?';
        e.lblPregunta.ForegroundColor = [0 0 0];
        e.lblPregunta.Visible = 'on';
        e.btnSi.Visible = 'on';
        e.btnSi.Enable = 'on';
        e.btnNo.Visible = 'on';
        e.btnNo.Enable = 'on';

        guidata(fig, e);
        fprintf('Numero identificado: %d\n', digito);
    end

    function confirmar_Callback(~, ~)
        e = guidata(fig);
        e.lblPregunta.Visible = 'off';
        e.btnSi.Visible = 'off';
        e.btnSi.Enable = 'off';
        e.btnNo.Visible = 'off';
        e.btnNo.Enable = 'off';
        e.lblInfo.String = 'Correcto!';
        e.lblInfo.ForegroundColor = [0 0.6 0];
        e.lblInfo.Visible = 'on';
        guidata(fig, e);
    end

    function negar_Callback(~, ~)
        e = guidata(fig);
        e.lblPregunta.Visible = 'off';
        e.btnSi.Visible = 'off';
        e.btnSi.Enable = 'off';
        e.btnNo.Visible = 'off';
        e.btnNo.Enable = 'off';

        uicontrol(fig, 'Style', 'text', 'String', '¿Cual es tu numero?', ...
            'Position', [50 140 300 35], 'FontSize', 13, 'FontWeight', 'bold', ...
            'BackgroundColor', [1 1 0.85], 'Tag', 'infobtn');

        for d = 0:9
            fila = floor(d / 5);
            columna = mod(d, 5);
            bx = 50 + columna * 65;
            by = 95 - fila * 50;
            uicontrol(fig, 'Style', 'pushbutton', 'String', num2str(d), ...
                'Position', [bx by 50 40], 'FontSize', 14, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.85 0.85 1], 'Tag', 'numbtn', ...
                'Callback', @(src, evt) seleccionar_Callback(d));
        end

        uicontrol(fig, 'Style', 'pushbutton', 'String', 'Ninguno', ...
            'Position', [170 0 130 35], 'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.9 0.9 0.9], 'Tag', 'numbtn', ...
            'Callback', @ninguno_Callback);

        guidata(fig, e);
    end

    function seleccionar_Callback(digitoCorrecto)
        e = guidata(fig);

        delete(findall(fig, 'Tag', 'numbtn'));
        delete(findall(fig, 'Tag', 'infobtn'));

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

            [net, ~, ~] = adapt(net, e.vecGuardado, target);
            save(archivoRed, 'net');
        end

        e.lblInfo.String = ['Guardado como numero ' num2str(digitoCorrecto) '. Red actualizada.'];
        e.lblInfo.ForegroundColor = [0 0.4 0.8];
        e.lblInfo.Visible = 'on';

        fprintf('Guardado como numero %d. Redes actualizadas.\n', digitoCorrecto);
        guidata(fig, e);
    end

    function ninguno_Callback(~, ~)
        delete(findall(fig, 'Tag', 'numbtn'));
        delete(findall(fig, 'Tag', 'infobtn'));

        e = guidata(fig);
        e.lblInfo.String = 'Imagen descartada. No se guardo.';
        e.lblInfo.ForegroundColor = [0.5 0.5 0.5];
        e.lblInfo.Visible = 'on';
        guidata(fig, e);
    end

end
