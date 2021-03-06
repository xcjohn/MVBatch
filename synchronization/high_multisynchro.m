function [warpBref,asynDetection] = high_multisynchro(cal,ref,W,Wconstr,ro,psih,psiv,monitor,asynDetection)

% High level rountine of the Multyisynchro algorithm to detect asynchronisms prior to 
% batch synchronization.
% The original work is:
% [1] Gonz�lez Mart�nez, JM.; De Noord, O.; Ferrer, A. (2014). 
% Multi-synchro: a novel approach for batch synchronization in scenarios 
% of multiple asynchronisms, Journal of Chemometrics, 28(5):462-475.
% [2] Gonz�lez Mart�nez, JM.; Vitale, R.; De Noord, OE.; Ferrer, A. (2014). 
% Effect of synchronization on bilinear batch process modeling, 
% Industrial and Engineering Chemistry Research, 53(11):4339-4351.
% [3] Gonz�lez-Martinez, J.M. Advances on bilinear modeling of biochemical
% batch processes (2015). PhD thesis, DOI: 10.4995/Thesis/10251/55684.
%
% CALLS:
%        [warpBref,asynDetection] = high_multisynchro(cal,ref)                         % minimum call
%        [warpBref,asynDetection] = high_multisynchro(cal,ref,W,Wconstr,ro,psih,psiv)  % complete call
%
% INPUTS:
%
% cal: (1xI) cell array containing the measurements collected for J variables at 
%       Ki different sampling times for each of I batches.
%       
% ref: (KxJ) reference batch.
%
% W: (Jx1) weight matrix to give more importance to certain process variables for the detection of asynchronisms.
%
% Wconstr: (Jx1) boolean array indicating if a specific variables is
% considered in the synchronization (0) or not (1).
%
% ro: (1x1) fraction of the interquartile range of the batch lengths (0.4 by
% default).
%
% psih: (1x1) minimum number of horizontal transitions from what a specific batch
% can be considered having a specific asynchronism (3 by default).
%        
% psiv: (1x1) minimum number of vertical transitions from what a specific batch
% can be considered having a specific asynchronism (3 by default).
%
% monitor: flag to indicate if the high-level routine is going to be used
% for online purpose.
%
% asynDetection: struct containing information derived from the high level routine of the algorithm:
%       - batchcI_II.I: (I1x1) indeces of the batches with class I and II
%       asynchronism.
%       - batchcIII.I: (I2x1) indeces of the batches with class III
%       asynchronism.
%       - batchcIV.I: (I3x1) indeces of the batches with class IV
%       asynchronism.
%       - batchcIII_IV.I: (I3x1) indeces of the batches with class III and IV
%       asynchronism.
%
%
% OUTPUTS:
%
% warpBref: (KrefxI) warping information obtained in the phase of asynchronism detection, which is expressed as a function of the
% reference batch.
%
% asynDetection: struct containing information derived from the high level routine of the algorithm:
%       - batchcI_II.I: (I1x1) indeces of the batches with class I and II
%       asynchronism.
%       - batchcI_II.warpBref: (KrefxI1) warping information of those batches with class I and II
%       asynchronism expressed as a function of the reference batch.
%       - batchcI_II.warpBn: {I1x1} warping information of those batches with class I and II
%       asynchronism expressed as a function of the test batches.
%       - batchcIII.I: (I2x1) indeces of the batches with class III
%       asynchronism.
%       - batchcIII.warpBref: (KrefxI2) warping information of those batches with class III
%       asynchronism expressed as a function of the reference batch.
%       - batchcIII.warpBn: {I2x1} warping information of those batches with class III
%       asynchronism expressed as a function of the test batches.
%       - batchcIV.I: (I3x1) indeces of the batches with class IV
%       asynchronism.
%       - batchcIV.warpBref: (KrefxI3) warping information of those batches with class IV
%       asynchronism expressed as a function of the reference batch.
%       - batchcIV.warpBn: {I3x1} warping information of those batches with class IV
%       asynchronism expressed as a function of the test batches.
%       - batchcIII_IV.I: (I3x1) indeces of the batches with class III and IV
%       asynchronism.
%       - batchcIII_IV.warpBref: (KrefxI3) warping information of those batches with class III and IV
%       asynchronism expressed as a function of the reference batch.
%       - batchcIII_IV.warpBn: {I3x1} warping information of those batches with class III and IV
%       asynchronism expressed as a function of the test batches.
% 
%
% coded by: Jos� M. Gonzalez-Martinez (J.Gonzalez-Martinez@shell.com)                  
% last modification: August 2014 -> offline and online version of the algorithm are merged. 
%
% Copyright (C) 2016  Jos� M. Gonzalez-Martinez
% Copyright (C) 2016  Technical University of Valencia, Valencia
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% Parameters checking
if nargin < 2, error('Incorrect number of input parameters. Please, check the help for further details.'), end
if ~iscell(cal), error('The first input paramter must be a cell array containing the unsynchronized trajectories.'); end
nBatches = size(cal,2);
nVariables = size(ref,2);
if size(ref,2) ~= nVariables, error('The reference batch does not have the same number of variables as the calibration data set.'); end
if nargin < 3 || isempty(W), W = zeros(nVariables,1); VarConstr = find(Wconstr==0);W(VarConstr) = nVariables/numel(VarConstr); end
sw = size(W);
if sw(1) ~= nVariables, error('The rnk of the matrix must be equal to the number of process variables.'); end
if min(W) < 0, error('Matrix W must be positive definite'); end
if nargin < 4, Wconstr = zeros(size(cal{1,1},2),1); end
VarNonConstr = find(Wconstr==0);
wVars = find(W==0);
if numel(VarNonConstr)~=nVariables-numel(wVars), error('The number of constrained variables does not coincide with the null weights in the matrix W'); end
if find(Wconstr==0)~=find(W~=0), error('One or some variables marked as constrained does/do not have a zero weight in W'); end
if find(Wconstr==0) < 1, error('If all the process variables are constrained, no synchronization can be performed.');end
if nargin < 5, ro = 0.4; end
if ro ~= Inf && (ro < 0 || ro > 1), error('Ro must be a value ranged between ]0,1]');end
if nargin < 6, psih = 3; end
if psih >= 10, error('A number of horizontal transitions greater than 10 is considered too optimistic to categorize a batch as one with normal asynchronism');end
if nargin < 7, psiv = 3; end
if psiv >= 10, error('A number of vertical transitions greater than 10 is considered too optimistic to categorize a batch as one with normal asynchronism');end
monitor = 1;
if nargin < 8 || isempty(monitor), monitor = 0;end
mode = 1;
if nargin < 9, mode = 0; end
if mode
    if ~isstruct(asynDetection), error('''asynDetection'' must be a struct contaning the indices of batches affected by different types of asynchronisms.');end
    if ~isfield(asynDetection.batchcI_II,'I'), error('The indices of the batches affected by class I and/or class II asynchronisms.'); end
    if ~isfield(asynDetection.batchcIII,'I'), error('The indices of the batches affected by class III asynchronism.'); end
    if ~isfield(asynDetection.batchcIV,'I'), error('The indices of the batches affected by class IV asynchronism.'); end
    if ~isfield(asynDetection.batchcIII_IV,'I'), error('The indices of the batches affected by class III and class IV asynchronisms.'); end
end



%% Initialization

warpBn = cell(1, nBatches);
warpBref = zeros(size(ref,1),nBatches);
vn = zeros(nBatches,1);
hn = zeros(nBatches,1);
batchDuration = zeros(nBatches,1);

% Arrays of indeces to classify batches with three different types of
% asynchronisms
if ~mode
    batchcI_II.I = [];
    batchcIII.I = [];
    batchcIII.kfin=ones(nBatches,1).*NaN;
    batchcIV.I = zeros(nBatches,1);
    batchcIV.kini=ones(nBatches,1).*NaN;
    batchcIII_IV.I = zeros(nBatches,1);
    batchcIII_IV.kini=ones(nBatches,1).*NaN;
    batchcIII_IV.kfin=ones(nBatches,1).*NaN;
    auxvkfin=ones(nBatches,1).*NaN;
    auxvkini=ones(nBatches,1).*NaN;
end


%% Step A: Scaling

calsc = cal; 
refs = ref;
if ~monitor
    [calsc,rng] = scale_(cal);
    refs = scale_(ref,rng);
end

%% Step B: Asynchronism detection

% Step 1: Apply the DTW-based synchronization method between Bi i=1,...,I y Bref
for i=1:nBatches 
    [~,warpBref(:,i),warpBn{i}] = DTW(calsc{i},refs,diag(ones(nVariables,1)),0);
    if ~mode
        % Estimation of the vertical trnasitions for the n-th batch
        k_2 = numel(find(warpBn{i}(:,2)==size(calsc{i},1)-2));
        k_1 = numel(find(warpBn{i}(:,2)==size(calsc{i},1)-1));
        k_0 = numel(find(warpBn{i}(:,2)==size(calsc{i},1)));
        if k_2 > max(k_1,k_0), auxvkfin(i) = size(calsc{i},1)-2; vn(i) = k_2; end 
        if k_1 > max(k_2,k_0), auxvkfin(i) = size(calsc{i},1)-1; vn(i) = k_1; end 
        if k_0 > max(k_1,k_2), auxvkfin(i) = size(calsc{i},1);   vn(i) = k_0; end 
        % Estimation of the horizontal transitions for the n-th batch
        k_3 = numel(find(warpBn{i}(:,1)==1));
        k_2 = numel(find(warpBn{i}(:,1)==2));
        k_1 = numel(find(warpBn{i}(:,1)==3));
        k_0 = numel(find(warpBn{i}(:,1)==4));
        if k_0 > max(k_3,max(k_1,k_2)), auxvkini(i) = 4; hn(i) = k_0; end 
        if k_1 > max(k_0,max(k_2,k_3)), auxvkini(i) = 3; hn(i) = k_1; end
        if k_2 > max(k_0,max(k_1,k_3)), auxvkini(i) = 2; hn(i) = k_2; end
        if k_3 > max(k_0,max(k_1,k_2)), auxvkini(i) = 1; hn(i) = k_3; end
        batchDuration(i) = size(cal{i},1);
    end

end


if ro ~= Inf
    psiv = ceil(iqr(vn)*ro); if psiv == 0, psiv = 3; end 
    psih = ceil(iqr(hn)*ro); if psih == 0, psih = 3; end 
end

if ~mode
    % Find those batches containing shift and incompleted batches (class III and IV asynchronism)
    batchcIII_IV.I = intersect(find(vn>=psiv),find(hn>=psih));
    batchcIII_IV.kini = auxvkini(batchcIII_IV.I);
    batchcIII_IV.kfin = auxvkfin(batchcIII_IV.I);

    % Find those batches that are not completed (class III asynchronism)
    batchcIII.I = setdiff(find(vn>=psiv),batchcIII_IV.I);
    if isempty(batchcIII_IV.I), batchcIII.I = setdiff(find(vn>=psiv),batchcIII_IV.I);end
    batchcIII.kfin=auxvkfin(batchcIII.I);

    % Find those batches that have a shift but are completed (class IV asynchronism)
    batchcIV.I = setdiff(find(hn>=psih),batchcIII_IV.I);
    if isempty(batchcIV.I), batchcIV.I = setdiff(find(hn>=psih),batchcIII_IV.I);end
    batchcIV.kini=auxvkini(batchcIV.I);

    % Find batches that have natural type of asynchronism (class I and II asynchronism)
    batchcI_II.I = setdiff(setdiff(setdiff([1:nBatches]',batchcIII_IV.I),batchcIII.I),batchcIV.I);

% STORE INFORMATION OF THE ASYNCHRONISM DETECTION

    asynDetection.batchcI_II.I = batchcI_II.I;
    asynDetection.batchcIII.I = batchcIII.I;
    asynDetection.batchcIV.I = batchcIV.I;
    asynDetection.batchcIII_IV.I = batchcIII_IV.I;
end

asynDetection.batchcI_II.warpBref = warpBref(:,asynDetection.batchcI_II.I);
asynDetection.batchcI_II.warpBn = warpBn(asynDetection.batchcI_II.I);

asynDetection.batchcIII.warpBref = warpBref(:,asynDetection.batchcIII.I);
asynDetection.batchcIII.warpBn = warpBn(asynDetection.batchcIII.I);

asynDetection.batchcIV.warpBref = warpBref(:,asynDetection.batchcIV.I);
asynDetection.batchcIV.warpBn = warpBn(asynDetection.batchcIV.I);

asynDetection.batchcIII_IV.warpBref = warpBref(:,asynDetection.batchcIII_IV.I);
asynDetection.batchcIII_IV.warpBn = warpBn(asynDetection.batchcIII_IV.I);



