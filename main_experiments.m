
%  绘制整轨ATL03数据的轨迹图
%% 
clc; clear; close all

path = 'D:\Projects\matlab_Projects\大气模型\ICESTat-2\atl03_data\';

% folder_list = ["ATL03_20220301_105314_051036_063751";
%     "ATL03_20220701_014816_141811_154526";
%     "ATL03_20221001_016117_062350_075104";
%     "ATL03_20221230_015418_150325_163040";
%     "ATL03_20230330_031733_044449_013419";
%     "ATL03_20230701_090532_103247_017120";
%     "ATL03_20230930_061913_075330_017221";
%     "ATL03_20231230_143315_160733_018022"];

folder_list = "ATL03_20220301_105314_051036_063751";


save_path = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\results\';


%% 第 1 步-------------------- 处理ATL03数据------------------------------------
interv     = [];
gtx_Mask   = [0,0,1,0,0,0];
min_lat    = [];
max_lat    = [];

Ph_UTC_Time  = [];
Ref_Ph_Lat   = [];
Ref_Ph_Lon   = [];
Ref_Ph_Ht    = [];
Ref_PD_total = [];
Ref_Dt_time  = [];
Ref_surf_type = [];

ref_ph_range_bias_corr = [];
ref_ph_ref_azimuth = [];
ref_ph_ref_elev = [];


%% 遍历ATL03数据的文件夹
% size(folder_list,1)
% 春季1；夏季2；秋季3；冬季4

id = 1;

for k = id : id

    atl03_folder = strcat(path,folder_list(k),'\');
    disp(folder_list(k))

    if isfolder(atl03_folder)
        h5files = dir(fullfile(atl03_folder,'*.h5'));
        h5files_num = size(h5files, 1);
    else
        disp('这不是一个文件夹')
        return;
    end

    %% 遍历文件夹下的所有 h5 文件
    % h5files_num
    for i = 1 : h5files_num
        disp(h5files(i).name)
        atl03_path = fullfile(atl03_folder, h5files(i).name);
        gtx_atm_ph = read_atl03_gtx_atm_v(atl03_path, gtx_Mask, min_lat, max_lat, interv);

        %% 数据采样
        
        if isempty(interv)
            step = 100;  % 默认为1，不采样数据
        else
            step = round(length(lonn) / interv);
        end

        ph_utc = gtx_atm_ph.Ph_UTC_Time(1:step:end);
        ph_lat = gtx_atm_ph.Ref_Ph_Lat(1:step:end);
        ph_lon = gtx_atm_ph.Ref_Ph_Lon(1:step:end);
        ph_nht = gtx_atm_ph.Ref_Ph_Ht(1:step:end);
        ph_pdt = gtx_atm_ph.Ref_PD_total(1:step:end);
        pth_dt = gtx_atm_ph.Ref_Dt_time(1:step:end);
        surf_type2 = gtx_atm_ph.Ref_surf_type(1:step:end,1:5);
        ph_rangbiascorr = gtx_atm_ph.ref_ph_range_bias_corr(1:step:end);
        ph_refazimuth = gtx_atm_ph.ref_ph_ref_azimuth(1:step:end);
        ph_refelev = gtx_atm_ph.ref_ph_ref_elev(1:step:end);

        % 预分配并存储数据
        Ph_UTC_Time  = [Ph_UTC_Time; ph_utc];
        Ref_Ph_Lat   = [Ref_Ph_Lat; ph_lat];
        Ref_Ph_Lon   = [Ref_Ph_Lon; ph_lon];
        Ref_Ph_Ht    = [Ref_Ph_Ht; ph_nht];
        Ref_PD_total = [Ref_PD_total; ph_pdt];
        Ref_Dt_time  = [Ref_Dt_time;pth_dt];
        Ref_surf_type= [Ref_surf_type;surf_type2];

        ref_ph_range_bias_corr = [ref_ph_range_bias_corr; ph_rangbiascorr];
        ref_ph_ref_azimuth = [ref_ph_ref_azimuth; ph_refazimuth];
        ref_ph_ref_elev = [ref_ph_ref_elev; ph_refelev];
        
    end
    disp(['总光子数据：', num2str(length(Ref_Ph_Lat))])
    
    % 结果字段存入结构图中
    gtx_atm_refph_info = struct('Ph_UTC_Time',Ph_UTC_Time,'Ref_Ph_Lat',Ref_Ph_Lat,...,
        'Ref_Ph_Lon',Ref_Ph_Lon,'Ref_Ph_Ht',Ref_Ph_Ht,...,
        'Ref_PD_total',Ref_PD_total,'Ref_Dt_time',Ref_Dt_time,'Ref_surf_type',Ref_surf_type,...,
        'ref_ph_range_bias_corr',ref_ph_range_bias_corr,'ref_ph_ref_azimuth',ref_ph_ref_azimuth,...,
        'ref_ph_ref_elev',ref_ph_ref_elev);

    % 按整轨保存参考光子信息
    if ~isempty(save_path)
        % 获取文件名中的轨道号
        filename = h5files(i).name;
        extracted = extractBetween(filename, length(filename) - 17, length(filename) - 14);
        disp(strcat('轨道号：',cellstr(extracted)))
        disp('>> gtx_atm_refph_info保存中...')
        save_path_mat = strcat(string(save_path),cellstr(extracted),"_gtx_atm_refph_info.mat");
        disp(["gtx_atm_refph_info save_path:",save_path_mat])
        save(save_path_mat,"gtx_atm_refph_info");
    else
       disp('>> 保存路径为空')
    end
end



%% 绘制轨迹图

fileout_trajectory_map = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\figure\';
plot_trajectory_map(Ref_Ph_Lon,Ref_Ph_Lat,Ref_PD_total,fileout_trajectory_map)

% figure
% subplot(2,1,1)
% plot(Ref_Dt_time, Ref_Ph_Ht, 'b.')
% subplot(2,1,2)
% m_proj('miller','lon',[-180,180],'lat',[-90,90]);
% m_coast('color',[0 .6 0]);
% hold on
% m_scatter(Ref_Ph_Lon, Ref_Ph_Lat, 5, Ref_PD_total, 'filled');
% box on




%%  整轨数据的参考光子信息写入表格

dataTable_point = table(Ph_UTC_Time, Ref_Ph_Lon, Ref_Ph_Lat, Ref_Ph_Ht, Ref_PD_total, ...
    'VariableNames', {'Ph_UTC_Time','Ref_Ph_Lon','Ref_Ph_Lat','Ref_Ph_Ht','Ref_PD_total'});

% Write the table to a CSV file
dataTable = table(Ref_Ph_Lon, Ref_Ph_Lat, Ref_Ph_Ht, Ref_PD_total,'VariableNames', {'lon','lat','h','pd'});
save_path_csv = strcat(string(save_path),cellstr(extracted),"_lat_lon_elevation_pd.csv");
writetable(dataTable, save_path_csv);




fprintf('Press any key to continue...')
pause

%% 第 2 步----------------------- 处理NC数据------------------------------
disp('>>  处理NC中')




nc_folder  = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\era5_data';
gpt31_path = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\icesat2code\gpt3_1.grd';





nc_file = dir(fullfile(nc_folder,'*.nc'));
for j = id : id

    nc_path = fullfile(nc_folder, nc_file(j).name);
    disp(nc_path)
    [gtx_ph_met_info, ~] = ERA5_cal_Meteorological_para(nc_path, dataTable_point, gpt31_path);

    % 按整轨保存参考光子信息
    if ~isempty(save_path)
        % 获取文件名中的轨道号
        ncfilename = nc_file(j).name;
        ncextracted = extractBetween(ncfilename, length(ncfilename) - 17, length(ncfilename) - 3);
        disp(strcat('轨道号：',cellstr(ncextracted)))
        disp('>> gtx_atm_refph_info保存中...')
        save_path_gtx_ph_met = strcat(string(save_path),cellstr(ncextracted),"_gtx_ph_met_info.mat");
        disp(["gtx_ph_met_info save_path:",save_path_gtx_ph_met])
        save(save_path_gtx_ph_met,"gtx_ph_met_info");
    else
       disp('>> 保存路径为空')
    end

end



%% ----------------- 由气象参数计算大气折射延迟 ----------------------------

Atm_delt_L = ICESAT_2_main(gtx_ph_met_info);
save_path_Atm_delt_L = strcat(string(save_path),cellstr(ncextracted),"_Atm_delt_L.mat");
disp(["Atm_delt_L save_path:",save_path_Atm_delt_L])
save(save_path_Atm_delt_L,"Atm_delt_L");
interp_delt_L = Interp_deltL_2_deltL(gtx_ph_met_info, Atm_delt_L);
save_path_interp_delt_L = strcat(string(save_path),cellstr(ncextracted),"_interp_delt_L.mat");
disp(["interp_delt_L save_path:",save_path_interp_delt_L])
save(save_path_interp_delt_L,"interp_delt_L");












