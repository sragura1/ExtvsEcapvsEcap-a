clearvars;
clc;

% Define the number of images for both ECAP and ECAP-A
num_images = 3;

% Initialize empty arrays to store combined statistics for ECAP and ECAP-A
areas_ECAP_combined = [];
aspect_ratios_ECAP_combined = [];
centroids_ECAP_combined = [];
nearest_neighbor_ECAP_combined = [];
precipitate_area_ECAP_combined = 0;
total_area_ECAP_combined = 0;

areas_ECAP_A_combined = [];
aspect_ratios_ECAP_A_combined = [];
centroids_ECAP_A_combined = [];
nearest_neighbor_ECAP_A_combined = [];
precipitate_area_ECAP_A_combined = 0;
total_area_ECAP_A_combined = 0;

% Set a size limit to resize large images
max_image_size = [1024, 1024];  % Resize images larger than 1024x1024 pixels

% Loop through each of the three ECAP and ECAP-A images
for i = 1:num_images
    % Load the ECAP and ECAP-A images
    imageECAP = imread(['ECAP_' num2str(i) '.tif']);
    imageECAP_A = imread(['ECAP_A_' num2str(i) '.tif']);
    
    % Resize the images if they are too large
    if size(imageECAP, 1) > max_image_size(1) || size(imageECAP, 2) > max_image_size(2)
        imageECAP = imresize(imageECAP, max_image_size);
    end
    if size(imageECAP_A, 1) > max_image_size(1) || size(imageECAP_A, 2) > max_image_size(2)
        imageECAP_A = imresize(imageECAP_A, max_image_size);
    end
    
    % Ask the user to input the pixel per micron for ECAP and ECAP-A images
    scale_factor_ECAP = input(['Please enter the pixels per micron for the ECAP image ' num2str(i) ': ']);
    scale_factor_ECAP_A = input(['Please enter the pixels per micron for the ECAP-A image ' num2str(i) ': ']);
    
    % Ask the user to input the pixel length of the scale bars in each image
    scale_bar_pixels_ECAP = input(['Please enter the scale bar length in pixels for ECAP image ' num2str(i) ': ']);
    scale_bar_pixels_ECAP_A = input(['Please enter the scale bar length in pixels for ECAP-A image ' num2str(i) ': ']);
    
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
    BW_ECAP_A = bwareaopen(BW_ECAP_A, 10);  % Clean up small objects for ECAP-A

    % Apply Otsu's global thresholding for ECAP
    threshold_ECAP = graythresh(imageECAP);  % Otsu's method to get threshold
    BW_ECAP = imbinarize(imageECAP, threshold_ECAP);  % Apply Otsu's threshold
    BW_ECAP = bwareaopen(BW_ECAP, 10);  % Clean up small objects for ECAP

    % Measure properties for ECAP and ECAP-A (Area, Aspect Ratio, Centroid)
    props_ECAP = regionprops(BW_ECAP, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');
    props_ECAP_A = regionprops(BW_ECAP_A, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');

    % Ensure that arrays are concatenated correctly
    if ~isempty(props_ECAP)
        areas_ECAP_combined = [areas_ECAP_combined; [props_ECAP.Area]'];  % Concatenate areas
        aspect_ratios_ECAP_combined = [aspect_ratios_ECAP_combined; [props_ECAP.MajorAxisLength]' ./ [props_ECAP.MinorAxisLength]'];  % Concatenate aspect ratios
        centroids_ECAP_combined = [centroids_ECAP_combined; reshape([props_ECAP.Centroid], 2, []).'];  % Concatenate centroids
        precipitate_area_ECAP_combined = precipitate_area_ECAP_combined + sum(BW_ECAP(:));  % Sum of pixels that are precipitates in ECAP
        total_area_ECAP_combined = total_area_ECAP_combined + numel(BW_ECAP);  % Total number of pixels in the ECAP images combined
    end

    if ~isempty(props_ECAP_A)
        areas_ECAP_A_combined = [areas_ECAP_A_combined; [props_ECAP_A.Area]'];  % Concatenate areas
        aspect_ratios_ECAP_A_combined = [aspect_ratios_ECAP_A_combined; [props_ECAP_A.MajorAxisLength]' ./ [props_ECAP_A.MinorAxisLength]'];  % Concatenate aspect ratios
        centroids_ECAP_A_combined = [centroids_ECAP_A_combined; reshape([props_ECAP_A.Centroid], 2, []).'];  % Concatenate centroids
        precipitate_area_ECAP_A_combined = precipitate_area_ECAP_A_combined + sum(BW_ECAP_A(:));  % Sum of pixels that are precipitates in ECAP-A
        total_area_ECAP_A_combined = total_area_ECAP_A_combined + numel(BW_ECAP_A);  % Total number of pixels in the ECAP-A images combined
    end
end

% Compute nearest neighbor distances for combined ECAP and ECAP-A data
if ~isempty(centroids_ECAP_combined)
    distances_ECAP_combined = pdist2(centroids_ECAP_combined, centroids_ECAP_combined);
    distances_ECAP_combined(distances_ECAP_combined == 0) = Inf;  % Ignore self-distance
    nearest_neighbor_ECAP_combined = min(distances_ECAP_combined, [], 2);  % Get nearest distance for each precipitate
end

if ~isempty(centroids_ECAP_A_combined)
    distances_ECAP_A_combined = pdist2(centroids_ECAP_A_combined, centroids_ECAP_A_combined);
    distances_ECAP_A_combined(distances_ECAP_A_combined == 0) = Inf;
    nearest_neighbor_ECAP_A_combined = min(distances_ECAP_A_combined, [], 2);
end

% Calculate the area percentages for combined ECAP and ECAP-A
precipitate_area_percent_ECAP_combined = (precipitate_area_ECAP_combined / total_area_ECAP_combined) * 100;  % Area % in ECAP combined
precipitate_area_percent_ECAP_A_combined = (precipitate_area_ECAP_A_combined / total_area_ECAP_A_combined) * 100;  % Area % in ECAP-A combined

% Calculate average values for combined ECAP
avg_size_ECAP_combined = mean(areas_ECAP_combined);
avg_spacing_ECAP_combined = mean(nearest_neighbor_ECAP_combined);
avg_aspect_ratio_ECAP_combined = mean(aspect_ratios_ECAP_combined);

% Calculate average values for combined ECAP-A
avg_size_ECAP_A_combined = mean(areas_ECAP_A_combined);
avg_spacing_ECAP_A_combined = mean(nearest_neighbor_ECAP_A_combined);
avg_aspect_ratio_ECAP_A_combined = mean(aspect_ratios_ECAP_A_combined);

% Display the combined statistics
fprintf('\nCombined Statistics for ECAP:\n');
fprintf('Average Precipitate Size: %.2f µm²\n', avg_size_ECAP_combined);
fprintf('Average Precipitate Spacing: %.2f µm\n', avg_spacing_ECAP_combined);
fprintf('Aspect Ratio: %.2f\n', avg_aspect_ratio_ECAP_combined);
fprintf('Precipitate Area Percentage: %.2f%%\n', precipitate_area_percent_ECAP_combined);

fprintf('\nCombined Statistics for ECAP-A:\n');
fprintf('Average Precipitate Size: %.2f µm²\n', avg_size_ECAP_A_combined);
fprintf('Average Precipitate Spacing: %.2f µm\n', avg_spacing_ECAP_A_combined);
fprintf('Aspect Ratio: %.2f\n', avg_aspect_ratio_ECAP_A_combined);
fprintf('Precipitate Area Percentage: %.2f%%\n', precipitate_area_percent_ECAP_A_combined);
