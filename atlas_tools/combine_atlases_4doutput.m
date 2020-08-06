% Use this script to combine multiple "map" files (4d nii where each index in the 4th dimension reflects one "map" [e.g., ICA weights]) and
% save out to one 4d nii file. Requires dependencies to be in the user's path already (see below).
%
% Example:
% >> outatlas=  './Ray2013-ICA70.nii';         %output 4d Nii file
% >> atlases = {...
%    './Ray2013/thresh_zstatd70_01.nii.gz',... %1st map
%    './Ray2013/thresh_zstatd70_02.nii.gz',... %2nd map
%    './Ray2013/thresh_zstatd70_03.nii.gz',... % etc.
%    ...
%    './Ray2013/thresh_zstatd70_70.nii.gz'};   %Nth map
%    >> combine_atlases_4doutput; %run it!  
%
% Requires: 
% SPM12: spm_vol, spm_read_vols, spm_write_vol
% GroupICATv4.0a/icatb (GIFT): icatb_resizeData
% REST: https://github.com/Chaogan-Yan/REST/blob/master/rest_Write4DNIfTI.m

counter = 0;
for ii  = 1:length(atlases), 
  tmpV = spm_vol(atlases{ii}); tmpY = spm_read_vols(tmpV);
  if ii==1, 
     outY = double(tmpY); outV = tmpV; outV.fname = outatlas;
  else,
    if sum(abs(outV(1).dim - tmpV.dim))>0
     tmpY = squeeze(icatb_resizeData(atlases{1}, tmpV.fname));
    end
  end

  counter = counter+1;
  if ii~=1, outY = cat(4,outY,tmpY); end; %outV = cat(1,outV,outV(1)); end

end
%spm_write_vol(outV,outY);
rest_Write4DNIfTI(outY,outV,outatlas)
