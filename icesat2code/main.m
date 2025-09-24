
%%  计算 "ATL03参考光子" 处单光子的大气折射延迟



%  版本 3




%% 数据路径

clc; clear
nc_path    = 'D:\Projects\matlab_Projects\星载激光雷达软件开发\satplab\toolbox\atmdc\testdata\2024-01-02-region.nc';
atl03_path = 'D:\Projects\matlab_Projects\星载激光雷达软件开发\satplab\toolbox\atmdc\testdata\ATL03_20240102101447_02232202_006_01.h5';
gpt35_path = 'D:\Projects\matlab_Projects\星载激光雷达软件开发\satplab\toolbox\atmdc\testdata\gpt3_1.grd';
save_path  = 'D:\Projects\matlab_Projects\星载激光雷达软件开发\satplab\toolbox\atmdc\testdata\';
gtx_Mask = [1,0,0,0,0,0];
min_lat = [];
max_lat = [];

% 插值气象参数
gtx_atm_ph = read_atl03_gtx_atm(atl03_path, gtx_Mask, min_lat, max_lat);

dataTable_point = table(gtx_atm_ph.Ph_UTC_Time,gtx_atm_ph.Ref_Ph_Lon,gtx_atm_ph.Ref_Ph_Lat,gtx_atm_ph.Ref_Ph_Ht, ...
                        'VariableNames', {'Ph_UTC_Time','Ref_Ph_Lon','Ref_Ph_Lat','Ref_Ph_Ht'});
[gtx_ph_met,~] = ERA5_cal_Meteorological_para(nc_path, dataTable_point, gpt35_path);


% 由气象参数计算大气折射延迟
Atm_delt_L= ICESAT_2_main(gtx_ph_met);

% 按时间插值得到光子时间的大气折射延迟
interp_delt_L = Interp_deltL_2_deltL(gtx_ph_met, Atm_delt_L);

% 求差，精度评估
errors = interp_delt_L - gtx_atm_ph.Ref_PD_total;
MAE = mean(abs(errors));
RMSE = sqrt(mean(errors.^2));
Bias = mean(errors);

disp(['MAE: ', num2str(MAE)]);
disp(['RMSE: ', num2str(RMSE)]);
disp(['Bias: ', num2str(Bias)]);
disp(['Max: ', num2str(max(errors))]);
disp(['Min: ', num2str(min(errors))]);

% 绘制相关性图
Xlable = 'Interp Atmospheric delay(m)';
Ylable = 'Ref Atmospheric delay(m)';
Legend = 'Atmospheric delay';
fileout = 'D:\Projects\matlab_Projects\星载激光雷达软件开发\satplab\toolbox\atmdc\testdata\cor';
plot_Correlation_atm_delay(interp_delt_L,gtx_atm_ph.Ref_PD_total,Xlable, Ylable, Legend, fileout)

figure
plot(gtx_atm_ph.Ref_Ph_Lat,gtx_atm_ph.Ref_Ph_Ht,'b.')

