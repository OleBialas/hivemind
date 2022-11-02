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




