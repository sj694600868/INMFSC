function [U_final, V_final, nIter_final, elapse_final, bSuccess, objhistory_final] = GNMF(X, k, W, options, fname)
% Graph regularized Non-negative Matrix Factorization (GNMF)
% 图正则化的非负矩阵分解
% where
%   X
% Notation:
% X ... (mFea x nSmp) data matrix 
%       mFea  ... number of words (vocabulary size)
%       nSmp  ... number of documents
% k ... number of hidden factors
% W ... weight matrix of the affinity graph 
%
% options ... Structure holding all settings
%
% You only need to provide the above four inputs.
%
% X = U*V'
%

differror = 1e-5;
maxIter = [];
if isfield(options, 'maxIter')
    maxIter = options.maxIter;
end

nRepeat = 10;
minIterOrig = 30;
minIter = minIterOrig-1;
meanFitRatio = 0.1;
alpha = 1;

if isfield(options,'alpha')
    alpha = options.alpha;
end

Norm = 2;
NormV = 1;

if min(min(X)) < 0
    error('Input should be nonnegative!');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[mFea,nSmp]=size(X);

W = alpha*W;
DCol = full(sum(W,2));
D = spdiags(DCol,0,speye(size(W,1)));
L = D - W;

bSuccess.bSuccess = 1;
selectInit = 1;

    U = abs(rand(mFea,k));
    V = abs(rand(nSmp,k));

    [U,V] = NormalizeUV(U, V, NormV, Norm);
    objhistory = CalculateObj(X, U, V, L);
    tryNo = 0;
    
while tryNo < nRepeat   
    tmp_T = cputime;
    tryNo = tryNo+1;
    nIter = 0;
    maxErr = 1;
    nStepTrial = 0;
    
    while(maxErr > differror)
        % ===================== update V ========================
        XU = X'*U;  % mnk or pk (p<<mn)
        UU = U'*U;  % mk^2
        VUU = V*UU; % nk^2
        
        WV = W*V;
        DV = repmat(DCol,1,k).*V;
        
        XU = XU + WV;
        VUU = VUU + DV;
        
        V = V.*(XU./max(VUU,1e-10));
        %======================== done V =======================
        
        % ===================== update U =======================
        XV = X*V;   % mnk or pk (p<<mn)
        VV = V'*V;  % nk^2
        UVV = U*VV; % mk^2
        
        U = U.*(XV./max(UVV,1e-10)); % 3mk
        %======================= Done U ========================   
        
        nIter = nIter + 1;
        
        if nIter > minIter
           
            newobj = CalculateObj(X, U, V, L);
            objhistory = [objhistory newobj];
            
            %====================保存目标函数值================
            fprintf('Saving...\n');
            save(fname,'objhistory');
            fprintf('Done!\n');
            %==================================================
            
            if selectInit
                objhistory = CalculateObj(X, U, V, L);
                maxErr = 0; 
            else
                if isempty(maxIter)
                    newobj = CalculateObj(X, U, V, L);
                    objhistory = [objhistory newobj]; %#ok<AGROW>
                    meanFit = meanFitRatio*meanFit + (1-meanFitRatio)*newobj;
                    maxErr = (meanFit-newobj)/meanFit;
                    
                else
                    maxErr = 1;
                    if nIter >= maxIter
                        maxErr = 0;
                        if isfield(options,'Converge') && options.Converge 
                        else
                            objhistory = 0;                        
                        end
                    end
                end
            end
        end
    end
    
    elapse = cputime - tmp_T;

    if tryNo == 1
        U_final = U;
        V_final = V;
        nIter_final = nIter;
        elapse_final = elapse;
        objhistory_final = objhistory;
        bSuccess.nStepTrial = nStepTrial;
    else
       if objhistory(end) < objhistory_final(end)
           U_final = U;
           V_final = V;
           nIter_final = nIter;
           objhistory_final = objhistory;
           bSuccess.nStepTrial = nStepTrial;
           if selectInit
               elapse_final = elapse;
           else
               elapse_final = elapse_final+elapse;
           end
       end
    end

    if selectInit
        if tryNo < nRepeat
            %re-start
            U = abs(rand(mFea,k));
            V = abs(rand(nSmp,k));
            
            [U,V] = NormalizeUV(U, V, NormV, Norm);
        else
            tryNo = tryNo - 1;
            minIter = 0;
            selectInit = 0;
            U = U_final;
            V = V_final;
            objhistory = objhistory_final;
            meanFit = objhistory*10;  
        end
    end
end

nIter_final = nIter_final + minIterOrig;

[U_final,V_final] = NormalizeUV(U_final, V_final, NormV, Norm);


%==========================================================================

function [obj, dV] = CalculateObj(X, U, V, L, deltaVU, dVordU)
    if ~exist('deltaVU','var')
        deltaVU = 0;
    end
    if ~exist('dVordU','var')
        dVordU = 1;
    end
    dV = [];
    maxM = 62500000;
    [mFea, nSmp] = size(X);
    mn = numel(X);
    nBlock = floor(mn*3/maxM);

    if mn < maxM
        dX = U*V'-X;
        obj_NMF = sum(sum(dX.^2));
        if deltaVU
            if dVordU
                dV = dX'*U + L*V;
            else
                dV = dX*V;
            end
        end
    else
        obj_NMF = 0;
        if deltaVU
            if dVordU
                dV = zeros(size(V));
            else
                dV = zeros(size(U));
            end
        end
        for i = 1:ceil(nSmp/nBlock)
            if i == ceil(nSmp/nBlock)
                smpIdx = (i-1)*nBlock+1:nSmp;
            else
                smpIdx = (i-1)*nBlock+1:i*nBlock;
            end
            dX = U*V(smpIdx,:)'-X(:,smpIdx);
            obj_NMF = obj_NMF + sum(sum(dX.^2));
            if deltaVU
                if dVordU
                    dV(smpIdx,:) = dX'*U;
                else
                    dV = dU+dX*V(smpIdx,:);
                end
            end
        end
        if deltaVU
            if dVordU
                dV = dV + L*V;
            end
        end
    end
    obj_Lap = sum(sum((V'*L).*V'));
   %obj_Lap = alpha*sum(sum((L*V).*V));
   
    obj = obj_NMF+obj_Lap;
  




function [U, V] = NormalizeUV(U, V, NormV, Norm)
    nSmp = size(V,1);
    mFea = size(U,1);
    if Norm == 2
        if NormV
            norms = sqrt(sum(V.^2,1));
            norms = max(norms,1e-10);
            V = V./repmat(norms,nSmp,1);
            U = U.*repmat(norms,mFea,1);
        else
            norms = sqrt(sum(U.^2,1));
            norms = max(norms,1e-10);
            U = U./repmat(norms,mFea,1);
            V = V.*repmat(norms,nSmp,1);
        end
    else
        if NormV
            norms = sum(abs(V),1);
            norms = max(norms,1e-10);
            V = V./repmat(norms,nSmp,1);
            U = U.*repmat(norms,mFea,1);
        else
            norms = sum(abs(U),1);
            norms = max(norms,1e-10);
            U = U./repmat(norms,mFea,1);
            V = V.*repmat(norms,nSmp,1);
        end
    end

        