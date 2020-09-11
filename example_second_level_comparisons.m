clear

%% Start by having done level-1 analysis...
addpath /labs/burwellstudy/apps/spm12
run_rsfmri_tools_startup;

pipestr = '24P+aCompCor+4GSR';
atlas = '/labs/burwellstudy/data/rois/Schaefer400+HarvOxSubCortRL.nii';
[~,atlasstr] = fileparts(atlas);
filefilter  =['/labs/mctfr-fmri/users/burwell/rsfmri_demodata/*' pipestr '_ROI-' atlasstr '*']


clear opts
opts.lpf       =                                          .1; % lowpass filter cutoff, in Hz (0 if none)
opts.tr_ntr    =                                [1.395  420 ; % Nx2 array of [TR, #TRs; ...] 
                                                 1.500  400]; % Important for inferring sample-rate if lpf>0 or hpf>0
opts.graphtype =                                      'full'; % 'full','upper','lower'
opts.mergetsv  = '/labs/mctfr-fmri/bids/es/participants.tsv'; % For this, should be participants.tsv .
opts.datakeys  = {'ManufacturersModelName',{'TrioTim','Prisma_fit'};
                  'SoftwareVersions',{'syngo_MR_B17','syngo_MR_D13D','syngo_MR_E11'}};
outfc_matroot  = get_fc(filefilter,opts);



% load functional connectivity data
ustr = 'allSubjects';
load([outfc_matroot '.mat']);

% NB. Users should include some subject exclusion around here to remove people w/ bad scans, excessive motion, etc.

% select scanner(s)
select_scan = [1 2]; %From ManufacturersModelName; 1=Trio, 2=Prisma

% select subset of regions to 
DefaultA_nodes = [149:166, 358:373]; %find rows in /labs/burwellstudy/data/rois/Schaefer400+HarvOxSubCortRL.txt
select_nodes = DefaultA_nodes;

% get region centroids and labels
roifile = '/labs/burwellstudy/data/rois/Schaefer400+HarvOxSubCortRL.nii'; % ROI connectivity regions
tgtatlas= '/labs/burwellstudy/data/rois/Schaefer400+HarvOxSubCortRL.nii'; % atlas with region labels
[labels,mnixyz] = label_3d_or_4d_rois(roifile,tgtatlas); 
for ii = 1:length(labels), labels{ii} = labels{ii}(~isspace(labels{ii})); end
 
% select edges for consideration
seledges = zeros(length(labels),length(labels)); %initiate node-by-node matrix of edges as 0s
for ii = select_nodes, for jj = select_nodes, seledges(ii,jj) = 1; end; end
figure; imagesc(seledges); title('Subset of nodes for consideration (yellow) vs. ignored (blue)');

% mean connectivity across all subjects
meanedges = zeros(length(select_nodes),length(select_nodes));
for ii = 1:length(select_nodes), for jj = 1:length(select_nodes),
  meanedges(ii,jj) = mean(tcc(roi==select_nodes(ii) & ismember(ManufacturersModelName,select_scan),select_nodes(jj)));
end; end
figure; imagesc(meanedges); title('Mean connectivity for the selected nodes');
set(gca,'XTick',1:length(select_nodes)); set(gca,'YTick',1:length(select_nodes)); 
set(gca,'XTickLabel',labels(select_nodes),'FontSize',8); set(gca,'YTickLabel',labels(select_nodes),'FontSize',8); 
set(gca,'XTickLabelRotation',45);

% save NODES to be visualized in BrainNet...
nodetable = table(mnixyz(select_nodes,1), ...
                  mnixyz(select_nodes,2), ...
                  mnixyz(select_nodes,3), ...
                  ones(length(select_nodes),1), ...
                  ones(length(select_nodes),1), ...
                  labels(select_nodes), ...
                  'VariableNames',{'x','y','z','cols','sizes','labels'});
writetable(nodetable,[outfc_matroot '_ustr-' ustr '.dat'], ...
           'Delimiter','\t','QuoteStrings',false,'WriteVariableNames',false)
eval(['!mv  ' [outfc_matroot '_ustr-' ustr '.dat'] ' ' [outfc_matroot '_ustr-' ustr '.node']]);

% save EDGES to be visualized in BrainNet...
edges2save = meanedges; edges2save = tril(edges2save,-1)'+tril(edges2save,-1); 
dlmwrite([outfc_matroot '_ustr-' ustr '.edge'], edges2save,'\t');

% Visualize using BrainNet ( https://www.nitrc.org/projects/bnv/ )
addpath /labs/burwellstudy/apps/BrainNetViewer_20171031/
BrainNet




