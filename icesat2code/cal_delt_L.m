function delt_L_2 = cal_delt_L(N, H)
% 计算大气延迟
site_size = size(N,1);
time_size = size(N,4);
delt_L_1 = zeros(site_size, time_size);
delt_L_2 = zeros(site_size, time_size);
pbar = waitbar(0, 'cal delt L....');
for i = 1:time_size
    for j = 1:site_size
        % 获取该点在不同高度层的折射率和高度
        % 检查高度剖面的顺序
        N_profile = squeeze(N(j, 1, :, i));  % 提取折射率剖面
        h_profile = squeeze(H(j, 1, :, i));  % 提取高度剖面
        id = ~isnan(N_profile);
        h_profile = h_profile(id);
        N_profile = N_profile(id);
        % 对高度层积分，计算大气延迟改正值
        % 积分方法1
        % delt_L_1(j, i) = trapz(h_profile,N_profile);
        dL = zeros(length(N_profile),1);
        % 积分方法2
        for k = 1 : length(N_profile)-1
            dL(k,1) = sum(h_profile(k)-h_profile(k+1))*(N_profile(k)+N_profile(k+1))/2;%梯型
        end
        delt_L_2(j,i) = sum(dL);
    end
    mesg = ['共' num2str(time_size) '层,第' num2str(i) '个'];
    waitbar( i/time_size, pbar, mesg );
end
close(pbar)
end
