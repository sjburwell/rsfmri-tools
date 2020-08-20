spm_dir = fileparts(which('spm'));
if ~isempty(spm_dir),
   addpath(spm_dir);
   display(['   run_rsfmri_tools_startup; required SPM12 toolbox path added: ' spm_dir]);
else,
   display(['   run_rsfmri_tools_startup; please addpath to SPM12 before starting rsfmri_tools']);
   return
end

rsfmri_tools_dir = fileparts(which('run_rsfmri_tools_startup'));
addpath(genpath(rsfmri_tools_dir));
display(['   run_rsfmri_tools_startup; required rsfmri_tools path added: ' rsfmri_tools_dir]);
