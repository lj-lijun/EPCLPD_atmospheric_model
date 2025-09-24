
%% 求解ICESat-2折射率系数


clc; clear


% 干空气参考气象参数
P_d = 101325;
Pw_d = 0;
T_d = 288.15;

% 湿空气参考气象参数
P_w = 1333;
Pw_w = 1333;
T_w = 293.15;

% 计算压缩率
[Z_d] = calculate_aircompression_ration(P_d, Pw_d, T_d);
[Z_w] = calculate_aircompression_ration(P_w, Pw_w, T_w);

% 计算参考气象参数条件下的干湿空气密度
Md = 0.02896546;   % kg/moll
Mw = 0.01801528;   % kg/moll
R = 8.314510;      % J/(K*mol)

rou_d = ((P_d-Pw_d)*Md + Pw_d*Mw)/(Z_d*R*T_d);
rou_w = ((P_w-Pw_w)*Md + Pw_w*Mw)/(Z_w*R*T_w);

% 计算参考气象参数处的折射率
% L = 0.532;

Lamda = 0.23:0.01:1.69;
% Lamda = [0.532,1.064];
N_d = [];
N_w = [];
N   = [];
for i = 1 : length(Lamda)
    L = Lamda(i);
    [Nd_r, Nw_r] = calculate_refractive_id(L);

    % 计算干湿项折射率系数N_d和N_w
    N_d(i,1) = (Md/R)*(Nd_r/rou_d);
    N_w(i,1) = (Mw/R)*(Nw_r/rou_w)-N_d(i,1);
    % 计算折射率 N
    % N_d ICESat-2为 8.1822296e-7;    ICESat-1为 7.8147358e-7
    % N_w ICESat-2为 -9.7331360e-8;   ICESat-1为 -1.0604128e-7
    N(i,1) = (N_d(i,1) .* (P_d ./ T_d) + N_w(i,1) .* (Pw_d ./ T_d)) ./ Z_d;
end

figureHandle = figure('color',[1 1 1]);
set(gcf, 'Units', 'centimeters', 'Position', [10 10 30 9]);
subplot(1,3,1);
plot(Lamda,N_d,'Linewidth',1.5,'Color','blue');
hold on;
scatter(0.532,8.23653826258188e-07,30,'red','filled');
hold on
scatter(1.064,7.86660530454458e-07,30,'black','filled');
xlabel('log(1/σ) (μm)')
ylabel('N_d_,_r(1/σ)')
legend('N_d_,_r(1/σ)','0.532 μm','1.064 μm')
set(gca,'XScale','log');
set(gca,'Linewidth',1);
grid on;

subplot(1,3,2);
plot(Lamda,N_w,'Linewidth',1.5,'Color','blue');
hold on;
scatter(0.532,-9.83838457179538e-08,30,'red','filled')
hold on
scatter(1.064,-1.07125948365324e-07,30,'black','filled')
xlabel('log(1/σ) (μm)')
ylabel('N_w_,_r (1/σ)')
legend('N_w_,_r (1/σ)','0.532 μm','1.064 μm')
set(gca,'XScale','log');
set(gca,'Linewidth',1);
grid on;

subplot(1,3,3);
plot(Lamda,N,'Linewidth',1.5,'Color','blue');
hold on;
scatter(0.532,0.000289747598537842,30,'red','filled')
hold on
scatter(1.064,0.000276733977670171,30,'black','filled')
xlabel('log(1/σ) (μm)')
ylabel('N (1/σ)')
legend('N (1/σ)','0.532 μm','1.064 μm')
set(gca,'XScale','log');
set(gca,'Linewidth',1);
grid on;
fileout = 'D:\Projects\matlab_Projects\大气模型\ICESTat-2\figure\n';
print(figureHandle, [fileout,'.png'],'-r600','-dpng');



function [Z] = calculate_aircompression_ration(P, Pw, T)
% 计算空气压缩率
% P为总压（Pa）、Pw为水汽分压（Pa）、T为气温（K）
% 输入的 P, Pw, T 为列矩阵

T0 = 273.15; % Reference temperature in Kelvin
% Coefficients
a0 = 1.58123e-6; % K * Pa^-1
a1 = -2.9331e-8; % Pa^-1
a2 = 1.1043e-10; % K^-1 * Pa^-1
b0 = 5.707e-6;   % K * Pa^-1
b1 = -2.051e-8;  % Pa^-1
c0 = 1.9898e-4;  % K * Pa^-1
c1 = -2.376e-6;  % Pa^-1
e0 = 1.83e-11;   % K^2 * Pa^-2
f0 = -7.65e-9;   % K^2 * Pa^-2

% Element-wise operations to handle vectorized inputs
term1 = (P / T) * (a0 + a1 * (T - T0) + a2 * (T - T0)^2);
term2 = (Pw / T) * (b0 + b1 * (T - T0));
term3 = ((Pw^2) / (P * T)) * (c0 + c1 * (T - T0));
term4 = ((P^2) / (T^2)) * e0;
term5 = ((Pw^2) / (T^2)) * f0;

% 计算空气压缩率 Z
Z = 1 - term1 + term2 + term3 + term4 + term5;

end

function [Nd_r, Nw_r] = calculate_refractive_id(L)
% 在参考气象条件下，计算给定波长的空气折射率
% 对于干空气：参考气象条件为P = 101325 Pa, Pw = 0, T = 288.15K；
% 对于湿空气：参考气象条件为P = 1333 Pa, Pw = 1333 Pa, T = 293.15K；
k = 1/L;         % 波长L的倒数(μm)
d0 = 238.0185;   % μm^(-2)
d1 = 5792105;    % μm^(-2)
d2 = 57.362;     % μm^(-2)
d3 = 167917;     % μm^(-2)
w0 = 295.235;    % μm
w1 = 2.6422;     % μm^(2)
w2 = -0.032380;  % μm^(4)
w3 = 0.004028;   % μm^(6)
C = 1.022;       

% Calculate rd_r(k) using the given formula(m)
Nd_r = 1e-8*(d1 * (d0 + k^2) / ((d0 - k^2)^2) + d3 * (d2 + k^2) / ((d2 - k^2)^2));

% Calculate rw_r(k) using the given formula(m)
Nw_r = 1e-8*(C * (w0 + 3 * w1 * (k^2) + 5 * w2 * (k^4) + 7 * w3 * (k^6)));

end


