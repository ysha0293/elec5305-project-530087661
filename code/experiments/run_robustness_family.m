function familyResults = run_robustness_family(family)
%RUN_ROBUSTNESS_FAMILY Complete one perturbation family end to end.

C=config(); P=project_paths();
meta=load_urbansound8k_metadata(P);
clipID=string(meta.slice_file_name);

[Xmfcc,Y,folds,clipMfcc]=build_mfcc_cache(meta,P);
[Xyam,Y2,folds2,clipYam]=build_yamnet_cache(meta,P);
assert(isequal(clipID,clipMfcc) && isequal(clipID,clipYam),"Feature caches are not clip-aligned.");
assert(isequal(string(Y),string(Y2)) && isequal(folds,folds2),"MFCC/YAMNet label or fold mismatch.");

family=lower(string(family));
switch family
    case "noise"
        nConditions=numel(C.noise.snrDb);
        severityNames=string(C.noise.snrDb)+"dB";
    case "reverb"
        nConditions=numel(C.reverb.labels);
        severityNames=C.reverb.labels;
    case "channel"
        nConditions=numel(C.channel.labels);
        severityNames=C.channel.labels;
    otherwise
        error("Unknown robustness family: %s",family);
end

familyResults=struct();
familyResults.family=family;
familyResults.conditions=cell(nConditions,1);

for s=1:nConditions
    severity=severityNames(s);
    fprintf("\n=================================================\n");
    fprintf("ROBUSTNESS: %s / %s\n",upper(family),severity);
    fprintf("=================================================\n");

    [XmfccPert,XyamPert,perturbationTable]=build_perturbed_condition_cache(meta,family,s,P);

    mfccR=run_robustness_10fold_svm(Xmfcc,XmfccPert,Y,folds,"MFCC",family,severity,P,clipID);
    yamR=run_robustness_10fold_svm(Xyam,XyamPert,Y,folds,"YAMNet",family,severity,P,clipID);

    Tmfcc=compute_representation_shift_table(Xmfcc,XmfccPert,meta,"MFCC",family,severity,C.shift.mfccMetric,P);
    Tyam=compute_representation_shift_table(Xyam,XyamPert,meta,"YAMNet",family,severity,C.shift.yamnetMetric,P);

    one=struct();
    one.severity=severity;
    one.MFCC=mfccR;
    one.YAMNet=yamR;
    one.shiftMFCC=Tmfcc;
    one.shiftYAMNet=Tyam;
    one.perturbationTable=perturbationTable;
    familyResults.conditions{s}=one;
end
end
