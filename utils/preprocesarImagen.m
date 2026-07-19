function vec = preprocesarImagen(imagenPath)
    [img, ~, alpha] = imread(imagenPath);

    usarAlpha = false;
    if ~isempty(alpha)
        porcentajeOpaco = sum(alpha(:) > 30) / numel(alpha);
        if porcentajeOpaco > 0.02 && porcentajeOpaco < 0.95
            usarAlpha = true;
        end
    end

    if usarAlpha
        bw = alpha > 30;
    else
        if size(img,3) == 4
            img = img(:,:,1:3);
        end
        if size(img,3) == 3
            img = rgb2gray(img);
        end
        img = double(img) / 255;

        nivel = graythresh(img);
        bw = imbinarize(img, nivel);

        if sum(bw(:)) > numel(bw) / 2
            bw = ~bw;
        end
    end

    if sum(bw(:)) == 0
        vec = zeros(28*28, 1);
        return;
    end

    [filas, columnas] = find(bw);
    r1 = min(filas); r2 = max(filas);
    c1 = min(columnas); c2 = max(columnas);
    recorte = bw(r1:r2, c1:c2);

    recorteResized = imresize(double(recorte), [20 20]);
    bwResized = recorteResized > 0.15;
    bwResized = imdilate(bwResized, strel('disk', 1));

    lienzo = zeros(28,28);
    lienzo(5:24, 5:24) = bwResized;

    vec = double(lienzo(:));
end