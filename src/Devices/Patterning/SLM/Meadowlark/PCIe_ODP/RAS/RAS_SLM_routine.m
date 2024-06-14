function [sol, est] = RAS_SLM_routine(Target, numiterations, Awidth)
X = 1:512;
gauss = @(x0, w0) exp(-((X - x0).^2)/w0.^2);
Alin = gauss(256.5, Awidth);
A0 = repmat(Alin(:)', 512, 1);
%A0=ones(512,512);
trt = zeros(512, 512);
%Target=smoothdata(Target,2,'gaussian',10);
for i = 1:512
    trt(i, :) = sqrt(Target(i, :)) / sum(Target(i, :));
end
initial_phase = angle(ifft(trt, 512, 2));
N = 512;
S1 = 1 / N * fft(A0.*exp(1i*initial_phase), 512, 2);
if gpuDeviceCount("available")
    S1 = gpuArray(S1);
    S2 = gpuArray(zeros(512, 512));
    S3 = gpuArray(zeros(512, 512));
    S4 = gpuArray(zeros(512, 512));
    A0 = gpuArray(A0);
    trt = gpuArray(trt);
end
stbl = false;
alpha = 0;
k = 0;
for j = 1:numiterations
    S2 = trt .* exp(1i*angle(S1));
    S3 = ifft(S2, 512, 2);
    S4 = A0 .* exp(1i*(angle(S3)));
    S1 = fft(S4, 512, 2);
end

sol = angle(ifft(S1, 512, 2));
est = abs(S1);
end