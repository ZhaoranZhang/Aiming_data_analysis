%% Figure 2—figure supplement 2 B

ControlResult = load_data;
[sub, sess, dir_, xy, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.xy,  ControlResult.badtrials);

targets = {[21.4852, 6.3690], [13, 2.8543], [4.5147, 6.3690]};
dirs    = [45, 90, 135];
subs    = unique(sub);
nSub    = numel(subs);
nDir    = numel(dirs);
nPhase  = 3;

xy(bts == 1, :) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            err  = sqrt(sum((xy(mask,:) - targets{d}).^2, 2)).';
            err(OutlierMAD(err, 2.5)) = NaN;
            Re(d, p, s) = nanmedian(err);
        end
    end
end

cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    Pdata  = squeeze(Re(d, :, :)).';                     % nSub x nPhase
    plt(d) = errorbar((1:nPhase) - 0.1 + 0.1*d, ...
                      nanmean(Pdata), SE(Pdata), ...
                      'color', cols(d,:), 'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Endpoint error (cm)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 16, 'box', 'off');
axis([0.5, 3.5, 0.2, 0.9]);


% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(4));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(6));

%% Figure 2—figure supplement 1 A

ControlResult = load_data;
[sub, sess, dir_, beep_, rt, bts] = deal( ...
    ControlResult.sub,  ControlResult.test, ControlResult.dir, ...
    ControlResult.beep, ControlResult.rt,   ControlResult.badtrials);

dirs   = [45, 90, 135];
beeps  = [0, 1];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nBeep  = numel(beeps);
nPhase = 3;

rt(bts == 1) = NaN;

Re_plot = NaN(nBeep, nDir, nPhase, nSub);   % 4D: split by beep, used for plotting
Re_stat = NaN(nDir, nPhase, nSub);          % 3D: beep merged at trial level, used for stats

for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            base = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            Re_stat(d, p, s) = nanmedian(rt(base));
            for b = 1:nBeep
                Re_plot(b, d, p, s) = nanmedian(rt(base & beep_ == beeps(b)));
            end
        end
    end
end
Re_plot = Re_plot * 1000;
Re_stat = Re_stat * 1000;

% Plot
cols  = bone(4);
style = {'--', ':'};
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for b = 1:nBeep
    for d = 1:nDir
        M = squeeze(Re_plot(b, d, :, :)).';
        x = (1:nPhase) - 0.15 + 0.15*(d-1);
        scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
                'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
        errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                 'linewidth', 2, 'capsize', 0, 'linestyle', style{b});
    end
end
ylabel('RT (ms)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5, 3.5, 200, 350]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
lab   = NaN(nCond, 2);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i)   = squeeze(Re_stat(d, p, :));
        lab(i, :) = [p, d];
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(lab(:,1)), categorical(lab(:,2)), ...
               'VariableNames', {'Phase','Direction'});

rm         = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl  = ranova(rm, 'WithinModel', 'Phase*Direction');
mauchlyTbl = mauchly(rm);
epsilonTbl = epsilon(rm);

% Effect rows: Phase (3,4), Direction (5,6), Phase:Direction (7,8)
effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d uses the within-subject error MS of the factor.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(4));    % Error(Phase)
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(6));    % Error(Direction)



%% Figure 2—figure supplement 1 B

ControlResult = load_data;
[sub, sess, dir_, mt, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.mt,  ControlResult.badtrials);

dirs   = [45, 90, 135];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nPhase = 3;

mt(bts == 1) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            Re(d, p, s) = nanmedian(mt(mask));
        end
    end
end
Re = Re * 1000;   % s -> ms

% Plot
cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    M = squeeze(Re(d, :, :)).';
    x = (1:nPhase) - 0.15 + 0.15*(d-1);
    scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
    plt(d) = errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                      'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Movement duration (ms)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5, 3.5, 270, 410]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(4));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(6));
%% Figure 5—figure supplement 1 A

ControlResult = load_data;
[sub, sess, dir_, mt, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.SubMove,  ControlResult.badtrials);

dirs   = [45, 90, 135];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nPhase = 3;

mt(bts == 1) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            temp = mt(mask);
            Re(d, p, s) = nansum(temp)./length(~isnan(temp));
        end
    end
end

% Plot
cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    M = squeeze(Re(d, :, :)).';
    x = (1:nPhase) - 0.15 + 0.15*(d-1);
    scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
    plt(d) = errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                      'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Submovements (%)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5,3.5,0.5,1]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(6));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(4));
%% Figure 5—figure supplement 1 B

ControlResult = load_data;
[sub, sess, dir_, mt, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.ipi,  ControlResult.badtrials);

dirs   = [45, 90, 135];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nPhase = 3;

mt(bts == 1) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            Re(d, p, s) = nanmean(mt(mask));
        end
    end
end

% Plot
cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    M = squeeze(Re(d, :, :)).';
    x = (1:nPhase) - 0.15 + 0.15*(d-1);
    scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
    plt(d) = errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                      'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Inter-peak-interval (ms)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5,3.5,30,120]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(6));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(4));
%% Figure 5—figure supplement 1 C

ControlResult = load_data;
[sub, sess, dir_, mt, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.pv1st,  ControlResult.badtrials);

dirs   = [45, 90, 135];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nPhase = 3;

mt(bts == 1) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            Re(d, p, s) = nanmedian(mt(mask));
        end
    end
end

% Plot
cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    M = squeeze(Re(d, :, :)).';
    x = (1:nPhase) - 0.15 + 0.15*(d-1);
    scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
    plt(d) = errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                      'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Peak speed (cm/s)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5,3.5,40,90]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(6));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(4));
%% Figure 5—figure supplement 1 D

ControlResult = load_data;
[sub, sess, dir_, mt, bts] = deal( ...
    ControlResult.sub, ControlResult.test, ControlResult.dir, ...
    ControlResult.pvtime1st,  ControlResult.badtrials);

dirs   = [45, 90, 135];
subs   = unique(sub);
nSub   = numel(subs);
nDir   = numel(dirs);
nPhase = 3;

mt(bts == 1) = NaN;

Re = NaN(nDir, nPhase, nSub);
for s = 1:nSub
    mSess  = unique(sess(sub == subs(s)));
    Lm     = numel(mSess);
    phases = {mSess(Lm-6:Lm-5), mSess(Lm-4:Lm-2), mSess(Lm-1:Lm)};
    for d = 1:nDir
        for p = 1:nPhase
            mask = (sub == subs(s)) & (dir_ == dirs(d)) & ismember(sess, phases{p});
            Re(d, p, s) = nanmedian(mt(mask));
        end
    end
end

% Plot
cols = bone(4);
figure('color', 'w', 'position', [100, 100, 400, 350]); hold on;
for d = 1:nDir
    M = squeeze(Re(d, :, :)).';
    x = (1:nPhase) - 0.15 + 0.15*(d-1);
    scatter(x, nanmean(M), 30, cols(d,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'markerfacealpha', 0.5);
    plt(d) = errorbar(x, nanmean(M), SE(M), 'color', cols(d,:), ...
                      'linewidth', 2, 'capsize', 0);
end
legend(plt, {'45^o','90^o','135^o'}, 'location', 'northeast', 'box', 'off', 'fontsize', 8);
ylabel('Peak speed time (ms)');
set(gca, 'xtick', 1:nPhase, 'xticklabel', {'early','mid','late'}, ...
    'fontsize', 12, 'box', 'off');
axis([0.5,3.5,120,200]);

% 2-way RM-ANOVA: Phase x Direction
nCond = nDir * nPhase;
y     = NaN(nSub, nCond);
i = 1;
for d = 1:nDir
    for p = 1:nPhase
        y(:, i) = squeeze(Re(d, p, :));
        i = i + 1;
    end
end
T      = array2table(y, 'VariableNames', compose("y%d", 1:nCond));
Within = table(categorical(repelem([1 2 3], 1, 3)'), categorical(repmat([1 2 3], 1, 3)'), ...
               'VariableNames', {'Direction','Phase'});

rm        = fitrm(T, sprintf('y1-y%d~1', nCond), 'WithinDesign', Within);
ranovatbl = ranova(rm, 'WithinModel', 'Phase*Direction');

effRows = [3, 5, 7];
errRows = [4, 6, 8];
peta2   = ranovatbl.SumSq(effRows) ./ (ranovatbl.SumSq(effRows) + ranovatbl.SumSq(errRows));

anovaResults = table( ...
    {'Phase';'Direction';'Phase:Direction'}, ...
    ranovatbl.F(effRows), ranovatbl.pValueGG(effRows), peta2, ...
    'VariableNames', {'Effect','F','pValue_GG','partial_eta2'});

% Pairwise (Bonferroni); Cohen's d denominator follows the paper's convention.
pwPhase = pairwise(rm, 'Phase',     ranovatbl.MeanSq(6));
pwDir   = pairwise(rm, 'Direction', ranovatbl.MeanSq(4));
%% --
function pw = pairwise(rm, factor, MS_d)
    tbl  = multcompare(rm, factor, 'ComparisonType', 'hsd');
    g1   = double(table2array(tbl(:,1)));
    g2   = double(table2array(tbl(:,2)));
    keep = g1 < g2;
    pw   = table(g1(keep), g2(keep), tbl.pValue(keep), ...
                 abs(tbl.Difference(keep)) / sqrt(MS_d), ...
                 'VariableNames', {'Group1','Group2','p_hsd','cohens_d'});
end