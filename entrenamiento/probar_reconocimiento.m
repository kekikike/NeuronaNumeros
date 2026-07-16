[archivo, ruta] = uigetfile({'.png;.jpg;*.jpeg'}, 'Selecciona una imagen');
if isequal(archivo, 0)
disp('No se selecciono ninguna imagen');
return;
end
imagenPath = fullfile(ruta, archivo);
digito = reconocer(imagenPath);
img = imread(imagenPath);
imshow(img);
title(['Numero identificado: ' num2str(digito)]);