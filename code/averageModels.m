function avgModel = averageModels(models)
    wbar = mean(cat(4, models.w), 4);
    bbar = mean(cat(1, models.b), 1);
    t    = models(1).t;
    fs   = models(1).fs;
    Dir  = models(1).Dir;
    type = models(1).type;
    avgModel = struct('w',wbar,'b',bbar,'t',t,'fs',fs,'Dir',Dir,'type',type);

    % Aw. You improved the readability. :(
    % We could slap a coat of paint (input checking, some features) on this
    % and put it in mTRFtoolbox.
