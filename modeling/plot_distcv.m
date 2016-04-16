function [alph,alpr,alph95,alpr95]=plot_distcv(xini, phases, prep, opt, axes1, axes2)

% Computes the D-statistic and SPE values of the calibration batches using 
%   leave-one-out cross-validation. 
%
% [alph,alpr,alph95,alpr95]=plot_distcv(xini, phases, prep, opt) 
%    % call with standard parameters
%
% [alph,alpr,alph95,alpr95]=plot_distcv(xini, phases, prep, opt, axes1, 
%   axes2) % complete call
%
%
% INPUTS:
%
% xini: (KxJxI) three-way batch data matrix for calibration, K(sampling times) 
%       x J(variables) x I(batches)
%
% phases: (n_phasesx5) phases of the MP model. Each row contains the information 
%   of a phase, namely [PRESS, PCs, lags, initial time, end time]. 
%
% prep: (1x1) preprocesing of the data
%       0: no preprocessing.
%       1: trajectory centering (average trajectory subtraction)
%       2: 1 + trajectory-scaling (scales data so that each pair variable and 
%           sampling time has variance 1) (default)  
%       3: 1 + variable-scaling (scales data so that each variable has
%           variance 1)
%       4: variable centering (subtraction of the average value of each
%           variable)
%       5: 4 + variable-scaling. 
%
% opt: boolean (1x1) 
%       true: plot results.
%       false: do not plot results.
%
% axes1: handle to the axes where the D-statistic chart is plotted.
%
% axes2: handle to the axes where the SPE chart is plotted.
%
%
% OUTPUTS:
%
% alph: suggested imposed significance level (alpha) for the 99% confidence 
%   limit in the D-statistic. 
%
% alpr: suggested imposed significance level (alpha) for the 99% confidence 
%   limit in the SPE.
%
% alph95: suggested imposed significance level (alpha) for the 95% confidence 
%   limit in the D-statistic. 
%
% alpr95: suggested imposed significance level (alpha) for the 95% confidence 
%   limit in the SPE.
%
%
% codified by: Jos� Camacho P�ez.
% version: 0.1
% last modification: 23/Apr/09.

% Parameters checking

if nargin < 2, error('Numero de argumentos erroneos.'); end;

if ndims(xini)~=3, error('Incorrect number of dimensions of xini.'); end;
s = size(xini);
if find(s<1), error('Incorrect content of xini.'); end;

if ndims(phases)~=2, error('Incorrect number of dimensions of phases.'); end;
sp=size(phases);
if (sp(1)<1||sp(2)~=5), error('Incorrect content of phases.'); end;
if find(phases(:,1:3)<0), error('Incorrect content of phases.'); end;
if find(phases(:,4:5)<1), error('Incorrect content of phases.'); end;
if find(phases(:,3:5)>s(1)), error('Incorrect content of phases.'); end;

if nargin < 3, prep = 2; end;
if nargin < 4, opt = 1; end;

if (prep<0||prep>5), error('Incorrect value of prep.'); end;

if nargin < 5, 
    h = figure;
    axes1 = axes; 
end;
if nargin < 6, 
    h2 = figure;
    axes2 = axes; 
end;

% Main code

[xce,av,sta] = preprocess3D(xini,prep);
    
q=[];
res=zeros(s(3),s(2),s(1));
pcs=[];
for i=1:sp(1),
    ind=(max(phases(i,4)-phases(i,3),1):phases(i,5));
    ind_ini=find(ind==phases(i,4));
    xu=unfold(xce(ind,:,:),phases(i,3));
    [U,S,V] = svd(xu,'econ');
    tAll = U*S;
    pAll = V;
    p = pAll(:,phases(i,2));
    t = tAll(:,phases(i,2));

    resa=xu-t*p';
    resb=fold(resa,s(3),phases(i,3));
    res(:,:,ind(ind_ini:end))=permute(resb(ind_ini:end,:,:),[3 2 1]);

        if ind_ini<phases(i,3)+1,
            menor_en=phases(i,3)-ind_ini;
             % Estimate covariance matrices for TSR-based imputation
            theta = cov(tAll);
            theta_A = cov(t);

            for j=0:menor_en,
                indb=1:s(2)*(ind_ini+j);
                ind2=phases(i,4)+j;
               % TSR IMPUTATION
                t_t = theta_A*p(indb,:)'*p(indb,:)*inv(p(indb,:)'*pAll(indb,:)*theta*pAll(indb,:)'*p(indb,:))*p(indb,:)'*xu(1:s(3),indb)';

                res(:,:,ind2)=permute(xce(ind2,:,:),[3 2 1])-t_t'*p(indb(end-s(2)+1:end),:)';   
                q=[q ;sum((permute(xce(ind2,:,:),[3 2 1])-t_t'*p(indb(end-s(2)+1:end),:)').^2,2)'];
            end        
        end
    ssqres = sum(resa.^2,2)';
    qb=[];
    for o=1:s(3):length(ssqres),
        qb=[qb;ssqres(o:o+s(3)-1)];
    end
    q=[q;qb];
    pcs=[pcs phases(i,2)*ones(1,phases(i,5)-phases(i,4)+1)];
end

tcv=[];
qcv=[];
for o=1:s(3),
    test=xini(:,:,o);
    xini2=xini(:,:,[1:o-1 o+1:s(3)]);
    tcvb=[];
    qcvb=[];
    for i=1:sp(1),
        ind=(max(phases(i,4)-phases(i,3),1):phases(i,5));
        ind_ini=find(ind==phases(i,4));
        
        [xce,av,sta] = preprocess3D(xini2(ind,:,:),prep);
        xu=unfold(xce,phases(i,3));
        [U,S,V] = svd(xu,'econ');
        tAll = U*S;
        pAll = V;
        p = pAll(:,phases(i,2));
        t = tAll(:,phases(i,2));
        teste = (test(ind,:,:)-av)./sta;
        testu=unfold(teste,phases(i,3));
        tpred = testu*p;
        resb=testu-tpred*p';
        resb=fold(resb,1,phases(i,3));
 
        if ind_ini<phases(i,3)+1,
            menor_en=phases(i,3)-ind_ini;
            % Estimate covariance matrices for TSR-based imputation
            theta = cov(tAll);
            theta_A = cov(t);

            for j=0:menor_en,
                jindb=1:s(2)*(ind_ini+j);
                jind2=phases(i,4)+j;
                % IMPUTATION USING TSR
                t_t = theta_A*p(jindb,:)'*p(jindb,:)*inv(p(jindb,:)'*pAll(jindb,:)*theta*pAll(jindb,:)'*p(jindb,:))*p(jindb,:)'*xu(1:(s(3)-1),jindb)';
                cov_inv=inv(cov(t_t'));
                t_t = theta_A*p(jindb,:)'*p(jindb,:)*inv(p(jindb,:)'*pAll(jindb,:)*theta*pAll(jindb,:)'*p(jindb,:))*p(jindb,:)'*testu(1,jindb)';
                % CALCULATE STATISTICS
                tcvb=[tcvb;t_t'*cov_inv*t_t];
                qcvb=[qcvb ;sum((permute(teste(jind2,:,:),[3 2 1])-t_t'*p(jindb(end-s(2)+1:end),:)').^2)];
            end        
        end
    
        ssc=size(t);
        j=1;
        for u=1:(s(3)-1):ssc(1),
            sc_model = t(u:u+s(3)-2,:);
            cov_inv = inv(cov(sc_model));
            tcvb=[tcvb;tpred(j,:)*cov_inv*tpred(j,:)'];
            j=j+1;
        end
    
        qcvb=[qcvb;squeeze(sum(sum(resb((phases(i,3)+1):end,:,:).^2,3),2))];
    end
    tcv=[tcv tcvb];
    qcv=[qcv qcvb];
end

[alph,alpr,alph95,alpr95]=plotcv(res,tcv,qcv,s(3),['x'],pcs,opt,axes1,axes2);