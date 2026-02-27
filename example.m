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

local_max = ordfilt2(abs(X_tilde), patch_rows*patch_cols, ones(patch_rows, patch_cols));
local_min = ordfilt2(abs(X_tilde), 1, ones(patch_rows, patch_cols));
alpha = local_max - local_min;
center_is_max = abs(X_tilde) == local_max;

gamma = std2(abs(X_tilde));
% A point is included in the mask if it has high local contrast
% OR if it's the dominant peak in its neighbourhood
mask_bg = (alpha > gamma) | center_is_max;

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
x_fg = real(istft(X_fg, Fs, "Window", window)); % instead of real()

audiowrite("background.mp3", x_bg, Fs);
audiowrite("foreground.mp3", x_fg, Fs);

%% VISUALISERING

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

subplot(3, 3, 6);
imagesc(20 * log10(abs(X_mag_bg) + tiny_number));
title("Background 2DFT");
xlabel("Rate");
ylabel("Scale");

subplot(3, 3, 9);
imagesc(20 * log10(abs(X_mag_fg) + tiny_number));
title("Foreground 2DFT");
xlabel("Rate");
ylabel("Scale");

%subplot(3, 3, 2);
%spectrogram(sound, length(window), length(window)*0.5, 512, Fs, 'yaxis');

