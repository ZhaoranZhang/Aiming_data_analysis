%% Figure 4—figure supplement 1 B & D
clear;
clc;

ControlResult = load_data_from_h5();

[Beep,Dir,tNum,rt,mt,stt,edt,spp,tp,pv,spp_n,Sub,Sess,bts,xy] = ...
    deal(ControlResult.beep,ControlResult.dir,ControlResult.trial,ControlResult.rt,ControlResult.mt, ...
    ControlResult.st,ControlResult.et,ControlResult.speedPro,ControlResult.timePro,ControlResult.pv, ...
    ControlResult.speed_nor,ControlResult.sub,ControlResult.test,ControlResult.badtrials,ControlResult.xy);

D = unique(ControlResult.dir);
B = unique(ControlResult.beep);
Group = {[2,3],[4,5,6],[7,8]};
S = unique(Sub);
SubN = numel(S);

para = ControlResult.speed_nor;
para(bts==1) = {[]};
spp(bts==1) = {[]};
tp(bts==1) = {[]};


for b = 1%:length(B)
    for d = 1:length(D)
        for p = 1:length(Group)
            for s = 1:SubN
                data = [];
                data2 = [];
                Msess = unique(Sess(Sub==s));
                Lm = length(Msess);
                Group = {[Msess(Lm-6),Msess(Lm-5)],[Msess(Lm-4),Msess(Lm-3),Msess(Lm-2)],[Msess(Lm-1),Msess(Lm)]};
                for sess = 1:length(Group{p})
                    trj = para(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    spp_trj = spp(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    tp_trj = tp(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    pvratio = [];
                    for i = 1:length(trj)
                        if ~isempty(trj{i})
                            pvtime(i) = tp_trj{i}(spp_trj{i}==max(spp_trj{i}))-tp_trj{i}(1);
                            pvratio(i) = find(trj{i}==max(trj{i}),1,'first');
                        else
                            pvtime(i) = NaN;
                            pvratio(i) = NaN;
                        end
                    end
                    data = [data,pvratio];
                    data2 = [data2,pvtime];
                end
                Re(b,d,p,s) = nanmedian(data);
                Re2(b,d,p,s) = nanmedian(data2);
            end
        end
    end
end
%
% Re(:,:,:,Delete) = [];
% Re2(:,:,:,Delete) = [];
% SubN = SubN-length(Delete);

cols = colormap(bone(4));
close all;
h1 = figure('color','w','position',[100,100,800,350]);
h2 = figure('color','w','position',[100,100,800,350]);

Re2 =  Re2.*1000;
data_s = [];
group = [];
direction = [];
beep = [];
subject = [];

data_s2 = [];
group2 = [];
direction2 = [];
beep2 = [];
subject2 = [];

for b = 1%:2
    figure(h1);
    subplot(1,2,b);
    subtitle('all beep'); hold on;

    figure(h2);
    subplot(1,2,b);
    subtitle('all beep'); hold on;

    for d = 1:length(D)
        for p = 1:length(Group)
            data = squeeze(Re(b,d,p,1:SubN));
            Pdata(:,p) = data;

            data_s = [data_s;data];
            group = [group;ones(size(data))*p];
            direction = [direction;ones(size(data))*d];
            beep = [beep;ones(size(data))*b];
            subject = [subject;(1:1:SubN)'];

            data = squeeze(Re2(b,d,p,1:SubN));
            Pdata2(:,p) = data;

            data_s2 = [data_s2;data];
            group2 = [group2;ones(size(data))*p];
            direction2 = [direction2;ones(size(data))*d];
            beep2 = [beep2;ones(size(data))*b];
            subject2 = [subject2;(1:1:SubN)'];
        end

        figure(h1);
        plt(d) = errorbar((1:1:3)-0.1+0.1*d,nanmean(Pdata),SE(Pdata), ...
            'color',cols(d,:), ...
            'linewidth',2, ...
            'capsize',0); hold on;

        figure(h2);
        plt2(d) = errorbar((1:1:3)-0.1+0.1*d,nanmean(Pdata2),SE(Pdata2), ...
            'color',cols(d,:), ...
            'linewidth',2, ...
            'capsize',0); hold on;
    end

    figure(h1);
    legend(plt,{'45^o','90^o','135^o'}, ...
        'location','northeast', ...
        'box','off', ...
        'fontsize',8);
    ylabel('Peak speed time ratio (%)');
    set(gca,'xtick',1:1:3, ...
        'xticklabel',{'pre','in','post'}, ...
        'fontsize',12, ...
        'box','off');
    axis([0.5,3.5,42,58]);

    figure(h2);
    legend(plt2,{'45^o','90^o','135^o'}, ...
        'location','northeast', ...
        'box','off', ...
        'fontsize',8);
    ylabel('Peak speed time(s)');
    set(gca,'xtick',1:1:3, ...
        'xticklabel',{'pre','in','post'}, ...
        'fontsize',12, ...
        'box','off');
    axis([0.5,3.5,100,220]);
end

% Statistics for PV ratio

data = data_s;

tbl_phase = [];
T = table;
Within = table(zeros(9,1),zeros(9,1),'VariableNames',{'Direction','Phase'});
i = 1;

for d = 1:3
    for p = 1:3
        temp = data(direction==d&group==p);
        eval(sprintf('T.y%d = temp;',i));
        i = i+1;
    end
end

Within.Phase = categorical(repmat([1 2 3],1,3)');
Within.Direction = categorical(repelem([1 2 3],1,3)');

rm = fitrm(T,'y1-y9~1','WithinDesign',Within);
ranovatbl = ranova(rm,'WithinModel','Phase*Direction');

p_eta(1,1) = ranovatbl.SumSq(3)/(ranovatbl.SumSq(3)+ranovatbl.SumSq(4));
p_eta(2,1) = ranovatbl.SumSq(5)/(ranovatbl.SumSq(5)+ranovatbl.SumSq(6));
p_eta(3,1) = ranovatbl.SumSq(7)/(ranovatbl.SumSq(7)+ranovatbl.SumSq(8));

tbl_mau = mauchly(rm);
tbl_eps = epsilon(rm);

tbl_phase{1} = multcompare(rm,'Phase','ComparisonType','hsd');
tbl_phase{2} = multcompare(rm,'Phase','ComparisonType','bonferroni');
tbl_phase{3} = multcompare(rm,'Phase','ComparisonType','lsd');

for cc = 1:3
    p_value(cc,1) = tbl_phase{cc}.pValue(1);
    p_value(cc,2) = tbl_phase{cc}.pValue(6);
    p_value(cc,3) = tbl_phase{cc}.pValue(2);
end

p_value(4,1) = abs(tbl_phase{1}.Difference(1))/sqrt(ranovatbl.MeanSq(6));
p_value(4,2) = abs(tbl_phase{1}.Difference(6))/sqrt(ranovatbl.MeanSq(6));
p_value(4,3) = abs(tbl_phase{1}.Difference(2))/sqrt(ranovatbl.MeanSq(6));

tbl_phased{1} = multcompare(rm,'Direction','ComparisonType','hsd');
tbl_phased{2} = multcompare(rm,'Direction','ComparisonType','bonferroni');
tbl_phased{3} = multcompare(rm,'Direction','ComparisonType','lsd');

for cc = 1:3
    p_valued(cc,1) = tbl_phased{cc}.pValue(1);
    p_valued(cc,2) = tbl_phased{cc}.pValue(6);
    p_valued(cc,3) = tbl_phased{cc}.pValue(2);
end

p_valued(4,1) = abs(tbl_phased{1}.Difference(1))/sqrt(ranovatbl.MeanSq(4));
p_valued(4,2) = abs(tbl_phased{1}.Difference(6))/sqrt(ranovatbl.MeanSq(4));
p_valued(4,3) = abs(tbl_phased{1}.Difference(2))/sqrt(ranovatbl.MeanSq(4));

Stats = [];
c_ = zeros(9,2);
c_i = [1,-1,0;1,0,-1]';

for dir = 1:3
    c_m = c_;
    index = (dir-1)*3+[1,2,3];
    c_m(index,:) = c_i;
    [tbl_] = manova(rm,'withinmodel',c_m);
    Stats(dir).df1 = tbl_.df1(1);
    Stats(dir).df2 = tbl_.df2(1);
    Stats(dir).F = tbl_.F(1);
    Stats(dir).P = tbl_.pValue(1);
    Stats(dir).eta = tbl_.F(1)*tbl_.df1(1)/(tbl_.F(1)*tbl_.df1(1)+tbl_.df2(1));
end

[PlanCon_P,PlanCon_F,eta_s] = PlannedConstrast(rm);

StatsResults{1} = [ranovatbl.F([3,5,7]),ranovatbl.pValueGG([3,5,7]),p_eta];
StatsResults{2} = [Stats(1).F,Stats(1).P,Stats(1).eta;
    Stats(2).F,Stats(2).P,Stats(2).eta;
    Stats(3).F,Stats(3).P,Stats(3).eta];
StatsResults{3} = [PlanCon_P(:,1),eta_s(:,1),PlanCon_P(:,2),eta_s(:,2),PlanCon_P(:,3),eta_s(:,3)];
StatsResults{4} = p_value;
StatsResults{5} = p_valued;

% Statistics for PV time

data = data_s2;

tbl_phase = [];
T = table;
Within = table(zeros(9,1),zeros(9,1),'VariableNames',{'Direction','Phase'});
i = 1;

for d = 1:3
    for p = 1:3
        temp = data(direction2==d&group2==p);
        eval(sprintf('T.y%d = temp;',i));
        i = i+1;
    end
end

Within.Phase = categorical(repmat([1 2 3],1,3)');
Within.Direction = categorical(repelem([1 2 3],1,3)');

rm2 = fitrm(T,'y1-y9~1','WithinDesign',Within);
ranovatbl2 = ranova(rm2,'WithinModel','Phase*Direction');

p_eta2(1,1) = ranovatbl2.SumSq(3)/(ranovatbl2.SumSq(3)+ranovatbl2.SumSq(4));
p_eta2(2,1) = ranovatbl2.SumSq(5)/(ranovatbl2.SumSq(5)+ranovatbl2.SumSq(6));
p_eta2(3,1) = ranovatbl2.SumSq(7)/(ranovatbl2.SumSq(7)+ranovatbl2.SumSq(8));

tbl_mau2 = mauchly(rm2);
tbl_eps2 = epsilon(rm2);

tbl_phase2{1} = multcompare(rm2,'Phase','ComparisonType','hsd');
tbl_phase2{2} = multcompare(rm2,'Phase','ComparisonType','bonferroni');
tbl_phase2{3} = multcompare(rm2,'Phase','ComparisonType','lsd');

for cc = 1:3
    p_value2(cc,1) = tbl_phase2{cc}.pValue(1);
    p_value2(cc,2) = tbl_phase2{cc}.pValue(6);
    p_value2(cc,3) = tbl_phase2{cc}.pValue(2);
end

p_value2(4,1) = abs(tbl_phase2{1}.Difference(1))/sqrt(ranovatbl2.MeanSq(6));
p_value2(4,2) = abs(tbl_phase2{1}.Difference(6))/sqrt(ranovatbl2.MeanSq(6));
p_value2(4,3) = abs(tbl_phase2{1}.Difference(2))/sqrt(ranovatbl2.MeanSq(6));

tbl_phased2{1} = multcompare(rm2,'Direction','ComparisonType','hsd');
tbl_phased2{2} = multcompare(rm2,'Direction','ComparisonType','bonferroni');
tbl_phased2{3} = multcompare(rm2,'Direction','ComparisonType','lsd');

for cc = 1:3
    p_valued2(cc,1) = tbl_phased2{cc}.pValue(1);
    p_valued2(cc,2) = tbl_phased2{cc}.pValue(6);
    p_valued2(cc,3) = tbl_phased2{cc}.pValue(2);
end

p_valued2(4,1) = abs(tbl_phased2{1}.Difference(1))/sqrt(ranovatbl2.MeanSq(4));
p_valued2(4,2) = abs(tbl_phased2{1}.Difference(6))/sqrt(ranovatbl2.MeanSq(4));
p_valued2(4,3) = abs(tbl_phased2{1}.Difference(2))/sqrt(ranovatbl2.MeanSq(4));

Stats2 = [];
c_ = zeros(9,2);
c_i = [1,-1,0;1,0,-1]';

for dir = 1:3
    c_m = c_;
    index = (dir-1)*3+[1,2,3];
    c_m(index,:) = c_i;
    [tbl_] = manova(rm2,'withinmodel',c_m);
    Stats2(dir).df1 = tbl_.df1(1);
    Stats2(dir).df2 = tbl_.df2(1);
    Stats2(dir).F = tbl_.F(1);
    Stats2(dir).P = tbl_.pValue(1);
    Stats2(dir).eta = tbl_.F(1)*tbl_.df1(1)/(tbl_.F(1)*tbl_.df1(1)+tbl_.df2(1));
end

[PlanCon_P2,PlanCon_F2,eta_s2] = PlannedConstrast(rm2);

StatsResults2{1} = [ranovatbl2.F([3,5,7]),ranovatbl2.pValueGG([3,5,7]),p_eta2];
StatsResults2{2} = [Stats2(1).F,Stats2(1).P,Stats2(1).eta;
    Stats2(2).F,Stats2(2).P,Stats2(2).eta;
    Stats2(3).F,Stats2(3).P,Stats2(3).eta];
StatsResults2{3} = [PlanCon_P2(:,1),eta_s2(:,1),PlanCon_P2(:,2),eta_s2(:,2),PlanCon_P2(:,3),eta_s2(:,3)];
StatsResults2{4} = p_value2;
StatsResults2{5} = p_valued2;

% Pairwise comparison plots

figure(h1);
data = data_s;
subplot(1,4,3);

for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(direction==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor',cols(d,:)); hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.', ...
    'linewidth',2, ...
    'color',[0.5,0.5,0.5], ...
    'capsize',0); hold on;

set(gca,'xtick',1:1:3, ...
    'xticklabel',{'45^o','90^o','135^o'}, ...
    'fontsize',12, ...
    'box','off', ...
    'XTickLabelRotation',0);

axis([0.5,3.5,42,58]);

subplot(1,4,4);

for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(group==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor','w'); hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.', ...
    'linewidth',2, ...
    'color',[0.5,0.5,0.5], ...
    'capsize',0); hold on;

set(gca,'xtick',1:1:3, ...
    'xticklabel',{'pre','in','post'}, ...
    'fontsize',12, ...
    'box','off', ...
    'XTickLabelRotation',0);

axis([0.5,3.5,42,58]);

figure(h2);
data = data_s2;
subplot(1,4,3);

for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(direction2==d&subject2==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor',cols(d,:)); hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.', ...
    'linewidth',2, ...
    'color',[0.5,0.5,0.5], ...
    'capsize',0); hold on;

set(gca,'xtick',1:1:3, ...
    'xticklabel',{'45^o','90^o','135^o'}, ...
    'fontsize',12, ...
    'box','off', ...
    'XTickLabelRotation',0);

% axis([0.5,3.5,0.10,0.22]);

subplot(1,4,4);

for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(group2==d&subject2==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor','w'); hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.', ...
    'linewidth',2, ...
    'color',[0.5,0.5,0.5], ...
    'capsize',0); hold on;

set(gca,'xtick',1:1:3, ...
    'xticklabel',{'pre','in','post'}, ...
    'fontsize',12, ...
    'box','off', ...
    'XTickLabelRotation',0);

% axis([0.5,3.5,0.10,0.22]);

%% %% Figure 4—figure supplement 1 A & C
clear;
clc;

ControlResult = load_data_from_h5();

[Beep,Dir,tNum,rt,mt,stt,edt,spp,tp,pv,spp_n,Sub,Sess,bts,xy,acp,acp_n] = ...
    deal(ControlResult.beep,ControlResult.dir,ControlResult.trial,ControlResult.rt,ControlResult.mt, ...
    ControlResult.st,ControlResult.et,ControlResult.speedPro,ControlResult.timePro,ControlResult.pv, ...
    ControlResult.speed_nor,ControlResult.sub,ControlResult.test,ControlResult.badtrials,ControlResult.xy, ...
    ControlResult.accPro,ControlResult.acc_nor);

D = unique(ControlResult.dir);
B = unique(ControlResult.beep);
Group = {[2,3],[4,5,6],[7,8]};
S = unique(Sub);
SubN = numel(S);

para = acp_n;
para(bts==1) = {[]};
acp(bts==1) = {[]};
tp(bts==1) = {[]};

for b = 1%:length(B)
    for d = 1:length(D)
        for p = 1:length(Group)
            for s = 1:SubN
                data = [];
                data2 = [];
                Msess = unique(Sess(Sub==s));
                Lm = length(Msess);
                Group = {[Msess(Lm-6),Msess(Lm-5)],[Msess(Lm-4),Msess(Lm-3),Msess(Lm-2)],[Msess(Lm-1),Msess(Lm)]};
                for sess = 1:length(Group{p})
                    trj = para(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    acp_trj = acp(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    tp_trj = tp(Dir==D(d)&Sub==S(s)&Sess==Group{p}(sess));
                    pvratio = [];
                    for i = 1:length(trj)
                        if ~isempty(trj{i})
                            pvtime(i) = tp_trj{i}(acp_trj{i}==max(acp_trj{i}))-tp_trj{i}(1);
                            pvratio(i) = find(trj{i}==max(trj{i}),1,'first');
                        else
                            pvtime(i) = NaN;
                            pvratio(i) = NaN;
                        end
                    end
                    data = [data,pvratio];
                    data2 = [data2,pvtime];
                end
                Re(b,d,p,s) = nanmedian(data);
                Re2(b,d,p,s) = nanmedian(data2);
            end
        end
    end
end

%
cols = colormap(bone(4));
close all;
h1 = figure('color','w','position',[100,100,800,350]);
h2 = figure('color','w','position',[100,100,800,350]);

data_s = [];
group = [];
direction = [];
beep = [];
subject = [];

data_s2 = [];
group2 = [];
direction2 = [];
beep2 = [];
subject2 = [];
for b = 1%:2 % B = 0
    figure(h1);
    subplot(1,2,b);
    subtitle('all beep');hold on;
    figure(h2);
    subplot(1,2,b);
    subtitle('all beep');hold on;
    for d = 1:length(D)
        for p = 1:length(Group)
            data = squeeze(Re(b,d,p,1:SubN));
            Pdata(:,p) = data;
            data_s = [data_s;data];
            group = [group;ones(size(data))*p];
            direction = [direction;ones(size(data))*d];
            beep = [beep;ones(size(data))*b];
            subject = [subject;(1:1:SubN)'];
            data = squeeze(Re2(b,d,p,1:SubN));
            Pdata2(:,p) = data;
            data_s2 = [data_s2;data];
            group2 = [group2;ones(size(data))*p];
            direction2 = [direction2;ones(size(data))*d];
            beep2 = [beep2;ones(size(data))*b];
            subject2 = [subject2;(1:1:SubN)'];
        end
        figure(h1);
        plt(d) = errorbar((1:1:3)-0.1+0.1*d,nanmean(Pdata),SE(Pdata),'color',cols(d,:),...
            'linewidth',2,'capsize',0);hold on;
        figure(h2);
        plt2(d) = errorbar((1:1:3)-0.1+0.1*d,nanmean(Pdata2),SE(Pdata2),'color',cols(d,:),...
            'linewidth',2,'capsize',0);hold on;
    end
    figure(h1);
    legend(plt,{'45^o','90^o','135^o'},'location','northeast','box','off',...
        'fontsize',8);
    ylabel('Peak acc time ratio (%)');
    set(gca,'xtick',1:1:3,'xticklabel',{'pre','in','post'},...
        'fontsize',12,'box','off');
    axis([0.5,3.5,20,40]);

    figure(h2);
    legend(plt2,{'45^o','90^o','135^o'},'location','northeast','box','off',...
        'fontsize',8);
    ylabel('Peak acc time(s)');
    set(gca,'xtick',1:1:3,'xticklabel',{'pre','in','post'},...
        'fontsize',12,'box','off');
    axis([0.5,3.5,0.07,0.14]);
end
%
data = data_s;

tbl_phase = [];
T = table;
Within = table(zeros(9,1),zeros(9,1),'VariableNames',{'Direction','Phase'});
i = 1;
for d = 1:3
    for p = 1:3
        temp = data(direction==d&group==p);
        eval(sprintf('T.y%d = temp;',i));
        %         eval(sprintf('T.y%d = data(direction==d&group==p);',i));
        i = i+1;
    end
end
Within.Phase = categorical(repmat([1 2 3],1,3)');
Within.Direction = categorical(repelem([1 2 3],1,3)');

% T.Subject = categorical((1:1:SubN)');
rm = fitrm(T,'y1-y9~1','WithinDesign',Within);
ranovatbl = ranova(rm,'WithinModel','Phase*Direction');
p_eta(1,1) = ranovatbl.SumSq(3)/(ranovatbl.SumSq(3)+ranovatbl.SumSq(4));
p_eta(2,1) = ranovatbl.SumSq(5)/(ranovatbl.SumSq(5)+ranovatbl.SumSq(6));
p_eta(3,1) = ranovatbl.SumSq(7)/(ranovatbl.SumSq(7)+ranovatbl.SumSq(8));

tbl_mau = mauchly(rm);
tbl_eps = epsilon(rm);
tbl_phase{1} = multcompare(rm,'Phase','ComparisonType','hsd');
tbl_phase{2} = multcompare(rm,'Phase','ComparisonType','bonferroni');
tbl_phase{3} = multcompare(rm,'Phase','ComparisonType','lsd');

% Pairwise Comparisons (Phase)
for cc = 1:3
    p_value(cc,1) = tbl_phase{cc}.pValue(1);% 1,2
    p_value(cc,2) = tbl_phase{cc}.pValue(6);% 2,3
    p_value(cc,3) = tbl_phase{cc}.pValue(2);% 1,3
end
% cohen's d
p_value(4,1) = abs(tbl_phase{1}.Difference(1))/sqrt(ranovatbl.MeanSq(6));
p_value(4,2) = abs(tbl_phase{1}.Difference(6))/sqrt(ranovatbl.MeanSq(6));
p_value(4,3) = abs(tbl_phase{1}.Difference(2))/sqrt(ranovatbl.MeanSq(6));


tbl_phased{1} = multcompare(rm,'Direction','ComparisonType','hsd');
tbl_phased{2} = multcompare(rm,'Direction','ComparisonType','bonferroni');
tbl_phased{3} = multcompare(rm,'Direction','ComparisonType','lsd');

% Pairwise Comparisons (Phase)
for cc = 1:3
    p_valued(cc,1) = tbl_phased{cc}.pValue(1);% 1,2
    p_valued(cc,2) = tbl_phased{cc}.pValue(6);% 2,3
    p_valued(cc,3) = tbl_phased{cc}.pValue(2);% 1,3
end
% cohen's d
p_valued(4,1) = abs(tbl_phased{1}.Difference(1))/sqrt(ranovatbl.MeanSq(4));
p_valued(4,2) = abs(tbl_phased{1}.Difference(6))/sqrt(ranovatbl.MeanSq(4));
p_valued(4,3) = abs(tbl_phased{1}.Difference(2))/sqrt(ranovatbl.MeanSq(4));


% manova for simple effects at different directions
Stats = [];
c_ = zeros(9,2);
c_i = [1,-1,0;1,0,-1]';
for dir = 1:3
    c_m = c_;
    index = (dir-1)*3+[1,2,3];
    c_m(index,:) = c_i;
    [tbl_] = manova(rm,'withinmodel',c_m);
    Stats(dir).df1 = tbl_.df1(1);
    Stats(dir).df2 = tbl_.df2(1);
    Stats(dir).F = tbl_.F(1);
    Stats(dir).P = tbl_.pValue(1);
    Stats(dir).eta = tbl_.F(1)*tbl_.df1(1)/(tbl_.F(1)*tbl_.df1(1)+tbl_.df2(1));

end

% direction 1 2 3
% planned contrast 12 23 13
% [PlanCon_P,PlanCon_F] = PlannedConstrast(rm);
[PlanCon_P,PlanCon_F,eta_s] = PlannedConstrast(rm);

StatsResults{1} = [ranovatbl.F([3,5,7]),ranovatbl.pValueGG([3,5,7]),p_eta];
StatsResults{2} = [Stats(1).F,Stats(1).P,Stats(1).eta;
    Stats(2).F,Stats(2).P,Stats(2).eta;
    Stats(3).F,Stats(3).P,Stats(3).eta];
StatsResults{3} = [PlanCon_P(:,1),eta_s(:,1),PlanCon_P(:,2),eta_s(:,2),PlanCon_P(:,3),eta_s(:,3)];
StatsResults{4} = p_value;
StatsResults{5} = p_valued;

data = data_s2;
tbl_phase = [];
T = table;
Within = table(zeros(9,1),zeros(9,1),'VariableNames',{'Direction','Phase'});
i = 1;
for d = 1:3
    for p = 1:3
        temp = data(direction2==d&group2==p);
        eval(sprintf('T.y%d = temp;',i));
        %         eval(sprintf('T.y%d = data(direction2==d&group2==p);',i));
        i = i+1;
    end
end
Within.Phase = categorical(repmat([1 2 3],1,3)');
Within.Direction = categorical(repelem([1 2 3],1,3)');

% T.Subject = categorical((1:1:SubN)');
rm2 = fitrm(T,'y1-y9~1','WithinDesign',Within);
ranovatbl2 = ranova(rm2,'WithinModel','Phase*Direction');
p_eta2(1,1) = ranovatbl2.SumSq(3)/(ranovatbl2.SumSq(3)+ranovatbl2.SumSq(4));
p_eta2(2,1) = ranovatbl2.SumSq(5)/(ranovatbl2.SumSq(5)+ranovatbl2.SumSq(6));
p_eta2(3,1) = ranovatbl2.SumSq(7)/(ranovatbl2.SumSq(7)+ranovatbl2.SumSq(8));

tbl_mau2 = mauchly(rm2);
tbl_eps2 = epsilon(rm2);
tbl_phase2{1} = multcompare(rm2,'Phase','ComparisonType','hsd');
tbl_phase2{2} = multcompare(rm2,'Phase','ComparisonType','bonferroni');
tbl_phase2{3} = multcompare(rm2,'Phase','ComparisonType','lsd');

% Pairwise Comparisons (Phase)
for cc = 1:3
    p_value2(cc,1) = tbl_phase2{cc}.pValue(1);% 1,2
    p_value2(cc,2) = tbl_phase2{cc}.pValue(6);% 2,3
    p_value2(cc,3) = tbl_phase2{cc}.pValue(2);% 1,3
end

% cohen's d
p_value2(4,1) = abs(tbl_phase2{1}.Difference(1))/sqrt(ranovatbl2.MeanSq(6));
p_value2(4,2) = abs(tbl_phase2{1}.Difference(6))/sqrt(ranovatbl2.MeanSq(6));
p_value2(4,3) = abs(tbl_phase2{1}.Difference(2))/sqrt(ranovatbl2.MeanSq(6));


tbl_phased2{1} = multcompare(rm2,'Direction','ComparisonType','hsd');
tbl_phased2{2} = multcompare(rm2,'Direction','ComparisonType','bonferroni');
tbl_phased2{3} = multcompare(rm2,'Direction','ComparisonType','lsd');

% Pairwise Comparisons (Phase)
for cc = 1:3
    p_valued2(cc,1) = tbl_phased2{cc}.pValue(1);% 1,2
    p_valued2(cc,2) = tbl_phased2{cc}.pValue(6);% 2,3
    p_valued2(cc,3) = tbl_phased2{cc}.pValue(2);% 1,3
end
% cohen's d
p_valued2(4,1) = abs(tbl_phased2{1}.Difference(1))/sqrt(ranovatbl2.MeanSq(4));
p_valued2(4,2) = abs(tbl_phased2{1}.Difference(6))/sqrt(ranovatbl2.MeanSq(4));
p_valued2(4,3) = abs(tbl_phased2{1}.Difference(2))/sqrt(ranovatbl2.MeanSq(4));

% manova for simple effects at different directions
Stats2 = [];
c_ = zeros(9,2);
c_i = [1,-1,0;1,0,-1]';
for dir = 1:3
    c_m = c_;
    index = (dir-1)*3+[1,2,3];
    c_m(index,:) = c_i;
    [tbl_] = manova(rm2,'withinmodel',c_m);
    Stats2(dir).df1 = tbl_.df1(1);
    Stats2(dir).df2 = tbl_.df2(1);
    Stats2(dir).F = tbl_.F(1);
    Stats2(dir).P = tbl_.pValue(1);
    Stats2(dir).eta = tbl_.F(1)*tbl_.df1(1)/(tbl_.F(1)*tbl_.df1(1)+tbl_.df2(1));
end

% direction 1 2 3
% planned contrast 12 23 13
% [PlanCon_P,PlanCon_F] = PlannedConstrast(rm);
[PlanCon_P2,PlanCon_F2,eta_s2] = PlannedConstrast(rm2);

StatsResults2{1} = [ranovatbl2.F([3,5,7]),ranovatbl2.pValueGG([3,5,7]),p_eta2];
StatsResults2{2} = [Stats2(1).F,Stats2(1).P,Stats2(1).eta;
    Stats2(2).F,Stats2(2).P,Stats2(2).eta;
    Stats2(3).F,Stats2(3).P,Stats2(3).eta];
StatsResults2{3} = [PlanCon_P2(:,1),eta_s2(:,1),PlanCon_P2(:,2),eta_s2(:,2),PlanCon_P2(:,3),eta_s2(:,3)];
StatsResults2{4} = p_value2;
StatsResults2{5} = p_valued2;

% pairwise comparisons plots
figure(h1);
data = data_s;
subplot(1,4,3);
for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(direction==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor',cols(d,:));hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.','linewidth',2, ...
    'color',[0.5,0.5,0.5],'capsize',0);hold on;
set(gca,'xtick',1:1:3,'xticklabel',{'45^o','90^o','135^o'},...
    'fontsize',12,'box','off','XTickLabelRotation',0);
axis([0.5,3.5,20,47]);
subplot(1,4,4);
for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(group==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor','w');hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.','linewidth',2, ...
    'color',[0.5,0.5,0.5],'capsize',0);hold on;
set(gca,'xtick',1:1:3,'xticklabel',{'pre','in','post'},...
    'fontsize',12,'box','off','XTickLabelRotation',0);
axis([0.5,3.5,20,47]);

figure(h2)
data = data_s2;
subplot(1,4,3);
for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(direction==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor',cols(d,:));hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.','linewidth',2, ...
    'color',[0.5,0.5,0.5],'capsize',0);hold on;
set(gca,'xtick',1:1:3,'xticklabel',{'45^o','90^o','135^o'},...
    'fontsize',12,'box','off','XTickLabelRotation',0);
axis([0.5,3.5,0.07,0.14]);
subplot(1,4,4);
for d = 1:3
    for s = 1:SubN
        dirbar(s,d) = nanmean(data(group==d&subject==s));
    end
    bar(d,nanmean(dirbar(:,d)),'FaceColor','w');hold on;
end

errorbar(1:1:3,nanmean(dirbar),SE(dirbar),'.','linewidth',2, ...
    'color',[0.5,0.5,0.5],'capsize',0);hold on;
set(gca,'xtick',1:1:3,'xticklabel',{'pre','in','post'},...
    'fontsize',12,'box','off','XTickLabelRotation',0);
axis([0.5,3.5,0.07,0.14]);


%%
function ControlResult = load_data_from_h5(folder)

if nargin < 1 || isempty(folder)
    folder = pwd;
end

csv_path = fullfile(folder, 'behavior_data.csv');
h5_path  = fullfile(folder, 'trajectories.h5');
T = readtable(csv_path);

ControlResult.sub       = T.sub.';

oldSub = ControlResult.sub;
uSub = unique(oldSub);

newSub = oldSub;

for i = 1:numel(uSub)
    newSub(oldSub == uSub(i)) = i;
end

ControlResult.original_sub = oldSub;
ControlResult.sub = newSub;

ControlResult.test      = T.session.';
ControlResult.trial     = T.trial.';
ControlResult.dir       = T.dir.';
ControlResult.beep      = T.beep.';
ControlResult.rt        = T.rt.';
ControlResult.mt        = T.mt.';
ControlResult.st        = T.st.';
ControlResult.et        = T.et.';
ControlResult.pv        = T.pv.';
ControlResult.pa        = T.pa.';
ControlResult.badtrials = T.badtrial.';
ControlResult.xy        = [T.xy_x, T.xy_y];

N = numel(ControlResult.sub);

ControlResult.speed_nor = read_fixed_profile(h5_path, '/speed_nor', N);
ControlResult.speedPro  = read_ragged_profile(h5_path, '/speedPro', N);
ControlResult.timePro   = read_ragged_profile(h5_path, '/timePro', N);
ControlResult.acc_nor = read_fixed_profile(h5_path, '/acc_nor', N);
ControlResult.accPro  = read_ragged_profile(h5_path, '/accPro', N);
end


function C = read_fixed_profile(h5_path, dataset_path, N)

X = h5read(h5_path, dataset_path);
X = squeeze(X);

if isvector(X)
    X = X(:);

    if mod(numel(X), N) ~= 0
        error('Dataset %s is not aligned with CSV rows.', dataset_path);
    end

    profileLen = numel(X) / N;
    X = reshape(X, profileLen, N);
end

if size(X, 2) == N
    profileMat = X;
elseif size(X, 1) == N
    profileMat = X.';
else
    error('Dataset %s is not aligned with CSV rows.', dataset_path);
end

C = cell(1, N);

for i = 1:N
    xi = profileMat(:, i).';

    if isempty(xi) || all(isnan(xi))
        C{i} = [];
    else
        C{i} = xi;
    end
end

end


function C = read_ragged_profile(h5_path, group_path, N)

vals = h5read(h5_path, [group_path '/values']);
offs = h5read(h5_path, [group_path '/offsets']);

vals = vals(:).';
offs = double(offs(:).');

if numel(offs) ~= N + 1
    error('Offsets in %s are not aligned with CSV rows.', group_path);
end

C = cell(1, N);

for i = 1:N
    startIdx = offs(i) + 1;
    endIdx   = offs(i + 1);

    if endIdx < startIdx
        C{i} = [];
    else
        C{i} = vals(startIdx:endIdx);
    end
end

end