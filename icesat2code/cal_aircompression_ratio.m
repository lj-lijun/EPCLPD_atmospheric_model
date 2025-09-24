function Z = cal_aircompression_ratio(lon_size, lat_size, P, Pw, T, time_size, level)
% 计算空气压缩率
% P为总压（Pa）、Pw为水汽分压（Pa）、T为气温（K）
% 输入的 P, Pw, T 为四维矩阵（第1维经度，第2维纬度，第3维层级，第4维时间）
Z = zeros(lon_size, lat_size, level, time_size);
T0 = 273.15; % Reference temperature in Kelvin
% Coefficients
a0 = 1.58123e-6; % K * Pa^-1
a1 = -2.933e-8;  % Pa^-1
a2 = 1.1043e-10; % K^-1 * Pa^-1
b0 = 5.707e-6;   % K * Pa^-1
b1 = -2.051e-8;  % Pa^-1
c0 = 1.9898e-4;  % K * Pa^-1
c1 = -2.376e-6;  % Pa^-1
e0 = 1.83e-11;   % K^2 * Pa^-2
f0 = -7.65e-9;   % K^2 * Pa^-2
pbar = waitbar(0, 'cal aircompression ratio...'  );
for t = 1 : time_size
    for i = 1 : level
        % 计算每个项时，确保它们的维度是 (lon_size, lat_size)
        term1 = (P(:, :, i, t) ./ T(:, :, i, t)) .* (a0 + a1 * (T(:, :, i, t) - T0) + a2 * (T(:, :, i, t) - T0).^2);
        term2 = (Pw(:, :, i, t) ./ T(:, :, i, t)) .* (b0 + b1 * (T(:, :, i, t) - T0));
        term3 = ((Pw(:, :, i, t).^2) ./ (P(:, :, i, t) .* T(:, :, i, t))) .* (c0 + c1 * (T(:, :, i, t) - T0));
        term4 = ((P(:, :, i, t).^2) ./ (T(:, :, i, t).^2)) .* e0;
        term5 = ((Pw(:, :, i, t).^2) ./ (T(:, :, i, t).^2)) .* f0;
        % 计算空气压缩率 Z
        Z(:, :, i, t) = 1./(1 - term1 + term2 + term3 + term4 + term5);
    end
    mesg = ['共' num2str(time_size) '层,第' num2str(t) '个'];
    waitbar(t/time_size, pbar, mesg);
end
close(pbar)
end