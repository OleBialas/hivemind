function gatherFiles(pattern, fname)

files = dir(fullfile('../results/', pattern));
varnames = {'Permutation', 'TrainDur', 'Subject', 'BestLambda', 'SpecAccuracy', 'GenAccuracy'};
table = array2table(zeros(0, length(varnames)), 'VariableNames', varnames);
for f = length(files)
    load(fullfile(files(f).folder, files(f).name))
    for idur = length(trainDur) % combine variables into one array and append it to the table
        data = [repelem(f, size(accGen, 1)); repelem(trainDur(idur), size(accGen, 1));...
            1:size(accGen, 1); bestLambdas(:, idur)'; accSpec(:, idur)'; accGen(:,idur)']'
        table = [table; array2table(data, 'VariableNames', varnames)]
    end
    delete(fullfile(files(f).folder, files(f).name))
    writetable(table, fullfile('../results', fname))
end


