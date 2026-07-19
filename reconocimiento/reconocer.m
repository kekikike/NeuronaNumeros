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

        if net.numLayers == 1
            w = net.IW{1,1};
            b = net.b{1};
            scoreNormalizado = (w * vec + b) / norm(w);
        else
            salida = net(vec);
            scoreNormalizado = salida - 0.5;
        end

        scores(numDigito + 1) = scoreNormalizado;
    end

    disp('Puntajes por digito (0 a 9):');
    disp(scores);

    [~, idx] = max(scores);
    digito = idx - 1;
end