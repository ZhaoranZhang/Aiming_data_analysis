function ControlResult = load_data(folder)
% LOAD_DATA  Load packed Zenodo data and reconstruct a ControlResult struct
% with the same field shapes as the original Aiming_Result_2023_v2_endpoint.mat
% (subject 11 already removed).
%
% Usage:
%   ControlResult = load_data();          % loads from current folder
%   ControlResult = load_data('path/to/data');
%
% Field shapes match the original .mat file:
%   .sub .test .trial .dir .beep .rt .mt .st .et .pv .badtrials  -> 1 x N
%   .xy                                                          -> N x 2
%   .speed_nor .speedPro .timePro                                -> 1 x N cell

if nargin < 1 || isempty(folder); folder = pwd; end
csv_path = fullfile(folder, 'behavior_data.csv');
h5_path  = fullfile(folder, 'trajectories.h5');

%% Per-trial scalars
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
ControlResult.ipi        = T.ipi.';
ControlResult.SubMove        = T.SubMove.';
ControlResult.badtrials = T.badtrial.';
ControlResult.xy        = [T.xy_x, T.xy_y];

ControlResult.pv1st        = T.pv1st.';
ControlResult.pvtime1st        = T.pvtime1st.';

N = numel(ControlResult.sub);

%% speed_nor: 100 x N -> 1 x N cell of 1 x 100
sn = h5read(h5_path, '/speed_nor');           % 100 x N
ControlResult.speed_nor = cell(1, N);
for i = 1:N
    ControlResult.speed_nor{i} = sn(:, i).';
end

%% speedPro: ragged
sp_vals = h5read(h5_path, '/speedPro/values');
sp_offs = h5read(h5_path, '/speedPro/offsets');
sp_vals = sp_vals(:).';   % force row
sp_offs = sp_offs(:).';
ControlResult.speedPro = cell(1, N);
for i = 1:N
    ControlResult.speedPro{i} = sp_vals(sp_offs(i)+1 : sp_offs(i+1));
end

%% timePro: ragged
tp_vals = h5read(h5_path, '/timePro/values');
tp_offs = h5read(h5_path, '/timePro/offsets');
tp_vals = tp_vals(:).';
tp_offs = tp_offs(:).';
ControlResult.timePro = cell(1, N);
for i = 1:N
    ControlResult.timePro{i} = tp_vals(tp_offs(i)+1 : tp_offs(i+1));
end
end
