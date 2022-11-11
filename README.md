This repo contains the data and code for a research project investigating how the
amount of training data affects the accuracy of temporal response functions (TRFs)
predicting brain responses to speech.

# Data
The data are hosted on the open science framework repository. This repo should be
cloned using datalad, which will automatically fetch the data from OSF.
After installing datalad, simply type
```sh
datalad install https://github.com/OleBialas/hivemind.git
cd hivemind
datalad get *
```
to load all of the data (it's also possible to only load parts of the data by
replacing the asterisk with the path to a specific file or folder).

The project comprises several datasets:
- oldman: ~ 1 hour of EEG recordings from 19 subjects as they were listening to an
    audiobook of "The old man and the sea".
    
# Parameters
Paramters for computing TRFs are stored in code/trfParams.mat and contain:
- tmin: minimum time delay in milliseconds
- tmax: maximum time delay in milliseconds
- direction: direction of the trf (1=forward, -1=backward)

Parameters for preprocessing the data are stored in code/preprocParams and contain:
- cutoffHigh: lowpass frequecy in Hz
- cutofflow: highpass frequency in Hz
- fs: sampling rate to which the data is resampled in Hz
- skip: duration of the initial segment of each trial that is removed in seconds
- segDur: duration of the segments in the data are cut

Scripts that load data and/or compute TRFs will load the respective parameters from these files. This ensures that we are using the same parameters througout the analysis. In the future, when we add more datasets we might stroe one set of parameters per dataset.

# Naming Conventions
To make scripts work across datasets we are following a few naming conventions.
- Within each experiments, subjects are named "sub" plus a two digit id (e.g. sub04 or sub 27)
- For every subject, there should be one file for each continuous recording of data named sub_<SUBJECID>_run<RUNID>.mat (e.g. sub04_run08.mat)
- The acoustic and linuistic featured are stored in files called audio that correspond to the eeg files (e.g. audi012.mat contains the representations of the audio played during the recording of sub06_run12.mat). Audio files (may) contain the following variables
- env: acoustic envelope
- ons: word onsets
- phe: 19-dimensional phonetic features
- pho: 39-dimensional phonemes
- sem: semantic surprisal of each word
- spg: 16-band spectrogram
- fs: sampling rate of all features




