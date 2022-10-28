function plotSubject(feats, sub)

% ---- Fitting parameters ----
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
%opts.StartPoint = [0.00444907476924962 0.379792900228052 -0.00131725834264842];
opts.Upper = [0 Inf Inf];

if ischar(feats)
    feats=char(num2cell(feats));
    feats=reshape(str2num(feats),1,[]);
end
featNames = ["env", "spg", "ons", "pho"];

for ife = 1:length(feats)
    if feats(ife)==1
        fname = append(featNames(ife), 'AccTime.csv');
        T = readtable(fullfile('../results', fname));
        T = T(T.Subject==sub,:);
        % compute the power function for each permutation 
        [aS, bS, cS] = deal(zeros(max(T.Permutation), 1));
        [aG, bG, cG] = deal(zeros(max(T.Permutation), 1));
        for ipe = 1:length(unique(T.Permutation))
            Tp = T(T.Permutation==ipe,:);
            [fitresult, gof] = fit(Tp.TrainDur, Tp.SpecAccuracy, ft, opts );
            aS(ipe) = fitresult.a;
            bS(ipe) = fitresult.b;
            cS(ipe) = fitresult.c;
            [fitresult, gof] = fit(Tp.TrainDur, Tp.GenAccuracy, ft, opts );
            aG(ipe) = fitresult.a;
            bG(ipe) = fitresult.b;
            cG(ipe) = fitresult.c;
        end
        % generate samples from the functions
        x = linspace(1, max(T.TrainDur), 1000);
        hold on
        plot(x, mean(aS)*x.^mean(bS)+mean(cS))
        plot(x, mean(aG)*x.^mean(bG)+mean(cS))



x = 1 : 300;
curve1 = log(x);
curve2 = 2*log(x);
plot(x, curve1, 'r', 'LineWidth', 2);
hold on;
plot(x, curve2, 'b', 'LineWidth', 2);
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
fill(x2, inBetween, 'g');

        yUpper = quantile(yResampled, .975, 2);
        yLower = quantile(y, .025, 2);
        
    end
end


function y = genSamples(x, a, b, c)
    
    y = zeros(length(x), length(a)); 
    for ii = 1:length(a)
        y(:,ii) = a(ii)*x.^b(ii)+c(ii);
    end