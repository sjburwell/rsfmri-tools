function [labels, points] = label_3d_or_4d_rois(infile,atlas);
%[labels, points] = label_3d_or_4d_rois(infile, atlas);
% Requirements: Must have SPM12 and GIFT toolboxes in path for below fns:
% 	spm_vol(), spm_read_vols(), icatb_resizeData()
%
% Input: 
% infile - 3D (integer values reflect ROIs) or 4D ("timepoints" reflect
%          independent components or maps) *.nii file.
% atlas  - points to atlas file which consists of *.nii & *.txt pair. 
%          The atlas *.nii file is all zeros for "unlabeled" regions and 
%          integers (1, 2, 3, etc.) for each anatomically labeled region 
%          (anat1, anat2, anat3, etc.). The accompanying *.txt file holds
%          the labels - one label per each row corresponding to the 
%          integers in the *nii file.
%
% Output:
% labels - anatomical labels that correspond to maximum overlap between 
%          infile and atlas.
% points - 3D MNI coordinates
%
% Example:
% [labels, points] = label_3d_or_4d_rois('/path/to/functional_atlas.nii','/path/to/anatomical_atlas.nii');
% or 
% [labels, points] = label_3d_or_4d_rois('/path/to/ica_components_4d.nii','/local/conn17f/conn/rois/atlas.nii');
%
 


%init spatial variables
compV = spm_vol(infile); 
atlasV= spm_vol(atlas); 
if sum(abs(compV(1).dim - atlasV(1).dim))>0, 
  atlasY = squeeze(icatb_resizeData(compV(1).fname,atlasV.fname)); 
else, 
  atlasY = spm_read_vols(atlasV);
end
[atlaspath,atlasname] = fileparts(atlas); 

fid = fopen(fullfile(atlaspath,[atlasname,'.txt']));
atlaskey=textscan(fid,'%s','delimiter','\t'); atlaskey = atlaskey{:};
fclose(fid);
points = [];
labels = [];
if length(compV)==1,
  allY = int16(spm_read_vols(compV));
  vals = unique(int16(double(allY))); vals(vals==0) = '';
  %vals = unique(tmpY); vals(vals==0) = '';
  for ii = 1:length(vals), 
    idx = find(allY(:)==vals(ii)); [x,y,z] = ind2sub(size(allY),idx);
    if size(cor2mni([x,y,z],compV.mat),1)==1,
       points = [points;      round(cor2mni([x,y,z],compV.mat) ,3)];
    else,
       points = [points; round(mean(cor2mni([x,y,z],compV.mat)),3)];
    end

    tmpY   = allY==vals(ii);
    tmpY   = tmpY.*atlasY;
    roiN   = mode(tmpY(tmpY>0));
    roiN   = int16(round(roiN));
    if ~isnan(roiN) & roiN>0,
       %labels = [labels; atlaskey(roiN)]; 
       labels = [labels; {[num2str(ii) '. ' atlaskey{roiN}]}];
    else,
       %labels = [labels; {'unknown'}];
       labels = [labels; {[num2str(ii) '. ' 'unknown']}];
    end
  end
else,
  for ii = 1:length(compV),
    tmpY = spm_read_vols(compV(ii)); 
    [~,idx] = max(tmpY(:)); [x,y,z] = ind2sub(size(tmpY),idx);
    points = [points; round(cor2mni([x,y,z],compV(ii).mat),3)];

    tmpY = double(tmpY>  (.80*max(max(max(tmpY)))));
    tmpY = tmpY.*atlasY;
    roiN = mode(tmpY(tmpY>0));
    if ~isnan(roiN),
       %labels = [labels; atlaskey(roiN)]; 
       labels = [labels; {[num2str(ii) '. ' atlaskey{roiN}]}];
    else,
       %labels = [labels; {'unknown'}];
       labels = [labels; {[num2str(ii) '. ' 'unknown']}];
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% cor2mni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mni = cor2mni(cor, T)
% function mni = cor2mni(cor, T)
% convert matrix coordinate to mni coordinate
%
% cor: an Nx3 matrix
% T: (optional) rotation matrix
% mni is the returned coordinate in mni space
%
% caution: if T is not given, the default T is
% T = ...
%     [-4     0     0    84;...
%      0     4     0  -116;...
%      0     0     4   -56;...
%      0     0     0     1];
%
% xu cui
% 2004-8-18
% last revised: 2005-04-30

if nargin == 1
    T = ...
        [-4     0     0    84;...
         0     4     0  -116;...
         0     0     4   -56;...
         0     0     0     1];
end

cor = round(cor);
mni = T*[cor(:,1) cor(:,2) cor(:,3) ones(size(cor,1),1)]';
mni = mni';
mni(:,4) = [];
return;




