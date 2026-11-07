function manifest = write_reproducibility_manifest()
%WRITE_REPRODUCIBILITY_MANIFEST Record environment, parameters and noise bank.

C=config(); P=project_paths();
manifest=struct();
manifest.generatedAt=string(datetime("now","Format","yyyy-MM-dd HH:mm:ss Z"));
manifest.matlabVersion=string(version);
manifest.matlabRelease=string(version("-release"));
manifest.computer=string(computer);
manifest.seed=C.seed;
manifest.rngAlgorithm=C.rngAlgorithm;
manifest.config=C;
manifest.toolboxInfo=ver;
manifest.metadataFile=string(P.metadataFile);
manifest.yamnetDownloadURL=C.yamnet.downloadURL;

% Record external noise files without forcing the formal experiment to run.
noiseFiles=strings(0,1); noiseHashes=strings(0,1);
if isfolder(P.noiseDir)
    for ext=C.noise.allowedExtensions
        D=dir(fullfile(P.noiseDir,"*"+ext));
        for k=1:numel(D)
            f=string(fullfile(D(k).folder,D(k).name));
            noiseFiles(end+1,1)=f; %#ok<AGROW>
            try
                noiseHashes(end+1,1)=file_sha256(f); %#ok<AGROW>
            catch
                noiseHashes(end+1,1)="unavailable"; %#ok<AGROW>
            end
        end
    end
end
manifest.noiseFiles=noiseFiles;
manifest.noiseSHA256=noiseHashes;
if isfile(P.noiseSourcesFile)
    manifest.noiseSources=readtable(P.noiseSourcesFile,"TextType","string");
else
    manifest.noiseSources=table();
end

fid=fopen(fullfile(P.reproDir,"experiment_manifest.txt"),"w");
if fid==-1, warning("Could not write experiment_manifest.txt"); return; end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid,"ELEC5305 Experiment Reproducibility Manifest\n");
fprintf(fid,"Generated: %s\n",manifest.generatedAt);
fprintf(fid,"MATLAB: %s (%s)\n",manifest.matlabVersion,manifest.matlabRelease);
fprintf(fid,"Platform: %s\n",manifest.computer);
fprintf(fid,"Seed: %d\n",C.seed);
fprintf(fid,"RNG algorithm: %s\n",C.rngAlgorithm);
fprintf(fid,"Target sample rate: %d Hz\n",C.targetFs);
fprintf(fid,"Clean cache version: %s\n",C.cache.version);
fprintf(fid,"Robustness cache version: %s\n",C.cache.robustnessVersion);
fprintf(fid,"Official-fold-only: %d\n",C.robustness.useOfficialFoldsOnly);
fprintf(fid,"Clean-training-only: %d\n",C.robustness.trainOnCleanOnly);
fprintf(fid,"Same perturbed waveform for both representations: %d\n",C.robustness.samePerturbedWaveformForAllRepresentations);
fprintf(fid,"\nMFCC: %d coeffs, %.1f ms frame, %.1f ms hop\n",C.mfcc.numCoeffs,C.mfcc.frameMs,C.mfcc.hopMs);
fprintf(fid,"SVM: kernel=%s, boxConstraint=%.6g, coding=%s\n",C.svm.kernel,C.svm.boxConstraint,C.svm.coding);
fprintf(fid,"YAMNet: model=%s, layer=%s, embedding=%d\n",C.yamnet.modelName,C.yamnet.embeddingLayer,C.yamnet.embeddingDimension);
fprintf(fid,"\nNoise SNR (dB): %s\n",mat2str(C.noise.snrDb));
fprintf(fid,"Noise mode: %s\n",C.noise.mode);
fprintf(fid,"Reverb RT60 (s): %s\n",mat2str(C.reverb.rt60Seconds));
fprintf(fid,"Reverb direct/reverb (dB): %s\n",mat2str(C.reverb.directToReverbDb));
fprintf(fid,"Channel low cut (Hz): %s\n",mat2str(C.channel.lowHz));
fprintf(fid,"Channel high cut (Hz): %s\n",mat2str(C.channel.highHz));
fprintf(fid,"\nExternal noise bank (%d files):\n",numel(noiseFiles));
for i=1:numel(noiseFiles)
    [~,name,ext]=fileparts(noiseFiles(i));
    fprintf(fid,"  %s%s | SHA256=%s\n",name,ext,noiseHashes(i));
end
fprintf(fid,"\nMetadata: %s\n",P.metadataFile);
end
