data = uint16(randi(250,5529600,1));  % 1M integer values between 1-250
 
% Standard unbuffered writing - slow
fid = fopen('D:\Ippei\working\test.dat', 'wb');
tic, for idx = 1:length(data), fwrite(fid,data(idx)); end, toc
fclose(fid);

% Buffered writing ? x4 faster
fid = fopen('D:\Ippei\working\test.dat', 'Wb');
tic, for idx = 1:length(data), fwrite(fid,data(idx)); end, toc
fclose(fid);





javaaddpath 'M:\behaviorICE v0.01'  % path to MyJavaThread.class

tic
data = rand(5e6,1);  % pre-processing (5M elements, ~40MB)
javaaddpath 'M:\behaviorICE v0.01'  % path to MyJavaThread.class
start(jwrite('C:\test.data',data));  % start running in parallel
data = fft(data);  % post-processing (Java I/O runs in parallel)
toc


tic;
for ii = 1:1
t=tic; start( jwrite('C:\Ippei\jtest.dat',data) ); prt(ii, toc(t));
end
toc;