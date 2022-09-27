function [stim,resp]=loadData(sub,dset,dur,skip,nrm,fs,env,spg,ons,pho)

arguments
	sub char
	dset char
	dur double = 5
	skip double = 1
	nrm logical = false
	fs double = 64
	env logical = true
	spg logical = false
	ons logical = false
	pho logical = false
end

eegDir = getenv('EEGDIR');
stimDir = getenv('STIMDIR');
if isempty(eegDir) | isempty(stimDir)
	error 'Could not find environment variables $EEGDIR and/or $STIMDIR ...'
end

subDir = fullfile(eegDir, dset, sub);
eegFiles = dir(fullfile(subDir, '/*run*.mat'));

resp = {};
stim = {};
for ii = 1:length(eegFiles)-1
	eeg = load(fullfile(...
		eegFiles(ii).folder, eegFiles(ii).name));
	eegData = eeg.eegData';  % TODO: store the data as times x channels
	if skip
		eegData = eegData(skip*eeg.fs:end, :)
	end
	sft = load(fullfile(...
		stimDir, dset, join(['audio', eegFiles(ii).name(10:11), '.mat'])));	
	% TODO: filtering, resampling	
	if nrm
		eegData = (eegData-mean(eegData))./std(eegData);
		sft.env = sft.env./mean(sft.env.^2)^0.5;
		sft.spg = sft.env./mean(sft.spg.^2)^0.5;
	feats = {};
	if env
		feats = [feats; sft.env];
	end
	if ons
		feats = [feats; sft.ons];
	end
	if spg
		feats = [feats; sft.spg];
	end
	if pho
		feats = [feats; sft.pho];
	end
	feats = cat(2, feats{:}); % concatenate to one matrix
	if length(feats) < length(eegData)
		eegData = eegData(1:length(feats),:);
	else
		feats = feats(1:length(eegData),:);
	end
	% crop the data into segments of length 'dur'	
	toCut = mod(length(eegData), dur*fs);
	eegData = eegData(1:length(eegData)-toCut, :);
	feats = feats(1:length(feats)-toCut, :);
	nTrials = length(eegData) / (dur*fs);
	eegData = permute(reshape(eegData,[dur*fs, nTrials, 128]),[2 1 3]);
	feats = permute(reshape(feats, dur*fs, nTrials, 1), [2 1 3]);
	for it=1:nTrials
		resp=[resp; squeeze(eegData(it, :, :))];
		stim=[stim; squeeze(env(it, :, :))];
	end
end

end



