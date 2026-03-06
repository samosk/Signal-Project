%% PARAMETERS

% STFT parameters
fft_points        = 2048;
fft_window        = hann(fft_points);
fft_overlap_ratio = 0.75;

% Neighborhood size for peak-picking
nh_size           = [1 15];

%% STEP 1: READ AUDIO AND CALCULATE STFT (T -> TF DOMAIN)

[x, Fs] = audioread('music/creep.mp3');
x = x(:, 1); % Use only left channel

noverlap = fft_points * fft_overlap_ratio;
[X, w, t] = stft(x, Fs, "Window", fft_window, ...
    "OverlapLength", noverlap, "FrequencyRange", "onesided");

%% STEP 2: CALCULATE 2DFT OF STFT MAGNITUDE (TF -> SR DOMAIN)

X_tilde = fft2(abs(X));

%% STEP 3: CREATE MASKS BY PEAK-PICKING (SR DOMAIN)

% Create two matrices of the same size as X_tilde, where each element is
% the max or min of the neighborhood centered around that element
domain = ones(nh_size(1), nh_size(2));
local_max = ordfilt2(abs(X_tilde), nh_size(1) * nh_size(2), domain);
local_min = ordfilt2(abs(X_tilde), 1, domain);

contrast = local_max - local_min;
center_is_max = abs(X_tilde) == local_max;

% A point is included in the background mask if it has high local contrast
% and is the dominant peak in its neighborhood
contrast_threshold = std2(abs(X_tilde));
mask_bg_sr = (contrast > contrast_threshold) & center_is_max;

% Calculate foreground mask
mask_fg_sr = 1 - mask_bg_sr;

%% STEP 4: APPLY MASKS AND INVERSE TRANSFORM (SR -> TF DOMAIN)

X_mag_bg = real(ifft2(mask_bg_sr .* X_tilde));
X_mag_fg = real(ifft2(mask_fg_sr .* X_tilde));

%% STEP 5: RECONSTRUCT SEPARATED AUDIO SIGNALS (TF -> T DOMAIN)

% Create corresponding binary masks in time-frequency domain
mask_bg_tf = abs(X_mag_bg) > abs(X_mag_fg);
mask_fg_tf = ~mask_bg_tf;

% Apply masks to original complex STFT (not only magnitude)
X_bg = mask_bg_tf .* X;
X_fg = mask_fg_tf .* X;

% Reconstruct audio signals
x_bg = real(istft(X_bg, Fs, "Window", fft_window, ...
    "OverlapLength", noverlap, "FrequencyRange", "onesided"));
x_fg = real(istft(X_fg, Fs, "Window", fft_window, ...
    "OverlapLength", noverlap, "FrequencyRange", "onesided"));

audiowrite("output/background.mp3", x_bg, Fs);
audiowrite("output/foreground.mp3", x_fg, Fs);

%% VISUALIZATION

tiny_number = 1e-7; % Added to avoid log(0) later
clim_max = max(20 * log10(abs(X(:)) + tiny_number) + tiny_number);

figure; subplot(3, 3, [1 2]);
imagesc(t, w, 20 * log10(abs(X) + tiny_number));
axis xy; colorbar; clim([clim_max - 80, clim_max]);
title("Mixture spectrogram");
xlabel("Time (s)"); ylabel("Frequency (Hz)");

subplot(3, 3, 3);
imagesc(20 * log10(abs(fftshift(X_tilde))));
colorbar;
title("Mixture 2DFT");
xlabel("Rate (cycles/s)"); ylabel("Scale (cycles/Hz)");

subplot(3, 3, [4 5]);
imagesc(t, w, 20 * log10(abs(X_mag_bg) + tiny_number));
axis xy; colorbar; clim([clim_max - 80, clim_max]);
title("Background spectrogram");
xlabel("Time (s)"); ylabel("Frequency (Hz)");

subplot(3, 3, 6);
imagesc(fftshift(mask_bg_sr));
colorbar;
title("Background mask 2DFT");
xlabel("Rate (cycles/s)"); ylabel("Scale (cycles/Hz)");

subplot(3, 3, [7 8]);
imagesc(t, w, 20 * log10(abs(X_mag_fg) + tiny_number));
axis xy; colorbar; clim([clim_max - 80, clim_max]);
title("Foreground spectrogram");
xlabel("Time (s)"); ylabel("Frequency (Hz)");

subplot(3, 3, 9);
imagesc(fftshift(mask_fg_sr));
colorbar;
title("Foreground mask 2DFT");
xlabel("Rate (cycles/s)"); ylabel("Scale (cycles/Hz)");
