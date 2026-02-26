function plot_spectrogram(filename, figtitle)
    [x, Fs] = audioread(filename);
    x = x(:, 1); % Take left channel

    window = 2048;
    spectrogram(x, window, 0.5*window, 128, Fs, "yaxis");
    title(figtitle);
end

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
