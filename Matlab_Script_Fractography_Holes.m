% MATLAB script to analyze dimple diameter, aspect ratio, and spacing in fractography images
clc;
clear;

% Step 1: Load the fractography image
[filename, pathname] = uigetfile({'*.jpg;*.png;*.tif'}, 'Select the Fractography Image');
if isequal(filename, 0)
    disp('User selected Cancel');
    return;
else
    img = imread(fullfile(pathname, filename));
end

% Step 2: Convert the image to grayscale if it's in color or has multiple channels
if size(img, 3) > 1
    img_gray = rgb2gray(img(:,:,1:3)); % Convert the first three channels to grayscale
else
    img_gray = img; % If already grayscale, use it as is
end

% Step 3: Enhance contrast using adaptive histogram equalization (optional)
img_enhanced = adapthisteq(img_gray);

% Step 4: Apply a Gaussian filter to smooth the image and reduce noise
img_filtered = imgaussfilt(img_enhanced, 2); % Sigma 2 can be adjusted

% Step 5: Perform adaptive thresholding to binarize the image (detect dark dimples)
bw = imbinarize(img_filtered, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.4);

% Step 6: Invert the binary image so that dimples are white (objects) and the rest is black (background)
bw_inverted = ~bw;

% Step 7: Fill small holes inside detected areas to improve dimple detection
bw_filled = imfill(bw_inverted, 'holes');

% Step 8: Remove small objects to clean up the binary image
bw_clean = bwareaopen(bw_filled, 50); % Adjust size threshold as needed

% Step 9: Detect the boundaries of the dimples
[B, L] = bwboundaries(bw_clean, 'noholes'); % Labeled image L and boundaries B

% Step 10: Measure properties of detected objects (dimples), including area and aspect ratio
dimple_props = regionprops(L, 'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength');

% Step 11: Calculate scale factor and dimple diameters
scale_bar_pixels = input('Enter the length of the scale bar in pixels: ');
scale_bar_length = input('Enter the actual scale bar length in micrometers (µm): ');
scale_factor = scale_bar_length / scale_bar_pixels;

dimple_diameters = zeros(length(dimple_props), 1);  % Store dimple diameters in µm
aspect_ratios = zeros(length(dimple_props), 1); % Store aspect ratios
centroids = reshape([dimple_props.Centroid], 2, [])'; % Centroid coordinates for spacing calculations

for i = 1:length(dimple_props)
    area = dimple_props(i).Area * (scale_factor^2);  % Convert area to µm²
    dimple_diameters(i) = 2 * sqrt(area / pi);  % Convert area to diameter in µm
    aspect_ratios(i) = dimple_props(i).MajorAxisLength / dimple_props(i).MinorAxisLength; % Aspect ratio
end

% Step 12: Display results
fprintf('Number of detected dimples: %d\n', length(dimple_props));

% Display the dimple diameters and aspect ratios
for i = 1:length(dimple_props)
    fprintf('Dimple %d: Diameter = %.2f µm, Aspect Ratio = %.2f\n', i, dimple_diameters(i), aspect_ratios(i));
end

% Step 13: Calculate mean dimple diameter, mean aspect ratio, and mean spacing
mean_dimple_diameter = mean(dimple_diameters);
mean_aspect_ratio = mean(aspect_ratios);
fprintf('Mean dimple diameter: %.2f µm\n', mean_dimple_diameter);
fprintf('Mean aspect ratio: %.2f\n', mean_aspect_ratio);

% Mean spacing: Calculate pairwise distances between dimple centroids
if length(centroids) > 1
    distances = pdist(centroids); % Pairwise distances between centroids
    mean_spacing = mean(distances);
    fprintf('Mean dimple spacing: %.2f µm\n', mean_spacing);
else
    fprintf('Not enough dimples to calculate spacing.\n');
end

% Step 14: Plotting mean dimple diameter and mean aspect ratio in one plot
figure;
bar([mean_dimple_diameter, mean_aspect_ratio]);
set(gca, 'XTickLabel', {'Mean Dimple Diameter (µm)', 'Mean Aspect Ratio'});
ylabel('Values');
title('Mean Dimple Diameter and Mean Aspect Ratio');

% Step 15: Plotting distribution of dimple diameters and aspect ratios in another plot and saving as PDF
figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.5]); % Larger, landscape figure

t = tiledlayout(1, 2, 'Padding', 'loose', 'TileSpacing', 'tight'); % Adjust spacing to avoid cutoff

% First histogram: Dimple diameters
nexttile;
histogram(dimple_diameters, 20, 'FaceColor', 'c', 'EdgeColor', 'b'); % Colorful histogram
xlabel('Dimple Diameter (µm)');
ylabel('Frequency');
title('Distribution of Dimple Diameters');
box on;

% Second histogram: Aspect ratios
nexttile;
histogram(aspect_ratios, 20, 'FaceColor', 'm', 'EdgeColor', 'r'); % Colorful histogram
xlabel('Aspect Ratio');
ylabel('Frequency');
title('Distribution of Aspect Ratios');
box on;

% Set the overall title with adjusted position to avoid cutoff
title(t, 'EXT', 'FontSize', 14);

% Save the distribution plot as a landscape PDF with 400 dpi resolution
set(gcf, 'PaperOrientation', 'landscape'); % Set orientation to landscape
set(gcf, 'PaperPositionMode', 'auto'); % Ensure it fits the page
print(gcf, 'dimple_distribution_plots.pdf', '-dpdf', '-fillpage', '-r400'); % Save with 400 dpi

% Step 16: Display the original image with dimple outlines
figure;
if size(img, 3) == 3
    % Display the RGB image
    imshow(img);
else
    % Display the grayscale image
    imshow(img_gray);
end

hold on;

% Plot the dimple boundaries on top of the image
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 2);
end

title('Detected Dimples with Outlines');
hold off;
