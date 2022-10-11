function [accSpec, accGen, bestLambdas] = genericVSspecific()
% Compute the prediction accuracy for each subject across various amounts
% of training data. For every unique training duration, the same randomly
% picked training data are used for specific and generic models and across
% subjects. The models' prediction accuracies are estimated on a test data
% set which is the same across all durations.
% 
% The function returns three arrays, all of which are shaped subjects by
% number of unique training durations. accSpec and accGen contain the
% prediction accuracy of subject-specific and generic models, and 
% bestLambdas contain the values for lambda that resulted in highest accuracy.
%
% This function should be executed multiple times to obtain a bootstrapped 
% permutation distribution of the prediction accuracies for each training duration
% ---- Model Features ----
dataSet = 'oldman'; % dataset to use
nSubjects = 19;
% different feature spaces to use, the logical values represent
% envelope, spectrogram, acoustic onsets and phonetic features
features = [true false false false;...
            false true false false;...
            false false true false;...
            false false false true;...
            true true true true];
% ---- TRF hyperparameters ----
direction = 1;
tmin = 0;
tmax = 400;
lambdas = logspace(-1, 5, 10);
% ---- Training parameters ----
% total duration of training data in seconds
trainDur = [30, 600, 2100];
%trainDur = [30, 60, 150, 300, 600, 900, 1200, 1500, 1800, 2100]
testDur = 300;  % duration of the data for testing the effect of lambda
chs = 1:128; % channels for determining prediction accuracy
% ---- Preprocessing parameters ---
segDur = 10; % duration of single segment after reshaping
cutoffHigh = 20; % lowpass frequency in Hz
cutoffLow = 1; % highpass frequency in Hz
skip = 1; % Duration of the initial segment to skip, in seconds
fs = 64; % Frequency to which data is resampled iin Hz

for ifeat = 1:length(features)
    env = features(ifeat, 1);
    spg = features(ifeat, 2);
    ons = features(ifeat, 3);
    pho = features(ifeat, 4);
    % train one model per subject, lambda and segment
    for isub = 1:nSubjects
        subject = strcat('sub', num2str(isub,'%02.f'));
        [stim, resp] = loadData(subject, dataSet, 'dur', segDur, 'skip', skip,...
            'toFs', fs, 'cutoffHigh', cutoffHigh, 'cutoffLow', cutoffLow,...
            'loadEnv', env, 'loadSpg', spg, 'loadOns', ons, 'loadPho', pho);
        for ilam = 1:length(lambdas)
            for iseg = 1:size(stim,1)
                models(isub, ilam, iseg) = mTRFtrain(stim{iseg}, resp{iseg},...
                    fs, direction, tmin, tmax, lambdas(ilam), 'verbose', 0);
            end
        end
    end
    % STEP I: Train one individualized model per subject for each unique training
    % duration using the lambda value that yields the highest accuracy.
    bestLambdas = zeros(nSubjects, length(trainDur));
    % split into test and training data
    idx = randperm(size(stim,1)) % randomize trial indices
    idxTest = idx(end-(testDur/segDur)+1:end); % use the last trial for testing...
    idxTrainAll = idx(1:end-(testDur/segDur)); % ... and the rest for training
    for idur = 1:length(trainDur)
        % pick randomly from the traing set accroding to training duration
        idxTrain = idxTrainAll(randperm(trainDur(idur)/segDur));
        for isub = 1:nSubjects % find the best lambda for each subject
            lambdasR = zeros(length(idxTrain), length(lambdas));
            for ilam = 1:length(lambdas)
                for icv = 1:length(idxTrain) % leave-one-out cross-validation
                    cvValid = idxTrain(icv);
                    cvTrain = idxTrain(setdiff(1:end,icv));
                    % select and average the models corresponding to training trials
                    cvModel = averageModels(models(isub, ilam, cvTrain));
                    [pred, stats] = mTRFpredict(stim(cvValid), resp(cvValid),...
                        cvModel, 'verbose', 0);
                    lambdasR(icv, ilam) = mean(stats.r(:, chs), 'all');
                end
            end
            % pick the best-lambda model
            [m,ilam] = max(mean(lambdasR, 1));
            bestLambdas(isub, idur) = lambdas(ilam);
            indModels(idur, isub) = averageModels(models(isub, ilam, idxTrain));
        end
        % STEP II: compute one generic model for each subject (i.e. average model
        % across all except the respective subject) using the mode of best
        % kambda acros all subjects for a given training duration.
        genLambda = mode(bestLambdas(:, idur));
        ilam = find(lambdas == genLambda);
        for isub = 1:nSubjects % find the best lambda for each subject
            subjects = 1:nSubjects;
            subjects = setdiff(subjects, isub); % all subjects except isub
            genModels(idur, isub) = averageModels(models(subjects, ilam, idxTrain));
        end
    end
    % STEP III: test the prediction accuracy of generic and subject-specific models
    % for every subject using the withheld test data set.
    accInd = zeros(nSubjects, length(trainDur));
    accGen = zeros(nSubjects, length(trainDur));
    for isub = 1:nSubjects
        isub
        subject = strcat('sub', num2str(isub,'%02.f'));
        [stim, resp] = loadData(subject, dataSet, 'dur', segDur, 'skip', skip,...
            'toFs', fs, 'cutoffHigh', cutoffHigh, 'cutoffLow', cutoffLow,...
            'loadEnv', env, 'loadSpg', spg, 'loadOns', ons, 'loadPho', pho);
        for idur = 1:length(trainDur)
            % test subject-specific model
            [pred, stats] = mTRFpredict(stim(idxTest), resp(idxTest),...
                indModels(idur, isub), 'verbose', 0);
            accInd(isub, idur) = mean(stats.r(:,chs), 'all');
            % test generic model
            [pred, stats] = mTRFpredict(stim(idxTest), resp(idxTest),...
                genModels(idur, isub), 'verbose', 0);
            accGen(isub, idur) = mean(stats.r(:,chs), 'all');
        end
    end
