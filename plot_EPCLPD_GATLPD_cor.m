
% Plot correlation of atmospheric refraction path delays


clc; clear; close all

%% --------------------------- Accuracy Assessment -----------------------------

gtx_atm_refph_info_path = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\results\1053_gtx_atm_refph_info.mat';
globalinterp_delt_L_path = 'D:\Desktop\星载激光大气改正论文\Remote Sensing of Environment\Atmospheric_Path_Delay_Modeling_Code\results\era5-2022-03-01_interp_delt_L.mat';

load(gtx_atm_refph_info_path)
load(globalinterp_delt_L_path)

%% draw map

png_name = '2022-03-01';

Ref_PD_total = gtx_atm_refph_info.Ref_PD_total;
errors = double(interp_delt_L - Ref_PD_total);

Q1 = quantile(errors, 0.25); % First quartile
Q3 = quantile(errors, 0.75); % Third quartile
IQR = Q3 - Q1;

lower_bound = Q1 - 2.5 * IQR;
upper_bound = Q3 + 2.5 * IQR;

id_error = errors >= lower_bound & errors <= upper_bound;
filtered_errors = errors(id_error);

MAE = mean(abs(filtered_errors));
RMSE = sqrt(mean(filtered_errors.^2));
Bias = mean(filtered_errors);

disp(['MAE: ', num2str(MAE)]);
disp(['RMSE: ', num2str(RMSE)]);
disp(['Bias: ', num2str(Bias)]);
disp(['Max: ', num2str(max(filtered_errors))]);
disp(['Min: ', num2str(min(filtered_errors))]);



Xlable = 'EPCLPD(m)';
Ylable = 'GATLPD(m)';
Legend = 'Path Delay';
fileout = strcat("D:\Projects\matlab_Projects\大气模型\ICESTat-2\figure\cor\2_", png_name);
plot_Correlation_atm_delay_v2(interp_delt_L(id_error), Ref_PD_total(id_error), Xlable, Ylable, Legend, fileout, png_name)




function [] = plot_Correlation_atm_delay_v2(x , y, Xlable, Ylable, Legend, fileout, png_name)

% 计算偏差 (Bias),
% 计算相关系数,
% 计算均方根误差 (RMSE)
bias = mean(y - x);
R    = corr(x, y);
rmse = sqrt(mean((y - x).^2));

% 使用线性回归拟合数据：y = a*x + b，a为斜率
p     = polyfit(x, y, 1);
slope = p(1);


%% 密度计算
data       = [x, y];
% radius     = 1.5; % 定义半径
% density_2D = density2D_KD(data(:,1:2),radius); % 2D平面密度

%% 打开窗口
figureHandle = figure;


%% 图片尺寸设置（单位：厘米）
figureUnits = 'centimeters';
figureWidth = 12;
figureHeight = 12;


%% 窗口设置

set(gcf, 'Units', figureUnits, 'Position', [30 10 figureWidth figureHeight]);


%% 密度散点图绘制
temp = data(:,1)-data(:,2);
temp_normalized = (temp - min(temp)) / (max(temp) - min(temp));

% temp = data(:,1);
scatter(data(:,1), data(:,2), 10, temp_normalized, 'filled', DisplayName = Legend)

minx1 = min(x);
minx2 = min(y);
maxy1 = max(x);
maxy2 = max(y);
xlim([min(minx1,minx2)-0.2,max(maxy1,maxy2)]+0.1);
ylim([min(minx1,minx2)-0.2,max(maxy1,maxy2)]+0.1);


%% 添加 1:1 线

xRange = xlim;  % 获取坐标轴的范围

% 绘制 1:1 线，连接坐标轴
hold on
plot([min(xRange) max(xRange)], [min(xRange) max(xRange)], 'LineStyle','--', 'Color', 'blue', 'LineWidth', 1, 'DisplayName', '1:1 Line');


%% 设置文本位置的归一化坐标
text(0.05, 0.9, ['R = ' num2str(R, '%.3f')], 'Units', 'normalized', ...
    'FontSize', 12, 'FontAngle', 'italic', 'Color', 'k', 'BackgroundColor', 'none');

text(0.05, 0.8, ['Bias = ' num2str(bias, '%.3f')], 'Units', 'normalized', ...
    'FontSize', 12, 'FontAngle', 'italic', 'Color', 'k', 'BackgroundColor', 'none');

text(0.05, 0.7, ['RMSE = ' num2str(rmse, '%.3f')], 'Units', 'normalized', ...
    'FontSize', 12, 'FontAngle', 'italic', 'Color', 'k', 'BackgroundColor', 'none');

% text(0.05, 0.6, ['Slope = ' num2str(slope, '%.3f')], 'Units', 'normalized', ...
%     'FontSize', 12, 'FontAngle', 'italic', 'Color', 'k', 'BackgroundColor', 'none');


%% 设置轴标签和图例
hXLabel = xlabel(Xlable);
hYLabel = ylabel(Ylable);
legend("show", 'Location', 'southeast');
title(['Date：',png_name])
%% 颜色定义
map = colormap(nclCM(232));  %color包里选颜色
map = flipud(map);
%% 细节优化
% 赋色
colormap(map)
h = colorbar('southoutside','FontSize',12,'AxisLocation','out');
h.Label.String = 'normalized residuals';
h.Position = [0.5, 0.35, 0.38, 0.025];
% 坐标轴美化
set(gca, 'Box', 'off', ...                                % 边框
    'LineWidth',1.2,...                                   % 线宽
    'XGrid', 'on', 'YGrid', 'on', ...                     % 网格
    'TickDir', 'out', 'TickLength', [.005 .005], ...      % 刻度
    'XMinorTick', 'off', 'YMinorTick', 'off', ...         % 小刻度
    'XColor', [.1 .1 .1],  'YColor', [.1 .1 .1])          % 坐标轴颜色

% 字体和字号
set(gca, 'FontSize', 12)
set([hXLabel, hYLabel], 'FontSize', 12)

% 背景颜色
set(gcf,'Color',[1 1 1])

% 添加上、右框线
xc = get(gca,'XColor');
yc = get(gca,'YColor');
unit = get(gca,'units');
ax = axes( 'Units', unit,...
    'Position',get(gca,'Position'),...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'Color','none',...
    'XColor',xc,...
    'YColor',yc);
set(ax, 'linewidth',1.2,...
    'XTick', [],...
    'YTick', []);


% 图片输出
print(figureHandle, strcat(fileout,'.png'),'-r600','-dpng');


end




%%
function density_2D = density2D_KD(data,radius)
% 功能：利用KD树提取离散点2D密度特征
% 输入：data   - 原始数据(m*3)
% 输出：planes - 拟合所得平面参数
M = size(data,1);
density_2D = zeros(M,1);
idx = rangesearch(data(:,1:2),data(:,1:2),radius,'Distance','euclidean','NSMethod','kdtree');
for i = 1:M
    density_2D(i,1) = length(idx{i})/(pi*radius^2);
end
end
% 基于KD树的离散点密度特征提取





%%
function colorList=nclCM(type,num)
% type : type of colorbar
% num  : number of colors
if nargin<2
    num=-1;
end
if nargin<1
    type=73;
end
nclCM_Data=load('nclCM_Data.mat');
CList_Data=nclCM_Data.Colors;
disp(nclCM_Data.author);

if isnumeric(type)
    Cmap=CList_Data{type};
else
    Cpos=strcmpi(type,nclCM_Data.Names);
    Cmap=CList_Data{find(Cpos,1)};
end
if num>0
    Ci=1:size(Cmap,1);Cq=linspace(1,size(Cmap,1),num);
    colorList=[interp1(Ci,Cmap(:,1),Cq,'linear')',...
        interp1(Ci,Cmap(:,2),Cq,'linear')',...
        interp1(Ci,Cmap(:,3),Cq,'linear')'];
else
    colorList=Cmap;
end
end



