function outname_final = get_fc(loadfilter,opts);
% get_fc() - generates a table of functional connectivity data gleaned from TSV files containing
%            denoised fMRI time-series, intended for use across multiple subjects. 
%
%
% Usage:
%   outfile = get_fc(loadfilter, opts);
%
% Required inputs:
%   loadfilter: character array containing path to *tsv files where each column corresponds to a 
%               time-series for a given region of interest.
%
% Optional inputs passed as structured variable (i.e., opts.mergetsv = ...):
%   mergetsv:   tab-separated file containing participant-identifying information to be merged 
%               with the connectivity data (e.g., BIDS' participants.tsv)
%   graphtype:  connectivity graph type, e.g., 
%                  'upper' = upper tri., 
%                  'lower' = lower tri., 
%                  'full'  = full matrix
%   trdrop:     int, number of initial TRs to drop before computing connectivity
%   hpf:        float, high-pass filter if any (default: 0 / none)
%   lpf:        float, low-pass filter if any (default: 0 / none)
%   tr_ntr:     Nx2 array containing the possible TRs and number of TRs for scans
%               to be observed; important when hpf>0 or lpf>0
%   datakeys:   cell array containing additional participant-level data to be 
%               output with connectivity (e.g., scanner info, software info., etc)
%               
% Example:
% >>opts.lpf       =                                          .1;
% >>opts.tr_ntr    =                    [1.395  420; 1.500  400];
% >>opts.graphtype =                                      'full';
% >>opts.mergetsv  = '/labs/mctfr-fmri/bids/es/participants.tsv';
% >>opts.datakeys  = {'ManufacturersModelName',{'TrioTim','Prisma_fit'};
%                     'SoftwareVersions',{'syngo_MR_B17','syngo_MR_D13D','syngo_MR_E11'}};
% >>outfc_matroot  = get_fc(filefilter,opts);
%
% Scott Burwell, August, 2020

subpfx = 'sub-'; fnpfxlen = length(subpfx); %requires, expects sub-#######
subs = cellstr(conn_dir(loadfilter));
[~,~,fext] = fileparts(subs{1}); 
switch fext, 
  case '.tsv',
   tmp   = load(subs{1}); 
  otherwise,
   disp('   get_fc; Sorry, the only acceptable file type at this point is *.tsv where each column is a time series from a different region of interest');
   return;
end

if exist('opts')&&isfield(opts,'mergetsv')&&~isempty(opts.mergetsv),
   mergetsv = opts.mergetsv; s = tdfread(mergetsv); else, mergetsv = ''; s = ''; end
if exist('opts')&&isfield(opts,'graphtype')&&~isempty(opts.graphtype),
   graphtype = opts.graphtype; else, graphtype = 'full'; end
if exist('opts')&&isfield(opts,'trdrop')&&~isempty(opts.trdrop),
   trdrop = opts.trdrop; else, trdrop = []; end
if exist('opts')&&isfield(opts,'hpf')&&~isempty(opts.hpf),
   hpf = opts.hpf; else, hpf = []; end
if exist('opts')&&isfield(opts,'lpf')&&~isempty(opts.lpf),
   lpf = opts.lpf; else, lpf = []; end
if exist('opts')&&isfield(opts,'tr_ntr')&&~isempty(opts.tr_ntr),
   tr_ntr = opts.tr_ntr; else, tr_ntr = []; end
if exist('opts')&&isfield(opts,'datakeys')&&~isempty(opts.datakeys),
   for ii = 1:size(opts.datakeys,1), 
     eval([opts.datakeys{ii,1},'=[];']);
   end
end
if exist('opts')&&isfield(opts,'confounds') &&~isempty(opts.confounds),
   display('   get_fc; WARNING: the confounds option has been deprecated, proceed with caution...');
   confounds  = opts.confounds;  else, confounds = []; 
end   

snum= []; 
roi = [];
tcc = [];
for ii = 1:length(subs),
    
    %%load subject
    switch fext,
    case '.tsv',
      tc = load(subs{ii});
    end

    %figure out samplerate based on the tr_ntr field
    if ~isempty(tr_ntr), sr = 1/tr_ntr(tr_ntr(:,2)==size(tc,1),1); else, sr = []; end

    %optional filtering
    if ~isempty(hpf)&&hpf>0, 
       tc = filts_highpass_butter(tc',hpf/(sr/2))';
    end
    if ~isempty(lpf)&&lpf>0,
       tc = filts_lowpass_butter(tc',lpf/(sr/2))';
    end

    %subsample TRs (if applicable)
    trsel = 1:size(tc,1); trsel = find(ismember(trsel,trdrop)==0); 
    tc = tc(trsel,:);

    %get subject info
    [froot,fname] = fileparts(subs{ii});

    %get scan information
    idx  = find( str2num(fname(fnpfxlen+1:fnpfxlen+7)) == str2num(s.participant_id(:,5:end)));
    snum = [snum; repmat( str2num(s.participant_id(idx,5:end)),length(corr(tc)), 1) ];

    %incorporate coding from other columnes in the mergetsv file
    if exist('opts')&&isfield(opts,'datakeys')&&~isempty(opts.datakeys),
       for jj = 1:size(opts.datakeys,1),
         if isfield(s,opts.datakeys{jj,1}),
           eval( ...
           [opts.datakeys{jj,1} '= [' ...
            opts.datakeys{jj,1} '; repmat(strmatch(s.' opts.datakeys{jj,1} '(idx,:), opts.datakeys{jj,2} ), length(corr(tc)),1)];'] ...
           );
         else,
           eval( ...
           [opts.datakeys{jj,1} '= [' ...
            opts.datakeys{jj,1} '; repmat(NaN, length(corr(tc)),1)];'] ...
           );
         end
       end
    end

    %insert column identifying unique regions of interest (ROIs) 
    roi  = [roi; [1:length(corr(tc))]'];

    %linear detrending
    for jj = 1:size(tc,2), tc(:,jj) = detrend(tc(:,jj)); end 

    X = [];
    if ~isempty(confounds)&&isfield(confounds,'tsvcols') &&~isempty(confounds.tsvcols),
       confid = s.participant_id(idx,5:end);
       conftsv= conn_dir([ confounds.tsvdir '/sub-' confid '/*' confid '*_confounds.tsv']);
       conftsv= tdfread(conftsv); 

       fields = fieldnames(conftsv);
       for jj = 1:length(fields), 
         if ischar(eval(['conftsv.' fields{jj}])), eval(['klooge=conftsv.' fields{jj} '(2:end,:);']); 
                   eval(['conftsv.' fields{jj} '=[0; str2num(klooge)];']); 
         end; 
       end

       for jj = 1:length(confounds.tsvcols), eval(['X = [X conftsv.' confounds.tsvcols{jj} '];']); end
       for jj = 1:size(X,2), X(:,jj) = detrend(X(:,jj)); end
       if confounds.expand==1, X = [X [zeros(1,size(X,2)); diff(X)]]; end
       if confounds.expand==2, X = [X [zeros(1,size(X,2)); diff(X)]]; X = [X X.^2]; end
       X = zscore(X(trsel,:)); 
 
       if ~isempty(confounds)&&isfield(confounds,'tsvcols2') &&~isempty(confounds.tsvcols2),
          for jj = 1:length(confounds.tsvcols2), eval(['X = [X zscore(conftsv.' confounds.tsvcols2{jj} '(trsel,:) )];']); end
       end

       %optional filtering, here applied to the confound matrix
       if ~isempty(hpf)&&hpf>0,
          X = filts_highpass_butter(X',hpf/(sr/2))';
       end
       if ~isempty(lpf)&&lpf>0,
          X = filts_lowpass_butter( X',lpf/(sr/2))';
       end

       disp(['Regressing ' num2str(size(X,2)) ' confounds for subject (' num2str(ii) ') ' confid]);
       for jj = 1:size(tc,2), B = regress(tc(:,jj),[ones(length(X),1) X]); Yhat = [ones(length(X),1) X]*B; tc(:,jj) = tc(:,jj)-Yhat; end       
    end
 
    %compute functional connectivity
    switch graphtype,
     case 'full',
      rho_firstorder = atanh(corr(tc));
     case 'lower',
      rho_firstorder = tril(atanh(corr(tc)),-1);
     case 'upper',
      rho_firstorder = tril(atanh(corr(tc)), 1);
     otherwise,
      rho_firstorder = atanh(corr(tc));
    end
    tcc = [tcc; rho_firstorder];

end



roilabels = {}; 
for ii = 1:length(corr(tc)), 
  roilabels = [roilabels; {['ROI' sprintf('%03d',ii)]}]; 
end

tablevars = {'ID','ROI'};
tabledata = [snum, roi];
if exist('opts')&&isfield(opts,'datakeys')&&~isempty(opts.datakeys),
  for jj = 1:size(opts.datakeys,1),
    if isfield(s,opts.datakeys{jj,1}),
      eval(['tabledata=[tabledata,'    opts.datakeys{jj,1} '   ];']);
      eval(['tablevars=[tablevars,{''' opts.datakeys{jj,1} '''}];']);
    end
  end
end
tablevars = [tablevars, roilabels'];
tabledata = [tabledata, tcc];

%construct output table
T = array2table(tabledata, 'VariableNames', tablevars);
[~,outname]  = fileparts(loadfilter); outname(outname=='*') = '';
outname_final= [ outname '_hpf' num2str(hpf) '_lpf' num2str(lpf) '_out']; 
writetable(T,[outname_final '.dat'],'Delimiter','\t');









%%%%%%%%%%%%%%% Plug-ins (PTB)

function [inmat] = filts_lowpass_butter(inmat,filtproportion,order),
% filts_lowpass_butter(inmat,filtproportion[,order]) 
% 
%  filters each row of inmat at level of filtproportion (e.g. 25/125hz).  
%       filtproportion = (filtfreq/(samplerate/2));  
%       filts uses the matlab butter filter, 3rd order, by default  
% 
% Psychophysiology Toolbox, General, Edward Bernat, University of Minnesota  
if exist('order')==0, order=3; end
[b,a]=butter(order,filtproportion);
for n=1:size(inmat,1),
  inmat(n,:)=filtfilt(b,a,inmat(n,:));
end


function [inmat] = filts_highpass_butter(inmat,filtproportion,order),
% filts_highpass_butter(inmat,filtproportion[,order]) 
% 
%  filters each row of inmat at level of filtproportion (e.g. 25/125hz).  
%       filtproportion = (filtfreq/(samplerate/2));  
%       filts uses the matlab butter filter, 3rd order, by default  
% 
% Psychophysiology Toolbox, General, Edward Bernat, University of Minnesota  
if exist('order')==0, order = 3; end
[b,a]=butter(order,filtproportion,'high');
for n=1:size(inmat,1),
  inmat(n,:)=filtfilt(b,a,inmat(n,:));
end



