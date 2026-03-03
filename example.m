%% STEP 1: READ AUDIO AND CALCULATE STFT

[x, Fs] = audioread('music/creep.mp3');
x = x(:, 1); % Use only left channel

window = ones(2048,1);
[X, w, t] = stft(x, Fs, "Window", window);

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
mask_bg = (alpha > gamma) | center_is_max;

%% STEP 4: INVERT BACKGROUND MASK
%          -> FOREGROUND MASK

mask_fg = 1 - mask_bg;

%% STEG 5: APPLY MASK ON 2DFT AND CALCULATE I2DFT
%          -> STFT FOR BACKGROUND AND FOREGROUND

X_mag_bg = ifft2(mask_bg .* X_tilde);
X_mag_fg = ifft2(mask_fg .* X_tilde);

%% STEG 6: CALCULATE ISTFT OF STFT FOR BACKGROUND AND FOREGROUND
%          -> AUDIO SIGNALS FOR BACKGROUND AND FOREGROUND

phase_X = angle(X);

% Reconstruct complex STFT by combining with original phase
% (1i is the imaginary unit)
X_bg = X_mag_bg .* exp(1i * phase_X);
X_fg = X_mag_fg .* exp(1i * phase_X);

x_bg = real(istft(X_bg, Fs, "Window", window));
x_fg = real(istft(X_fg, Fs, "Window", window));

audiowrite("output/background.mp3", x_bg, Fs);
audiowrite("output/foreground.mp3", x_fg, Fs);

%% VISUALIZATION

tiny_number = 1e-7;

figure;
subplot(3, 3, [1 2]);
imagesc(t, w, 20 * log10(abs(X) + tiny_number));
title("Mixture spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 3);
imagesc(20 * log10(abs(fftshift(X_tilde))));
title("Mixture 2DFT");
xlabel("Rate");
ylabel("Scale");

subplot(3, 3, [4 5]);
imagesc(t, w, 20 * log10(abs(X_mag_bg) + tiny_number));
title("Background spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 6);
imagesc(mask_bg);
title("Background mask 2DFT");
xlabel("Rate");
ylabel("Scale");

subplot(3, 3, [7 8]);
imagesc(t, w, 20 * log10(abs(X_mag_fg) + tiny_number));
title("Foreground spectrogram");
xlabel("Time (s)");
ylabel("Frequency (Hz)");

subplot(3, 3, 9);
imagesc(mask_fg);
title("Foreground mask 2DFT");
xlabel("Rate");
ylabel("Scale");