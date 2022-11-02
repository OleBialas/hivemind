function [results] = segDurAccuracy(sub, lambda, feats, fname)
% test how segment duration affects prediction accuracy

% --- Parse command line input ---
if ischar(feats)
    feats=char(num2cell(feats));
    feats=reshape(str2num(feats),1,[]);
end
if ischar(sub)
    sub = str2num(sub)
end
subject = strcat('sub', num2str(sub,'%02.f'));

% ---- Training parameters ----
dataSet = 'oldman'; % dataset to use
nPermute = 100;  % number of permutations
segDur = [0.5, 1, 5, 10, 30, 40, 60, 80, 160]; % length of data segments
trainDur = 2400;  % duration of training data
testDur = 300;  % duration of the data for testing the effect of lambda
chs = 1:128; % channels for determining prediction accuracy
% ---- TRF hyperparameters ----
direction = 1;
tmin = 0;
tmax = 400;
% ---- Preprocessing parameters ---
cutoffHigh = 20; % lowpass frequency in Hz
cutoffLow = 1; % highpass frequency in Hz
skip = 1; % Duration of the initial segment to skip, in seconds
fs = 64; % Frequency to which data is resampled iin Hz

results = zeros(nPermute, length(segDur));
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
        results(ip, isd) = mean(stats.r, 'all');
    end
end

if exist('fname', 'var')
    fname = fullfile('../results/', fname);
    save(fname, 'trainDur', 'testDur', 'segDur', 'featNames', 'results');
end
