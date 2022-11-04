% ---- Training parameters ----
dataSet = 'oldman'; % dataset to use
fname='segDurPhe.csv';
nPermute = 100;  % number of permutations
segDur = [0.5, 1, 2, 3, 4, 5, 10, 20, 30, 40, 60, 80, 160]; % length of data segments 
trainDur = 2400;  % duration of training data
testDur = 480;  % duration of the data for testing the effect of lambda
chs = 1:128; % channels for determining prediction accuracy
lambda = 100;
% ---- TRF hyperparameters ----
feats = [0 0 0 0 1 0];
direction = 1;
tmin = 0;
tmax = 400;
% ---- Preprocessing parameters ---
cutoffHigh = 20; % lowpass frequency in Hz
cutoffLow = 1; % highpass frequency in Hz
skip = 1; % Duration of the initial segment to skip, in seconds
fs = 64; % Frequency to which data is resampled iin Hz
varnames = {'Permutation', 'Subject', 'SegDur', 'Accuracy'};
table = array2table(zeros(0, length(varnames)), 'VariableNames', varnames);
for isub = 1:19
    subject = strcat('sub', num2str(isub,'%02.f'));
    for isd = 1:length(segDur)
        [stim, resp] = loadData(subject, dataSet, 'dur', segDur(isd), 'skip', skip,...
            'toFs', fs, 'cutoffHigh', cutoffHigh, 'cutoffLow', cutoffLow,...
            'loadEnv', feats(1), 'loadSpg', feats(2), 'loadOns', feats(3),...
            'loadPhe', feats(4), 'loadPho', feats(5), 'loadSem', feats(6));
        for ip = 1:nPermute
            idx = randperm(size(stim,1)); % randomize trial indices
            idxTest = idx(1:(testDur/segDur(isd)));
            idxTrain = idx(end-(trainDur/segDur(isd)):end);
            model = mTRFtrain(stim(idxTrain)', resp(idxTrain)',...
                fs, direction, tmin, tmax, lambda, 'verbose', 0);
            [~, stats] = mTRFpredict(stim(idxTest), resp(idxTest), model, 'verbose', 0);
            data = [ip, isub, segDur(isd), mean(stats.r, 'all')];
            table = [table; array2table(data, 'VariableNames', varnames)];
        end
    end
end
writetable(table, fullfile('../results', fname))
