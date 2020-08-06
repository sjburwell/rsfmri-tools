% Use this script to 
%
%
%
%
%
% Requires: 
% SPM12: spm_vol, spm_read_vols, spm_write_vol
% GroupICATv4.0a/icatb (GIFT): icatb_resizeData


outatlas = '/labs/burwellstudy/data/rois/Yeo17+HarvardOxfordSubcortical.nii';
atlases  = { ...
'./lead-dbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/labeling/Yeo2011_17Networks_MNI152 (Yeo 2011).nii', ...              %atlas containing cortical regions
'./lead-dbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/labeling/Harvard Oxford Thr25 2mm Whole Brain (Makris 2006).nii' ... %atlas including subcortical regions
};
rois = { ...
  'all', ... %extract all parcels from first atlas
[92:105] ... %extract only certain regions from second atlas
};


counter = 0;
for ii  = 1:length(atlases), 
  tmpV = spm_vol(atlases{ii}); tmpY = spm_read_vols(tmpV);
  if ii==1, 
     outY = double(tmpY); outV = tmpV; outV.fname = outatlas; outV.dt = [16 0];
  else,
    if sum(abs(outV.dim - tmpV.dim))>0
     tmpY = squeeze(icatb_resizeData(atlases{1}, tmpV.fname));
    end
  end

  vals = unique(int16(double(tmpY))); 
  if strcmp(rois{ii},{'all'}), vals = vals; else, vals = rois{ii}; end
  vals(vals==0) = '';
  for jj = 1:length(vals), 
    counter = counter+1;
    outY(int16(tmpY)==vals(jj)) = counter;
  end
end
spm_write_vol(outV,outY);

