
function [Atm_delt_L] = ICESAT_2_main(gtx_ph_met)
% 读取数据并计算站点处气象参数

T = gtx_ph_met.T_i;  % 四维温度(纬度，1，38层的值，时间)，0为填充
Q = gtx_ph_met.Q_i;  % 四维比湿
P = gtx_ph_met.P_i;  % 四维气压
H = gtx_ph_met.H_i;  % 四维海拔
time_size = size(T,4);
dataTable_point = gtx_ph_met.dataTable_point;
site_size = size(dataTable_point,1);
levels = size(T,3);
% disp(levels)

%% 计算干湿气压值 
disp('>> 计算干湿气压值')
Mw = 0.01801528;   % kg/moll
Md = 0.02896546;   % kg/moll
pw = zeros(site_size, 1, levels, time_size);
pd = zeros(site_size, 1, levels, time_size);
pp = zeros(site_size, 1, levels, time_size);
pbar = waitbar(0, 'ERA5 cal Pd and Pw....');
for i = 1 : levels
    tem = Mw/Md + (1- Mw/Md) * Q(:,:,i,:);
    pw(:,:,i,:) = Q(:,:,i,:).*(P(:,:,i,:)*100)./tem;  % 单位为Pa
    pd(:,:,i,:) = P(:,:,i,:)*100 - pw(:,:,i,:);  % 单位为Pa
    pp(:,:,i,:) = P(:,:,i,:)*100;  % 将hPa的气压转换为Pa
    mesg = ['共' num2str(levels) '层,第' num2str(i) '个'];
    waitbar(i / levels, pbar, mesg);
end
close(pbar)

%% 计算空气压缩率Z
disp('>> 计算空气压缩率')
Z = cal_aircompression_ratio(site_size, 1, pp, pw, T, time_size, levels);

%% 计算格网点处折射率 N
disp('>> 计算光子点处折射率')
% nd = 8.1822296e-7;   % ICESat-1为 7.8147358e-7
% nw = -9.7331360e-8;  % ICESat-1为 -1.0604128e-7
nd = 8.2365383e-7;   
nw = -9.8383846e-8;  
N = zeros(site_size, 1, levels, time_size);
pbar = waitbar(0, 'cal N....');
for j = 1 : time_size
    for i = 1 : levels
        N(:,:,i,j) = (nd .* pp(:,:,i,j) + nw .* pw(:,:,i,j)) ./ T(:,:,i,j) .* Z(:,:,i,j);
    end
    mesg = ['共' num2str(time_size) '层,第' num2str(j) '个'];
    waitbar( j/time_size, pbar, mesg );
end
close(pbar)

%% 计算大气折射延迟
disp('>> 计算大气折射延迟')
Atm_delt_L = cal_delt_L(N, H);

disp('>> Run ICESAT_2_main Successfully !')

end



