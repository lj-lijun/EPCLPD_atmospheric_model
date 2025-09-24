function [gtx_atm_data] = read_atl03_gtx_atm_v(File_Name, gtx_Mask, lat_min_threshold, lat_max_threshold,interv)

% disp('>> 正在读取数据...')
gt_names = {'gt1r', 'gt1l', 'gt2r', 'gt2l', 'gt3r', 'gt3l'};

% 读取过程不变量：光子时间信息
data_start_utc      = h5read(File_Name,'/ancillary_data/data_start_utc');
start_delta_time    = h5read(File_Name,'/ancillary_data/start_delta_time');

% 读取不同GT轨道的光子信息
id_gtx = find(gtx_Mask == 1);

% 初始化输出变量
Ph_UTC_Time = [];
Ref_Ph_Lat  = [];
Ref_Ph_Lon  = [];
Ref_Ph_Ht   = [];
Ref_PD_total = [];
Ref_Dt_time = [];
Ref_surf_type = [];

ref_ph_lat = [];
ref_ph_nht = [];
ref_ph_range_bias_corr = [];
ref_ph_ref_azimuth = [];
ref_ph_ref_elev = [];


% 读取不同GT的数据
for i = 1:length(id_gtx)
    gt_name = gt_names{id_gtx(i)};

    %% 构建字段路径
    lat_field  = sprintf('/%s/geolocation/reference_photon_lat', gt_name);
    lon_field  = sprintf('/%s/geolocation/reference_photon_lon', gt_name);
    neutat_ht_field = sprintf('/%s/geolocation/neutat_ht', gt_name);
    delta_time_field = sprintf('/%s/geolocation/delta_time', gt_name);
    neutat_delay_total_field = sprintf('/%s/geolocation/neutat_delay_total', gt_name);
    reference_photon_index_field = sprintf('/%s/geolocation/reference_photon_index', gt_name);
    surf_type_field = sprintf('/%s/geolocation/surf_type', gt_name);
    range_bias_corr_field = sprintf('/%s/geolocation/range_bias_corr', gt_name);
    ref_azimuth_field = sprintf('/%s/geolocation/ref_azimuth', gt_name);
    ref_elev_field = sprintf('/%s/geolocation/ref_elev', gt_name);


    % 一次性读取多个字段
    range_bias_corr = h5read(File_Name, range_bias_corr_field);
    ref_azimuth = h5read(File_Name, ref_azimuth_field);
    ref_elev = h5read(File_Name, ref_elev_field);
    lat = h5read(File_Name, lat_field);
    lon = h5read(File_Name, lon_field);
    neutat_ht = h5read(File_Name, neutat_ht_field);
    delta_time = h5read(File_Name, delta_time_field);
    neutat_delay_total = h5read(File_Name, neutat_delay_total_field);
    reference_photon_index = h5read(File_Name, reference_photon_index_field);
    surf_type_tag = h5read(File_Name, surf_type_field);
    surf_type_tag = surf_type_tag';



    %% 自granule开始以来的秒数可以定义为 delta_time 减去 '/ancillary_data/start_delta_time'
    d_delta_time = delta_time - start_delta_time;



    % ATLAS 是相对于协调世界时UTC,要将 ATLAS/UTC 时间转换为 GPS 时间
    startTime = datetime(data_start_utc, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z''', 'TimeZone', 'UTC');
    Ph_UTC_Times = startTime + seconds(d_delta_time);
    Ph_UTC_Times.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z''';  % 设置输出格式



    %% 去空值
    NaN_id = logical(reference_photon_index);
    Ph_UTC_Times = Ph_UTC_Times(NaN_id);
    lat = lat(NaN_id);
    lon = lon(NaN_id);
    neutat_ht = neutat_ht(NaN_id);
    neutat_delay_total = neutat_delay_total(NaN_id);
    delta_t = delta_time(NaN_id);
    surf_type1 = surf_type_tag(NaN_id, 1:5);

    range_bias_corr = range_bias_corr(NaN_id);
    ref_azimuth = ref_azimuth(NaN_id);
    ref_elev = ref_elev(NaN_id);



    %% 截取数据，使用元素级别的逻辑运算符
    if isempty(lat_min_threshold) ||  isempty(lat_max_threshold)
        id_range = lat >= min(lat) & lat <= max(lat);
    else
        id_range = lat > lat_min_threshold & lat < lat_max_threshold;
    end
    phutc = Ph_UTC_Times(id_range);
    lonn  = lon(id_range);
    latt  = lat(id_range);
    nhtt  = neutat_ht(id_range);
    pdtt  = neutat_delay_total(id_range);
    dtime = delta_t(id_range);
    surf_type = surf_type1(id_range, 1:5);
    rangbiascorr = range_bias_corr(id_range);
    refazimuth = ref_azimuth(id_range);
    refelev = ref_elev(id_range);



    %% 采样数据
    % 均匀采样
    if isempty(interv)
        step = 1;  % 默认为1，不采样数据
    else
        step = round(length(lonn) / interv);
    end
    ph_utc = phutc(1:step:end);
    ph_lat = latt(1:step:end);
    ph_lon = lonn(1:step:end);
    ph_nht = nhtt(1:step:end);
    ph_pdt = pdtt(1:step:end);
    pth_dt = dtime(1:step:end);
    surf_type2 = surf_type(1:step:end,1:5);
    ph_rangbiascorr = rangbiascorr(1:step:end);
    ph_refazimuth = refazimuth(1:step:end);
    ph_refelev = refelev(1:step:end);



    % 预分配并存储数据
    Ph_UTC_Time  = [Ph_UTC_Time; ph_utc];
    Ref_Ph_Lat   = [Ref_Ph_Lat; ph_lat];
    Ref_Ph_Lon   = [Ref_Ph_Lon; ph_lon];
    Ref_Ph_Ht    = [Ref_Ph_Ht; ph_nht];
    Ref_PD_total = [Ref_PD_total; ph_pdt];
    Ref_Dt_time  = [Ref_Dt_time;pth_dt];
    Ref_surf_type= [Ref_surf_type;surf_type2];  

    ref_ph_lat = [ref_ph_lat; latt];
    ref_ph_nht = [ref_ph_nht; nhtt];
    ref_ph_range_bias_corr = [ref_ph_range_bias_corr; ph_rangbiascorr];
    ref_ph_ref_azimuth = [ref_ph_ref_azimuth; ph_refazimuth];
    ref_ph_ref_elev = [ref_ph_ref_elev; ph_refelev];

end



% 结果字段存入结构图中
gtx_atm_data = struct('Ph_UTC_Time',Ph_UTC_Time,'Ref_Ph_Lat',Ref_Ph_Lat,...,
    'Ref_Ph_Lon',Ref_Ph_Lon,'Ref_Ph_Ht',Ref_Ph_Ht,...,
    'Ref_PD_total',Ref_PD_total,'Ref_Dt_time',Ref_Dt_time,'Ref_surf_type',Ref_surf_type,...,
    'ref_ph_range_bias_corr',ref_ph_range_bias_corr,'ref_ph_ref_azimuth',ref_ph_ref_azimuth,'ref_ph_ref_elev',ref_ph_ref_elev);

disp('>> Run read_atl03_gtx_atm Successfully !')

end


