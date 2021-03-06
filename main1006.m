function main1006(dataset,KClass)
 
%
% main.m 
% GSNMFC
% Graph Sparse Non-negative Matrix Factorization with Hard Constrain for Data Representation(GSNMFC)
% dataset   - 'COIL20'  'PIE_pose27'  'Yale_32' or 'ORL_32'
% rdim = 2 3 4 5 6 7 8 9 10       要在原始数据集中选取的类数进行实验

%    
 
tic

% 循环 10 次求平均
HXac=[];    % 预分配
HXmi=[];    % 预分配

% for h=1:10
for h=1:1
    
%--------------------------------------------------------------------------
%                            Dataset
%--------------------------------------------------------------------------
switch dataset,
  
 case 'CBCL',
     load('CBCL.mat');	
     nClass = length(unique(gnd));
     %fname='GSNMFC-CBCL';
     n=1200;
     
     
% Normalize each data vector to have L2-norm equal to 1  
     fea = NormalizeFea(fea);
 case 'COIL20',
     load('COIL20.mat');	
     nClass = length(unique(gnd));
     fname='INMFSC-COIL';
     n=1000;
     fname_TV='V-NMF-COIL';
     
% Normalize each data vector to have L2-norm equal to 1  
     fea = NormalizeFea(fea);
 
 case 'PIE_pose27',
     load('PIE_pose27.mat');	
     nClass = length(unique(gnd));
     fname='INMFSC-PIE';
     n=2300;
       fname_TV='V-NMF-PIE';
      fea = NormalizeFea(fea);
     
% Normalize each data vector to have L2-norm equal to 1  
   
     
 case 'Yale_32',
     load('Yale_32.mat');	
     nClass = length(unique(gnd));
     fname='INMFSC-Yale';
      fname_TV='V-NMF-Yale';
      fea = NormalizeFea(fea);
% Normalize each data vector to have L2-norm equal to 1 
     fea=NormalizeFea(fea);

 case 'ORL_32',
        load('ORL_32.mat');	
        nClass = length(unique(gnd));
        fname='INMFSC-ORL';
         fname_TV='V-NMF-ORL';
         n=200;
         fea = NormalizeFea(fea);
 
        
% Normalize each data vector to have L2-norm equal to 1 
          
end
p=0.8;
% 》》》》》--- 从原数据集中取出 KClass 类为原始分解矩阵 X ---《《《《《《 %
  % 选取数据集中数据作为训练集的比例为：p
  [m,n]=size(fea);        % fea 的维度大小,其中，m是样本的个数，n是类的维数
    samNum=m/nClass;           % 每个类中的样本数
    train_samNum=ceil(samNum*p); % 训练集中每个类中所要取得样本数，若遇到小数向上取整
    
     test_fea=[fea(train_samNum+1:samNum,:)];  % 特征数据
    test_gnd=[gnd(train_samNum+1:samNum,:)];  % 相应的标签数据
    for i=2:nClass
        % 选取特征数据
        test_fea=[test_fea;fea(samNum*i-train_samNum+1:samNum*i,:)];
        % 选取相应的标签数据
        test_gnd=[test_gnd;gnd(samNum*i-train_samNum+1:samNum*i,:)];
    end    
    
    train_fea=[fea(1:train_samNum,:)];  % 特征数据
    train_gnd=[gnd(1:train_samNum,:)];  % 相应的标签数据
    for i=2:nClass
        % 选取特征数据
        train_fea=[train_fea;fea(samNum*i-(samNum-1):(samNum*i-(samNum-1)+train_samNum-1),:)];
        % 选取相应的标签数据
        train_gnd=[train_gnd;gnd(samNum*i-(samNum-1):(samNum*i-(samNum-1)+train_samNum-1),:)];
    end    

X=train_fea';
[m,n]=size(X);  


%%%%%%%%%%  初始化  %%%%%%%%%%%%
  U = abs(rand(m,KClass));
 V = abs(rand(KClass,n));

maxiter=400;
%%%%%%%%%%  初始化  %%%%%%%%%%%%

% error=5;
for iter=1:maxiter
    U=U.*((X*V')./(U*V*V'));
    V=V.*((U'*X)./(U'*U*V));
    nmfnew=norm(X-U*V,'fro');
    nmfobj=[];
    nmfobj = [nmfobj nmfnew];
%=======================================================
        fprintf('Saving...\n');
        save(fname,'nmfobj');
        fprintf('Done!\n');
%=======================================================
    
end

U_tr=U;
V_tr=V;


%=================== 显示基矩阵 =====================%
figure(1)
 switch dataset
     case 'COIL20',
         visual(U_tr,3,5);
          title(fname);
     case 'PIE_pose27',
      %   visual(U_tr,3,5);
         %visual(U,3,9);
          title(fname);
     case 'Yale_32',
         visual(U_tr,3,4);
          title(fname);
     case 'ORL_32',
        % visual(U_tr,3,6);
         visual(V_tr,3,6);
         %visual(U,3,10);
          title(fname);
 end
%=================== 显示收敛性曲线 ========================%
%  figure(2)
%  %load(fname);
% 
% 
%  plot(nmfobjhistory(2:150));
%   figure(3)
%   plot(inmfscOBJ(2:end));
% 
%  hold on 
%  figure(4) 
%  title(fname);
%  xlabel('Iteration');
%  ylabel('Objective function value')
%  plot(maxiter,nmfobjhistory(2:end),'k-',maxiter,inmfscOBJ(2:end),'b--');


%  
% figure(4) 
%  plot(x,nmfobjhistory,'k-', x,inmfscOBJ,'b--');
%  title(' Plot of nmfobjhistory  inmfscOBJ and its derivative'); 

%  title(fname);
%  xlabel('Iteration');
%  ylabel('Objective function value')
%  legend('INMFSC')

 
%[sp1F,sp12,sp2F,sp22,sp3F,sp32]=sp1(U)
 %  聚类性能
 
% 》》》》》》》》》》》》  利用LibSVM进行分类  《《《《《《《《《《《《《《《
 
 % 数据预处理
        % 利用基矩阵求出测试数据集的系数矩阵
        % 由于求解矩阵方程往往会出现多解的情况，所以我们采用NMF基本迭代公式求得
        % v=v((X'U)./(VU'U));
        % 其中，X取全部的数据集fea（注意需要取转置）
        test_fea=fea;
         test_gnd=gnd;
        [V_TE, V_nIter] = V_test(test_fea', U_tr, fname_TV);        
                
        % =================== 显示测试集中求系数矩阵 V 的收敛性曲线 ========================%
        figure(3)
        load(fname_TV);
        plot(TestOBJ(3:end));
        title(fname_TV);
        xlabel('Iteration');
        ylabel('Objective function');
        
        save('V_TE','V_TE');  % 保存测试集的系数矩阵
        
 % 再次进行数据预处理——数据归一化到【0,1】
 % 进行训练的特征数据：V_tr（  [特征,样本数]） 标签数据：train_gnd（[nClass*train_samNum,1]）
 % 进行预测的特征数据：V_TE（[特征，样本数]）标签数据：test_gnd   取gnd([])全部标签数据
 
% test_gnd=gnd;
 
% maxpminma为matlab自带的映射函数
    % [train_wine,pstrain] =mapminmax(train_wine');
[V_tr,pstrain]=mapminmax(V_tr');
% 将映射函数的范围参数分别置为0和1
pstrain.ymin = 0;
pstrain.ymax = 1;
% 对训练集进行[0,1]归一化
    % [train_wine,pstrain] =mapminmax(train_wine,pstrain);
[V_tr,pstrain] =mapminmax(V_tr,pstrain);

% mapminmax为matlab自带的映射函数
[V_TE,pstest] =mapminmax(V_TE');
% 将映射函数的范围参数分别置为0和1
pstest.ymin = 0;
pstest.ymax = 1;
% 对测试集进行[0,1]归一化
[V_TE,pstest] =mapminmax(V_TE,pstest);

% 对训练集和测试集进行转置,以符合libsvm工具箱的数据格式要求
%V_tr = V_tr';
V_TE = V_TE';

% 利用SVM对分解后的系数矩阵进行训练和预测
model=svmtrain(train_gnd,V_tr,'-c 2 -g 0.02');
[predict_label, accuracy] = svmpredict(test_gnd, V_TE, model);


 end

toc
