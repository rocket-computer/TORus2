% Las medidas se aplican al average de cada condición 

%% VISUALIZE MEASURES PIXEL-WISE.
clear 

for nfish =  8%@ SET
user_settings

[VSDI] = TORus('load',nfish);

temp = TORus('loadmovie',nfish,'_09filt3');
movies = temp.data(:,:,1:end-1,:);

% windows in which analyse the measures

% windows = [0 100; 0 200; 100 200; 100 300] ; %@SET

cond_codes = [2000:2002];
  
%     cond_codes = unique(VSDI.condition(:,1));
%     cond_codes=  cond_codes(~isnan(cond_codes));
%     cond_codes = setdiff(cond_codes, 0);
%     cond_codes =[2000 2001 2002 2003 3000 3001 3002 4000 4001 4002 ]; %for nfish = 6 (#210412)

for reject_on = [0]  %@ SET

    setting.manual_reject = 0; %@ SET
    setting.GSmethod_reject = 1;  %@ SET
    setting.GSabsthres_reject = 1; %@ SET
    setting.force_include = 0; %@ SET
    
% out.folder = '/home/tamara/Documents/MATLAB/VSDI/TORus/plot/erps/test_measurements' ; %@ SET
out.folder = '/home/tamara/Documents/MATLAB/VSDI/TORus/plot/boxplot/boxplot+multcomp/preS_F0_filt09/maps';
%% SELECT CASES
    
    rejectidx = [];
    
    if setting.manual_reject
        rejectidx = [rejectidx  makeRow(VSDI.reject.manual)];
    end
    
    if setting.GSabsthres_reject
        rejectidx = [rejectidx  makeRow(VSDI.reject.GSabs025)];
        
    end
    
    if setting.GSmethod_reject
        rejectidx = [rejectidx makeRow(VSDI.reject.GSdeviat2sd)];
    end
    
    if setting.force_include
        rejectidx = setdiff(rejectidx, VSDI.reject.forcein);
        
    end
    
    rejectidx = sort(unique(rejectidx));
    
    
    
    %% 1. PEAK-2-PEAK MEASUREMENTS OF AVERAGE MOVIE
    
    % all windows for the function in 'ms'
    window.min = [-100 100]; 
    window.max = [0 600];
    window.movsum = 50;
    window.baseline = [-300 0];
    window.slope = 50;
    
    noise.SDfactor=4;
    noise.fr_abovenoise=30; 
    method = 'movsum';
    
%--------------------------------------
%1. APPLY FUNCTION TO THE AVERAGE-MOVIE FOR EACH CONDITION AND PLOT
%--------------------------------------
  tic
         j = 1;
        
        for condi = makeRow(cond_codes)
            sel_trials  = find(VSDI.condition(:,1)==condi);
            if reject_on  %@ SET      
                sel_trials = setdiff(sel_trials, rejectidx);     
            end
            
            avemovie = mean(movies(:,:,:,sel_trials),4);

            for rowi = 1:size(avemovie,1)
                for coli = 1:size(avemovie,2)
                wave = squeeze(avemovie(rowi, coli, :));
                output = devo_peak2peak(wave, VSDI.timebase, window,noise, method, 0);
                
                frames.peak2peak(rowi,coli,j) = output.p2p_value;
                frames.peakminusbasel(rowi,coli,j) = output.peakminusbasel;
                frames.peaklat(rowi,coli,j) = output.peaklat_ms;
                frames.p2plat(rowi,coli,j) = output.p2plat_ms;
                frames.onset30_latency_ms(rowi,coli,j) = output.onset30_latency_ms;
                frames.onsetnoise_ms(rowi,coli,j) = output.onsetnoise_ms;
                frames.noisethresh(rowi,coli,j) = output.noisethresh;
                frames.slopemax(rowi,coli,j) = output.slopemax;

                peakidx.tmin(rowi,coli,j) = output.peakidx(1); %it'll be used for the calculation o
                peakidx.tmax(rowi,coli,j) = output.peakidx(2); %it'll be used for the calculation o
                
                clear output
                end %coli
            end %rowi
          
            j = j+1;
            clear sel_trials 
            display(condi)
        end %condi
        
        t2 = toc
%         blob()
        
        %2. GET MAX-MIN AND PLOT THEM WITH THE SAME LIMITS
        maxval.peak2peak= max(abs(frames.peak2peak(:)));
        maxval.peakminusbasel= max(abs(frames.peakminusbasel(:)));
        maxval.peaklat= max(abs(frames.peaklat(:)));
        maxval.p2plat= max(abs(frames.p2plat(:)));
        maxval.onset30_latency_ms= max(abs(frames.onset30_latency_ms(:)));
        maxval.onsetnoise_ms= max(abs(frames.onsetnoise_ms(:)));
        maxval.noisethresh= max(abs(frames.noisethresh(:)));
        maxval.slopemax= max(abs(frames.noisethresh(:)));
    
        c_lim.peak2peak = [0 maxval.peak2peak(~isoutlier(maxval.peak2peak))];
        c_lim.peakminusbasel = [0 maxval.peakminusbasel(~isoutlier(maxval.peakminusbasel))];
        c_lim.peaklat = [0 maxval.peaklat(~isoutlier(maxval.peaklat))];
        c_lim.p2plat = [0 maxval.p2plat(~isoutlier(maxval.p2plat))];
        c_lim.onset30_latency_ms = [0 maxval.onset30_latency_ms];
        
        c_lim.onsetnoise_ms = [0 150];

        c_lim.noisethresh = [0 maxval.noisethresh(~isoutlier(maxval.noisethresh))];
        c_lim.slopemax = [0 maxval.slopemax(~isoutlier(maxval.slopemax))*0.5]; %smaller color limits

        BVmap = colormap_loadBV();
        
% %--------------------------------------
% %  PLOT peak2peak
% %--------------------------------------
% 
%         figure
%         localmap = jet; 
%         for ploti = 1:length(cond_codes)
% 
%             ax(ploti) = subplot(3,4,ploti);
%             imagesc(frames.peak2peak(:,:,ploti))
%             set (ax(ploti), 'clim', c_lim.peak2peak)
%             colormap(localmap)
%                 condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
%                 tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
%             title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
%             
%         end
%         
%         % plot colorbar
%         ax(11) = subplot(3,4,11);
%         colorbar
%         set (ax(11), 'clim', c_lim.peak2peak)
%         colormap(localmap)
%         
%         %plot brain
%         ax(12) = subplot(3,4,12);
%         imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
%         colormap(ax(12), bone)    
%         
%         if  reject_on
%             sgtitle([num2str(VSDI.ref), 'peak2peak for each cond (cl)'])
%         else
%             sgtitle([num2str(VSDI.ref), 'peak2peak for each cond'])
%             
%         end
%         
%         % save image and close @SET
%         if  reject_on
%             out.name =[num2str(VSDI.ref), '-peak2peak(average mov)settings1(clean)'];
%         else
%             out.name =[num2str(VSDI.ref), '-peak2peak(average mov)settings1'];
%             
%         end
%         
%         saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
%         close
%         
      
%--------------------------------------
%  PLOT peakminusbasel
%--------------------------------------
  

        figure
        localmap = jet;
        for ploti = 1:length(cond_codes)
            ax(ploti) = subplot(3,4,ploti);
            imagesc(frames.peakminusbasel(:,:,ploti))
            set (ax(ploti), 'clim', c_lim.peakminusbasel)
            colormap(localmap)
                condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
                tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
            title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
            
        end
        
        % plot colorbar
        ax(11) = subplot(3,4,11);
        colorbar
        set (ax(11), 'clim', c_lim.peakminusbasel)
        colormap(localmap)
        
        %plot brain
        ax(12) = subplot(3,4,12);
        imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
        colormap(ax(12), bone)    
        
        if  reject_on
            sgtitle([num2str(VSDI.ref), 'peak-basel (average mov) for each cond. (cl)'])
        else
            sgtitle([num2str(VSDI.ref), 'peak-basel (average mov) for each cond.'])
            
        end
        
        % save image and close @SET
        if  reject_on
            out.name =[num2str(VSDI.ref), '-peakminusbasel(average mov)settings1(clean)'];
        else
            out.name =[num2str(VSDI.ref), '-peakminusbasel(average mov)settings1'];
            
        end
        
        saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
        close

        
% %--------------------------------------
% %  PLOT onsetnoise_ms
% %--------------------------------------
  

        figure
        localmap = flipud(jet);
        for ploti = 1:length(cond_codes)
            ax(ploti) = subplot(3,4,ploti);
            imagesc(frames.onsetnoise_ms(:,:,ploti))
            set (ax(ploti), 'clim', c_lim.onsetnoise_ms)
            colormap(localmap)
                condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
                tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
            title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
            
        end
        
        % plot colorbar
        ax(11) = subplot(3,4,11);
        colorbar
        set (ax(11), 'clim', c_lim.onsetnoise_ms)
        colormap(localmap)
        
        %plot brain
        ax(12) = subplot(3,4,12);
        imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
        colormap(ax(12), bone)    
        
        if  reject_on
            sgtitle([num2str(VSDI.ref), 'onsetnoise_m_s (ave mov) for each cond. (cl)'])
        else
            sgtitle([num2str(VSDI.ref), 'onsetnoise_m_s (ave mov) for each cond.'])
            
        end
        
        % save image and close @SET
        if  reject_on
            out.name =[num2str(VSDI.ref), '-onsetnoise_ms(ave mov)settings1(clean)'];
        else
            out.name =[num2str(VSDI.ref), '-onsetnoise_ms(ave mov)settings1'];
            
        end
        
        saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
        close 
        
% % %--------------------------------------
% % %  PLOT noise_threshold
% % %--------------------------------------
% 
%         figure
%         localmap = jet;
%         for ploti = 1:length(cond_codes)
%             ax(ploti) = subplot(3,4,ploti);
%             imagesc(frames.noisethresh(:,:,ploti))
%             set (ax(ploti), 'clim', c_lim.noisethresh)
%             colormap(localmap)
%                 condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
%                 tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
%             title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
%             
%         end
%         
%         % plot colorbar
%         ax(11) = subplot(3,4,11);
%         colorbar
%         set (ax(11), 'clim', c_lim.noisethresh)
%         colormap(localmap)
%         
%         %plot brain
%         ax(12) = subplot(3,4,12);
%         imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
%         colormap(ax(12), bone)    
%         
%         if  reject_on
%             sgtitle([num2str(VSDI.ref), 'noise thresh (ave mov) for each cond. (cl)'])
%         else
%             sgtitle([num2str(VSDI.ref), 'noise thresh (ave mov) for each cond.'])
%             
%         end
%         
%         % save image and close @SET
%         if  reject_on
%             out.name =[num2str(VSDI.ref), '-noisethresh(ave mov)settings1(clean)'];
%         else
%             out.name =[num2str(VSDI.ref), '-noisethresh(ave mov)settings1'];
%             
%         end
%         
%         saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
%         close       

%--------------------------------------
%  PLOT peaklat
%--------------------------------------
%   
% 
%         figure
%         localmap = hot;
%         for ploti = 1:length(cond_codes)
%             ax(ploti) = subplot(3,4,ploti);
%             imagesc(frames.peaklat(:,:,ploti))
%             set (ax(ploti), 'clim', c_lim.peaklat)
%             colormap(localmap)
%                 condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
%                 tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
%             title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
%             
%         end
%         
%         % plot colorbar
%         ax(11) = subplot(3,4,11);
%         colorbar
%         set (ax(11), 'clim', c_lim.peaklat)
%         colormap(localmap)
%         
%         %plot brain
%         ax(12) = subplot(3,4,12);
%         imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
%         colormap(ax(12), bone)    
%         
%         if  reject_on
%             sgtitle([num2str(VSDI.ref), 'peaklat (average mov) for each cond. (cl)'])
%         else
%             sgtitle([num2str(VSDI.ref), 'peaklat (average mov) for each cond.'])
%             
%         end
%         
%         % save image and close @SET
%         if  reject_on
%             out.name =[num2str(VSDI.ref), '-peaklat(average mov)settings1(clean)'];
%         else
%             out.name =[num2str(VSDI.ref), '-peaklat(average mov)settings1'];
%             
%         end
%         
%         saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
%         close       
%         
% %--------------------------------------
% %  PLOT p2plat
% %--------------------------------------
% 
%         figure
%         localmap = hot;
%         for ploti = 1:length(cond_codes)
%             ax(ploti) = subplot(3,4,ploti);
%             imagesc(frames.p2plat(:,:,ploti))
%             set (ax(ploti), 'clim', c_lim.p2plat)
%             colormap(localmap)
%                 condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
%                 tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
%             title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
%             
%         end
%         
%         % plot colorbar
%         ax(11) = subplot(3,4,11);
%         colorbar
%         set (ax(11), 'clim', c_lim.p2plat)
%         colormap(localmap)
%         
%         %plot brain
%         ax(12) = subplot(3,4,12);
%         imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
%         colormap(ax(12), bone)    
%         
%         if  reject_on
%             sgtitle([num2str(VSDI.ref), 'p2plat (average mov) for each cond. (cl)'])
%         else
%             sgtitle([num2str(VSDI.ref), 'p2plat (average mov) for each cond'])
%             
%         end
%         
%         % save image and close @SET
%         if  reject_on
%             out.name =[num2str(VSDI.ref), '-p2plat(average mov)settings1(clean)'];
%         else
%             out.name =[num2str(VSDI.ref), '-p2plat(average mov)settings1'];
%             
%         end
%         
%         saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
%         close
%         
%       
% %--------------------------------------
% %  PLOT onset30_latency_ms
% %--------------------------------------
% 
%         figure
%         localmap = hot;
%         for ploti = 1:length(cond_codes)
%             ax(ploti) = subplot(3,4,ploti);
%             imagesc(frames.onset30_latency_ms(:,:,ploti))
%             set (ax(ploti), 'clim', c_lim.onset30_latency_ms)
%             colormap(localmap)
%                 condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
%                 tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
%             title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
%             
%         end
%         
%         % plot colorbar
%         ax(11) = subplot(3,4,11);
%         colorbar
%         set (ax(11), 'clim', c_lim.onset30_latency_ms)
%         colormap(localmap)
%         
%         %plot brain
%         ax(12) = subplot(3,4,12);
%         imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
%         colormap(ax(12), bone)    
%         
%         if  reject_on
%             sgtitle([num2str(VSDI.ref), '30%onset lat (average mov) for each cond (cl)'])
%         else
%             sgtitle([num2str(VSDI.ref), '30%onset lat (average mov) for each cond'])
%             
%         end
%         
%         % save image and close @SET
%         if  reject_on
%             out.name =[num2str(VSDI.ref), '-onset30lat(average mov)settings1 (clean)'];
%         else
%             out.name =[num2str(VSDI.ref), '-onset30lat(average mov)settings1'];
%             
%         end
%         
%         saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
%         close
%         
...
%--------------------------------------
%  PLOT slopemax
%--------------------------------------

        figure
        localmap = jet;
        for ploti = 1:length(cond_codes)
            ax(ploti) = subplot(3,4,ploti);
            imagesc(frames.slopemax(:,:,ploti))
            set (ax(ploti), 'clim', c_lim.slopemax)
            colormap(localmap)
                condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
                tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
            title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
            
        end
        
        % plot colorbar
        ax(11) = subplot(3,4,11);
        colorbar
        set (ax(11), 'clim', c_lim.slopemax)
        colormap(localmap)
        
        %plot brain
        ax(12) = subplot(3,4,12);
        imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
        colormap(ax(12), bone)    
        
        if  reject_on
            sgtitle([num2str(VSDI.ref), 'slope max lat (average mov) for each cond (cl)'])
        else
            sgtitle([num2str(VSDI.ref), 'slope max lat (average mov) for each cond'])
            
        end
        
        % save image and close @SET
        if  reject_on
            out.name =[num2str(VSDI.ref), '-slopemax(average mov)settings1 (clean)'];
        else
            out.name =[num2str(VSDI.ref), '-slopemax(average mov)settings1'];
            
        end
        
        saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
        close        

%% 2. PEAK-to-PEAK MEAN SLOPE OF AVERAGE MOVIE
    
    
    window_ave.min = [-100 100];
    window_ave.max = [0 600];
    window_ave.movsum = 50;%ms
    window_ave.baseline = [-300 0];
    window_ave.slope = 50;
    
    
    noise_ave.fr_abovenoise = 30;
    noise_ave.SDfactor = 4;
    
    lat_limit = 1000; %for trial rejection
    
    method = 'movsum';
    
%--------------------------------------
%1. APPLY FUNCTION TO THE AVERAGE-MOVIE FOR EACH CONDITION AND CALCULATE
%MEAN SLOPE
%--------------------------------------
  tic
         j = 1;
        
        for condi = makeRow(cond_codes)
            sel_trials  = find(VSDI.condition(:,1)==condi);
            if reject_on  %@ SET      
                sel_trials = setdiff(sel_trials, rejectidx);     
            end
            
            avemovie = mean(movies(:,:,:,sel_trials),4);

            for rowi = 1:size(avemovie,1)
                for coli = 1:size(avemovie,2)
                wave = squeeze(avemovie(rowi, coli, :));
                output = devo_peak2peak(wave, VSDI.timebase, window, noise, method, 0);
                
                idx0= dsearchn(VSDI.timebase, 0);%get 0 index
                waveW = wave(idx0:output.peakidx(2));
                waveslope = diff(waveW);
                meanslope = mean(waveslope);
                
                frames.meanslope(rowi, coli, j) = meanslope;
                end %COLI
            end %rowi
            j = j+1
        end %condi

        toc
%         blob()
                

 %2. GET MAX-MIN AND PLOT THEM WITH THE SAME LIMITS
 maxval.meanslope= max(abs(frames.meanslope(:)));
 c_lim.meanslope = [0 maxval.meanslope];

 
 BVmap = colormap_loadBV();


%--------------------------------------
%  PLOT mean-slope
%--------------------------------------

        figure
        localmap = jet;
        for ploti = 1:length(cond_codes)

            ax(ploti) = subplot(3,4,ploti);
            imagesc(frames.meanslope(:,:,ploti))
            set (ax(ploti), 'clim', c_lim.meanslope)
            colormap(localmap)
                condidx = find(VSDI.condition(:,1) ==cond_codes(ploti)); % get idx from condition
                tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
            title(['c',num2str(cond_codes(ploti)), '(', num2str(tempmA),'mA)'])
        end
        
        % plot colorbar
        ax(11) = subplot(3,4,11);
        colorbar
        set (ax(11), 'clim', c_lim.meanslope)
            colormap(localmap)
        
        %plot brain
        ax(12) = subplot(3,4,12);
        imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
        colormap(ax(12), bone)    
        
        if  reject_on
            sgtitle([num2str(VSDI.ref), 'mean slope (in peak-to-peak) for each cond (cl)'])
        else
            sgtitle([num2str(VSDI.ref), 'mean slope (in peak-to-peak)for each cond'])
            
        end
        
        % save image and close @SET
        if  reject_on
            out.name =[num2str(VSDI.ref), '-p2p mean slope (average mov)settings1 (clean)'];
        else
            out.name =[num2str(VSDI.ref), '-p2p mean slope (average mov)settings1'];
            
        end
        
        saveas(gcf,fullfile(out.folder,[out.name '.jpg']),'jpg')
        close
        
        blob()
end %reject_one
        clear

end %nfish 
blob() ; pause(0.1); blob()