function outDir = condition_output_dir(P,family,severity)
%CONDITION_OUTPUT_DIR Hierarchical output directory for one robustness condition.
familyTag = regexprep(lower(string(family)),"[^a-z0-9]+","_");
severityTag = regexprep(lower(string(severity)),"[^a-z0-9]+","_");
outDir = fullfile(P.robustnessDir,familyTag,severityTag);
if ~isfolder(outDir)
    mkdir(outDir);
end
end
