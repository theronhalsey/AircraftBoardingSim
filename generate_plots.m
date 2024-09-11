n_sections = 4;
p_groupMin = [30 5]; % minimum percentage of passengers that are a pair, trio based in: https://www.statista.com/statistics/297694/type-of-companion-travelers-typically-traveled-with-worldwide/
B2F_results_file = "Results/B2F_" + num2str(n_sections) + "_" + num2str(p_groupMin(1)) + "_" + num2str(p_groupMin(2)) + ".csv";
F2B_results_file = "Results/F2B_" + num2str(n_sections) + "_" + num2str(p_groupMin(1)) + "_" + num2str(p_groupMin(2)) + ".csv";
SW_results_file = "Results/SOUTHWEST_" + num2str(n_sections) + "_" + num2str(p_groupMin(1)) + "_" + num2str(p_groupMin(2)) + ".csv";
lables = {"Back-to-Front", "Front-to-Back", "Southwest"};
hist_lables = {"B2F-Bins", "B2F-Curve","F2B-Bins", "F2B-Curve", "SW-Bins", "SW-Curve"};

B2F_results = readmatrix(B2F_results_file);
F2B_results = readmatrix(F2B_results_file);
SW_results = readmatrix(SW_results_file);

B2F_results = B2F_results(1:end-1,:);
F2B_results = F2B_results(1:end-1,:);
SW_results = SW_results(1:end-1,:);

min_waiting =  [min(B2F_results(:,1)) min(F2B_results(:,1)) min(SW_results(:,1))]; % min
max_waiting =  [max(B2F_results(:,1)) max(F2B_results(:,1)) max(SW_results(:,1))]; % max
mean_waiting = [mean(B2F_results(:,1)) mean(F2B_results(:,1)) mean(SW_results(:,1))]; % mean
std_waiting = [std(B2F_results(:,1)) std(F2B_results(:,1)) std(SW_results(:,1))]; % standard deviation


min_cycles = [min(B2F_results(:,2)) min(F2B_results(:,2)) min(SW_results(:,2))]; % min
max_cycles = [max(B2F_results(:,2)) max(F2B_results(:,2)) max(SW_results(:,2))]; % max
mean_cycles = [mean(B2F_results(:,2)) mean(F2B_results(:,2)) mean(SW_results(:,2))]; % mean
std_cycles = [std(B2F_results(:,2)) std(F2B_results(:,2)) std(SW_results(:,2))]; % standard deviation

a = figure();
boxchart([B2F_results(:,1) F2B_results(:,1) SW_results(:,1)]);
set(gca,'xticklabel', lables);
hold on
plot(mean_waiting,'-o',Color='r',MarkerFaceColor='red');
hold off
title("Times a Passenger is Stuck Waiting...");
saveas(a,'Figures/box_waiting.png');

b = figure();
boxchart([B2F_results(:,2) F2B_results(:,2) SW_results(:,2)]);
set(gca,'xticklabel', lables);
hold on
plot(mean_cycles,'-o',Color='r',MarkerFaceColor='red');
hold off
title("Cycles to Complete Boarding");
saveas(b,'Figures/box_cycles.png');

c = figure();
histfit(B2F_results(:,1));
hold on
histfit(F2B_results(:,1));
histfit(SW_results(:,1));
legend(hist_lables);
hold off
title("Times a Passenger is Stuck Waiting...");
saveas(c,'Figures/hist_waiting.png');

d = figure();
n_boxes = 70;
histfit(B2F_results(:,2),n_boxes);
hold on
histfit(F2B_results(:,2),n_boxes);
histfit(SW_results(:,2),n_boxes);
legend(hist_lables);
hold off
title("Cycles to Complete Boarding");
saveas(d,'Figures/hist_cycles.png');