[music, Fs] = audioread('music/creep.mp3');
if size(music,2) > 1, music = mean(music, 2); end
windowSize = 2048;

figure;

subplot(2,1,1);
spectrogram(music, windowSize, windowSize*0.5, 512, Fs, 'yaxis');
title('Overlap');

subplot(2,1,2);
spectrogram(music, windowSize, 0, 512, Fs, 'yaxis');
title('NO Overlap');

