%% FIGURE FAST SKETCH -

clear

% roi to analyze
roiname1 = 'dm4m_R';
roiname2 = 'dm2_R'; % dm2-R

% ref_wave = 'circ_filt309';
% ref_movie= '_09filt3' ;

ref_wave = 'filt512';
ref_movie= '_12filt5' ;


savein = '/home/tamara/Documents/MATLAB/VSDI/TORus/plot/informes/03_figure_sketch/fast_plot' ;%@ SET
load('/home/tamara/Documents/MATLAB/VSDI/TORus/plot/informes/03_figure_sketch/fast_condition_list.mat')

% COMMON SETTINGS FOR THE FUNCTION
feedf.window.min = [-100 100]; % 'feed-function' structure
feedf.window.max = [0 1000];
feedf.window.movsum = 50;
feedf.window.basel = [-100 0];
feedf.window.slope=50;
feedf.window.wmean=[0 250];

feedf.noise.fr_abovenoise = 30;
feedf.noise.SDfactor = 2;

% Window For average-based analysis

feedf.window_ave = feedf.window;

feedf.noise_ave = feedf.noise;
feedf.noise_ave.SDfactor = 4;% SET differences


feedf.method = 'movsum';
% END OF SETTINGS


% USER SETTINGS
path.rootpath = '/home/tamara/Documents/MATLAB/VSDI/TORus'; %@ SET for each experiment
tempsep.idcs   = strfind(path.rootpath,'/');
tempsep.newdir = path.rootpath(1:tempsep.idcs(end));

path.data = fullfile(path.rootpath, 'data');
path.grouplist = fullfile(path.rootpath);
path.list =fullfile(path.rootpath, 'data','BVlists');


addpath(genpath(fullfile(tempsep.newdir, 'VSDI_ourToolbox', 'functions')));

% end of user_settings

        %----------------------------------------------------------------
        % @SET: REJECT SETTINGS
        %----------------------------------------------------------------
        
        reject_on = [0];  %@ SET
        % Subsettings:
        setting.manual_reject = 0; %@ SET
        setting.GSmethod_reject = 1;  %@ SET
        setting.GSabsthres_reject = 1; %@ SET+
        setting.force_include = 0; %@ SET


%% A: TILES CON CURVITA -CIRCULAR PLOT
clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave path ref_movie setting reject_on
reject_on = 0;

for block = [12] %[1:3 6:10]%1:length(fast_condition_list)
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load', nfish);
    VSDmov = TORus('loadmovie',nfish,ref_movie);
    
    
    roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
    roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
    
    
        %----------------------------------------------------------------
        % COMPUTE REJECTION 
        %----------------------------------------------------------------
        
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
    
    for condi = makeRow(trial_kinds)
        
        
        %----------------------------------------------------------------
        % CONTINUE CODE
        %----------------------------------------------------------------        
        
        [idxA] = find(VSDI.condition(:,1)==condi);
        %     [idxB] = find(VSDI.condition(:,1)==force0ending(condi));
        
        if reject_on 
            idxA = setdiff(idxA, rejectidx);
        end
        
        
        %to plot single trial
        movie2plot = mean(VSDmov.data(:,:,:,idxA),4) ;
        movie2plot(:,:,end) = roi_crop(VSDI.backgr(:,:,VSDI.nonanidx(1)), VSDI.crop.mask); %substitute by non-filtered background
        
        % apply crop mask
        movie2plot = roi_crop(movie2plot, VSDI.crop.mask);
        
        % FUNCTION SETTINGS
        
        movieset.data =movie2plot;
        movieset.times = VSDI.timebase;
        
        tileset.start_ms = 100;
        tileset.end_ms = 250;
        tileset.time2plot = 0; %select time (ms)
%         tileset.clims = [-0.25 0.25];%  values above or below will be saturated
%         tileset.thresh = [-0.1 0.1]; %% values inside this range will be zero-out
% 
            tileset.clims = [-0.13 0.13];% LOWER values above or below will be saturated
            tileset.thresh = [-0.035 0.035]; %%LOWER values inside this range will be zero-out
%         
        waveset.coord =  VSDI.roi.circle.center([roi1 roi2],:);
        waveset.r = VSDI.roi.circle.R;
        waveset.xlim = [0 600];
        waveset.ylim =tileset.clims;
        
        % END OF FUNCTION SETTINGS
        
        % ------------------
        % APPLY FUNCTION
        % ------------------
        devo_plot_tiles_4frames_nwaves(movieset, tileset,waveset)
        % ------------------
        
        % ADJUSTMENTS FOR THE PLOT 
        % Plot the threshold and clims:
        yline(tileset.thresh(2), 'b--')
        yline(tileset.clims(2), 'r--')
        
        tempmA = num2str(VSDI.condition(idxA(1),4));
        titulo = [num2str(VSDI.ref), ':', tempmA,'mA (cod=',num2str(condi),cond_def, ')' ];
        sgtitle(titulo)
        name2save = fullfile(savein,['plot_A_tiles_simple',num2str(VSDI.ref),'cod' ,num2str(condi) , 'dataset',ref_movie, '_reject' num2str(reject_on) '.jpg']);
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 3]);
        saveas(gcf,name2save,'jpg')
        close
%         
    end % condi
end %block

blob()

%% A2: TILES CON CURVITA -ANATOMICAL PLOT
clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave path ref_movie

for block = 4 %1:length(fast_condition_list)
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load', nfish);
    VSDmov = TORus('loadmovie',nfish,ref_movie);
    
    
    roi1 = name2idx(roiname1, VSDI.roi.labels);
    roi2 = name2idx(roiname2, VSDI.roi.labels);
    
    for condi = makeRow(trial_kinds)
        [idxA] = find(VSDI.condition(:,1)==condi);
        %     [idxB] = find(VSDI.condition(:,1)==force0ending(condi));
        
        %to plot single trial
        movie2plot = mean(VSDmov.data(:,:,:,idxA),4) ;
        movie2plot(:,:,end) = roi_crop(VSDI.backgr(:,:,VSDI.nonanidx(1)), VSDI.crop.mask); %substitute by non-filtered background
        
        % apply crop mask
        movie2plot = roi_crop(movie2plot, VSDI.crop.mask);
        
        % FUNCTION SETTINGS
        
        movieset.moviedata =movie2plot;
        movieset.times = VSDI.timebase;
        
        tileset.start_ms = 100;
        tileset.end_ms = 250;
        tileset.time2plot = 0; %select time (ms)
        tileset.clims = [-0.25 0.25];%  values above or below will be saturated
        tileset.thresh = [-0.1 0.1]; %% values inside this range will be zero-out
        
        % ...for anatomical-roi waves
        %         waveset.coord =  VSDI.roi.manual_poly([roi1,roi2],1);
        %         waveset.mask = VSDI.roi.manual_mask(:,:,[roi1,roi2]);
        %         waveset.xlim = [0 600];
        %         waveset.ylim = [-0.5 tileset.clims(2)];
        
        % ...for circular samples
        waveset.coord =  VSDI.roi.circle.center([roi1 roi2],:);
        waveset.coord(1,1) =  35; % CHANGE COORDINATES for fish 11
        waveset.coord(2,2) =  31;
        
        waveset.r = VSDI.roi.circle.R;
        waveset.xlim = [0 600];
        waveset.ylim = [-0.05 tileset.clims(2)];
        
        % END OF FUNCTION SETTINGS
        
        % ------------------
        % APPLY FUNCTION
        % ------------------
        devo_plot_tiles_4frames_nwaves(movieset, tileset,waveset)
        %         devo_plot_tiles_4frames_anatomicalwaves(movieset, tileset,waveset)
        
        % ------------------
        
        % ADJUSTMENTS
        % Plot the threshold and clims:
        yline(tileset.thresh(2), 'b--')
        yline(tileset.clims(2), 'r--')
        
        tempmA = num2str(VSDI.condition(idxA(1),4));
        titulo = [num2str(VSDI.ref), ':', tempmA,'mA (cod=',num2str(condi),cond_def, ')' ];
        sgtitle(titulo)
        name2save = fullfile(savein,['plot_A_tiles_simple',num2str(VSDI.ref),'cod' ,num2str(condi) , 'dataset',ref_movie,'.jpg']);
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 3]);
        saveas(gcf,name2save,'jpg')
        close
        
    end % condi
end %block

blob()
%% B1 - PEAKMAP with cropmask
clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave path ref_movie

for block = [1 6] %1:length(fast_condition_list)
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load', nfish);
    VSDmov = TORus('loadmovie',nfish,ref_movie);
    movies = VSDmov.data;
    
    measure = {'peakminusbasel'};
    
    peakmap.clims = [0 0.3];%  values above or below will be saturated
    peakmap.thresh = [-0.01 0.01]; %% values inside this range will be zero-out
    
    %--------------------------------------
    %1. APPLY FUNCTION TO THE AVERAGE-MOVIE FOR EACH CONDITION AND PLOT
    %--------------------------------------
    j = 1;
    
    for condi = makeRow(trial_kinds)
        sel_trials  = find(VSDI.condition(:,1)==condi);
        
        avemovie = mean(movies(:,:,:,sel_trials),4);
        
        for rowi = 1:size(avemovie,1)
            for coli = 1:size(avemovie,2)
                wave = squeeze(avemovie(rowi, coli, :));
                output = devo_peak2peak(wave, VSDI.timebase, feedf.window_ave,[], feedf.method, 0, 0);
                
                frames.peakminusbasel(rowi,coli,j) = output.peakminusbasel;
                
                peakidx.tmin(rowi,coli,j) = output.peakidx(1); %it'll be used for the calculation o
                peakidx.tmax(rowi,coli,j) = output.peakidx(2); %it'll be used for the calculation o
                
                clear output
            end %coli
        end %rowi
        
        j = j+1;
        %     display(condi)
        clear sel_trials
        
    end %condi
    %         blob()
    
    %2. GET MAX-MIN AND PLOT THEM WITH THE SAME LIMITS
    maxval.peakminusbasel= max(abs(frames.peakminusbasel(:)));
    c_lim.peakminusbasel = [0 maxval.peakminusbasel(~isoutlier(maxval.peakminusbasel))];
    
    
    %----------------------------------------------------------------
    %3. CONFIGURATION OF PARAMETERS THAT ARE SPECIFIC FOR EACH MEASURE
    %----------------------------------------------------------------
    measureframe= [];
    localset.clim = [];
    
    
    measureframe = frames.peakminusbasel;
    
    localset.map = jet;
    localset.map(1,:) = [0 0 0];
    
    localset.clim = c_lim.peakminusbasel;
    
    
    localset.title = [num2str(VSDI.ref), 'peak-b for each cond block' num2str(trial_kinds(1))];
    
    
    %GET MAX AND PLOT THEM WITH THE SAME LIMITS
    localset.max = max(abs(measureframe(:)));
    
    
    
    % %--------------------------------------
    % %  PLOT MEASURES
    % %--------------------------------------
    
    figure
    
    for ploti = 1:length(trial_kinds)
        
        ax(ploti) = subplot(3,4,ploti);
        cropped_im = roi_crop(measureframe(:,:,ploti), VSDI.crop.mask);
        cropped_back = roi_crop(VSDI.backgr(:,:,VSDI.nonanidx(1)), VSDI.crop.mask);
        imagesc(cropped_im);
        %         set (ax(ploti), 'clim', localset.clim) peakmap.clims
        set (ax(ploti), 'clim', peakmap.clims)
        
        colormap(localset.map)
        condidx = find(VSDI.condition(:,1) ==trial_kinds(ploti)); % get idx from condition
        tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
        title(['c',num2str(trial_kinds(ploti)), '(', num2str(tempmA),'mA)'])
        clear cropped_im cropped_back condidx tempmA
        axis image
    end
    
    % plot colorbar
    ax(11) = subplot(3,4,11);
    colorbar
    %     set (ax(11), 'clim', localset.clim)
    set (ax(11), 'clim', peakmap.clims)
    
    colormap(localset.map)
    
    %plot brain
    ax(12) = subplot(3,4,12);
    imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
    colormap(ax(12), bone)
    axis image
    
    sgtitle([localset.title '(' cond_def ')'])
    
    
    name2save = fullfile(savein,['plot_B1_peakmap' localset.title ref_movie '.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    
    close
    clear localset measureframe maxval c_lim
    
    
end %block
blob()
%% B2 SLOPEMEAN-MAP with cropmask
clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave path ref_movie

for block = 1:length(fast_condition_list)
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load', nfish);
    VSDmov = TORus('loadmovie',nfish,ref_movie);
    movies = VSDmov.data;
    
    measure = {'slopemean'};
    
    peakmap.clims = [-0.1 0.1];%  values above or below will be saturated
    peakmap.thresh = [-0.01 0.01]; %% values inside this range will be zero-out
    
    %--------------------------------------
    %1. APPLY FUNCTION TO THE AVERAGE-MOVIE FOR EACH CONDITION
    %--------------------------------------
    
    j = 1;
    
    for condi = makeRow(trial_kinds)
        sel_trials  = find(VSDI.condition(:,1)==condi);
        avemovie = mean(movies(:,:,:,sel_trials),4);
        
        for rowi = 1:size(avemovie,1)
            for coli = 1:size(avemovie,2)
                wave = squeeze(avemovie(rowi, coli, :));
                output = devo_peak2peak(wave, VSDI.timebase, feedf.window_ave, [], feedf.method, 0, 0);
                
                idx0= dsearchn(VSDI.timebase, 0);%get 0 index
                idxpeak = output.peakidx(2);
                
                %mean slope from zero to max peak
                waveW = wave(idx0:idxpeak);
                slopemean = mean(diff(waveW));
                
                measureframe(rowi, coli, j) = slopemean;
            end %coli
        end %rowi
        j = j+1;
        clear sel_trials
    end % condi
    
    %GET MAX AND PLOT THEM WITH THE SAME LIMITS
    localset.max = max(abs(measureframe(:)));
    
    
    % 2. CONFIGURE THE OTHER PARAMETERS
    localset.map = jet;
    localset.map(1,:) = [0 0 0];
    
    localset.clim = [0 localset.max];
    
    localset.title = [num2str(VSDI.ref), 'slopemean for each cond - block' num2str(trial_kinds(1))];
    
    
    % %--------------------------------------
    % %  PLOT MEASURES
    % %--------------------------------------
    
    figure
    
    for ploti = 1:length(trial_kinds) %one plot for each condition
        
        ax(ploti) = subplot(3,4,ploti);
        cropped_im = roi_crop(measureframe(:,:,ploti), VSDI.crop.mask);
        cropped_back = roi_crop(VSDI.backgr(:,:,VSDI.nonanidx(1)), VSDI.crop.mask);
        imagesc(cropped_im);
        set (ax(ploti), 'clim', localset.clim)
        colormap(localset.map)
        condidx = find(VSDI.condition(:,1) ==trial_kinds(ploti)); % get idx from condition
        tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
        title(['c',num2str(trial_kinds(ploti)), '(', num2str(tempmA),'mA)'])
        clear cropped_im cropped_back condidx tempmA
        axis image
    end
    
    % plot colorbar
    ax(11) = subplot(3,4,11);
    colorbar
    set (ax(11), 'clim', localset.clim)
    colormap(localset.map)
    
    %plot brain (background)
    ax(12) = subplot(3,4,12);
    imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
    colormap(ax(12), bone)
    axis image
    sgtitle([localset.title '(' cond_def ')'])
    
    
    name2save = fullfile(savein,['plot_B2_slopemap' localset.title ref_movie '.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    
    close
    clear localset measureframe maxval c_lim
    
    
end %block
blob()

%% B3 WMEAN-MAP with cropmask
clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave path ref_movie

for block = 4
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load', nfish);
    VSDmov = TORus('loadmovie',nfish,ref_movie);
    movies = VSDmov.data;
    
    measure = {'wmean'};
    
    peakmap.clims = [-0.1 0.1];%  values above or below will be saturated
    peakmap.thresh = [-0.01 0.01]; %% values inside this range will be zero-out
    
    %--------------------------------------
    %1. APPLY FUNCTION TO THE AVERAGE-MOVIE FOR EACH CONDITION
    %--------------------------------------
    
    j = 1;
    
    for condi = makeRow(trial_kinds)
        sel_trials  = find(VSDI.condition(:,1)==condi);
        avemovie = mean(movies(:,:,:,sel_trials),4);
        
        for rowi = 1:size(avemovie,1)
            for coli = 1:size(avemovie,2)
                wave = squeeze(avemovie(rowi, coli, :));
                output = devo_peak2peak(wave, VSDI.timebase, feedf.window_ave, [], feedf.method, 0, 0);
                
                measureframe(rowi, coli, j) = output.wmean;
            end %coli
        end %rowi
        j = j+1;
        clear sel_trials
    end % condi
    
    %GET MAX AND PLOT THEM WITH THE SAME LIMITS
    localset.max = max(abs(measureframe(:)));
    
    
    % 2. CONFIGURE THE OTHER PARAMETERS
    localset.map = jet;
    localset.map(1,:) = [0 0 0];
    
    localset.clim = [0 localset.max];
    
    localset.title = [num2str(VSDI.ref), 'slopemean for each cond'];
    
    
    % %--------------------------------------
    % %  PLOT MEASURES
    % %--------------------------------------
    
    figure
    
    for ploti = 1:length(trial_kinds) %one plot for each condition
        
        ax(ploti) = subplot(3,4,ploti);
        cropped_im = roi_crop(measureframe(:,:,ploti), VSDI.crop.mask);
        cropped_back = roi_crop(VSDI.backgr(:,:,VSDI.nonanidx(1)), VSDI.crop.mask);
        imagesc(cropped_im);
        set (ax(ploti), 'clim', localset.clim)
        colormap(localset.map)
        condidx = find(VSDI.condition(:,1) ==trial_kinds(ploti)); % get idx from condition
        tempmA = VSDI.condition(condidx(1),4); %get mA from first trial that meet the condition
        title(['c',num2str(trial_kinds(ploti)), '(', num2str(tempmA),'mA)'])
        clear cropped_im cropped_back condidx tempmA
        axis image
    end
    
    % plot colorbar
    ax(11) = subplot(3,4,11);
    colorbar
    set (ax(11), 'clim', localset.clim)
    colormap(localset.map)
    
    %plot brain (background)
    ax(12) = subplot(3,4,12);
    imagesc(VSDI.backgr(:,:,VSDI.nonanidx(1)));
    colormap(ax(12), bone)
    axis image
    sgtitle([localset.title '(' cond_def ')'])
    
    
    name2save = fullfile(savein,['plot_B3_wmean' localset.title '.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    
    close
    clear localset measureframe maxval c_lim
    
    
end %block
blob()
%% C: PLOT mA vs peak (reference from circle or anatomical roi)

clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein roinames ref_wave ref_movie

%SETTINGS
outfolder = '/home/tamara/Documents/MATLAB/VSDI/TORus/plot/brady';
excelname = fullfile(outfolder,'brady_grouped_bycondition.xlsx');

% set(0,'DefaultFigureVisible','off')


%END OF USER SETTINGS

% ---------------------------------------------------------------------------
% AMPLITUDE TRIAL-WISE TO PLOT BY CONDITION
% ---------------------------------------------------------------------------
% roikind = 'circular';
roikind = 'anatomical';

ref_wave = 'filt512';

% measure = 'wmean';
measure = 'peakminusbasel';


for  block =  1:length(fast_condition_list)
    
    nfish = fast_condition_list{block,1};
    
    trial_kinds = fast_condition_list{block,2};
    cond_def =fast_condition_list{block,3};
    
    VSDI = TORus('load',nfish);
    %     spike = TORus('loadspike', nfish); % ECG
    VSDroiTS =TORus('loadwave',nfish);
    
    
    % roi settings according to the chosen kind
    switch roikind
        case 'circular'
            roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
            roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
            ref_wave = ['circ_' ref_wave ];
        case 'anatomical'
            roi1 = name2idx(roiname1, VSDI.roi.labels);
            roi2 = name2idx(roiname2, VSDI.roi.labels);
            
            waves = VSDroiTS.(ref_wave).data; %@ SET
    end
            %     output = {'trial', 'spiketime', 'cond','mA','', '%brady(count)','', 'IBIbasel', 'ibi0', 'ibi1','ibi2','ibi3','', 'estimation','dm4','dm4m','dm2','dldm'}; %header first
            
            
            % ----------------------------------------------
            % BRAINVISION/WAVE-BASED MEASURES
            % ----------------------------------------------
            for triali =  makeRow (VSDI.nonanidx)
                
                for nroi = [roi1 roi2]
                    wave = squeeze(waves(:, nroi,triali));
                    local_output = devo_peak2peak(wave, VSDI.timebase, feedf.window,[], feedf.method, 0);
                    
                    peak(triali, nroi) = local_output.(measure);
                    clear wave local_output
                end
                
            end %triali
            
            % ----------------------------------------------
            % MEAN VALUES FOR EACH CONDITION
            % ----------------------------------------------
            
            % HEADER
            j = 1;
            for condi = makeRow( trial_kinds)
                sel_trials = find(VSDI.condition(:,1) == condi);
                meanAct(j,1) = mean(peak(sel_trials,roi1));
                meanAct(j,2) = mean(peak(sel_trials,roi2));
                
                
                semAct(j,1) =  std(peak(sel_trials,roi1))/sqrt(length(peak(sel_trials,roi1)));%dm4
                semAct(j,2) =  std(peak(sel_trials,roi2))/sqrt(length(peak(sel_trials,roi2))); %dm4m
                
                
                mA(j) = VSDI.condition(sel_trials(1),4) ;
                
                j=j+1;
                clear sel_trials
            end
            
            %         % for the plot
            %         condlabel(k-1) = which_cond;
            %         roiactiv(k-1,1) = mean(output(cond_trials,1)); % dm4
            %         roiactiv(k-1,2) = mean(output(cond_trials,2)); % dm4m
            %         roiactiv(k-1,3) = mean(output(cond_trials,3)); % dm2
            %         roiactiv(k-1,4) = mean(output(cond_trials,4)); % dldm
            
            % ADAPT 'mA' (for x-axis labels) if there is a tone
            
            if mA(2) == 0 || isnan(mA(2)) % if the second condition is NaN or 0, then it is a tone and some adjustements are needed to be plotted
                flag_adapt =1;
                mA(1) = -0.5; mA(2) = 0;
                
                labels{1} = '0';labels{2} = 'tone';
                
                for ii = 3:length(mA)
                    labels{ii} =  num2str(mA(ii));
                end
            else
                
                flag_adapt =0;
                
            end
            
            
            figure
            errorbar(mA, meanAct(:,1), semAct(:,1), 'o-','linewidth', 1.8)
            hold on
            errorbar(mA, meanAct(:,2), semAct(:,2), 'o-','linewidth', 1.8)
            
            roinames{1} = roiname1;
            roinames{2} = roiname2;
            
            legend(roinames)
            
            
            xticks(mA);
            
            if flag_adapt
                xticklabels(labels)
            end
            
            
            xlim([min(mA)-0.5, max(mA)+0.5])
%             ylim([0.05 0.4])
            xlabel('mA'); ylabel([measure ' mean \pm sem'])
            title ([measure ,':',  num2str(VSDI.ref), cond_def, '(', num2str(trial_kinds(1)) , ')'])
            
            % ----------------------------------------------
            % WRITE EXCEL
            % ----------------------------------------------
            %     if export.excel == 1
            %         % write output (new sheet for each fish
            %         localoutput = cell2table(localoutput);
            %         writetable (localoutput, excelname, 'sheet', num2str(VSDI.ref))
            %     end
            
            name2save = fullfile(savein,['plot_C_MeanSem_trialwise_' num2str(VSDI.ref) '_block' num2str(condi(1)) , 'dataset_', ref_wave, '_' measure '.jpg']);
            set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
            saveas(gcf,name2save,'jpg')
            
            close
            clear mA meanAct stdAct  peak
            
    end %nfish
    
    blob()

    %% D – CURVAS COND SOLAPADAS POR REGIÓN
    clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein ref_wave path
    % ref_wave = 'circ_filt512';
    ref_wave = 'filt517';
    
    %----------------------------------------------------------------
    % @SET: fish + conditions
    %----------------------------------------------------------------
    for  block = [11 12]% 1:length(fast_condition_list)
        
        % Get selection to be analyzed from structure
        nfish = fast_condition_list{block,1};
        trial_kinds = fast_condition_list{block,2};
        descript = fast_condition_list{block,3};
        
        %----------------------------------------------------------------
        % @SET: MEASURE (OR LOOP THROUGH ALL MEASURES)
        %----------------------------------------------------------------
        
        %     waveslim.ave = [-0.2 0.4]; %ylim for pltting average waves
        %     waveslim.all = [-0.2 0.6]; %ylim for plotting all waves (has to be higher)
        
        
        [VSDI] = TORus('load',nfish);
        
        roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
        roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
        
        VSDroiTS = TORus('loadwave',nfish);
        waves = VSDroiTS.(ref_wave).data; %@ SET
        
        
        selroi = [roi1 roi2];
        
        
        clearvars -except measure reject_on nfish trial_kinds VSDI movies waves fcode ...
            feedf.window feedf.window_ave feedf.noise feedf.noise_ave rejectidx roiname1 roiname2 feedf.method lat_limit...
            wavesylim selroi setting  fast_condition_list descript roi1 roi2 roiname1 roiname2 feedf...
            fast_condition_list savein ref_wave path
        
        %@ SET : SELECT ONLY 2 ROIS (the code is hardwired to accept only 2 of them)
        
        % SELECT CASES
        sel_trials= [];
        
        for condi = makeRow(trial_kinds) %to make sure that only the conditions of interest are computed)
            condtrials = makeCol(find(VSDI.condition(:,1)==condi));
            sel_trials  = [sel_trials; condtrials];
        end
        
        sel_trials= sort(sel_trials);
        
        
        % ONSET OF  WAVES FROM CIRCULAR ROIS FROM ONE CONDITION AVERAGE
        
        % build color matrix
        colors = lines(length(trial_kinds));
        
        figure
        ploti = 1;%counter
        
        for nroi = makeRow(selroi)
            
            ax(ploti) = subplot(1,2,ploti); %waves from all conditions in the first column (loop through conditions)
            hold on;
            
            j = 1; %counter for legend labels
            
            for codi = 1:length(trial_kinds)
                code = trial_kinds(codi);
                tricond = intersect(find(VSDI.condition(:,1) == code) , sel_trials);
                codemA(codi)= VSDI.condition(tricond(1),4); %mA corresponding to the code label (for the next subplot)
                roiwave = mean(waves(:,nroi,tricond),3) ;
                
                hold on;
                output = devo_peak2peak(roiwave, VSDI.timebase, feedf.window, feedf.noise, feedf.method, 0, 0);
                
                idx0= dsearchn(VSDI.timebase, 0);
                
                %             waveW = roiwave(idx0:output.peakidx(2));
                %             slopemean(nroi, codi) = mean(diff(waveW));
                
                %             slopemax(nroi,codi) = output.slopemax;
                %             peak(nroi,codi) = output.peakminusbasel;
                
                plot(VSDI.timebase,roiwave, 'color', colors(codi,:), 'linewidth', 3); hold on %  'linewidth', 1.8
                
                %         ylim([-0.2 .3])
                %             ylim(waveslim.ave)
                
                xlim([-300 600])

                ylabel('%\Delta F (trials ave)');
                
                title([ VSDI.roi.labels_circ{nroi}])
                
                
                clear output roiwave waveW slopeval
                
                legend_labels{j} =[ num2str(VSDI.condition(tricond(1),4)) 'mA'];
                j = j+1;
                
            end %codi
            
            
            hold off
            
            
            ploti = ploti+1;
            
            
        end %  roi
        %     set(ax, 'ylim', [-0.05 0.32])
        set(ax, 'ylim', [-0.05 0.5])
        
        legend(legend_labels, 'location', 'southeast')
        
        
        sgtitle([num2str(VSDI.ref), '(', descript, ')' ])
        
        name2save = fullfile(savein,['plot_D_solapadas' num2str(VSDI.ref) '_' num2str(condi(1)) '_' ref_wave '.jpg']);
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
        saveas(gcf,name2save,'jpg')
        close
    end
    blob()
    
    %% E - LOW vs HIGH: peak activity + brady
    % output values in csv for R (it is not worth doing this on matlab)
    
    clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein ref_wave path
    
    %----------------------------------------------------------------
    % @SET: fish + conditions + description
    %----------------------------------------------------------------
    list{1,1} = 11; %subject
    list{1,2} = [400 401 404]; %conditions to include
    list{1,3} = 'pulso 0,15ms'; % description
    
    list{2,1} = 3;
    list{2,2} = [300 302 303];
    list{2,3} = 'tren 10ms';
    
    %----------------------------------------------------------------
    % LOOP THROUGH LIST OF SUBJECTS AND CONDITIONS
    %----------------------------------------------------------------
    
    for ii = 1:2
        nfish = list{ii,1};
        trial_kinds = list{ii,2};
        description = list{ii,3};
        
        
        [VSDI] = TORus('load',nfish);
        [spike] = TORus('loadspike', nfish); % ECG
        [VSDroiTS] = TORus('loadwave',nfish);
        
        waves = VSDroiTS.(ref_wave).data; %@ SET
        
        
        roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
        roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
        
        %----------------------------------------------------------------
        % GET PEAK
        %----------------------------------------------------------------
        
        for triali =  makeRow (VSDI.nonanidx)
            
            for nroi = [roi1 roi2]
                wave = squeeze(waves(:, nroi,triali));
                local_output = devo_peak2peak(wave, VSDI.timebase, feedf.window,[], feedf.method, 0);
                
                peak(triali, nroi) = local_output.peakminusbasel;
                clear wave local_output
            end
            
        end %triali
        
        
        % MEAN VALUES FOR EACH CONDITION
        
        j = 1; %condition counter
        for condi = makeRow( trial_kinds)
            sel_trials = find(VSDI.condition(:,1) == condi);
            meanAct(ii,j,1) = mean(peak(sel_trials,roi1));
            meanAct(ii,j,2) = mean(peak(sel_trials,roi2));
            
            mA(ii,j) = VSDI.condition(sel_trials(1),4) ;
            
            j=j+1;
            clear sel_trials
        end
        
        
        % ADAPT 'mA' (for x-axis labels) if there is a tone
        
        if mA(ii,2) == 0 || isnan(mA(ii,2)) % if the second condition is NaN or 0, then it is a tone and some adjustements are needed to be plotted
            flag_adapt =1;
            mA(ii,1) = -0.5; mA(ii,2) = 0;
            
            labels{ii,1} = '0';labels{ii,2} = 'tone';
            
            for jj= 3:length(mA)
                labels{ii,jj} =  num2str(mA(ii));
            end
        else
            
            flag_adapt =0;
            
        end
        
        %----------------------------------------------------------------
        % GET BRADY: SPIKE-BASED MEASURES FOR EACH TRIAL
        %----------------------------------------------------------------
        w.pre= 10; % ventana pre-estímulo(en segundos) , de los que se va a tomar las espigas para hacer la media de frecuencia instantánea o el conteo
        w.post = w.pre/2; %sólo para el conteo
        
        for triali =  makeRow (VSDI.nonanidx)
            
            % ----------------------------------------------
            % SPIKE(ecg)-BASED MEASURES
            % ----------------------------------------------
            if  VSDI.spike.RO(triali) == 0
                flag_noROspike = 1;
            else
                flag_noROspike = 0;
                
            end
            
            
            if ~flag_noROspike
                
                stim = VSDI.spike.RO(triali)+VSDI.info.Sonset/1000 ; %stimulus arrival time (in spike) for this trial (RO time here has already left out the shutter delay, so we dont have to sum it up)
                
                
                % 1. LEAVE OUT STIMULUS NOISE (if it's a somatic stimulus):
                
                % Get safety window to remove US noise
                if (VSDI.list(triali).Sdur >= 60) & (VSDI.condition(triali,4) >= 1) % EXPERIMENT-SPECIFIC PARAMETER: if it is a long train (60ms) of 1mA or more
                    noisewin = 430/1000; % (430ms) empirically measured from the noise captured by the cup-electrodes
                else
                    noisewin = VSDI.info.Sdur(triali)/1000+ 0.03; %+0.03security window (from spike, the events normally have a 0.02 minimum step from spike to spike)
                end
                
                % 2. Clean the spikes due to that trial's noise
                clean_spikes = spike.spikes(spike.spikes<stim -0.01); %keep all before the stim (excluding another prestim safety window)
                
                if ~isnan(VSDI.condition(triali,1))% IF IT IS NaN, IT IS A TONE, so the artifact due to the stim does not exist
                    clean_post = spike.spikes(spike.spikes> stim + noisewin );
                else % If it is a tone, no 'noisewin' clearing is needed
                    clean_post = spike.spikes(spike.spikes> stim);
                    
                end
                clean_spikes = [clean_spikes; clean_post];
                
                % 3. GET IDX FOR BRADYCHARDIA MEASURE FROM THE CLEANED HEART
                % SPIKES
                idx_pre = find(clean_spikes > stim-w.pre  & clean_spikes < stim);
                
                idx_post =  find(clean_spikes > stim  & clean_spikes < stim+ w.post);
                idx_spike0 = find(clean_spikes> stim, 1, 'first');
                
                % bradycardia counting
                precount = length(idx_pre);
                postcount = length(idx_post)*2;
                brady_count = ((precount - postcount)/precount)*100;
                
                % IBI calculation
                preibi = mean(diff(clean_spikes(idx_pre)));
                
                post0 = clean_spikes(idx_spike0) - clean_spikes(idx_spike0-1);
                post1 = clean_spikes(idx_spike0+1) - clean_spikes(idx_spike0);
                post2 = clean_spikes(idx_spike0+2) - clean_spikes(idx_spike0+1);
                post3 = clean_spikes(idx_spike0+3) - clean_spikes(idx_spike0+2);
                
                % PERCENT IBI calculation
                perc0 = ((post0 - preibi) / preibi)*100;
                perc1 = ((post1- preibi) / preibi)*100;
                perc2 = ((post2 - preibi) / preibi)*100;
                perc3 = ((post3 - preibi) / preibi)*100;
                
                
                % ----------------------------------------------
                % OUTPUT
                % ----------------------------------------------
                
                output(triali,1) = round(brady_count);
                
                output(triali,2) = preibi;
                output(triali,3) = post0;
                output(triali,4) = post1;
                output(triali,5) = post2;
                output(triali,6) = post3;
                
                output(triali,7) = perc0;
                output(triali,8) = perc1;
                output(triali,9) = perc2;
                output(triali,10) = perc3;
                
                
            end % flag
            
            
        end %triali
        
        
        % MEAN VALUES FOR EACH CONDITION
        k = 1;
        for which_cond =  makeRow(trial_kinds)
            
            cond_trials = find(VSDI.condition(:,1) == which_cond);
            
            %         meanbrady(ii,k,1) = mean(output(cond_trials,1)); %brady count
            
            %         meanbrady(ii,k,2) = mean(output(cond_trials,7)); % ibis0 %
            %         meanbrady(ii,k,3) = mean(output(cond_trials,8)); % ibis1 %
            %         meanbrady(ii,k,4) = mean(output(cond_trials,9)); % ibis2 %
            %         meanbrady(ii,k,5) = mean(output(cond_trials,10)); % ibis3 %
            meanibi0(ii,k) = mean(output(cond_trials,7)); % ibis0 %
            k = k+1
        end %which_cond
        clear output peak
    end %ii
    
    % ----------------------------------------------------------------
    % PLOT
    %----------------------------------------------------------------
    
    figure
    % BRADY
    ylim_brad = [-30 90];
    ylim_peak = [0 0.35];
    
    ax1 = subplot(3,2,1); subj = 1;
    plot(mA(subj,:),meanibi0(1,:),'linewidth', 1.3)
    ylabel('BRADY (% ibi0)')
    xticks(mA(subj,:))
    title(list{1,3})
    ylim(ylim_brad)
    
    ax2 = subplot(3,2,2); subj = 2;
    plot(mA(subj,:),meanibi0(2,:),'linewidth', 1.3)
    xlabel('mA')
    ylim(ylim_brad)
    xticks(mA(subj,:))
    set(gca,'YAxisLocation','right')
    title(list{2,3})
    legend('%ibi0', 'location', 'southeast')
    
    
    % PEAK
    legendroi = {roiname1, roiname2};
    
    ax3 = subplot(3,2,[3 5]); subj = 1;
    plot(mA(subj,:),meanAct(subj,:,1),'linewidth', 1.3, 'DisplayName', roiname1, 'color', '#7E2F8E' )
    hold on
    plot(mA(subj,:),meanAct(subj,:,2),'linewidth', 1.3, 'DisplayName', roiname2, 'color', '#D95319' )
    ylabel ('PEAK ACTIVITY (% \Delta F)')
    xticks(mA(subj,:))
    ylim(ylim_peak)
    xlim([mA(subj,1) mA(subj, end)])
    
    ax4 = subplot(3,2,[4 6]); subj= 2;
    plot(mA(subj,:),meanAct(subj,:,1),'linewidth', 1.3, 'DisplayName', roiname1 , 'color', '#7E2F8E'); hold on
    plot(mA(subj,:),meanAct(subj,:,2),'linewidth', 1.3, 'DisplayName', roiname2 , 'color', '#D95319')
    legend(legendroi, 'location', 'southeast')
    xlabel('mA')
    xticks(mA(subj,:))
    ylim(ylim_peak)
    xlim([mA(subj,1) mA(subj, end)])
    
    
    % ----------------------------------------------------------------
    % SAVE FIGURE
    %----------------------------------------------------------------
    for ii = 1:2
        VSDI = TORus('load',ii);
        
        namefish(ii) = VSDI.ref
    end
    name2save = fullfile(savein,['plot_E_' num2str(namefish(1)) 'n' num2str(namefish(2))  '.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    close
    
    
    %% E2 BARPLOT OF LOW vs HIGH: peak activity + brady
    % output values in csv for R (it is not worth doing this on matlab)
    
    clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein ref_wave path
    ref_wave = 'filt512';
    
    %----------------------------------------------------------------
    % @SET: fish + conditions + description
    %----------------------------------------------------------------
    list{1,1} = 11; %subject
    list{1,2} = [401]; %conditions to include
    list{1,3} = 'p015ms'; % description
    
    list{2,1} = 3;
    list{2,2} = [303];
    list{2,3} = 't10ms';
    feedf.window.wmean=[0 250];
    
    % % calculate max number of trials:
    % for ii = 1:2
    %     [VSDI] = TORus('load',list{ii,1});
    %     n(ii) = length(find(VSDI.condition(:,1) == list{ii,2}));
    % end
    % ntri = min(n)
    
    %----------------------------------------------------------------
    % LOOP THROUGH LIST OF SUBJECTS AND CONDITIONS
    %----------------------------------------------------------------
    id = 1; %counters to build the cell structures
    idB = 1;
    
    for ii = 1:2
        nfish = list{ii,1};
        trial_kinds = list{ii,2};
        description = list{ii,3};
        
        
        [VSDI] = TORus('load',nfish);
        [spike] = TORus('loadspike', nfish); % ECG
        [VSDroiTS] = TORus('loadwave',nfish);
        
        waves = VSDroiTS.(ref_wave).data; %@ SET
        
        
        roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
        roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
        
        condi = list{ii,2};
        sel_trials = find(VSDI.condition(:,1) == condi);
        %         sel_trials = sel_trials(1:ntri);
        
        %----------------------------------------------------------------
        % GET PEAK
        %----------------------------------------------------------------
        
        for triali =  makeRow (VSDI.nonanidx)
            
            for nroi = [roi1 roi2]
                wave = squeeze(waves(:, nroi,triali));
                local_output = devo_peak2peak(wave, VSDI.timebase, feedf.window,[], feedf.method, 0);
                
                peak(triali, nroi) = local_output.wmean;
                clear wave local_output
                
            end
            
        end %triali
        
        
        % MEAN VALUES FOR EACH CONDITION
        
        
        for triali = makeRow(sel_trials)
            for roi= [roi1, roi2]
                Rmean_long{id,1} = list{ii,3};
                Rmean_long{id,2} = VSDI.roi.labels{roi};
                Rmean_long{id,3} = peak(triali,roi);
                id = id +1;
            end
        end
        
        
        
        %     % ADAPT 'mA' (for x-axis labels) if there is a tone
        %
        %     if mA(ii,2) == 0 || isnan(mA(ii,2)) % if the second condition is NaN or 0, then it is a tone and some adjustements are needed to be plotted
        %         flag_adapt =1;
        %         mA(ii,1) = -0.5; mA(ii,2) = 0;
        %
        %         labels{ii,1} = '0';labels{ii,2} = 'tone';
        %
        %         for jj= 3:length(mA)
        %             labels{ii,jj} =  num2str(mA(ii));
        %         end
        %     else
        %
        %         flag_adapt =0;
        %
        %     end
        
        %----------------------------------------------------------------
        % GET BRADY: SPIKE-BASED MEASURES FOR EACH TRIAL
        %----------------------------------------------------------------
        w.pre= 10; % ventana pre-estímulo(en segundos) , de los que se va a tomar las espigas para hacer la media de frecuencia instantánea o el conteo
        w.post = w.pre/2; %sólo para el conteo
        
        for triali =  makeRow (VSDI.nonanidx)
            
            % ----------------------------------------------
            % SPIKE(ecg)-BASED MEASURES
            % ----------------------------------------------
            if  VSDI.spike.RO(triali) == 0
                flag_noROspike = 1;
            else
                flag_noROspike = 0;
                
            end
            
            
            if ~flag_noROspike
                
                stim = VSDI.spike.RO(triali)+VSDI.info.Sonset/1000 ; %stimulus arrival time (in spike) for this trial (RO time here has already left out the shutter delay, so we dont have to sum it up)
                
                
                % 1. LEAVE OUT STIMULUS NOISE (if it's a somatic stimulus):
                
                % Get safety window to remove US noise
                if (VSDI.list(triali).Sdur >= 60) & (VSDI.condition(triali,4) >= 1) % EXPERIMENT-SPECIFIC PARAMETER: if it is a long train (60ms) of 1mA or more
                    noisewin = 430/1000; % (430ms) empirically measured from the noise captured by the cup-electrodes
                else
                    noisewin = VSDI.info.Sdur(triali)/1000+ 0.03; %+0.03security window (from spike, the events normally have a 0.02 minimum step from spike to spike)
                end
                
                % 2. Clean the spikes due to that trial's noise
                clean_spikes = spike.spikes(spike.spikes<stim -0.01); %keep all before the stim (excluding another prestim safety window)
                
                if ~isnan(VSDI.condition(triali,1))% IF IT IS NaN, IT IS A TONE, so the artifact due to the stim does not exist
                    clean_post = spike.spikes(spike.spikes> stim + noisewin );
                else % If it is a tone, no 'noisewin' clearing is needed
                    clean_post = spike.spikes(spike.spikes> stim);
                    
                end
                clean_spikes = [clean_spikes; clean_post];
                
                % 3. GET IDX FOR BRADYCHARDIA MEASURE FROM THE CLEANED HEART
                % SPIKES
                idx_pre = find(clean_spikes > stim-w.pre  & clean_spikes < stim);
                
                idx_post =  find(clean_spikes > stim  & clean_spikes < stim+ w.post);
                idx_spike0 = find(clean_spikes> stim, 1, 'first');
                
                % bradycardia counting
                precount = length(idx_pre);
                postcount = length(idx_post)*2;
                brady_count = ((precount - postcount)/precount)*100;
                
                % IBI calculation
                preibi = mean(diff(clean_spikes(idx_pre)));
                
                post0 = clean_spikes(idx_spike0) - clean_spikes(idx_spike0-1);
                post1 = clean_spikes(idx_spike0+1) - clean_spikes(idx_spike0);
                post2 = clean_spikes(idx_spike0+2) - clean_spikes(idx_spike0+1);
                post3 = clean_spikes(idx_spike0+3) - clean_spikes(idx_spike0+2);
                
                % PERCENT IBI calculation
                perc0 = ((post0 - preibi) / preibi)*100;
                perc1 = ((post1- preibi) / preibi)*100;
                perc2 = ((post2 - preibi) / preibi)*100;
                perc3 = ((post3 - preibi) / preibi)*100;
                
                
                % ----------------------------------------------
                % OUTPUT
                % ----------------------------------------------
                
                output(triali,1) = round(brady_count);
                
                output(triali,2) = preibi;
                output(triali,3) = post0;
                output(triali,4) = post1;
                output(triali,5) = post2;
                output(triali,6) = post3;
                
                output(triali,7) = perc0;
                output(triali,8) = perc1;
                output(triali,9) = perc2;
                output(triali,10) = perc3;
                
                
            end % flag
            
        end %triali (ibi counting)
        
        
        % CELL WITH BRADY MEASURE
        
        for triali = makeRow( sel_trials )
            Rbradi_long{idB,1} = list{ii,3};
            Rbradi_long{idB,2} = output(triali,7);
            idB = idB +1;
        end
        
        
        clear output peak
    end %ii
    
    
    
    csvname_mean = fullfile(savein, ['plotE_long_format_forR_wmean_between_F',num2str(list{1,1}),'c_',  list{1,3}, '_and_F',num2str(list{2,1}),'c_',  list{2,3}, '_data' ref_wave '.csv']);
    csvname_bradi = fullfile(savein, ['plotE_long_format_forR_bradi_between_F',num2str(list{1,1}),'c_',  list{1,3}, '_and_F',num2str(list{2,1}),'c_',  list{2,3}, '_data' ref_wave '.csv']);
    
    % write output (new sheet for each fish
    Rmean_long = cell2table(Rmean_long);
    Rbradi_long = cell2table(Rbradi_long);
    
    writetable (Rmean_long, csvname_mean)
    writetable (Rbradi_long, csvname_bradi)
    
    
    %% H -SCATTER PLOT OF ACTIVITY
    
    clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein ref_wave path
    
    currentfolder =pwd;
    load('/home/tamara/Documents/MATLAB/VSDI/TORus/plot/informes/03_figure_sketch/fast_condition_scatter.mat')
    cd( currentfolder)
    custom_map = jet(size(fast_condition_scatter,1));
    
    %----------------------------------------------------------------
    % @SET: fish + conditions
    %----------------------------------------------------------------
    for  block = 1:length(fast_condition_scatter)
        
        % Get selection to be analyzed from structure
        nfish = fast_condition_scatter{block,1};
        trial_kinds = fast_condition_scatter{block,2};
        shape = fast_condition_scatter{block,3};
        
        %----------------------------------------------------------------
        % @SET: MEASURE (OR LOOP THROUGH ALL MEASURES)
        %----------------------------------------------------------------
        measure = {'peakminusbasel'};
        
        %----------------------------------------------------------------
        % @SET: MEASURE (OR LOOP THROUGH ALL MEASURES)
        %----------------------------------------------------------------
        
        waveslim.ave = [-0.2 0.4]; %ylim for pltting average waves
        
        [VSDI] = TORus('load',nfish);
        
        roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
        roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
        
        display([num2str(VSDI.ref) '-block:' num2str(trial_kinds(1))]) % DISPLAY FISH AND BLOCK INFO
        
        VSDroiTS = TORus('loadwave',nfish);
        waves = VSDroiTS.(ref_wave).data; %@ SET
        
        
        % ----------------------------------------------
        % BRAINVISION/WAVE-BASED MEASURES
        % ----------------------------------------------
        for triali =  makeRow (VSDI.nonanidx)
            
            for nroi = [roi1 roi2]
                wave = squeeze(waves(:, nroi,triali));
                local_output = devo_peak2peak(wave, VSDI.timebase, feedf.window,[], feedf.method, 0);
                
                peak(triali, nroi) = local_output.peakminusbasel;
                clear wave local_output
            end
            
        end %triali
        
        % ----------------------------------------------
        % MEAN VALUES FOR EACH CONDITION
        % ----------------------------------------------
        
        % HEADER
        j = 1;
        for condi = makeRow( trial_kinds)
            
            sel_trials = find(VSDI.condition(:,1) == condi);
            
            dots1(j,1) = VSDI.condition(sel_trials(1),4) ;
            dots2(j,1) = VSDI.condition(sel_trials(1),4) ;
            
            
            dots1(j,2) = mean(peak(sel_trials,roi1));
            dots2(j,2) = mean(peak(sel_trials,roi2));
            
            j=j+1;
            clear sel_trials
        end
        
        scatter(dots1(:,1), dots1(:,2), 60, 'filled', shape, 'MarkerFaceColor', '#7E2F8E'); hold on %, 'MarkerEdgeColor', custom_map(block,:)
        scatter(dots2(:,1), dots2(:,2), 60, 'filled', shape, 'MarkerFaceColor', '#77AC30'	) %green
        
        
    end
    % ADD TITLE AND ADJUST LIMITS
    
    ylimite = get(gca, 'ylim');
    ylimite(2) = ylimite(2)+ 0.05;
    
    xlimite = get(gca, 'xlim');
    xlimite(1) = xlimite(1) - 0.1; xlimite(2) = xlimite(2) + 0.2;
    
    ylim (ylimite);
    xlim(xlimite);
    
    xlabel('mA'); ylabel('mean Peak activity for each condition');
    
    title(['means of peaks values. purple= ' roiname1 ' green =' roiname2])
    
    name2save = fullfile(savein,['plot_H_scatter.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    close
    
    %% H2 -SCATTER PLOT OF BRADYCARDIA
    
    clearvars -except roi1 roi2 roiname1 roiname2 feedf fast_condition_list savein ref_wave path
    
    currentfolder =pwd;
    load('/home/tamara/Documents/MATLAB/VSDI/TORus/plot/informes/03_figure_sketch/fast_condition_scatter.mat')
    cd( currentfolder)
    custom_map = jet(size(fast_condition_scatter,1));
    
    w.pre= 10; % ventana pre-estímulo(en segundos) , de los que se va a tomar las espigas para hacer la media de frecuencia instantánea o el conteo
    w.post = w.pre/2; %sólo para el conteo
    
    %----------------------------------------------------------------
    % @SET: fish + conditions
    %----------------------------------------------------------------
    for  block = 1:length(fast_condition_scatter)
        
        % Get selection to be analyzed from structure
        nfish = fast_condition_scatter{block,1};
        trial_kinds = fast_condition_scatter{block,2};
        shape = fast_condition_scatter{block,3};
        
        
        %----------------------------------------------------------------
        % @SET: MEASURE (OR LOOP THROUGH ALL MEASURES)
        %----------------------------------------------------------------
        
        %     waveslim.ave = [-0.2 0.4]; %ylim for pltting average waves
        
        [VSDI] = TORus('load',nfish);
        spike = TORus('loadspike', nfish); % ECG
        
        roi1 = name2idx(roiname1, VSDI.roi.labels_circ);
        roi2 = name2idx(roiname2, VSDI.roi.labels_circ);
        
        display([num2str(VSDI.ref) '-block:' num2str(trial_kinds(1))]) % DISPLAY FISH AND BLOCK INFO
        
        
        % ----------------------------------------------
        % SPIKE-BASED MEASURES FOR EACH TRIAL
        % ----------------------------------------------
        for triali =  makeRow (VSDI.nonanidx)
            
            % ----------------------------------------------
            % SPIKE(ecg)-BASED MEASURES
            % ----------------------------------------------
            if  VSDI.spike.RO(triali) == 0
                flag_noROspike = 1;
            else
                flag_noROspike = 0;
                
            end
            
            
            if ~flag_noROspike
                
                stim = VSDI.spike.RO(triali)+VSDI.info.Sonset/1000 ; %stimulus arrival time (in spike) for this trial (RO time here has already left out the shutter delay, so we dont have to sum it up)
                
                
                % 1. LEAVE OUT STIMULUS NOISE (if it's a somatic stimulus):
                
                % Get safety window to remove US noise
                if (VSDI.list(triali).Sdur >= 60) & (VSDI.condition(triali,4) >= 1) % EXPERIMENT-SPECIFIC PARAMETER: if it is a long train (60ms) of 1mA or more
                    noisewin = 430/1000; % (430ms) empirically measured from the noise captured by the cup-electrodes
                else
                    noisewin = VSDI.info.Sdur(triali)/1000+ 0.03; %+0.03security window (from spike, the events normally have a 0.02 minimum step from spike to spike)
                end
                
                % 2. Clean the spikes due to that trial's noise
                clean_spikes = spike.spikes(spike.spikes<stim -0.01); %keep all before the stim (excluding another prestim safety window)
                
                if ~isnan(VSDI.condition(triali,1))% IF IT IS NaN, IT IS A TONE, so the artifact due to the stim does not exist
                    clean_post = spike.spikes(spike.spikes> stim + noisewin );
                else % If it is a tone, no 'noisewin' clearing is needed
                    clean_post = spike.spikes(spike.spikes> stim);
                    
                end
                clean_spikes = [clean_spikes; clean_post];
                
                % 3. GET IDX FOR BRADYCHARDIA MEASURE FROM THE CLEANED HEART
                % SPIKES
                idx_pre = find(clean_spikes > stim-w.pre  & clean_spikes < stim);
                
                idx_post =  find(clean_spikes > stim  & clean_spikes < stim+ w.post);
                idx_spike0 = find(clean_spikes> stim, 1, 'first');
                
                % bradycardia counting
                precount = length(idx_pre);
                postcount = length(idx_post)*2;
                brady_count = ((precount - postcount)/precount)*100;
                
                % IBI calculation
                preibi = mean(diff(clean_spikes(idx_pre)));
                
                post0 = clean_spikes(idx_spike0) - clean_spikes(idx_spike0-1);
                post1 = clean_spikes(idx_spike0+1) - clean_spikes(idx_spike0);
                post2 = clean_spikes(idx_spike0+2) - clean_spikes(idx_spike0+1);
                post3 = clean_spikes(idx_spike0+3) - clean_spikes(idx_spike0+2);
                
                % PERCENT IBI calculation
                perc0 = ((post0 - preibi) / preibi)*100;
                perc1 = ((post1- preibi) / preibi)*100;
                perc2 = ((post2 - preibi) / preibi)*100;
                perc3 = ((post3 - preibi) / preibi)*100;
                
                
                % ----------------------------------------------
                % OUTPUT
                % ----------------------------------------------
                
                output(triali,1) = round(brady_count);
                
                output(triali,2) = preibi;
                output(triali,3) = post0;
                output(triali,4) = post1;
                output(triali,5) = post2;
                output(triali,6) = post3;
                
                output(triali,7) = perc0;
                output(triali,8) = perc1;
                output(triali,9) = perc2;
                output(triali,10) = perc3;
                
                
            end % flag
            
            
        end %triali
        % ----------------------------------------------
        % MEAN VALUES FOR EACH CONDITION
        % ----------------------------------------------
        
        
        k = 1;
        for which_cond =  makeRow(trial_kinds)
            
            cond_trials = find(VSDI.condition(:,1) == which_cond);
            
            meanoutout(k,1) = mean(output(cond_trials,1)); %brady count
            
            meanoutout(k,2) = mean(output(cond_trials,7)); % ibis0 %
            meanoutout(k,3) = mean(output(cond_trials,8)); % ibis1 %
            meanoutout(k,4) = mean(output(cond_trials,9)); % ibis2 %
            meanoutout(k,5) = mean(output(cond_trials,10)); % ibis3 %
            
            tempidx = find(VSDI.condition(:,1) == which_cond,1,'first');
            mA(k) = VSDI.condition(tempidx,4);
            k = k+1;
            
        end
        
        %     scatter(mA, meanoutout(:,1), 60, 'filled', shape, 'MarkerFaceColor', '#000000'); hold on %brady count
        
        scatter(mA, meanoutout(:,2), 60, 'filled', shape, 'MarkerFaceColor', '#0072BD'); hold on % ibis0 %
        %     scatter(mA, meanoutout(:,3), 60, 'filled', shape, 'MarkerFaceColor', '#7E2F8E'); hold on % ibis1 %
        %     scatter(mA, meanoutout(:,4), 60, 'filled', shape, 'MarkerFaceColor', '#77AC30'); hold on % ibis2 %
        
        
    end %for block
    
    % ----------------------------------------------
    % ADD TITLE AND ADJUST LIMITS
    % ----------------------------------------------
    
    ylimite = get(gca, 'ylim');
    ylimite(2) = ylimite(2)+ 0.05;
    
    xlimite = get(gca, 'xlim');
    xlimite(1) = xlimite(1) - 0.1; xlimite(2) = xlimite(2) + 0.2;
    
    ylim (ylimite);
    xlim(xlimite);
    
    xlabel('mA'); ylabel('mean %brady (ibi0)  for each condition');
    
    title( '%brady in different fish')
    %
    name2save = fullfile(savein,['plot_H2_scatter_brady.jpg']);
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 8]);
    saveas(gcf,name2save,'jpg')
    close
    
    
    %% Updated: 09/09/2021
    % Last use: 