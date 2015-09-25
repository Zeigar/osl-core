function glean_subspace(GLEAN)
% Runs the subspace stage of GLEAN


method = lower(char(intersect(fieldnames(GLEAN.settings.subspace),{'pca','parcellation','voxel'})));

switch method
    case {'voxel','pca'}
        data = 'enveloped';
    case 'parcellation'
        data = 'beamformed';     
end


if ~all(cellfun(@exist,{GLEAN.data.subspace}))
      
    % Copy data to subspace directory
    for session = 1:numel(GLEAN.data)
        D = spm_eeg_load(GLEAN.data(session).(data));
        D = copy(D,GLEAN.data(session).subspace);
    end
    
    % Apply normalisation
    for session = 1:numel(GLEAN.data)
        switch GLEAN.settings.subspace.normalisation
            case 'none'
                % Do nothing
            case {'voxel','global'}
                stdev = sqrt(osl_source_variance(D));
                if strcmp(GLEAN.settings.subspace.normalisation,'global')
                    stdev = mean(stdev);
                end
                M = montage(D,'getmontage');
                M.tra = diag(1./stdev)*M.tra;  
                % Remove unused montages:
                D = montage(D,'remove',1:montage(D,'getnumber'));
                D = montage(D,'add',M);
                D.save
            otherwise
                error('Invalid normalisation')
        end
        
    end
    
    
    switch method
        
        case 'voxel'
            
            % Do nothing
            
%        case 'pca'
%             
%             C = osl_groupcov(prefix({GLEAN.data.subspace},'tmp'));
%             pcadim = min(GLEAN.settings.subspace.pca.dimensionality,D.nchannels);
%             [allsvd,M] = eigdec(C,pcadim);
%             
%             if GLEAN.settings.subspace.pca.whiten
%                 M = diag(1./sqrt(allsvd)) * M';
%             else
%                 M = M';
%             end
            
            
            
        case 'parcellation'
            
            for session = 1:numel(GLEAN.data)   
                
                % Compute parcellation:
                S                   = [];
                S.D                 = GLEAN.data(session).subspace;
                S.parcellation      = GLEAN.settings.subspace.parcellation.file;
                S.mask              = GLEAN.settings.subspace.parcellation.mask;
                S.orthogonalisation = GLEAN.settings.subspace.parcellation.orthogonalisation;
                S.method            = GLEAN.settings.subspace.parcellation.method;
                glean_parcellation(S);
                
                % Compute envelopes:
                S               = [];
                S.D             = GLEAN.data(session).subspace;
                S.fsample_new   = GLEAN.settings.envelope.fsample;
                S.logtrans      = GLEAN.settings.envelope.log;
                if isfield(GLEAN.settings.envelope,'freqbands')
                    S.freqbands = GLEAN.settings.envelope.freqbands;
                else
                    S.freqbands = [];
                end
                S.demean    = 0;
                S.prefix    = '';
                D = glean_hilbenv(S);
                move(D,GLEAN.data(session).subspace)
            end
            
        otherwise
            error('I don''t know what to do!')
            
    end
%     
%     
%     % Apply spatial basis and write output files
%     for session = 1:numel(GLEAN.data)
%         
%         D = spm_eeg_load(prefix(GLEAN.data(session).subspace,'tmp'));
%         
%         montnew             = [];
%         montnew.name        = 'spatialbasis';
%         montnew.labelnew    = arrayfun(@(x) strcat(method,num2str(x)),1:size(M,1),'uniformoutput',0)';
%         montnew.labelorg    = D.chanlabels;
%         montnew.tra         = M;     
%         
%         S2 = [];
%         S2.D            = prefix(GLEAN.data(session).subspace,'tmp');
%         S2.montage      = montnew;
%         S2.keepsensors  = false;
%         S2.keepothers   = false;
%         S2.mode         = 'write';
%         
%         D = spm_eeg_montage(S2);
%         D.save;
%         
%         move(D,GLEAN.data(session).subspace)
%         unix(['rm ' strrep(prefix(GLEAN.data(session).subspace,'tmp'),'.mat','.*at')]);
%     end
%     



end
% 
% 
% 
% 
% 
%         
% 