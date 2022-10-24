function plotSubject(feats, sub)

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
        for ipe = 1:length(unique(T.Permutation))
            Tp = T(T.Permutation==ipe,:);
            fitPowerFun(Tp.TrainDur, Tp.SpecAccuracy, true)
        end
    end
end







