function vec = preprocesarImagen(imagenPath)
    img = imread(imagenPath);
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    img = double(img);

    nivelOscuro = prctile(img(:), 5);
    nivelClaro = prctile(img(:), 95);
    umbral = (nivelOscuro + nivelClaro) / 2;

    bw = img < umbral;

    if sum(bw(:)) == 0
        vec = zeros(28*28, 1);
        return;
    end

    [filas, columnas] = find(bw);
    r1 = min(filas); r2 = max(filas);
    c1 = min(columnas); c2 = max(columnas);
    recorte = bw(r1:r2, c1:c2);

    recorte = imresize(double(recorte), [20 20]) > 0.3;

    lienzo = zeros(28,28);
    lienzo(5:24, 5:24) = recorte;

    vec = double(lienzo(:));
end