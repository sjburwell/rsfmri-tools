clear

addpath /labs/burwellstudy/apps/spm12
run_rsfmri_tools_startup;


pipestr = '03P+AROMANonAgg';
atlas = '/labs/burwellstudy/data/rois/Schaefer400+HarvOxSubCortRL.nii';
[~,atlasstr] = fileparts(atlas);
filefilter  =['/labs/burwellstudy/data/fmri/fmriprep-es2/fmriprep/denoised-3dtproject_passband-.009to9999/*' pipestr '_ROI-' atlasstr '*']


clear opts
opts.lpf       =                                          .1; % lowpass filter cutoff, in Hz (0 if none)
opts.tr_ntr    =                                [1.395  420 ; % Nx2 array of [TR, #TRs; ...] 
                                                 1.500  400]; % Important for inferring sample-rate if lpf>0 or hpf>0
opts.graphtype =                                      'full'; % 'full','upper','lower'
opts.mergetsv  = '/labs/mctfr-fmri/bids/es/participants.tsv'; % For this, should be participants.tsv .
opts.datakeys  = {'ManufacturersModelName',{'TrioTim','Prisma_fit'};
                  'SoftwareVersions',{'syngo_MR_B17','syngo_MR_D13D','syngo_MR_E11'}};
outfc_matroot  = get_fc(filefilter,opts);

