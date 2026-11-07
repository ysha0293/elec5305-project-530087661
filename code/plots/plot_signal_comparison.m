function plot_signal_comparison(xClean,xPert,fs,plotTitle,outFile,C)
%PLOT_SIGNAL_COMPARISON Waveform, spectrum, spectrogram and MFCC comparison.

xClean=double(xClean(:)); xPert=double(xPert(:));
maxSamples=min(numel(xClean),round(2*fs));
t=(0:maxSamples-1)'/fs;

N=max(2048,2^nextpow2(maxSamples));
f=(0:floor(N/2))'*fs/N;
Sc=abs(fft(xClean(1:maxSamples),N)); Sc=20*log10(Sc(1:numel(f))+eps);
Sp=abs(fft(xPert(1:maxSamples),N)); Sp=20*log10(Sp(1:numel(f))+eps);

win=round(0.025*fs); hop=round(0.010*fs); overlap=win-hop;
[~,fc,tc,pc]=spectrogram(xClean,hann(win,'periodic'),overlap,1024,fs,'yaxis');
[~,fp,tp,pp]=spectrogram(xPert,hann(win,'periodic'),overlap,1024,fs,'yaxis');

Mc=mfcc(xClean,fs,"Window",hann(win,"periodic"),"OverlapLength",overlap,"NumCoeffs",C.mfcc.numCoeffs);
Mp=mfcc(xPert,fs,"Window",hann(win,"periodic"),"OverlapLength",overlap,"NumCoeffs",C.mfcc.numCoeffs);

fig=figure('Visible','off','Position',[100 100 1400 750]);
tiledlayout(2,4,'Padding','compact','TileSpacing','compact');

nexttile; plot(t,xClean(1:maxSamples)); xlabel('Time (s)'); ylabel('Amplitude'); title('Clean waveform'); grid on;
nexttile; plot(f,Sc); xlim([0 fs/2]); xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)'); title('Clean spectrum'); grid on;
nexttile; imagesc(tc,fc,10*log10(pc+eps)); axis xy; ylim([0 fs/2]); xlabel('Time (s)'); ylabel('Hz'); title('Clean spectrogram'); colorbar;
nexttile; imagesc(Mc'); axis xy; xlabel('Frame'); ylabel('MFCC coefficient'); title('Clean MFCC'); colorbar;

nexttile; plot(t,xPert(1:maxSamples)); xlabel('Time (s)'); ylabel('Amplitude'); title('Perturbed waveform'); grid on;
nexttile; plot(f,Sp); xlim([0 fs/2]); xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)'); title('Perturbed spectrum'); grid on;
nexttile; imagesc(tp,fp,10*log10(pp+eps)); axis xy; ylim([0 fs/2]); xlabel('Time (s)'); ylabel('Hz'); title('Perturbed spectrogram'); colorbar;
nexttile; imagesc(Mp'); axis xy; xlabel('Frame'); ylabel('MFCC coefficient'); title('Perturbed MFCC'); colorbar;

sgtitle(plotTitle,'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',220);
close(fig);
end
