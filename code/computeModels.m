function computeModels(feats, lambda, fname):
% Compute TRFs for all subjects for a given feature space and value of lambda
% The models are gonna be stored in the models folder under the name specified
% by fname. They are contained in a structure of shape subjects by segments.

dataSet='oldman';
% load parameters for preprocessing and TRFs
load('trfParams.mat');
load('preprocParams.mat');

if ischar(feats)
    feats=char(num2cell(feats));
    feats=reshape(str2num(feats),1,[]);
end

models = struct('w',[],'b',[],'t',[],'fs',[],'Dir',[],'type',[])

for isub = 1:19
    subject = strcat('sub', num2str(isub,'%02.f'));
    [stim, resp] = loadData(subject, dataSet, 'dur', segDur, 'skip', skip,...
        'toFs', fs, 'cutoffHigh', cutoffHigh, 'cutoffLow', cutoffLow,...
        'loadEnv', feats(1), 'loadSpg', feats(2), 'loadOns', feats(3),...
        'loadPhe', feats(4), 'loadPho', feats(5), 'loadSem', feats(6));
    for iseg = 1:size(stim,1)
        models(isub, iseg) = mTRFtrain(stim{iseg}, resp{iseg},...
            fs, direction, tmin, tmax, lambda, 'verbose', 0);
    end
end
% save the result
fname = fullfile('../', 'models', dataSet, fname)
save(fname, 'models')

