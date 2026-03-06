%% PLOT SPECTROGRAMS FOR MULTIPLE AUDIO FILES

figure;

subplot(3, 2, 1);
plot_spectrogram("music/creep.mp3", "Creep (Rock)");

subplot(3, 2, 2);
plot_spectrogram("music/wonderwall.mp3", "Wonderwall (Rock)");

subplot(3, 2, 3);
plot_spectrogram("music/five_more_hours.mp3", "Five More Hours (EDM)");

subplot(3, 2, 4);
plot_spectrogram("music/wake_me_up.mp3", "Wake Me Up (EDM)");

subplot(3, 2, 5);
plot_spectrogram("music/feeling_good.mp3", "Feeling Good (Jazz)");

subplot(3, 2, 6);
plot_spectrogram("music/what_a_wonderful_world.mp3", "What a Wonderful World (Jazz)");

%% LOCAL FUNCTION
function plot_spectrogram(filename, figtitle)
    % STFT parameters
    fft_points        = 2048;
    fft_window        = hann(fft_points);
    fft_overlap_ratio = 0.75;

    [x, Fs] = audioread(filename);
    x = x(:, 1); % Use only left channel
    noverlap = fft_points * fft_overlap_ratio;

    [X, w, t] = stft(x, Fs, "Window", fft_window, ...
        "OverlapLength", noverlap, "FrequencyRange", "onesided");

    tiny_number = 1e-7;
    X_dB = 20 * log10(abs(X) + tiny_number);
    clim_max = max(X_dB(:));

    imagesc(t, w, X_dB);
    axis xy; colorbar; clim([clim_max - 80, clim_max]);
    title(figtitle);
    xlabel("Time (s)"); ylabel("Frequency (Hz)");
end