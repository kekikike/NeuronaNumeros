function vec = preprocesarImagen(imagenPath)
    img = imread(imagenPath);
    if size(img,3) == 3
        img = rgb2gray(img);
    end

    bw = imbinarize(img);

    if sum(bw(:)) > numel(bw)/2
        bw = ~bw;
    end

    [filas, columnas] = find(bw);

    if isempty(filas)
        vec = zeros(28*28, 1);
        return;
    end

    r1 = min(filas); r2 = max(filas);
    c1 = min(columnas); c2 = max(columnas);
    recorte = bw(r1:r2, c1:c2);

    recorte = imresize(recorte, [20 20]);

    lienzo = zeros(28,28);
    lienzo(5:24, 5:24) = recorte;

    vec = double(lienzo(:));
end