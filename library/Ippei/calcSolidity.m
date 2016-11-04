function solidity = calcSolidity(X, iteration)


% CH = bwboundaries(BW);
% X = CH{1}';
% 
% 
% [dimX, dimY, dimZ] = size(stack);


N = length(X);


% Hull = zeros(N,1,'uint32');

% % define first vector
% v = [0;-1];
% i = 1;

% tic
%
%
% % Find Left most point
% [~, Hull(1)] = min(X(1,:));
% for ii = 1:100
%     while ((Hull(i) ~= Hull(1)) || (i==1))
%         i = i+1;
%         U = bsxfun(@minus, X, X(:,Hull(i-1)));
%         V = repmat(v,1,N);
%         A = acos(sum(U.*V,1)./(sqrt( sum(U.^2,1) ) .*sqrt( sum(V.^2,1) ) ));
%         [~ , Hull(i)] = max(A);
%         v = X(:,Hull(i-1)) - X(:,Hull(i));
%     end
%     i = 1;
%     v = [0;-1];
% end
%
%
% toc




% define first vector
v = [0;-1];
i = 1;

solidity = zeros(iteration, 1);

tic


gX = gpuArray(double(X));
gHull = gpuArray.zeros(N, 1, 'double');
gv = gpuArray(double(v));
% gi = gpuArray(double(i));
gN = gpuArray(double(N));


% Find Left most point
[~, gHull(1)] = min(gX(1,:));
for ii = 1:iteration
    while ((gHull(i) ~= gHull(1)) || (i==1))
        i = i+1;
        U = bsxfun(@minus, gX, gX(:,gHull(i-1)));
        V = repmat(gv,1,gN);
        try
            A = acos(sum(U.*V,1)./(sqrt( sum(U.^2,1) ) .*sqrt( sum(V.^2,1) ) ));
        catch
            A = acos(complex(sum(U.*V,1)./(sqrt( sum(U.^2,1) ) .*sqrt( sum(V.^2,1) ) )));
        end
        [~ , gHull(i)] = max(A);
        gv = gX(:,gHull(i-1)) - gX(:,gHull(i));
        Hull = gather(gHull);

    end
    i = 1;
    gv = [0;-1];
    gHull = gpuArray.zeros(N, 1, 'double');
    [~, gHull(1)] = min(gX(1,:));
    
    
    worm = polyarea(X(1,:),X(2,:));

    Line = X(:,Hull(Hull~=0));
    convex = polyarea(Line(1,:),Line(2,:));
    
    solidity(ii) = worm / convex;
    
end
toc














% 
% %%
% Line = X(:,Hull(Hull~=0));
% figure;
% scatter(X(1,:),X(2,:));
% hold on;
% scatter(Line(1,:),Line(2,:),'r');
% plot(Line(1,:),Line(2,:));
% hold off;
% 




end