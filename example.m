[x, Fs] = audioread('music/creep.mp3');
x = x(:,1);
%Skapa spectrogram av ljudfil
window = ones(2048,1);
[X,w,t] = stft(x, Fs, "Window",window);
figure;

subplot(2,1,1);
%spectrogram(x, length(window), length(window)*0.5, 512, Fs, 'yaxis');
%Göra en 2DFT av spectrogrammet
X_tilde = fft2(X);
imagesc(abs(fftshift(X_tilde)));
%Gör Peak-Picking i vår 2DFT, ger oss en mask för bakgrund
% Patch dimensions
patch_rows = 1;
patch_cols = 15;
pad_rows = floor(patch_rows / 2);
pad_cols = floor(patch_cols / 2);

X_padded = padarray(abs(X_tilde), [pad_rows, pad_cols], 'symmetric', 'both');
% Extract all valid patches as columns using im2col
patches = im2col(X_padded, [patch_rows, patch_cols], 'sliding');

% Compute alpha for every (s_c, r_c) position
alpha_vals = max(patches) - min(patches);

% Reshape into a 2D matrix aligned with valid center positions
[M, N] = size(X_tilde);
alpha_map = reshape(alpha_vals, M, N);
threshold = 30000;
Mask_background = alpha_map > threshold;
%Ta fram förgrundsmasken genom att invertera bakgrundsmasken
Mask_foreground = 1 - Mask_background;
%Multiplicera bakgrundmasken med 2DFT och gör en I2DFT på det, då får vi
%spectrogrammet för bakgrunden
X_bg = ifft2(Mask_background .* X_tilde);
subplot(2,1,2);
mesh(abs(X_bg));
%upprepa för förgrunden, multiplicera mask med 2DFT och gör I2DFT

%Gör en ISTFT för både bakgrund- och förgrundspectrogram för att få ljudsignalerna
%sound = istft(X, Fs, "Window",window);
%subplot(2,1,2);

%spectrogram(sound, length(window), length(window)*0.5, 512, Fs, 'yaxis');
%audiowrite("test.mp3",sound,Fs);