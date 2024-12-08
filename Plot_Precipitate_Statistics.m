clear all;
clc;

% Load ECAP and ECAP-A images
imageECAP = imread('ECAP.tif');
imageECAP_A = imread('ECAP_A.tif');

% Check the size of the image and extract the first channel/plane if needed
if ~ismatrix(imageECAP)
    imageECAP = imageECAP(:, :, 1);  % Extract the first channel/plane
end

if ~ismatrix(imageECAP_A)
    imageECAP_A = imageECAP_A(:, :, 1);  % Extract the first channel/plane
end

% Convert to 8-bit grayscale for thresholding
imageECAP = im2uint8(mat2gray(imageECAP));
imageECAP_A = im2uint8(mat2gray(imageECAP_A));

% Apply manual thresholding for ECAP-A
manual_threshold_ECAP_A = 0.35;  % Adjust based on the histogram
BW_ECAP_A = imbinarize(imageECAP_A, manual_threshold_ECAP_A);
BW_ECAP_A = bwareaopen(BW_ECAP_A, 1);  % Clean up small objects for ECAP-A

% Apply Otsu's global thresholding for ECAP
threshold_ECAP = graythresh(imageECAP);  % Otsu's method to get threshold
BW_ECAP = imbinarize(imageECAP, threshold_ECAP);  % Apply Otsu's threshold
BW_ECAP = bwareaopen(BW_ECAP, 1);  % Clean up small objects for ECAP

% Measure properties for ECAP and ECAP-A (Area, Aspect Ratio, Centroid)
props_ECAP = regionprops(BW_ECAP, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');
props_ECAP_A = regionprops(BW_ECAP_A, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');

% Compute areas
areas_ECAP = [props_ECAP.Area];
areas_ECAP_A = [props_ECAP_A.Area];

% Compute aspect ratio (MajorAxisLength / MinorAxisLength)
aspect_ratios_ECAP = [props_ECAP.MajorAxisLength] ./ [props_ECAP.MinorAxisLength];
aspect_ratios_ECAP_A = [props_ECAP_A.MajorAxisLength] ./ [props_ECAP_A.MinorAxisLength];

% Extract centroids for ECAP and ECAP-A
centroids_ECAP = reshape([props_ECAP.Centroid], 2, []).';
centroids_ECAP_A = reshape([props_ECAP_A.Centroid], 2, []).';

% Compute nearest neighbor distances for ECAP and ECAP-A
distances_ECAP = pdist2(centroids_ECAP, centroids_ECAP);
distances_ECAP(distances_ECAP == 0) = Inf;  % Ignore self-distance
nearest_neighbor_ECAP = min(distances_ECAP, [], 2);  % Get nearest distance for each precipitate

distances_ECAP_A = pdist2(centroids_ECAP_A, centroids_ECAP_A);
distances_ECAP_A(distances_ECAP_A == 0) = Inf;
nearest_neighbor_ECAP_A = min(distances_ECAP_A, [], 2);

% Calculate the area percentages for ECAP and ECAP-A
total_area_ECAP = numel(BW_ECAP);  % Total number of pixels in the ECAP image
total_area_ECAP_A = numel(BW_ECAP_A);  % Total number of pixels in the ECAP-A image

precipitate_area_ECAP = sum(BW_ECAP(:));  % Sum of pixels that are precipitates in ECAP
precipitate_area_ECAP_A = sum(BW_ECAP_A(:));  % Sum of pixels that are precipitates in ECAP-A

precipitate_area_percent_ECAP = (precipitate_area_ECAP / total_area_ECAP) * 100;  % Area % in ECAP
precipitate_area_percent_ECAP_A = (precipitate_area_ECAP_A / total_area_ECAP_A) * 100;  % Area % in ECAP-A

% Calculate average values for ECAP
avg_size_ECAP = mean(areas_ECAP);
avg_spacing_ECAP = mean(nearest_neighbor_ECAP);
avg_aspect_ratio_ECAP = mean(aspect_ratios_ECAP);

% Calculate average values for ECAP-A
avg_size_ECAP_A = mean(areas_ECAP_A);
avg_spacing_ECAP_A = mean(nearest_neighbor_ECAP_A);
avg_aspect_ratio_ECAP_A = mean(aspect_ratios_ECAP_A);

% Define colors for ECAP and ECAP-A
color_ECAP = [0, 0.5, 1];  % Bright blue for ECAP
color_ECAP_A = [1, 0.5, 0];  % Bright red for ECAP-A
errorbar_color = [0, 0, 0];  % Black for error bars

% Calculate average values and standard deviations for ECAP
avg_size_ECAP = mean(areas_ECAP);
avg_spacing_ECAP = mean(nearest_neighbor_ECAP);
avg_aspect_ratio_ECAP = mean(aspect_ratios_ECAP);
std_aspect_ratio_ECAP = std(aspect_ratios_ECAP);  % Standard deviation

% Calculate average values and standard deviations for ECAP-A
avg_size_ECAP_A = mean(areas_ECAP_A);
avg_spacing_ECAP_A = mean(nearest_neighbor_ECAP_A);
avg_aspect_ratio_ECAP_A = mean(aspect_ratios_ECAP_A);
std_aspect_ratio_ECAP_A = std(aspect_ratios_ECAP_A);  % Standard deviation

% Create a figure for the comparisons
figure;

% Modify the layout to have 2 rows and 2 columns for 4 subplots
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'loose');

% Subplot 1: Average Precipitate Size
nexttile;
b = bar([avg_size_ECAP, avg_size_ECAP_A]);
b.FaceColor = 'flat';
b.CData(1,:) = color_ECAP;  
b.CData(2,:) = color_ECAP_A;  
set(gca, 'XTick', [1, 2], 'XTickLabel', {'ECAP', 'ECAP-A'});  
ylabel('Average Precipitate Size (µm²)', 'FontSize', 12);
title('Average Precipitate Size', 'FontSize', 14);
text(0.1, 0.95, 'a', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');
box on;  
%grid on;  

% Subplot 2: Average Precipitate Spacing
nexttile;
b = bar([avg_spacing_ECAP, avg_spacing_ECAP_A]);
b.FaceColor = 'flat';
b.CData(1,:) = color_ECAP;  
b.CData(2,:) = color_ECAP_A;  
set(gca, 'XTick', [1, 2], 'XTickLabel', {'ECAP', 'ECAP-A'});  
ylabel('Average Precipitate Spacing (µm)', 'FontSize', 12);
title('Average Precipitate Spacing', 'FontSize', 14);
text(0.1, 0.95, 'b', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');
box on;  
%grid on;  

% Subplot 3: Precipitate Area Percentage
nexttile;
b = bar([precipitate_area_percent_ECAP, precipitate_area_percent_ECAP_A]);
b.FaceColor = 'flat';
b.CData(1,:) = color_ECAP;  
b.CData(2,:) = color_ECAP_A;  
set(gca, 'XTick', [1, 2], 'XTickLabel', {'ECAP', 'ECAP-A'});  
ylabel('Precipitate Area (%)', 'FontSize', 12);
title('Precipitate Area Percentage', 'FontSize', 14);
text(0.1, 0.95, 'c', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');
box on;  
%grid on;

% Subplot 4: Aspect Ratio of Precipitates with Standard Deviation
nexttile;
hold on;
b = bar([avg_aspect_ratio_ECAP, avg_aspect_ratio_ECAP_A]);
b.FaceColor = 'flat';
b.CData(1,:) = color_ECAP;  % Assign corrected color for ECAP
b.CData(2,:) = color_ECAP_A;  % Assign corrected color for ECAP-A
errorbar([1, 2], [avg_aspect_ratio_ECAP, avg_aspect_ratio_ECAP_A], ...
         [std_aspect_ratio_ECAP, std_aspect_ratio_ECAP_A], 'k', 'linestyle', 'none', 'Color', errorbar_color);  % Black error bars
set(gca, 'XTick', [1, 2], 'XTickLabel', {'ECAP', 'ECAP-A'});  % Explicitly set correct x-tick labels
ylabel('Aspect Ratio');
title('Aspect Ratio of Precipitates');
ylim([0, 3.5]);  % Adjust y-axis limits to ensure the bars fill the frame
text(0.1, 0.95, 'd', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');
box on;  % Ensure the box frame is on for the subplot
hold off;

% Adjust figure settings and save
set(gcf, 'Position', [100, 100, 1200, 800]);
print(gcf, 'improved_comparison_plot', '-dpdf', '-r900', '-bestfit');
