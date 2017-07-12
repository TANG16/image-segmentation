%load bin file
%% addpath things might need to be changed
addpath ../common
addpath ../ransac

addpath(genpath('../deep_learning'))
addpath ../
addpath(genpath('common'))
addpath ex1
%%
if exist('LastFolder','var')
    GetFileName=sprintf('%s/*.bin',LastFolder);
else
    GetFileName='*.bin';
end
%cat to search
cat=1;
[FileNameL,PathNameL] = uigetfile(GetFileName,'Select the STORM bin file to crop');
LastFolder=PathNameL;

LeftFile =sprintf('%s%s',PathNameL,FileNameL);
list = readbinfileNXcYcZc(LeftFile);

x=list.xc;
y=list.yc;

frame=list.frame;


%need to load label
train.y = labels';
% train.X = ones(5,length(labels));

%%
train.X = [];
for i=1:length(labels)
    fprintf('ROI %d of %d \r',i,length(labels))
    idx = find(frame==i & list.cat==cat);
    list_num = numel(idx);
    x_now = x(idx);
    y_now = y(idx);
    %PxSize accounted for in ransac_ring
    [t_hist, r_hist, center, score, radius] = ransac_ring(x_now,y_now);
    train_Now = [score/list_num; radius; center';...
                    (r_hist./list_num)'; std(t_hist)/mean(t_hist);...
                    std(r_hist)/mean(r_hist)];
    train.X(:,i) = train_Now;
end



train_size = size(train.X);
%%
theta = rand(train_size(1),1)*.001;
% train.X(1,:)=[];
% train.X(3,:)=[];

options = struct('MaxIter', 1000,'optTol',0.000001);
%minimize theta
tic;
theta=minFunc(@logistic_regression_vec, theta, options, train.X, train.y);
fprintf('Optimization took %f seconds.\n', toc);

accuracy = binary_classifier_accuracy(theta,train.X,train.y);
fprintf('Training accuracy: %2.1f%%\n', 100*accuracy);


%% SVM
X=train.X';
Y=cast(labels,'logical');
SVMModel = fitcsvm(X,Y,'KernelFunction','rbf','Standardize',true,'ClassNames',[0 1])
[label_svm,score_svm] = predict(SVMModel,X);
accuracy_svm = sum(label_svm==Y)/length(Y);
fprintf('SVM Training accuracy: %2.1f%%\n', 100*accuracy_svm);

CVSVMModel = crossval(SVMModel);
[label_svm,score_svm] = predict(CVSVMModel,X);
