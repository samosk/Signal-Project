%% STEP 1: READ AUDIO AND CALCULATE STFT

[x, Fs] = audioread('music/creep.mp3');
x = x(:, 1); % Use only left channel

window = hann(2048);
overlap = 1536; % 75% overlap
[X, w, t] = stft(x, Fs, "Window", window, "OverlapLength", overlap, "FrequencyRange", "onesided");

%% STEP 2: CALCULATE 2DFT OF STFT MAGNITUDE

X_tilde = fft2(abs(X));

%% STEG 3: DO PEAK-PICKING IN 2DFT
%          -> BACKGROUND MASK

% Neighborhood dimensions
patch_rows = 1;
patch_cols = 15;

% Create two matrices of the same size as X_tilde, where each element is
% the max or min of the neighborhood centered around that element
local_max = ordfilt2(abs(X_tilde), patch_rows*patch_cols, ones(patch_rows, patch_cols));
local_min = ordfilt2(abs(X_tilde), 1, ones(patch_rows, patch_cols));

alpha = local_max - local_min;
center_is_max = abs(X_tilde) == local_max;

gamma = std2(abs(X_tilde));
% A point is included in the mask if it has high local contrast
% OR if it's the dominant peak in its neighborhood
mask_bg = (alpha > gamma) & center_is_max;

%% STEP 4: INVERT BACKGROUND MASK
%          -> FOREGROUND MASK

mask_fg = 1 - mask_bg;

%% STEG 5: APPLY MASK ON 2DFT AND CALCULATE I2DFT
%          -> STFT FOR BACKGROUND AND FOREGROUND

X_mag_bg = real(ifft2(mask_bg .* X_tilde));
X_mag_fg = real(ifft2(mask_fg .* X_tilde));

%% STEG 6: CALCULATE ISTFT OF STFT FOR BACKGROUND AND FOREGROUND
%          -> AUDIO SIGNALS FOR BACKGROUND AND FOREGROUND

% Convert masks to time-frequency domain
mask_tf_bg = abs(X_mag_bg) > abs(X_mag_fg);
mask_tf_fg = ~mask_tf_bg;

% Apply to original complex STFT
X_bg = mask_tf_bg .* X;
X_fg = mask_tf_fg .* X;

x_bg = real(istft(X_bg, Fs, "Window", window, "OverlapLength", overlap, "FrequencyRange", "onesided"));
x_fg = real(istft(X_fg, Fs, "Window", window, "OverlapLength", overlap, "FrequencyRange", "onesided"));

audiowrite("output/background.mp3", x_bg, Fs);
audiowrite("output/foreground.mp3", x_fg, Fs);

%% VISUALIZATION

tiny_number = 1e-7;
clim_max = max(20 * log10(abs(X(:)) + tiny_number) + tiny_number);

figure;
subplot(3, 3, [1 2]);
imagesc(t, w, 20 * log10(abs(X) + tiny_number));
axis xy;
colorbar;
clim([clim_max - 80, clim_max]);
title("Mixture spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 3);
imagesc(20 * log10(abs(fftshift(X_tilde))));
colorbar;
title("Mixture 2DFT");
xlabel("Rate");
ylabel("Scale");

subplot(3, 3, [4 5]);
imagesc(t, w, 20 * log10(abs(X_mag_bg) + tiny_number));
axis xy;
colorbar;
clim([clim_max - 80, clim_max]);
title("Background spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 6);
imagesc(fftshift(mask_bg));
colorbar;
title("Background mask 2DFT");
xlabel("Rate");
ylabel("Scale");

subplot(3, 3, [7 8]);
imagesc(t, w, 20 * log10(abs(X_mag_fg) + tiny_number));
axis xy;
colorbar;
clim([clim_max - 80, clim_max]);
title("Foreground spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 9);
imagesc(fftshift(mask_fg));
colorbar;
title("Foreground mask 2DFT");
xlabel("Rate");
ylabel("Scale");