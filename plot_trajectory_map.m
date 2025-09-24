
function [] = plot_trajectory_map(Ref_Ph_Lon,Ref_Ph_Lat,Ref_PD_total,fileout)

% Mapping of trajectories

figureHandle = figure;
m_proj('miller','lon',[-180,180],'lat',[-90,90]);
m_coast('color',[0 .6 0]);

hold on
m_scatter(Ref_Ph_Lon, Ref_Ph_Lat, 5, Ref_PD_total, 'filled');
% m_line(ph_lon, ph_lat, 'linewi', 2, 'color', 'b');
m_grid('linestyle', 'none', 'box', 'fancy', 'tickdir', 'out');
m_northarrow(-150, 0, 30, 'type', 4, 'linewi', .5);


h = colorbar('east','FontSize',11,'AxisLocation','out');
h.Label.String = 'ICESat-2 atmospheric delay(m)';
h.Location = 'eastoutside'; 


% colormap('parula');  % Change 'parula' to the desired colormap
map = colormap(nclCM(232)); 
map = flipud(map);

print(figureHandle,[fileout,'atl03_trajectory.png'],'-r600','-dpng');

end

