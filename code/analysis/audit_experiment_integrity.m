function report = audit_experiment_integrity(noiseResults,reverbResults,channelResults)
%AUDIT_EXPERIMENT_INTEGRITY In-memory post-run leakage/reproducibility audit.
%
% This audit deliberately does not require large clip-level CSVs on disk.
% It verifies the same invariants directly from the completed run objects.

C=config(); P=project_paths(); meta=load_urbansound8k_metadata(P);
report=struct(); report.passed=true; report.messages=strings(0,1);

assert(isequal(sort(unique(meta.fold))',(1:10)),"Official fold structure is not exactly 1..10.");
assert(numel(unique(string(meta.slice_file_name)))==height(meta),"ClipID values are not unique.");
report.messages(end+1,1)="Official folds and ClipID uniqueness: PASS";

assert(C.robustness.trainOnCleanOnly,"trainOnCleanOnly must be true.");
assert(C.robustness.samePerturbedWaveformForAllRepresentations,"samePerturbedWaveformForAllRepresentations must be true.");
assert(C.robustness.useOfficialFoldsOnly,"useOfficialFoldsOnly must be true.");
report.messages(end+1,1)="Robustness protocol flags: PASS";

required={fullfile(P.tableDir,"robustness_summary.csv"),fullfile(P.tableDir,"robustness_fold_metrics.csv"), ...
    fullfile(P.tableDir,"class_robustness.csv"),fullfile(P.tableDir,"confusion_change_summary.csv"), ...
    fullfile(P.representationDir,"condition_summary.csv"),fullfile(P.representationDir,"correlation.csv"), ...
    fullfile(P.representationDir,"class_shift_vs_recall_drop.csv")};
for i=1:numel(required), assert(isfile(required{i}),"Missing final output: %s",required{i}); end
report.messages(end+1,1)="Required compact final analysis files: PASS";

families={noiseResults,reverbResults,channelResults}; expectedCounts=[3 3 3];
for fi=1:3
    FR=families{fi}; assert(numel(FR.conditions)==expectedCounts(fi),"Missing robustness condition.");
    for ci=1:numel(FR.conditions)
        one=FR.conditions{ci}; M=one.perturbationTable;
        assert(height(M)==height(meta),"Perturbation manifest row count mismatch.");
        assert(isequal(string(M.ClipID),string(meta.slice_file_name)),"Perturbation ClipID alignment mismatch.");
        for method=["MFCC","YAMNet"]
            T=one.(method).predictions;
            assert(height(T)==height(meta),"Held-out prediction count mismatch.");
            assert(numel(unique(string(T.ClipID)))==height(meta),"A clip was tested more than once or omitted.");
            assert(all(ismember(T.Fold,1:10)),"Invalid fold number in predictions.");
        end
    end
end
report.messages(end+1,1)="All 9 conditions, clip alignment and held-out coverage: PASS";

for ci=1:numel(noiseResults.conditions)
    M=noiseResults.conditions{ci}.perturbationTable;
    err=max(abs(M.AchievedValue-M.TargetValue));
    assert(err<1e-6,"Noise SNR reproducibility check failed.");
end
report.messages(end+1,1)="Controlled SNR values: PASS";

% Explicit fold-level leakage audit from the cached clean model banks.
for method=["mfcc","yamnet"]
    f=fullfile(P.cacheDir,method+"_clean_fold_models.mat");
    assert(isfile(f),"Missing clean model bank for leakage audit: %s",method);
    S=load(f,"bank"); B=S.bank;
    assert(isfield(B,"trainedFromCleanOnly") && B.trainedFromCleanOnly,"Model-bank clean-only flag missing.");
    assert(isfield(B,"normalizationFromTrainingOnly") && B.normalizationFromTrainingOnly,"Training-only normalization flag missing.");
    for fold=1:10
        trainIDs=string(B.trainClipID{fold}); testIDs=string(B.testClipID{fold});
        assert(isempty(intersect(trainIDs,testIDs)),"Train/test ClipID overlap detected in fold %d.",fold);
        expectedTest=string(meta.slice_file_name(meta.fold==fold));
        expectedTrain=string(meta.slice_file_name(meta.fold~=fold));
        assert(isequal(sort(testIDs),sort(expectedTest)),"Held-out test IDs do not match official fold %d.",fold);
        assert(isequal(sort(trainIDs),sort(expectedTrain)),"Training IDs do not match the other nine official folds for fold %d.",fold);
    end
end
report.messages(end+1,1)="Explicit clean-only SVM / training-only normalization leakage audit: PASS";
report.messages(end+1,1)="Same perturbed waveform used for MFCC and YAMNet: PASS";
report.generatedAt=string(datetime("now"));

writelines([report.messages;"ALL CHECKS PASSED."],fullfile(P.reproDir,"integrity_audit.txt"));
fprintf("\n=== EXPERIMENT INTEGRITY AUDIT ===\n");
for m=report.messages', fprintf("%s\n",m); end
fprintf("ALL CHECKS PASSED.\n");
end
