
% ��ʾ�������ݼ���ԭͼ��6��6��
load('COIL20.mat');
% load('PIE_pose27.mat');
% load('ORL_32.mat');

faceW = 32; 
faceH = 32; 
numPerLine = 10;     % Ҫ���ͼ������� 
ShowLine = 10;       % Ҫ��ʾͼ������� 

Y = zeros(faceH*ShowLine,faceW*numPerLine); 
for i=0:ShowLine-1 
  	for j=0:numPerLine-1 
    	 Y(i*faceH+1:(i+1)*faceH,j*faceW+1:(j+1)*faceW) = reshape(fea(i*numPerLine+j+1,:),[faceH,faceW]); 
  	end 
end 

imagesc(Y);colormap(gray);