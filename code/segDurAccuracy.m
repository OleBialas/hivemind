function results = segDurAccuracy(sub)
% test how segment duration affects prediction accuracy
dataSet = 'oldman'; % dataset to use
subject = strcat('sub', num2str(str2num(sub),'%02.f'));
fname = fullfile('../results/', strcat('segDurAcc_',subject,'.m'))
nPermute = 100;
% ---- TRF hyperparameters ----
direction = 1;
tmin = 0;
tmax = 400;
lambdas = logspace(-1, 5, 10);
% ---- Training parameters ----
% total duration of training data in seconds
segDur = [0.5, 1, 5, 10, 30, 60, 120, 180];
trainDur=2700;
testDur = 360;  % duration of the data for testing the effect of lambda
chs = 1:128; % channels for determining prediction accuracy
% ---- Preprocessing parameters ---
cutoffHigh = 20; % lowpass frequency in Hz
cutoffLow = 1; % highpass frequency in Hz
skip = 1; % Duration of the initial segment to skip, in seconds
fs = 64; % Frequency to which data is resampled iin Hz

featIdx = [1 1; 2 17; 18 18; 19 37; 38 76; 77 77];
featNames = ["env" "spg" "ons" "phe" "pho" "sem"];
results = zeros(nPermute, length(segDur), length(featIdx));

for isd = 1:length(segDur)
    disp(isd)
    [stim, resp] = loadData(subject, dataSet, 'dur', segDur(isd), 'skip', skip,...
        'toFs', fs, 'cutoffHigh', cutoffHigh, 'cutoffLow', cutoffLow,...
        'loadEnv', 1, 'loadSpg', 1, 'loadOns', 1, 'loadPhe', 1, 'loadPho', 1, 'loadSem', 1);
    
    for ip = 1:nPermute
        idx = randperm(size(stim,1)); % randomize trial indices
        idxTest = idx(1:(testDur/segDur(isd)));
        idxTrain = idx(end-(trainDur/segDur(isd)):end);
        
        for ife = 1:length(featIdx)
            stimIdx = cellfun(@(c)...
                c(:,featIdx(ife, 1):featIdx(ife, 2)),stim,'UniformOutput',false);
            stats = mTRFcrossval(...
                stimIdx(idxTrain)', resp(idxTrain)', fs, direction, tmin, tmax, lambdas);
            [~, maxIdx] = max(mean(mean(stats.r, 1), 3));
            model = mTRFtrain(...
                stimIdx(idxTrain)', resp(idxTrain)', fs, direction, tmin, tmax, lambdas(maxIdx));
            [~, stats] = mTRFpredict(stimIdx(idxTest), resp(idxTest), model);
            results(ip, isd, ife) = mean(stats.r, 'all');
        end
    end
end
