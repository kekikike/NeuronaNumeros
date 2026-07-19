function net = crear_red(capaOculta)
    net = feedforwardnet(capaOculta);
    net.trainFcn = 'trainscg';
    net.trainParam.epochs = 200;
    net.trainParam.goal = 1e-6;
    net.trainParam.lr = 0.01;
    net.trainParam.showWindow = false;
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = 0.80;
    net.divideParam.valRatio = 0.15;
    net.divideParam.testRatio = 0.05;
    net.performFcn = 'crossentropy';
    net.layers{end}.transferFcn = 'softmax';
end
