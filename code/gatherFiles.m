function gatherFiles(pattern, fname)
% Combine all matrices returned by different runs of `trainingTimeAccuracy.m` and write them
% into a single table. That table is saved in the results folder under the name specified by
% the parameter FNAME. The parameter PATTERN defines a string pattern which is used to find
% the files to combine (e.g. PATTERN='*envModel*' will load all files that have that pattern
% in their filename. All files loaded by this script will be deleted.
trainDur = [10, 20, 30, 40, 50, 60, 150, 300, 600, 900, 1200, 1500, 1800, 2100, 3000];
files = dir(fullfile('../results/', pattern));
varnames = {'Permutation', 'TrainDur', 'Subject', 'BestLambda', 'SpecAccuracy', 'GenAccuracy'};
table = array2table(zeros(0, length(varnames)), 'VariableNames', varnames);
for f = 1:length(files)
    load(fullfile(files(f).folder, files(f).name))
    for idur = 1:length(trainDur) % combine variables into one array and append it to the table
        data = [repelem(f, size(accGen, 1)); repelem(trainDur(idur), size(accGen, 1));...
            1:size(accGen, 1); bestLambdas(:, idur)'; accSpec(:, idur)'; accGen(:,idur)']';
        table = [table; array2table(data, 'VariableNames', varnames)];
    end
    delete(fullfile(files(f).folder, files(f).name))
    writetable(table, fullfile('../results', fname))
end


