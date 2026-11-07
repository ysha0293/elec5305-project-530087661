function hex = file_sha256(fileName)
%FILE_SHA256 SHA-256 checksum for reproducibility records.
fid = fopen(fileName,'rb');
if fid < 0
    error("Could not open file for SHA-256: %s",fileName);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid,Inf,'*uint8');
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
d = typecast(md.digest(),'uint8');
hex = lower(string(reshape(dec2hex(d,2).',1,[])));
end
