function [stim,resp]=loadData(sub,dset,varargin)
%LOADDATA Loads and reshapes EEG data and stimulus features
% This function loads the EEG data for the specified subject SUB and
% experiment DSET and reshapes them into shorter segments. The 
% corresponding stimulus features are reshaped in the same way.
%
% The function returns two cell arrays STIM and RESP which contain
% one cell array per segment. Each nested cell array contains one
% samples-by-features matrix. Additional parameters are specified as
% (name, value) pairs:
%
%   Parameter       Value
%   'dur'           Duration of the data segments after reshaping.
%                   Defaults to five seconds
%   'cutoffHigh'    Upper frequency cutoff for filtering.in Hz.
%   'cutoffLow'     Lower frequency cutoff for filtering in Hz.
%                   Per default, no filter is applied.
%   'skip'          Duration of the initial data segment that is
%                   omitted. Defaults to one second.
%   'toFs'          New rate for resampling the data. Per default
%                   the data is not resampled.
%   'loadEnv'       If true, load the broadband envelopes.
%   'loadOns'       If true, load the acoustic onets.
%   'loadSpg'       If true, load the 16-band spectrograms
%   'loadPhe'       If true load the 19 phonetic features
%   'loadPho'       If true load the 39 Phonemes
%
% The shape of STIM depends on the stimulus features selcted. When
% selcting all features, STIM has 76 columns where the first column
% contains the envelope, columns 2-17 contain the 16-band spectrogram,
% column 18 contains the acoustic onsets, columns 19-37 contain the
% phonetic features and the last 39 columns contain the phonemes
%TODO: fix resampling for stick functions!

args = parsevarargin(varargin);
subDir = fullfile('../data/preprocessed/', dset, sub);
eegFiles = dir(fullfile(subDir, '/*run*.mat'));

resp = {};
stim = {};
for ii = 1:length(eegFiles)
	load(fullfile(...
		eegFiles(ii).folder, eegFiles(ii).name));
    if args.cutoffLow
        n = fs * 5/args.cutoffLow;
        f = [0 args.cutoffLow-args.cutoffLow*0.25 args.cutoffLow, fs/2] / (fs/2);
        a = [0 0 1 1];
        b = firls(n,f,a);
        eegData = filtfilt(b, 1, eegData);
    end
    if args.cutoffHigh
        n = fs * 5/args.cutoffHigh;
        f = [0 args.cutoffHigh args.cutoffHigh+args.cutoffHigh*0.25 fs/2] / (fs/2);
        a = [1 1 0 0];
        b = firls(n,f,a);
        eegData = filtfilt(b, 1, eegData);
    end

	load(fullfile('../stimuli', dset,...
        join(['audio', eegFiles(ii).name(10:11), '.mat'])));
    if args.normalize
		eegData = (eegData-mean(eegData))./std(eegData);
		env = env./mean(env.^2)^0.5;
		spg = spg./mean(spg.^2, 'all').^0.5;
    end
    if args.toFs
        eegData = resample(eegData, args.toFs, fs);
        [env, spg, ons, phe, pho] = resampleFeats(...
            env, spg, ons, phe, pho, fs, args.toFs);
        fs = args.toFs;
    end
	feats = {};
	if args.loadEnv
		feats = [feats; env];
	end
	if args.loadSpg
		feats = [feats; spg];
	end
	if args.loadOns
		feats = [feats; ons];
	end
	if args.loadPhe
		feats = [feats; phe];
	end
	if args.loadPho
		feats = [feats; pho];
	end
	feats = cat(2, feats{:}); % concatenate to one matrix
    nfeats = size(feats, 2);
	if length(feats) < length(eegData)
		eegData = eegData(1:length(feats),:);
	else
		feats = feats(1:length(eegData),:);
	end
	if args.skip
		eegData = eegData(args.skip*fs:end, :);
		feats = feats(args.skip*fs:end, :);
	end
	% crop the data into segments of length 'dur'	
	toCut = mod(length(eegData), args.dur*fs);
	eegData = eegData(1:length(eegData)-toCut, :);
	feats = feats(1:length(feats)-toCut, :);
	nTrials = length(eegData) / (args.dur*fs);
	eegData = permute(reshape(eegData,[args.dur*fs, nTrials, 128]),[2 1 3]);
	feats = permute(reshape(feats, [args.dur*fs, nTrials, nfeats]), [2 1 3]);
	for it=1:nTrials
		resp=[resp; squeeze(eegData(it, :, :))];
		stim=[stim; squeeze(feats(it, :, :))];
	end
end


function [envOut, spgOut, onsOut, pheOut, phoOut] = resampleFeats(...
        envIn, spgIn, onsIn, pheIn, phoIn, fromFs, toFs)

% resample continuous envelope and spectrogram
envOut = resample(envIn, toFs, fromFs);
spgOut = resample(spgIn, toFs, fromFs);
% resample binary onsets, phonemes and phonetic features
onsTimes = find(onsIn)/fromFs;
onsSamples = round(onsTimes*toFs);
onsOut = zeros(size(envOut));
onsOut(onsSamples) = 1;
phoOut = zeros(size(envOut,1), size(phoIn,2));
for ipho = 1:size(phoIn,2)
    starts = find(diff(phoIn(:,ipho))==1)+1;
    starts = round((starts/fromFs)*toFs);
    stops = find(diff(phoIn(:,ipho))==-1);
    stops = round((stops/fromFs)*toFs);
    for ii = 1:length(stops)
        phoOut(starts(ii):stops(ii), ipho) = 1;
    end
end
pheOut = zeros(size(envOut,1), size(pheIn,2));
for iphe = 1:size(pheIn,2)
    starts = find(diff(pheIn(:,iphe))==1)+1;
    starts = round((starts/fromFs)*toFs);
    stops = find(diff(pheIn(:,iphe))==-1);
    stops = round((stops/fromFs)*toFs);
    for ii = 1:length(stops)
        pheOut(starts(ii):stops(ii), iphe) = 1;
    end
end


function args = parsevarargin(varargin)
%PARSEVARARGIN  Parse input arguments.
%   [PARAM1,PARAM2,...] = PARSEVARARGIN('PARAM1',VAL1,'PARAM2',VAL2,...)
%   parses the input arguments of the main function.

% Create parser object
p = inputParser;

errorMsg = 'It must be a positive integer scalar.';
validFcn = @(x) assert(rem(x,1)==0,errorMsg);
addParameter(p,'dur',5,validFcn);
addParameter(p,'cutoffLow',false,validFcn);  % lower filter cutoff
addParameter(p,'cutoffHigh',false,validFcn); % upper filter cutoff
addParameter(p,'toFs',false,validFcn); % resampling samplerate
addParameter(p,'skip',1,validFcn); % Initial segment to skip

% Boolean arguments
errorMsg = 'It must be a numeric scalar (0,1) or logical.';
validFcn = @(x) assert(x==0||x==1||islogical(x),errorMsg);
addParameter(p,'loadEnv',false,validFcn); % load envelopes
addParameter(p,'loadOns',false,validFcn); % load onsets
addParameter(p,'loadSpg',false,validFcn); % load spectrograms
addParameter(p,'loadPhe',false,validFcn); % load phonetic features
addParameter(p,'loadPho',false,validFcn); % load phonetic features
addParameter(p,'normalize',true,validFcn); % normalize eeg, envelopes and spectrogram

% Parse input arguments
parse(p,varargin{1,1}{:});
args = p.Results;
