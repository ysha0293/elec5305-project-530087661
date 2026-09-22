function results = run_clean_benchmark()
%RUN_CLEAN_BENCHMARK Complete clean MFCC-vs-YAMNet official 10-fold study.

P=project_paths();
meta=load_urbansound8k_metadata(P);

fprintf("\n=============================================\n");
fprintf("CLEAN BENCHMARK: MFCC + SVM\n");
fprintf("=============================================\n");

[Xmfcc,Y,folds]=build_mfcc_cache(meta,P);
mfccR=run_official_10fold_svm(Xmfcc,Y,folds,"MFCC",P);

fprintf("\n=============================================\n");
fprintf("CLEAN BENCHMARK: YAMNet + SVM\n");
fprintf("=============================================\n");

[Xyam,Y2,folds2]=build_yamnet_cache(meta,P);

assert(isequal(string(Y),string(Y2)), ...
    "MFCC and YAMNet labels do not match.");
assert(isequal(folds,folds2), ...
    "MFCC and YAMNet fold assignments do not match.");

yamR=run_official_10fold_svm(Xyam,Y2,folds2,"YAMNet",P);

plot_clean_comparison(mfccR,yamR,P);

results.MFCC=mfccR;
results.YAMNet=yamR;
end
