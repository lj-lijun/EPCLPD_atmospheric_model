
% Plotting NC files using the m-map library

clc;
clear;
close;

%  Read NC file
filename = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\era5_data\global_era5-2022-03-01.nc';


%View file information
% ncdisp(filename);

lat1 = ncread(filename,'latitude');
lon1 = ncread(filename,'longitude');
tt   = ncread(filename,'r');
Time = ncread(filename,'valid_time');
pp   = ncread(filename,'pressure_level');

% Data pre-processing
[lat,lon] = meshgrid(lat1, lon1);
datenum_start = datenum(1970,1,1); 
Time_num      = (double(Time)./(24*60*60)) + datenum_start; 
base_date = datetime(1900, 1, 1);


% Convert days to actual dates
date = base_date + days(Time_num - 693962);  %  datenum('1900-1-1') = 693962


% Adjusting the time to the nearest minute using the dateshift function
date = dateshift(date, 'start', 'minute', 'nearest');



% Selection of layers and variables
% -----------------------------

layer = 37; 
time_s = 2;
ttt = tt(:,:,layer,time_s);




% -----------------------------


%% Drawing with the M_map tool miller robinson
figureHandle = figure;
% Crop the range to your desired area  
% robinson    
m_proj('miller','lon',[-180,180],'lat',[-90,90]);
m_pcolor(lon,lat,ttt);

% m_coast('patch',[.7 .7 .7],'edgecolor','none'); %  line     patch
m_coast('line'); %  line     patch
m_grid('tickdir','out','linew1',1.2); 
colormap(m_colmap('jet','step',10));

% h = colorbar('southoutside','FontSize',11);
h = colorbar('eastoutside','FontSize',11);

%h.Label.String = strcat('Air Temperature(K) Layer = ',num2str(38-layer));
%h.Label.String = strcat('Specific Humidity(g/kg) Layer = ',num2str(38-layer));
h.Label.String = strcat('Relative humidity(%rh) Layer = ',num2str(38-layer));
%h.Label.String = strcat('Geopotential(m^2/s^-^2) Layer = ',num2str(38-layer));

%h.Position = [0.3, 0.16, 0.4, 0.025];  % 修改此行以控制颜色条的长度和位置
date_str = char(date(time_s,1));
title(date_str)



fileout = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\figure\';



% Image output
print(figureHandle, [fileout,'R_',num2str(38-layer),'_nc.png'],'-r600','-dpng');







 