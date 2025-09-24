function date = convert_days_to_date(days_from_base)
% 将从1900年1月1日开始的天数转换为实际日期
% days_from_base - 从1900年1月1日开始的天数，可以是带有小数的值（表示时间）
base_date = datetime(1900, 1, 1);  % 基准日期
% 将天数转换为实际日期
date = base_date + days(days_from_base - 693962);  %  datenum('1900-1-1') = 693962
% 使用 dateshift 函数将时间调整到最近的分钟
date = dateshift(date, 'start', 'minute', 'nearest');
end
