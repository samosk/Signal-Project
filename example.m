%% STEG 1: LÄS IN LJUD OCH BERÄKNA STFT

[x, Fs] = audioread('music/creep.mp3');
x = x(:, 1); % Ta endast vänster kanal

window = ones(2048,1);
[X, w, t] = stft(x, Fs, "Window", window);

%% STEG 2: GÖR 2DFT PÅ MAGNITUDEN AV STFT

X_tilde = fft2(abs(X));

%spectrogram(x, length(window), length(window)*0.5, 512, Fs, 'yaxis');

%% STEG 3: GÖR PEAK-PICKING I 2DFT
%          -> GER BAKGRUNDSMASK

% Patch dimensions
patch_rows = 1;
patch_cols = 15;
pad_rows = floor(patch_rows / 2);
pad_cols = floor(patch_cols / 2);

X_tilde_pad = padarray(abs(X_tilde), [pad_rows, pad_cols], 'symmetric', 'both');

% Extract all valid patches as columns using im2col
patches = im2col(X_tilde_pad, [patch_rows, patch_cols], 'sliding');

% Compute alpha for every (s_c, r_c) position
alpha_vals = max(patches) - min(patches);

% Reshape into a 2D matrix aligned with valid center positions
[M, N] = size(X_tilde);
alpha_map = reshape(alpha_vals, M, N);

center_idx = ceil((patch_rows * patch_cols) / 2);
center_vals = patches(center_idx, :);
is_local_max = reshape(center_vals == max(patches), M, N);

gamma = std2(abs(X_tilde));
mask_bg = (alpha_map > gamma) | is_local_max;
% A point is included in the mask if it has high local contrast
% OR if it's the dominant peak in its neighbourhood

%% STEG 4: INVERTERA BAKGRUNDSMASK
%          -> GER FÖRGRUNDSMASK

mask_fg = 1 - mask_bg;

%% STEG 5: Multiplicera mask med 2DFT och gör I2DFT
%          -> GER STFT FÖR BAKGRUND OCH FÖRGRUND

X_mag_bg = ifft2(mask_bg .* X_tilde); % TODO: try 'symmetric'
X_mag_fg = ifft2(mask_fg .* X_tilde);

%% STEG 6: GÖR ISTFT PÅ STFT FÖR BAKGRUND OCH FÖRGRUND
%          -> Ger ljudsignaler för bakgrund och förgrund

phase_X = angle(X);  % original phase

% Reconstruct complex STFT by combining with original phase
X_bg = X_mag_bg .* exp(1j * phase_X); % j is the imaginary unit
X_fg = X_mag_fg .* exp(1j * phase_X);

x_bg = real(istft(X_bg, Fs, "Window", window)); % TODO: try 'ConjugateSymmetric', true
x_fg = real(istft(X_fg, Fs, "Window", window));

audiowrite("background.mp3", x_bg, Fs);
audiowrite("foreground.mp3", x_fg, Fs);

%% VISUALISERING

figure;
subplot(3, 3, [1 2]);
imagesc(abs(fftshift(X_tilde)));
title("Mixture spectrogram");

subplot(3, 3, 6);
mesh(abs(X_mag_bg));
title("Background 2DFT");

subplot(3, 3, 9);
mesh(abs(X_mag_fg));
title("Foreground 2DFT");

%subplot(3, 3, 2);
%spectrogram(sound, length(window), length(window)*0.5, 512, Fs, 'yaxis');

