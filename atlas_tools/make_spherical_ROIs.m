% Script to make spherical ROIs in MNI space using the MarsBar region of interest toolbox (SPM plugin). 
%
% Example:
% >> roiroot = './myspheres/'; 
% >> roinames= {'left','right','left','right'};
% >> roinets = {'Amyg','Amyg','Hipp','Hipp'};
% >> roicenters= { ...
%    [-28  -4 -22] ...
%    [ 26  -4 -22] ...
%    [-28 -18 -16] ...
%    [ 32 -22 -12]};
% >> radius = 5;
% 
% Requires:
% MarsBar: http://marsbar.sourceforge.net/
 
marsbar('on');
if ~exist(roiroot), eval(['! mkdir ' roiroot]); end
for ii = 1:length(roinames),
    params = struct('centre', roicenters{ii}, 'radius', radius);
    roi    = maroi_sphere(params);

    if ~exist(fullfile(roiroot, roinets{ii})), eval(['! mkdir ' fullfile(roiroot, roinets{ii})]); end

    curlab = roinames{ii};
    if     roicenters{ii}(1)>0,
       curlab = [curlab, '-R'];
    elseif roicenters{ii}(1)<0,
       curlab = [curlab, '-L'];
    end

    curdir = fullfile(roiroot, roinets{ii}, curlab); 
    if ~exist(curdir), eval(['! mkdir ' curdir]); end

    coordstr = num2str(roicenters{ii}(1)); 
    for jj=2:3, coordstr = [coordstr '_' num2str(roicenters{ii}(jj))]; end
    save_as_image(roi, fullfile(curdir, ['Sphere_' coordstr '_' num2str(radius) '.nii']));

end
