function manifest = write_reproducibility_manifest()
%WRITE_REPRODUCIBILITY_MANIFEST Save experiment settings and environment.
%
% This file makes later reruns auditable: MATLAB release, platform,
% toolbox versions, random seed, model URL and all configuration values are
% stored together with the results.

C = config();
P = project_paths();

manifest = struct();
manifest.generatedAt = string(datetime("now","Format","yyyy-MM-dd HH:mm:ss Z"));
manifest.matlabVersion = string(version);
manifest.matlabRelease = string(version("-release"));
manifest.computer = string(computer);
manifest.seed = C.seed;
manifest.rngAlgorithm = C.rngAlgorithm;
manifest.config = C;
manifest.toolboxInfo = ver;
manifest.metadataFile = string(P.metadataFile);
manifest.yamnetDownloadURL = C.yamnet.downloadURL;

save(fullfile(P.reproDir,"experiment_manifest.mat"),"manifest","-v7.3");

fid = fopen(fullfile(P.reproDir,"experiment_manifest.txt"),"w");
if fid==-1
    warning("Could not write experiment_manifest.txt");
    return;
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid,"ELEC5305 Experiment Reproducibility Manifest\n");
fprintf(fid,"Generated: %s\n",manifest.generatedAt);
fprintf(fid,"MATLAB: %s (%s)\n",manifest.matlabVersion,manifest.matlabRelease);
fprintf(fid,"Platform: %s\n",manifest.computer);
fprintf(fid,"Seed: %d\n",C.seed);
fprintf(fid,"RNG algorithm: %s\n",C.rngAlgorithm);
fprintf(fid,"Target sample rate: %d Hz\n",C.targetFs);
fprintf(fid,"MFCC coefficients: %d\n",C.mfcc.numCoeffs);
fprintf(fid,"MFCC frame: %.3f ms\n",C.mfcc.frameMs);
fprintf(fid,"MFCC hop: %.3f ms\n",C.mfcc.hopMs);
fprintf(fid,"SVM kernel: %s\n",C.svm.kernel);
fprintf(fid,"SVM box constraint: %.6g\n",C.svm.boxConstraint);
fprintf(fid,"SVM coding: %s\n",C.svm.coding);
fprintf(fid,"YAMNet model: %s\n",C.yamnet.modelName);
fprintf(fid,"YAMNet source URL: %s\n",C.yamnet.downloadURL);
fprintf(fid,"Cache version: %s\n",C.cache.version);
fprintf(fid,"Metadata: %s\n",P.metadataFile);
end
