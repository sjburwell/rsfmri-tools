# rsfmri_tools
This repository contains MATLAB utilities for conducting resting-state functional MRI (rsfMRI) connectivity analyses.

# Installation and setup:
The following scripts rely entirely on MATLAB and a few MATLAB dependencies. If you have not already, please download and install [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/). Then, you make sure you download and unzip the necessary scripts from this GitHub repository. In Linux, you may clone the directory through the below command:
```linux
git clone https://github.com/sjburwell/rsfmri_tools.git
```

Next, start MATLAB and make sure that all the necessary installations are in your path. This may look something like this:
```matlab
addpath /PATH/TO/YOUR/SPM12/INSTALLATION
run_rsfmri_tools_startup;
```
If successful, the commandline should say something like: "run_rsfmri_tools_startup; required SPM12 toolbox path added..." and "run_rsfmri_tools_startup; required rsfmri_tools path added:"

# Example usage:
Now, we are ready to set up the connectivity estimation scripts. This step requires that you have previously calculated and output tab-separated value (.tsv) files that contain R columns of T rows, where each R corresponds to a different "Region of Interest" (ROI), and each T corresponds to a time-point (or TR, in functional neuroimaging). If you have not yet done this step, please see another GitHub repo of mine that provides scrips for doing so: [fmriprep_denoising](https://github.com/sjburwell/fmriprep_denoising).

While there are other MATLAB dependencies (e.g., SPM12), you should be able to obtain connectivity values using only the function get_fc(). Detailed help for the function can be queried by:
```matlab
help get_fc
```

Here, I will show an example using  

```matlab
filefilter =['/home/burwell/tempdelete/fmriprep_denoising/tmpdir/*03P+AROMANonAgg_ROI-Schaefer400+HarvOxSubCortRL*'];
opts.lpf       =                                          .1; % lowpass filter cutoff, in Hz (0 if none)
opts.tr_ntr    =                                [1.395  420 ; % Nx2 array of [TR, #TRs; ...] 
                                                 1.500  400]; % Important for inferring sample-rate if lpf>0 or hpf>0
opts.graphtype =                                      'full'; % 'full','upper','lower'
opts.mergetsv  = '/labs/mctfr-fmri/bids/es/participants.tsv'; % For BIDS, should be participants.tsv
opts.datakeys  = {'ManufacturersModelName',{'TrioTim','Prisma_fit'};
                  'SoftwareVersions',{'syngo_MR_B17','syngo_MR_D13D','syngo_MR_E11'}};
outfc_matroot  = get_fc(filefilter,opts);
```







