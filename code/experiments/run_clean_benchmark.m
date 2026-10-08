function results = run_clean_benchmark()
%RUN_CLEAN_BENCHMARK Complete clean MFCC-vs-YAMNet official 10-fold study.

P=project_paths();
meta=load_urbansound8k_metadata(P);
clipID=string(meta.slice_file_name);

fprintf("\n=============================================\n");
fprintf("CLEAN BENCHMARK: MFCC + SVM\n");
fprintf("=============================================\n");

[Xmfcc,Y,folds,clipMfcc]=build_mfcc_cache(meta,P);
assert(isequal(clipID,clipMfcc),"MFCC cache clip order does not match metadata.");
mfccR=run_official_10fold_svm(Xmfcc,Y,folds,"MFCC",P,clipID);

fprintf("\n=============================================\n");
fprintf("CLEAN BENCHMARK: YAMNet + SVM\n");
fprintf("=============================================\n");

[Xyam,Y2,folds2,clipYam]=build_yamnet_cache(meta,P);

assert(isequal(string(Y),string(Y2)), ...
    "MFCC and YAMNet labels do not match.");
assert(isequal(folds,folds2), ...
    "MFCC and YAMNet fold assignments do not match.");
assert(isequal(clipID,clipYam), ...
    "YAMNet cache clip order does not match metadata.");

% This alignment check is important for the later robustness stage: both
% representations refer to the same physical audio clip at every row.
assert(isequal(clipMfcc,clipYam), ...
    "MFCC and YAMNet cache clip IDs do not match.");

yamR=run_official_10fold_svm(Xyam,Y2,folds2,"YAMNet",P,clipID);

plot_clean_comparison(mfccR,yamR,P);

results.MFCC=mfccR;
results.YAMNet=yamR;
results.clipID=clipID;
end
