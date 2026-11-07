%% TEST_SETUP - verify the complete final experiment before a long run.
clear; clc;
codeDir=fileparts(mfilename("fullpath")); addpath(genpath(codeDir));
C=config(); P=project_paths(); meta=load_urbansound8k_metadata(P);

fprintf("\n=== COMPLETE PROJECT SETUP CHECK ===\n");
fprintf("Project root   : %s\n",P.projectRoot);
fprintf("Dataset root   : %s\n",P.datasetRoot);
fprintf("Metadata rows  : %d\n",height(meta));
fprintf("Classes        : %d\n",numel(unique(meta.classID)));
fprintf("Official folds : %d\n",numel(unique(meta.fold)));
fprintf("Seed           : %d (%s)\n",C.seed,C.rngAlgorithm);

assert(height(meta)==8732,"Expected 8732 UrbanSound8K rows.");
assert(isequal(sort(unique(meta.fold))',(1:10)),"Expected official folds exactly 1..10.");
assert(numel(unique(meta.classID))==10,"Expected 10 classes.");
assert(numel(unique(string(meta.slice_file_name)))==height(meta),"Clip IDs must be unique.");

requiredFunctions=["mfcc","resample","fitcecoc","audioPretrainedNetwork", ...
    "yamnetPreprocess","designfilt","filtfilt","spectrogram"];
for fn=requiredFunctions
    ok=exist(fn,"file")==2;
    fprintf("%-24s: %d\n",fn,ok);
    assert(ok,"Required MATLAB function is unavailable: %s",fn);
end

fprintf("\nChecking YAMNet...\n");
[~,classes,info]=load_yamnet_model();
fprintf("YAMNet loaded: %d AudioSet classes | source=%s\n",numel(classes),info.source);

fprintf("\nChecking formal external noise bank...\n");
noiseFiles=list_environmental_noise_files(P);
fprintf("Noise files: %d\n",numel(noiseFiles));
for i=1:numel(noiseFiles)
    fprintf("  %s\n",noiseFiles(i));
end
assert(isfile(P.noiseSourcesFile),"Missing assets/noise/SOURCES.csv.");
src=readtable(P.noiseSourcesFile,"TextType","string");
assert(all(ismember(["file_name","source_url","license"],string(src.Properties.VariableNames))), ...
    "SOURCES.csv must contain file_name, source_url and license columns.");
for i=1:numel(noiseFiles)
    [~,n,e]=fileparts(noiseFiles(i));
    fname=string(n)+string(e);
    idx=string(src.file_name)==fname;
    assert(nnz(idx)==1 && strlength(string(src.source_url(idx)))>0 && strlength(string(src.license(idx)))>0, ...
        "Add exactly one source_url/license entry to SOURCES.csv for %s",fname);
end
fprintf("Noise source/license metadata: PASS\n");

% Small deterministic perturbation self-test.
x=sin(2*pi*440*(0:C.targetFs-1)'/C.targetFs);
x=preprocess_audio(x,C.targetFs,C.targetFs);
[y1,~]=add_environmental_noise_snr(x,C.targetFs,noiseFiles(1),10,12345);
[y2,~]=add_environmental_noise_snr(x,C.targetFs,noiseFiles(1),10,12345);
assert(isequal(y1,y2),"Noise perturbation failed deterministic reproducibility test.");

rir1=build_synthetic_rir(C.targetFs,C.reverb.rt60Seconds(1),C.reverb.rirDurationSeconds,C.reverb.directToReverbDb(1),12345);
rir2=build_synthetic_rir(C.targetFs,C.reverb.rt60Seconds(1),C.reverb.rirDurationSeconds,C.reverb.directToReverbDb(1),12345);
assert(isequal(rir1,rir2),"RIR generation failed deterministic reproducibility test.");

write_reproducibility_manifest();
fprintf("\nSetup check PASSED. You can run main.m.\n");
