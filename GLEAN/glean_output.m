function glean_output(GLEAN)
% Runs the output stage of GLEAN

model = load(GLEAN.model);

if isfield(GLEAN.settings.envelope,'freqbands')
    F = numel(GLEAN.settings.envelope.freqbands);
else
    F = 1;
end


for output_type = fieldnames(GLEAN.settings.output)'
    
    output = lower(char(output_type));
    
    switch output
        
        case 'pcorr'
            
            for subspace = fieldnames(GLEAN.output.pcorr)'
                
                switch char(subspace)
                    case 'voxel'
                        data = 'enveloped';
                    case 'parcel'
                        data = 'subspace';
                end
                
                D = spm_eeg_load(GLEAN.data(1).(data));
                
                switch lower(char(fieldnames(GLEAN.settings.model)))
                    case 'hmm'
                        regressors = cell2mat(arrayfun(@(k) model.hmm.statepath==k,1:model.hmm.K,'UniformOutput',0));
                        session_maps = nan(D.nchannels,model.hmm.K,F,numel(GLEAN.data));
                    case 'ica'
                        regressors = model.ica.tICs';
                        session_maps = nan(D.nchannels,size(model.ica.tICs,1),F,numel(GLEAN.data));
                end
                
                
                for session = 1:numel(GLEAN.data)
                    
                    if F == 1
                        session_maps(:,:,1,session) = glean_regress(GLEAN.data(session).(data),regressors(model.subIndx==session,:),output);
                    else
                        session_maps(:,:,:,session) = glean_regress(GLEAN.data(session).(data),regressors(model.subIndx==session,:),output);
                    end
                    % Save the session specific maps
                    disp(['Saving partial correlation maps for session ' num2str(session)])
                    for f = 1:F
                        map = session_maps(:,:,f,session);
                        switch GLEAN.settings.output.(output).format
                            case 'mat'
                                save(GLEAN.output.(output).(char(subspace)).sessionmaps{session}{f},'map');
                            case 'nii'
                                save2nii(map,GLEAN.output.(output).(char(subspace)).sessionmaps{session}{f},char(subspace))
                        end
                    end
                    
                end
                group_maps = nanmean(session_maps,4);
                
                
                % Save the group averaged maps
                disp('Saving group partial correlation map')
                for f = 1:F
                    map = group_maps(:,:,f);
                    switch GLEAN.settings.output.(output).format
                        case 'mat'
                            save(GLEAN.output.(output).(char(subspace)).groupmaps{f},'map');
                        case 'nii'
                            save2nii(map,GLEAN.output.(output).(char(subspace)).groupmaps{f},char(subspace))
                    end
                end
            end
            
        case 'connectivity_profile'
            if F > 1
                error('Not yet supported for multiband HMM');
            end
            
            group_maps = glean_connectivityprofile(model.hmm);
            
            % Save the group averaged maps
            disp('Saving group connectivity_profile map')
            for f = 1:F
                map = group_maps(:,:,f);
                switch GLEAN.settings.output.(output).format
                    case 'mat'
                        save(GLEAN.output.(output).groupmaps{f},'map');
                    case 'nii'
                        save2nii(map,GLEAN.output.(output).groupmaps{f},'parcel')
                end
            end
            
            
    end
    
end



    function save2nii(map,fname,space)
        % Have to work out what spatial basis set we're in:
        % pre-envelope parcellation (orthogonalisation) - use parcellation as mask
        % post-envelope parcellation or pca - use full voxelwise mask for pcorr,
        %                                   - use parcellation for connectivity profile
        
        switch space
            case 'voxel'
                writenii(map,fname,GLEAN.settings.output.(output).mask);
            case 'parcel'
                map = parcellation2map(map,GLEAN.settings.subspace.parcellation.file,GLEAN.settings.subspace.parcellation.mask);
                writenii(map,fname,GLEAN.settings.output.(output).mask);
        end

    end

end