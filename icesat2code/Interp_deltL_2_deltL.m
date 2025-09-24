
function Atm_Delay_Total = Interp_deltL_2_deltL(gtx_ph_met, Atm_delt_L)

Ph_UTC_Time = gtx_ph_met.dataTable_point(:,1);


%% 将ERA5日期转为与光子一致的UTC时间
Era5_Date = gtx_ph_met.ncdate;
Era5_Date.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z''';  % 设置输出格式


%% 循环每个光子时间，插值得到大气折射延迟
time_len = size(Ph_UTC_Time, 1);
Atm_Delay_Total = [];

pbar = waitbar(0, 'ERA5 cal Pd and Pw....');
disp('>> 进行插值中');
for i = 1 :  time_len

    ph_time_i = Ph_UTC_Time{i, 1};    % 提取时间
    ph_delt_i = Atm_delt_L(i,:);      % 提取所有时刻的大气折射延迟

    % 判断光子的时间是否在ERA5时间内
    % 按照冰2的思想：插值时程的起始点为小于第一个观测值减去一个数值天气模式时间步长；
    % 插值时间段的结束时间为大于最后观测时间段的最早时间段加上数值天气模式的一个时间步长。
    % 此处加3个小时
    t_start   = ph_time_i - hours(3);
    t_end     = ph_time_i + hours(3);
    t_start.TimeZone = 'UTC';
    t_end.TimeZone = 'UTC';
    Era5_Date.TimeZone = 'UTC';

    isInRange = ( t_start >= Era5_Date(1)) && (t_end <= Era5_Date(end));

    if isInRange

        % 日期转数值
        t0 = datenum(Era5_Date(1));
        t1 = datenum(Era5_Date) - t0;
        t2 = datenum(ph_time_i) - t0;

        % 使用样条插值获取给定时间处的值
        % pchip和spline（Cubic Spline）都是常用的插值方法

        interp_delt_L_i = spline(t1, ph_delt_i, t2);
        Atm_Delay_Total = [Atm_Delay_Total; interp_delt_L_i];
    else
        errordlg('插值日期不在时间范围内,退出插值');
        return
        
    end
    mesg = ['共' num2str(time_len) '个光子,第' num2str(i) '个'];
    waitbar(i / time_len, pbar, mesg);
end
close(pbar)
disp('>> Run Interp_deltL_2_deltL Successfully !')
end
