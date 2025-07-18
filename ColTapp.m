function ColTapp_v1_2
%% initializing the interface

% suppress some warnings
%#ok<*AGROW>
%#ok<*HIST>
warning('off','MATLAB:hg:uicontrol:ValueMustBeInRange');
warning('off', 'images:imfindcircles:warnForSmallRadius');



% Check if GUI toolbox is installed
stp=Verifiyversion();
if stp
    return
end
clear stp;
Fvar=struct(); %those are variables with fixed values in the software

Fvar.screen=get(0,'ScreenSize');
if Fvar.screen(3)/Fvar.screen(4)>2
    Fvar.figscale=0.7;
else
    Fvar.figscale=1;
end


%% New figure
hs.f = figure('units','norm','Position',[0.1 0.1 0.8*Fvar.figscale 0.8], 'KeyPressFcn', @WindowKeyPressFcn,...
    'MenuBar', 'none', 'NumberTitle', 'off','HandleVisibility','on', ...
    'Name', 'ColTapp v1.2-beta', 'ToolBar', 'none');
removeToolbarExplorationButtons(hs.f);

saveV='-v7';
Layoutcomponents; 
mO=struct();mouseOvers;
%% Initialise variables
p=struct();%all the data
b=struct(); %contains variables that are used in batch mode
orig=struct();
pback=struct();
restore1=struct();
VorEdg=struct();
k=struct();

colonies=struct();%struct for tlag comparison
Kymo=struct();
initialize_gui;

%% Make figure visible after adding components
hs.fig.Visible = 'on';
hs.firstLoad=1;%for the load button. if the user open a new set, the complete layout is redone in order to ensure that the buttons are in
%the state they should be

%% initialising functions
    function stp=Verifiyversion()
        stp=0;
        
        if verLessThan('Matlab','1.6')
            disp('Matlab 2008 and earlier are not supported')
            stp=1;
            return
        end
        
        v=ver;%get list of all toolboxes
        %first the check if the necesarry GUI toolbox is installed
        if sum(strcmp({v.Name},'GUI Layout Toolbox'))==0
            quest=questdlg('The necesarry "GUI Layout Toolbox" is missing. Do you want to open the website to download and install that toolbox now?',...
                'Toolbox download', 'Yes','No','Yes');
            stp=1;
            switch quest
                case 'Yes'
                    url='https://ch.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox';
                    web(url,'-browser');
                    return
                case 'No'
                    return
                case ''
                    return
            end
            
        end
        
        if sum(strcmp({v.Name},'Image Processing Toolbox'))==0
            quest=questdlg('The necesarry "Image Processing Toolbox" is missing. To install it, you need to re-run the MATLAB installer and select the toolbox. Do you want to open the download-page?',...
                'Toolbox download', 'Yes','No','Yes');
            stp=1;
            switch quest
                case 'Yes'
                    url='https://www.mathworks.com/downloads/';
                    web(url,'-browser');
                    return
                case 'No'
                    return
                case ''
                    return
            end
        end
        
        %for some things, we need the curve fitting toolbox, check that as well
        if sum(strcmp({v.Name},'Curve Fitting Toolbox'))==0
            quest=questdlg(['The "Curve Fitting Toolbox" is missing. It is needed for detecting the radius of transition and growth rate for timelapse analysis.',...
                'You can continue without this toolbox but may run into problems. To install that toolbox, re-run the matlab installer and select the toolbox to install'],...
                'Toolbox missing', 'Continue without','Cancel','Continue without');
            switch quest
                case 'Continue without'
                    pause(0.000001)
                case 'Cancel'
                    stp=1;
                    return
                case ''
                    stp=1;
                    return
            end
        end
        Fvar.imTBmiss=0;
        if ~license('checkout','Image_Toolbox')
            quest=questdlg(['The "Image Toolbox" license is missing or the license is in use. It is needed for various image manipulation tools.',...
                'You can continue without this toolbox but may run into errors Data analysis stuff should be possible. To install that toolbox, re-run the matlab installer and select the toolbox to install'],...
                'Toolbox missing', 'Continue without','Cancel','Continue without');
            switch quest
                case 'Continue without'
                    pause(0.000001)
                    Fvar.imTBmiss=1;
                case 'Cancel'
                    stp=1;
                    return
                case ''
                    stp=1;
                    return
            end
            
            if ~license('checkout','map_toolbox')
                quest=questdlg(['The "Mapping Toolbox" license is missing or the license is in use. It is needed only for the Voronoi calculation',...
                    'So you should install it if you plan to analyse colonies spatial distribution with the voronoi metric. Run the matlab installer and select the toolbox to install'],...
                    'Toolbox missing', 'Continue without','Cancel','Continue without');
                switch quest
                    case 'Continue without'
                        pause(0.000001)
                        Fvar.imTBmiss=1;
                    case 'Cancel'
                        stp=1;
                        return
                    case ''
                        stp=1;
                        return
                end
            end
        end
        
        if verLessThan('Matlab','9.8')
            saveV='-v7.3';
            % files are saved without compression for speed. In Matlab
            % version 2020, it is now possible to save matfiles with
            % version 7 instead of 7.3, which increases speed. In
            % older versions, -v7.3 will be used. We assume no version
            % before 2008
        end
        
        clear v
    end%check if necessary toolboxes are missing
    function Layoutcomponents
        %color values for the different button types
        hs.btnCol.gray=[0.7 0.7 0.7];
        %         hs.btnCol.green1=[0 0.6 0];
        %         hs.btnCol.green2=[0 0.9 0];$
        hs.btnCol.green1=[0.4490    0.8588    0.5922]; %main buttons
        hs.btnCol.green2=[0.5071    0.9216    0.5078]; %load etc buttons
        
        % Cutting main units
        hs.main=uix.VBoxFlex('Parent', hs.f,'Padding',0, 'Spacing', 10); % whole box, separed into two units: 1) TopLayer and 2) BottomLayer
        hs.TopLayer=uix.HBox('Parent',hs.main); %1
        hs.BottomLayer=uix.HBoxFlex('Parent',hs.main,'Padding', 0, 'Spacing', 10); %#2, separated into two units: 3) LeftPan (all buttons etc on left side) and 4) FigPan (the picture box)
        hs.LeftPan=uix.VBox('Parent', hs.BottomLayer,'Padding', 30); %#3
        hs.FigPanBig=uix.HBox('Parent', hs.BottomLayer,'Padding', 30); %#4
        
        % smaller cuts
        hs.NavigatePics=uix.HBox('Parent', hs.LeftPan); %box for all
        hs.AllParam=uix.HBox('Parent', hs.LeftPan);
        
        % Add contents
        
        %in Toplayer
        hs.LoadSave=uix.VBox('Parent', hs.TopLayer);
        hs.LoadClassify=uix.HBox('Parent', hs.LoadSave);
        hs.LoadButton=uicontrol('Parent', hs.LoadClassify, 'String', 'Load/Open (O)', 'CallBack', @LoadButton_callback,'FontSize',15, 'BackgroundColor', hs.btnCol.green2);
        hs.Batch=uicontrol('Parent', hs.LoadClassify, 'String', 'Batch analysis', 'CallBack', @MergeRun,'FontSize',15, 'BackgroundColor', hs.btnCol.green2);
        hs.LoadSaveAS=uix.HBox('Parent', hs.LoadSave);
        hs.SaveAsButton=uicontrol('Parent', hs.LoadSaveAS, 'String', 'Save file', 'CallBack', @SaveAsButton_callback,'FontSize',15, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.SaveAsCSV2=uicontrol('Parent', hs.LoadSaveAS, 'String', '.csv Export', 'CallBack', @Export2_callback,'FontSize',15, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Classify=uicontrol('Parent', hs.LoadSaveAS, 'String', 'Classify', 'CallBack', @Classify_callback,'FontSize',15, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.UserMessage=uix.VBox('Parent', hs.TopLayer);
        hs.UserMess=uicontrol('Style', 'text','Parent',hs.UserMessage, 'String', 'starting','FontSize',12);
        hs.UserMess2=uix.HBoxFlex('Parent',hs.UserMessage);
        hs.UserMessDir=uicontrol('Style', 'text','Parent',hs.UserMess2, 'String', 'directory','FontSize',12);
        hs.UserMessFrame=uicontrol('Style', 'text','Parent',hs.UserMess2, 'String', 'Frame number','FontSize',12);
        hs.UserMessNumCol=uicontrol('Style', 'text','Parent',hs.UserMess2, 'String', 'number of colonies','FontSize',12);
        hs.Progress1=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
        hs.Progress2=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
        
        % in left Pan
        % in navigate
        hs.setframebox=uix.HBox('Parent',hs.NavigatePics);
        hs.setframeinput=uicontrol('Parent',hs.setframebox, 'Style','edit', 'KeyPressFcn', @set_frame_callback);
        hs.SetFrameSlider=uicontrol('Parent',hs.setframebox, 'Style', 'slider',  ...
            'Callback', @set_frame_slider,'FontSize',15,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.setframebox.Widths=[-1, -3];
        hs.Options=uicontrol('Parent',hs.NavigatePics, 'String', 'Options', 'Callback', @Options_Callback,'FontSize',15,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.NavigatePics.Widths=[-1 -1];
        hs.VoidTop=uix.Empty('Parent', hs.AllParam);
        hs.AllParam.Widths=-1;
        
        %tabs
        hs.Tabs=uitabgroup('Parent', hs.LeftPan); %%%%%%%%%%%%%%%%%
        hs.AutoDetectTab = uitab('Parent', hs.Tabs, 'Title', 'Detect');
        hs.SITab= uitab('Parent', hs.Tabs, 'Title', 'Main-EP');
        hs.TimeLapseTab = uitab('Parent', hs.Tabs, 'Title', 'Main-TL');
        hs.ResultsTab= uitab('Parent', hs.Tabs, 'Title', 'Visualize');
        
        % in right Pan
        hs.LeftButton=uicontrol('Parent', hs.FigPanBig, 'String', '<','Callback', @previous_Callback,'FontSize',15,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.FigPan=uipanel('Parent', hs.FigPanBig); %in order to be able to use subplot, creating a panel for the figure
        hs.fig=axes('Parent', hs.FigPan, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %creating axes in it
        hs.RightButton=uicontrol('Parent', hs.FigPanBig, 'String', '>', 'Callback', @next_Callback,'FontSize',15,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.FigPanBig.Widths=[20, -1, 20];
        
        % in tabs
        %Detect Tab
        hs.DetectTabBox=uix.VBox('Parent', hs.AutoDetectTab,'Padding', 20);
        hs.umRef=uicontrol('Parent',hs.DetectTabBox, 'String', 'Set spatial calibration factor','FontSize',14, 'Callback', @umRef_Callback, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void0=uix.Empty('Parent', hs.DetectTabBox);
        hs.aoistring=uicontrol('Style', 'text','Parent',hs.DetectTabBox, 'String', 'Area of interest:','FontSize',14);
        hs.aoibox=uix.HBox('Parent',hs.DetectTabBox);
        hs.aoiplate=uicontrol('Parent',hs.aoibox, 'String', 'Plate', 'Callback', @DelimitAreaPlate_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.aoipolygon=uicontrol('Parent',hs.aoibox, 'String', 'Polygon', 'Callback', @DelimitAreaPolygon_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.aoiwhole=uicontrol('Parent',hs.aoibox, 'String', 'None', 'Callback', @DelimitAreaWhole_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void=uix.Empty('Parent', hs.DetectTabBox);
        hs.enhanceImg=uix.HBox('Parent',hs.DetectTabBox);
        hs.EnhanceImage=uicontrol('Style', 'checkbox','Parent',hs.enhanceImg, 'String', 'Autocontrast','FontSize',14, 'Callback', @EnhanceImage_Callback, 'Enable', 'inactive');
        hs.EnhanceImage2=uicontrol('Style', 'checkbox','Parent',hs.enhanceImg, 'String', 'Improve lighting','FontSize',14, 'Callback', @EnhanceImage2_Callback, 'Enable', 'inactive');
        hs.DefineRange=uicontrol('Parent',hs.DetectTabBox, 'String', 'Define radius range', 'Callback', @AutomaticallyDefineParameters_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.FindColonies=uicontrol('Parent',hs.DetectTabBox, 'String', 'Find Colonies', 'Callback', @FindColonies_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void1=uix.Empty('Parent', hs.DetectTabBox);
        hs.modColonyClick=uicontrol('Style', 'checkbox', 'Parent',hs.DetectTabBox,'String','Add/Remove with click', 'Callback', @EnablemodColonyClick_Callback,'FontSize',14, 'Enable', 'off');
        hs.AddRmv=uix.HBox('Parent',hs.DetectTabBox);
        hs.AddCol=uicontrol('Parent',hs.AddRmv, 'String', '(C) Add', 'Callback', @Addcol_callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.RmvCol=uicontrol('Parent',hs.AddRmv, 'String', '(R) Remove', 'Callback', @RemoveCol2_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Clean=uix.HBox('Parent',hs.DetectTabBox);
        hs.CleanZone=uicontrol('Parent',hs.Clean, 'String', '(T) Clear in', 'Callback', @ClearZone_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.CleanOutZone=uicontrol('Parent',hs.Clean, 'String', '(Z) Clear out', 'Callback', @ClearOutZone_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.UndoButton=uicontrol('Parent',hs.DetectTabBox, 'String', '(backslash) Undo', 'Callback', @Undo_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void2=uix.Empty('Parent', hs.DetectTabBox);
        hs.Liststring=uicontrol('Style', 'text','Parent',hs.DetectTabBox, 'String', 'User lists','FontSize',14);
        hs.UserListButtons=uix.HBox('Parent',hs.DetectTabBox);
        hs.AddList=uicontrol('Parent',hs.UserListButtons, 'String', '+/-', 'Callback', @Add_to_List_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.ShowList=uicontrol('Parent',hs.UserListButtons, 'String', 'Show', 'Callback', @Show_UserList_Callback,'FontSize',15,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.ListSelect=uicontrol('Parent',hs.UserListButtons, 'Style', 'popup','String', {'none','new'},'FontSize',15,'BackgroundColor', 'white','Callback', @ChangeUserList_callBack );
        hs.Highlight=uix.HBox('Parent',hs.DetectTabBox);
        hs.HLButton=uicontrol('Parent',hs.Highlight, 'String', 'Highlight Colony', 'Callback', @HighlightCol_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.HLinput=uicontrol('Parent',hs.Highlight, 'Style','edit', 'KeyPressFcn', @HighlightCol_Callback);
        hs.HLDelButton=uicontrol('Parent',hs.Highlight, 'String', 'X','FontWeight','bold','Callback', @DeleteHighlightCol_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Highlight.Widths=[-4, -1, -1];
        hs.Void3=uix.Empty('Parent', hs.DetectTabBox);
        hs.LocalCorrection1=uicontrol('Parent',hs.DetectTabBox, 'String', 'Calculate Voronoi areas','FontSize',14, 'Callback', @Voronoi_Callback,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        
        
        %EP Tab
        hs.SITabBox= uix.VBox('Parent', hs.SITab,'Padding', 20) ;
        hs.ovbx=uix.HBox('Parent',hs.SITabBox);
        hs.overlay=uicontrol('Style', 'checkbox', 'Parent',hs.ovbx,'String','Overlay images', 'Callback', @OverlayCheckboxchange_Callback,'FontSize',14, 'Enable', 'off');
        hs.overlayselect=uicontrol('Parent',hs.ovbx, 'Style', 'popup','String', {''},'FontSize',15,'BackgroundColor', 'white','Callback', @ChangeOverlayFolder_callBack );
        hs.Void=uix.Empty('Parent', hs.SITabBox);
        hs.AddNonGrowingButton=uicontrol('Parent',hs.SITabBox, 'String', '(N) Add 0-radius colony', 'Callback', @AddNonGrowing_callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void1=uix.Empty('Parent', hs.SITabBox);
        hs.multiEP=uicontrol('Parent',hs.SITabBox,'String','Link folders', 'Callback', @MultiEPLoad_Callback,'FontSize',14, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.showmultiEP=uicontrol('Parent',hs.SITabBox,'String','Display linked colonies', 'Callback', @MultiEPShow_Callback,'FontSize',14, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.registermultiEP=uicontrol('Parent',hs.SITabBox,'String','Register linked folders', 'Callback', @MultiEPRegister_Callback,'FontSize',14, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.GRmultiEP=uicontrol('Parent',hs.SITabBox,'String','Growth rate from linked folders', 'Callback', @MultiEPGR_Callback,'FontSize',14, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void2=uix.Empty('Parent', hs.SITabBox);
        hs.LoadRef2=uicontrol('Parent',hs.SITabBox, 'String', 'Define reference growth parameters', 'Callback', @GiveRef_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void3=uix.Empty('Parent', hs.SITabBox);
        hs.TappEst=uicontrol('Parent',hs.SITabBox, 'String', 'Apearance time estimation', 'Callback', @TappEst_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void4=uix.Empty('Parent', hs.SITabBox);
        hs.IntensityRadius=uicontrol('Parent',hs.SITabBox, 'String', 'Intensity along radius', 'Callback', @EP_intensityRadius_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        
        %Timelapse tab
        hs.TimelapseTabBox=uix.VBox('Parent', hs.TimeLapseTab,'Padding', 20);
        hs.registration=uicontrol('Style', 'checkbox', 'Parent',hs.TimelapseTabBox,'String','Registration', 'Callback', @RegistrationCheckboxchange_Callback,'FontSize',14, 'Enable', 'off');
        hs.CenterCorrString=uicontrol('Style', 'text','Parent',hs.TimelapseTabBox, 'String', {'';'Center correction:'},'FontSize',14);
        hs.CenterCorr=uix.HBox('Parent',hs.TimelapseTabBox);
        hs.AutoCenter=uicontrol('Parent',hs.CenterCorr, 'String', 'Automatic', 'Callback', @AutoCenter_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.ManualCenter=uicontrol('Parent',hs.CenterCorr, 'String', 'Manual', 'Callback', @CenterCheck_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.closecenter=uix.HBox('Parent',hs.TimelapseTabBox);
        hs.closecenterinput=uicontrol('Parent',hs.closecenter, 'Style','edit', 'KeyPressFcn', @closecenter_Callback, 'String', '5');
        hs.closecenterbutton=uicontrol('Parent',hs.closecenter, 'String', 'Detect close centers', 'Callback', @closecenter_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.closecenter.Widths=[-1, -4];
        hs.Void2=uix.Empty('Parent', hs.TimelapseTabBox);
        hs.FindTimeCol=uicontrol('Parent',hs.TimelapseTabBox, 'String', 'Track radii over time', 'Callback', @FindTimeCol_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.findwrongkymo=uicontrol('Parent',hs.TimelapseTabBox, 'String', 'Find failed kymographs', 'Callback', @AutoKymoCheck_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.CorrectThresh=uicontrol('Parent',hs.TimelapseTabBox, 'String', 'Correct kymographs', 'Callback', @CorrectThresh_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void3=uix.Empty('Parent', hs.TimelapseTabBox);
        hs.LoadRef1=uicontrol('Parent',hs.TimelapseTabBox, 'String', 'Define reference growth parameters', 'Callback', @GiveRef_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void4=uix.Empty('Parent', hs.TimelapseTabBox);
        hs.TappCalc=uicontrol('Parent',hs.TimelapseTabBox, 'String', 'Apearance time determination', 'Callback', @TappCalc_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void4=uix.Empty('Parent', hs.TimelapseTabBox);
        hs.IntensityString=uicontrol('Style', 'text','Parent',hs.TimelapseTabBox, 'String', {'Intensity time-lapse'},'FontSize',14);
        hs.Intensity=uix.HBox('Parent',hs.TimelapseTabBox);
        hs.IntensityFull=uicontrol('Parent',hs.Intensity, 'String', 'Full image', 'Callback', @Intensity_TL_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.IntensityColony=uicontrol('Parent',hs.Intensity, 'String', 'Per Colony', 'Callback', @Colony_Intensity_TL_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        
        
        %Visualize tab
        hs.ResultsTabBox=uix.VBox('Parent', hs.ResultsTab,'Padding', 20);
        hs.SizeDist=uicontrol('Parent',hs.ResultsTabBox, 'String', 'Radius distribution', 'Callback', @SizeDist_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.plot=uicontrol('Parent',hs.ResultsTabBox, 'String', 'Radius vs Time', 'Callback', @plotTL_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.VoidSizeDat=uix.Empty('Parent',hs.ResultsTabBox);
        hs.TappDist=uicontrol('Parent',hs.ResultsTabBox, 'String', 'Appearance time distribution', 'Callback', @TappDist_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.GRdist=uicontrol('Parent',hs.ResultsTabBox, 'String', 'Growth rate distribution','Callback', @GRdist_Callback,'FontSize',14,'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        hs.Void=uix.Empty('Parent', hs.ResultsTabBox);
        
        % proportions of buttons
        hs.TopLayer.Widths=[400, -3];
        hs.main.Heights=[-1, -10];
        hs.UserListButtons.Widths=[-0.75 -1.25 -2];
        hs.BottomLayer.Widths=[-1, -2.2];
        hs.LeftPan.Heights=[-1 ,20,-15];
        hs.DetectTabBox.Heights=[-1 -0.2 -1 -1 -1 -1 -1 -1 -1 -1.5 -1 -1 -1 -1 -1 -1.5 -1 -1 -1];
        hs.SITabBox.Heights=[-1 -1 -1 -2 -1 -1 -1 -1 -2 -1 -2 -1 -1 -1];
        hs.TimelapseTabBox.Heights=[-1 -2 -1 -1 -1 -1 -1 -1 -2 -1 -2 -1 -2 -1 -1];
        hs.ResultsTabBox.Heights=[-1 -1 -1 -1 -1 -12];
    end %make GUI
    function mouseOvers
        % this is a list of text for mouse overs
        mO.SFramCst='If this box is ticked, the exported CSV will not repeat the values which do not change with time.';
        mO.WideLong='The radius data can be exported either as a column data or as a matrix, where columns represent time';
        
        % add newline characters in the texts
        numax=35;
        for whSt=fieldnames(mO)'
            str=[mO.(whSt{1}),' ']; %this is the string to cut
            newstr='';
            while length(str)>numax+4
                spces=strfind(str,' ');
                cut=spces(find(spces>21,1));
                newstr= [newstr,str(1:cut-1),newline];
                str=str(cut+1:end);
            end
            mO.(whSt{1})=[newstr,str(1:end)]; %replace the text
        end
    end %tooltips for mouse-over hoovering
    function initialize_pstruc
        % first listing all the ones that control operation of the GUI
        % and associated functions. Below will come the generated data that
        % can be exported for the user then more easily
              
        % general handling
        p.coltappV=1.2; %for tracking of version to enable backward compatability
        p.nChannelDontAsk=false; %if this is set to true, it just sets always to single channel handling
        p.modColonyClick=true; %left click to add and middle to remove if true
        p.imgMethod=2; %indicate which method of RGB to grayscale transformation to use (1 to 16, 2 is R RGB channel)
        p.ExportMode='px'; %exporting in micrometer or pixel? (auto changes to um if calibration is set)
        p.csvdelimiter=1; %delimter to use for csv export (index of list {',',';', '	', ' ', ':'};)
        p.savebackups=true; %disable the backup save by setting to false (.mat files with date in name)
        p.Rlin=130; %approximate radius at which a colony transition from exp to lin growth regarding radius

        % visualisation and appearance
        p.showColony=true;%show blue cirlces for colonies if =1
        p.showNr=false;%=1 if number of colony should be shown on image
        p.showGrayscale=false;%switch to greyscale if =1
        p.showNrCol='k';%change the color of the number for the col nr display
        p.showCircleScale=1; %scale radius of circle displayed
        p.showROI=false; %show the area of analysis (either the circle and/or the polygon)
        p.showList=false; %if 1 and p.UserLists is not empty, the program colors circles of list in a particular color
        p.ShowVoronoiAreas=false; %display the Voronoi area text if true
        p.ShowVoronoiEdges=false;%display the Voronoi edges if true

        % describing experiment and plate
        p.petriDishUmSize=89000; %micrometer dish size diameter
        p.deltaTmin=10; %default deltaT between pictures

        %for plots etc
        p.plotUnit=1; %1=plot pxl vs frame, 2=smoothed um vs h, 3=log um vs h, 4=all
        p.rawTitle='Raw radius in pixel vs time in frames'; %//TODO: combine the 3 titles into one list and choose based on p.plotUnit
        p.smoothTitle='Radius in \mum vs time in hours';
        p.logTitle='Log10 transformed radius in \mum vs time in hours';
        p.histbins=15; %number of histogram bins
        
        % colony detection
        p.detectMinRadPx = 20; %min radius for colony detection in pxl
        p.detectMaxRadPx = 65; %max rad for colony detection in pxl
        p.BlackColony=0; % if =1 -> use imcomplement for colony detection
        p.detectSensitivity = 0.96; %overall sensitivity for colony detection
        p.detectMinFillCircle=0.8; %80% filling at least to be considered a colony
        p.detectMinFillCircleOverlap=0.9; %90% filling at least when conflicting colonies
        p.detectBinarizeSensitivity=0.01; %sensitivity for binarization for colony detection
        p.detectRadStepsize=7; % imfindcircles iterated with a step of this radius  size
        p.detectRescaleBigCol=10; %this value works best for imfindcircles in colonies cases
        p.detectMaxOverlap=0.9;%how much colony overlaping is allowed to be?
        p.detectBinarizationMethod=1; %which option: 1) adaptive binarization 2) otsu 3) none 
        p.detectCircleMode=1; %=1 -> regionprops mode; =2 -> global mode
        p.detectBoundingBoxScale=1.35; %for find colonies: scale crop area of bounding box to search within
        p.detectBlurDiskSize=0.025; %initial bluring disk scaling based on bounding box size
        p.detectMaxCircleGradient=8; %max circles to be found on gradient image. If more, use actual image
        p.detectMinBorderDist=10; %min distance of a center from subimage border in pxl
        p.detectForegroundBias=0.17; %subtract this from graythresh value for binary image of blob to bias towards more foreground
        p.detectMinForground=0.70; %min area to be foreground
        p.detectMaxOverlapCompare=0.9; %max overlap of two circles when comparing them
        p.detectDiscardOvelapMinRadDiff=10; %goes together with p.detectDiscardOvelapMinCentDst. discard one of a pair of circles...
        p.detectDiscardOvelapMinCentDst=20; %if both distance and radius difference are below these 2 thresholds
        p.detectMaxOverlapTotal=0.95; %total area of a circle allowed to overlap with any circle
        p.detectMaxOverlapStartThresh=0.8; %start value for iterative threshold increase for final overlap discarding
        p.detectMinCenterDistFinal=2; %final check to exclude colonies closer than 2px
                
        % radius tracking and calculation from kymograph
        p.registrationFactor=100; % //TODO: check what this does
        p.radCropAreaScaleFactor=1.15;%how big is the area around colony for analysis. Fixed parameter, set to 115% of col rad
        p.radOverlapScale=1; %scales the radius of the focal colony to be smaller/bigger to be able to exclude close colonies as well
        p.radzeroRadCutoff=6; %used in CalcRadKymo, arbitrary threshold (we chose 6 because= 1 hour) after which the radius is set to 0 (no colony has appeared yet)
        p.radThetaResolution=128; % # of grid points for theta coordinate (change to needed binning)
        p.radOverlapRemoveTheta=true; %=1 if the overlapping region between 2 colonies is removed for the interpolation in radial coordinates (TL function)
        p.radUseEnhancedImg=0; %use enhanced images for timelapse if =1
        p.radDefaultKymoMode=1; %default kymo mode: 1->global; 2->edge
        p.radKymoBias=0.17; % the threshold shift for the radius curve to fit to the kymograpbh
        p.TLimgenhance=0; %use enhanced images for timelapse if =1
        
        % kymograph to radius variables. defaults. The values per colony are stored in the variables without def at the end
        p.kymoScalePillboxdef=1/10000; %this times dim1*dim2 of kymo is used for pillbox filter
        p.kymoWienerFilterSizedef=5; %size of the wiener2 filter kernel
        p.kymoMaxIntensityCutoffdef=1; %every intensity above p.kymoMaxIntensityCutoff is set to 1
        p.kymoCannyLowThreshdef=0.05; %lower canny edge detection threshold
        p.kymoCannyHighThreshdef=0.19; %upper canny edge detection threshold
        p.kymoNoiseFilterSizedef=0.05; %this times dim2 (time) of kymo is used to define the size (in area pixel) of noise objects
        p.kymoVerticalLineRemovaldef=0.7; %this times dim2 is threshold for vertical line removal
        p.kymoHorizontalLineRemovaldef=0.4;  %this times dim1 is threshold for horizontal line removal
        p.kymoCloseFilterLineLendef=1/30; %this times dim2 (time) of kymo is the size of line to use for closing
        p.kymoCloseFilterLineAngledef=10; %the angle to be used for line closing
        p.kymoCloseFilterDiskSizedef=3; %this times dim2 (time) of kymo is used for disk closing
        p.kymoMaskScalingdef=1.7; %scale the binarization threshold for mask creation
        p.kymoIterationsdef = 70; %number of iterations of active contouring
        p.kymoInvertContourdef=0; %invert contour if 1
        p.kymoInvertKymodef=0; %invert kymograph if 1
        p.kymoDisablePrefilterdef=0; %disable all image prefiltering

        % appearance time calculation
        p.tappMode='um'; %can be either 'um' or 'px'. define if the Tapp is calculated via pxl or um thresholding
        p.tappThreshUm=200; %for the Tapp calculation (if mode um)
        p.tappThreshPx=10; %detection threshold in pxl (if mode px)
        p.tappLengthLinFitFrame=50; %number of frames in which we fit the linear regression
        p.tappRefMode='Mean'; %reference mode for growth rate extraction: 'Mean' or 'Quantile'
        p.tappRefQuantile=0.5; %default quantile for reference growth rate extraction (only used if refMode is set to 'Quantile')
        p.tappStayOverThresh=5; % Rad needs to stay above the threshold for that many frames otherwise discarded
        
        % initialization of various empty variables used for progress tracking
        % and data storage
        % general control variables
        p.operatingMode=[]; %define if loaded images are single set or timelapse
        p.operatingModeStr=[]; %the text written on the classify button
        p.definedOperatingMode=false;%change to true if p.operatingMode is set //TODO: remove and make sure it still works
        p.imgFormat=[]; %indicates if the user loaded RGB or grayscale images
        p.nChannel=[]; %for multi-channel (fluorescent) image handling
        p.channelprocessing = 1; %which channel is currently processed
        p.channelPrefix=''; %prefix to identify the imaging channel from image name
        p.dir=char(java.lang.System.getProperty('user.home'));%directory. start at home
        p.i=1;%which frame is displayed
        p.overlayIMGstatus=false; %=1 if overlay is activated
        p.dirOverlay=[]; %directory for the overlay images
        p.iOverlay=1;%overlay frame.
        p.iold=0; %old frame, used to check if the frame has changed and image needs update
        p.iOverlayold=0; %old frame, used to check if the frame has changed and image needs update
        p.l=[]; %will contain a list of files with filename
        p.lOverlay=[]; %will contain a list of files with filename
        p.filextension='.JPG'; %default file extension
        p.fileCount=0; %number of files in the directory
        p.smoothFrames=1;%smoothing factor for plots
        p.TLrun=0;% set to 1 if TL is running to suppress display of various things

        % ROI variables
        p.roiType=[];%Analysis area: 0=All images,1=Automatically found plate,2=Delimited zone
        p.roiPolygonImg=[];%For Delimited zone : polygon vertices
        p.roiPlateRad=[];%%For plate:radius of ROI circle in pxl
        p.roiPlateCenter=[];%For plate: center of ROI cirlce

        % TL specific variables
        p.focalframe=[];%where are the centers stored
        p.KymoTrack=[]; %track if the kymograph is correctly elongated during the TL run
        p.KymoChanged=false; %changes to true if something is changed in the kymograph and needs to be saved
        p.overlapTL=[]; % contains for each colony the colonies that overlap with that one
        p.overlapCoord=[]; %contains the 2 coordinates of the two overlapping circles. for each colony, for each overlapping colony
        p.overlapCoordSmall=[]; %same, but transformed for the small image used in the TL run
        p.mat2grayRef=[]; %contains the reference values for mat2gray
        p.kymomode=[]; %kymomode for each colony: 1: global threshold, 2: edge detection
        p.newR=[]; % //TODO: check what this does
        
        % EP-specific variables
        p.multiEPdirs=[]; %contains folder names of each linked folder
        p.timepoints=[]; %timepoints for each linked folder
        p.thistimepoint=[];%timepoint of active folder

        % registration variables
        p.REGstatus=false;%=1 if TL registration is activated
        p.registrationTranslation=[]; %Registration translation shift (x,y)
        p.colonyCenRadUnregistered=[]; %backup the unregistered colony centers and radii
        
        p.coloniesColors=[]; % //TODO: check what this 


        % these are the variables that are measured and should be easily exported
        % general measurement variables
        p.umConversion=[]; %conversion rate from pxl to um, stored per frame

        % radius, center, growth rate, appearance time variables
        p.colonyCenRad=[];%contains the radii and centers derived from find colony function
        p.centers=[];%all centers detected //TODO: remove this and use p.colonyCenRad (lol, Copilot knew it)
        p.radii=[];%all radii detected //TODO: remove this and use p.colonyCenRad (lol, Copilot knew it)
        p.RadMean=[];%radius over time
        p.RadMeanUm=[];%meanRad in micrometers //TODO: remove this and use p.RadMean * p.umConversion
        p.GR=[]; %growth rates per colony
        p.TappErrors=[]; %contains the colonies for which an error occured
        p.R0=[]; %x=0 intercept of the linear regression
        p.Tapp=[]; %appearance time per colony
        p.estTapp=[];%estimated Tapp for EP
        p.TappCalibrated=[]; %subtracted the reference appearance time
        p.VoronoiAreas=[]; %contains the calculated voronoi area

        % user list variables
        p.UserLists=struct; %list of user defined colonies (marked on image and in export)
        p.UserLists.listOptions={'none','-1 near col','-2 failed kymo','new'};
        
        p.colList=[]; %which colony to analyse
        p.timeList=[];%which frames to analyse
        p.timeVect=[]; %range of time

        % reference condition variables
        p.TappRef=[]; %reference appearance time
        p.GRRef=[];%reference GR
        p.GRRefAll=[];%all GR of reference folder
        p.TappRefAll=[];%all Tapp for reference folder
        p.quantileV=0.5; %default quantile for reference

        % comparison variables
        p.currentName='MainComparison';%default name for comparison plotting
        p.compLoaded=false;%set to true if a loaded comparison is a TL
        p.compFileName=[];%name for loaded comparison file storage
        p.comparisonRadUm=[];%for single images: load the rad distribution of exponential comparison at timepoint

        p.Tlag=[]; % will store the Tlag for the opened image set

    end
    function initialize_gui
        
        loadConfig
        
        % batch run
        b.runningBatch=0; %this value becomes 1 when program is running in batch mode
        b.batchFile=[]; %this will contain a list of folders to analyse (all files therein)
        
        Kymo.Kymo=[]; %contains the kymograph
        
        Fvar.lastUndo=nan(7,1); %this will contain values to track user actions to undo actions
        varUndos={'colonyCenRad', 'centers','radii','UserLists'}; %variables to allow undo
        % parameters that are not saved in the p file
        for iv=1:7
            for jv=1:length(varUndos)
                Fvar.([varUndos{jv},num2str(iv)])= [];%all radii for undo
            end
        end
        varUndos='RadMean'; %also to allow undo
        for iv=1:7
            Fvar.([varUndos,num2str(iv)])= [];%all radii for undo
        end
        
        
        Fvar.grayoptions={'RGB, R channel', 'RGB, G channel', 'RGB, B channel', 'Lab, L channel', 'Lab, a channel','Lab, b channel',...
            'YIQ, Y channel', 'YIQ, I channel', 'YIQ, Q channel', 'CIE, X channel','CIE, Y channel', 'CIE, Z channel','YCbCr, Y channel',...
            'YCbCr, Cb channel','YCbCr, Cr channel', 'rgb2gray'};
        Fvar.TLrunning=true;% set to 1 if TL is running to suppress display of various things
        Fvar.csvdelimiters={'comma','semicolon', 'tab', 'space', 'colon'};
        Fvar.csvdelimiterssymbol={',',';', '	', ' ', ':'};
        Fvar.imgextsion={'jpg','jpeg', 'png', 'bmp', 'tiff', 'tif','JPG','JPEG','PNG','BMP','TIFF','TIF'};
        Fvar.showImage=true; %set false to improve speed of the timelapse as the image is not shown for each step

        Fvar.imTBmiss=0; %this is a flag to indicate if the image processing toolbox is missing. //TODO: remove this for python

        Fvar.rgb=[];%contains image
        Fvar.imgray=[]; %the grayscale transformed image
        Fvar.im=[]; %and that the imshow plot
        
        Fvar.background=[]; %temporarily storage of background for cleaner images
        Fvar.imgenhanced=false; %set to 1 if image enhancement process was applied
        Fvar.imgenhanced2=false; %set to 1 if image enhancement process was applied
        
        Fvar.clickcall=0;
        Fvar.clickdisable=0;
        Fvar.numNonUserList=2;
        
        Fvar.circlehandleR=[];
        Fvar.circlehandleG=[];
        Fvar.circlehandleB=[];
        Fvar.numberhandle=[];
        Fvar.roihandle=[];
        Fvar.voroThandle=[];
        Fvar.voroAhandle=[];
        
        VorEdg.VoronoiEdges=[];
        
        ProgressInitialize %call to this function initialize all progress ckeck variables
        hs.UserMess.String='started'; %user message to be printed
    end %initiate all parameters

%% load data, initialize missing variables, classify folders
    function loadConfig
        % Define the filename
        fullPath = mfilename('fullpath');
        [curd, ~, ~] = fileparts(fullPath);
        configFile = 'coltapp_config.json';
        
        % Check if the config file exists
        if isfile(fullfile(curd, configFile))
            % Load and decode the JSON file
            fid = fopen(configFile, 'r');
            raw = fread(fid, inf);
            str = char(raw');
            fclose(fid);
            p = jsondecode(str);
        else
            % If the file doesn't exist, create it with default settings
            initialize_pstruc;
            saveConfig(p, fullfile(curd, configFile)); % Save the default parameters to a new JSON file
        end
    end

    function saveConfig(p, configFile)
        % Encode the struct as JSON
        jsonStr = jsonencode(p, 'PrettyPrint', true); % 'PrettyPrint' for human-readable JSON
        
        % Write to the file
        fid = fopen(configFile, 'w');
        if fid == -1
            error('Cannot create JSON file.');
        end
        fwrite(fid, jsonStr, 'char');
        fclose(fid);
    end
    function LoadButton_callback (~, ~)
        %This function executes when "Load/Open" button is pressed. It asks
        %user to find a directory and calls the function chngDir
        dirTemp=p.dir;%store the current dir for default display
        
        %ask user for dir
        dirUser=uigetdir(dirTemp,'please select the directory with the timelapse images');
        if dirUser==0; return; end %user cancelled
        
        if writeperm(dirUser); errordlg('ColTapp needs Writting permisssion to operate. This permission was denied.'); return; end
        
        %         b=struct();
        if ~exist('b', 'var')
            b=struct();
            b.batchmode=0;
        end
        if ~isstruct(b)
            b=struct();
            b.batchmode=0;
        end
        if ~isfield(b, 'batchmode')
            b.batchmode=0;
        end
        
        if hs.firstLoad==1%this will be one for the first startup of the GUI. Do nothing than change that value
            hs.firstLoad=0;
            errorTrck=0;
        else% we reset the GUI
            % Add the UI components
            clf
            Layoutcomponents;
            clear p; clear colonies;
            % Initialise variables
            p=struct();%all the data
            colonies=struct();%struct for tlag comparison
            orig=struct();
            VorEdg=struct();
            initialize_gui;
            errorTrck=1;
        end
        hs.UserMess.String='Please wait, data is loading...';customdrawnow

        p.dir=dirUser; %update p.dir
        p.dirS=p.dir; %the file saving is initialy done on the same folder
        erlod=chngDir; %actual loading function
        
        if length(p.l)<1
            waitfor(errordlg('There are no images in this folder. Loading is cancelled'));
            if ~errorTrck
                clf
                Layoutcomponents;
                clear p; clear colonies;
                % Initialise variables
                hs.UserMessNumCol.String= ''; customdrawnow
                delete(hs.fig);
                hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
                p.dir=dirUser; %update p.dir
                p.dirS=p.dir; %the file saving is initialy done on the same folder
                hs.UserMess.String='Loading failed';customdrawnow
                return
            else
                p.dir=dirTemp;
                p.dirS=p.dir;
                chngDir
                refresh(1);
                ProgressUpdate;
                hs.UserMess.String='Loading failed';customdrawnow
                return
            end
            
        elseif ~erlod
            p.dir=dirTemp;
            p.dirS=p.dir;
            chngDir
            refresh(1);
            ProgressUpdate;
            hs.UserMess.String='Loading failed';customdrawnow
            return
        else
            hs.UserMessNumCol.String= ''; customdrawnow
            hs.UserMess.String='Setting up GUI...';customdrawnow
            delete(hs.fig);
            hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
        end
        
        backwardCompatTest()
        
        p.dir=dirUser; %reallocate the p.dir to the input dir. chngDir loads the whole p struct and if the folder was moved or
        %renamed, it would load the old invalid p.dir which  gives
        %errors..
        p.dirS=p.dir; %same for that
        p.del=strfind(p.dirS,filesep); %looking for delimiter in folder name
        %check if the type of the image set is already defined
        if isempty(p.operatingMode) || ((sum(strcmp(p.operatingMode,'single'), 'omitnan')==0)&&(sum(strcmp(p.operatingMode,'TL'), 'omitnan')==0))
            p.definedOperatingMode=0;
        end
        
        if ~p.definedOperatingMode
            p.focalframe=length(p.l);%otherwise, running into errors if no focalframe is defined...
            Classify_callback;%classify the images as timelapse or single image sets
            if p.nChannel > 1
                p.channelindex = nan(length(p.l),1);
                for chi = 1:p.nChannel
                    chpat = [p.channelPrefix, num2str(chi)];
                    p.channelindex(arrayfun(@(x) contains(x.name, chpat), p.l)) = chi;
                end
                for chi = 2:p.nChannel
                    fieldName = sprintf('l%d', chi); % Construct field name dynamically
                    p.(fieldName) = p.l(p.channelindex == chi);
                end
                p.l = p.l(p.channelindex == 1);
                p.focalframe = length(p.l);
            end
            
            if strcmp(p.operatingMode,'TL'); p.i=length(p.l); end %if in TL mode, directly jump to the last frame if classify
            chngList(2,0,zeros(0,1));
            chngList(1,0,zeros(0,1));
        else
            if isempty(p.nChannel)
                p.nChannel = 1;
            end
        end
        
        if length(p.dir)>30%display dir name in GUI
            hs.UserMessDir.String = ['...' p.dir(end-30:end)];
        else
            hs.UserMessDir.String = p.dir;
        end
        
        
        txtMsg= ''; text(0.25, 0.5, txtMsg,'Fontsize', 14);customdrawnow
        axes(hs.Progress1); fill([0 0 0 0],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none');customdrawnow
        if p.i<1 || p.i>length(p.l)
            p.i=1;
        end
        set(hs.Classify, 'String', p.operatingModeStr);
        p.compFileName=[];%reset that to reset the load comparison button action mode
        p.progress.open=1; %files are open
        hs.overlay.Value=p.overlayIMGstatus;%reset the overlay toggle
        
        if isempty(p.roiType) || length(p.roiType)~=length(p.l)%check if the AA has the correct length, if not initialize with 0 -> whole image
            p.roiType=zeros(length(p.l),1);
        end
        
        if ~isempty(p.RadMean) %Basically only occurs if switching from one mode to the other
            if size(p.RadMean,1)~=size(p.colonyCenRad{p.focalframe},1)
                p.RadMean(size(p.colonyCenRad{p.focalframe},1)+1:end,:)=[];
            end
        end
        
        if isempty(p.umConversion) %|| length(p.umConversion)~=length(p.l) %initialize p.umConversion if not done yet
            p.umConversion=nan(length(p.l),1);
        end
        
        
        Fvar.showImage=1;p.i=length(p.l);Fvar.TLrunning=0;%ensure that the image is shown correctly
        
        
        p.disableSave=0;
        
        %         refresh(0)
        if ~isfield(p,'vAA'); p.showROI=1; end %initialize p.showROI
        if p.showGrayscale || ~strcmp(p.imgFormat, 'rgb') %define color of the colony Nr.
            p.showNrCol='g';
        else
            p.showNrCol='k';
        end
        p.KymoChanged=0;
        ProgressUpdate;
        %and update the left/right arrows state if needed
        
        if p.overlayIMGstatus && isempty(p.dirOverlay)
            RemoveMultiEP_Callback
        end
        
        
        
        
        if strcmp(p.operatingMode,'TL') && ~isempty(p.focalframe)
            p.i=p.focalframe;
        elseif strcmp(p.operatingMode,'TL') && isempty(p.focalframe)
            p.i=length(p.l);
        elseif ~isempty(p.i)
            p.i=1;
        end
        p.ShowCol=1;
        hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
        refresh(0);
        
        if length(p.l)==1 %let them disappear if only 1 image loaded
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Visible', 'off');
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Visible', 'off');
        else
            if p.i==1
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            elseif p.i==length(p.l)
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            else
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            end
        end
        set(hs.modColonyClick, 'Value', p.modColonyClick);
        if ~strcmp(p.operatingMode, 'TL')
            set(hs.GRdist, 'String', 'Growth rate vs Time');
        else
            set(hs.GRdist, 'String', 'Growth rate distribution');
        end
        
        Fvar.clickdisable= ~p.modColonyClick;
        
        if p.showList
            set (hs.ShowList, 'String', 'Hide')
        else
            set (hs.ShowList, 'String', 'Show')
        end
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        hs.UserMess.String='Loading finished';customdrawnow
    end%load folder
    function E=writeperm(dirUser)
        [fid,errmsg] = fopen([dirUser,filesep,'testColTapp.m'],'a');
        if ~isempty(errmsg)
            E=1;
        else
            E=0;
            fclose(fid);
            delete([dirUser,filesep,'testColTapp.m']);
        end
    end
    function errorloading=chngDir
        %will return 1 if loading was correct. Loads a list of files in a
        %directory. Looks if previous mat files were already save, and
        %loads them accordingly.
        dirTemp=p.dir;%store the indicated dir to ensure no errors occur if the folder was moved or renamed since last opening
        %getting file list
        errorloading=1;
        clear l;
        reduceKymo=0;
        if ~exist('b','var')
            b=struct();
        end
        if ~isstruct(b)
            b=struct();
        end
        if ~isfield(b,'runningBatch')
            b.runningBatch=0;
        end
        if b.runningBatch
            p=struct();
            VorEdg=struct();
            p.dir=dirTemp;
            p.dirS=dirTemp;
            p.l=[];
        end
        for filextension=Fvar.imgextsion
            clear keep;
            l=dir([p.dir, filesep, '*',filextension{1}]); %lists all files with filextension
            if ~isempty(l) %found files
                for h=1:size(l,1)
                    keep(h)=(l(h).name(1)~='.'); %removes all directories and parents (files which start with '.')
                end
                if sum(keep)>length(p.l)
                    p.l=l(keep);
                end
            end
        end
        
        if ~isempty(dir([p.dir, filesep, '*','all.mat','*'])) %found a file countaing "all"
            l=p.l; %saving the list variable
            files=dir([p.dir, filesep, '*','all.mat','*']);
            a=nan(length(files),1);
            for ii=1:length(files)%copy the date of each file to a vector to be able to run max on it
                
                try
                    a(ii)=datenum(files(ii).date);
                catch %somehow datenum does not work
                    if ~isempty(strfind(files(ii).date,'Mrz'))
                        files(ii).date=strrep(files(ii).date,'Mrz','Mar');
                        try
                            a(ii)=datenum(files(ii).date);
                        catch
                            if b.batchmode==0
                                errordlg(['The date of the file ', files(ii).name, ' in the folder you try to load cannot be read. Please delete that and try again.']);
                                hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                                return ;
                            else
                                b.summary(b.TheOneRunning)=0;
                                return
                            end
                        end
                    end
                end
                
            end
            [~, ind]=max(a);%find the most recent file and take that to load
            try
                fileAll=load([p.dir,filesep,files(ind).name]); %this contains, counts, i, Rad, RadMean, dir, minRad, maxRad and sensitivity
            catch %somehow files can become corrupt, notify the user which one and cancel loading
                if b.batchmode==0
                    errordlg(['The file called: ', files(ind).name, ' in the folder you try to load is corrupt. Please delete that and try again.']);
                    hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                    return
                else
                    b.summary(b.TheOneRunning)=0;
                    return
                end
                
            end
            if isfield(fileAll,'p')
                if ~isfield(fileAll.p, 'coltappV')
                    p.coltappV = 1;
                end
                for fn=fieldnames(fileAll.p)'
                    p.(fn{1}) = fileAll.p.(fn{1});
                    %disp(fn{1}) %will display all loaded fieldnames
                end
            else %files created by previous versions of CTA
                for fn=fieldnames(fileAll)'
                    p.(fn{1}) = fileAll.(fn{1});
                    %                     disp(fn{1})
                end
            end
            


            if length(p.l)==length(l)
                p.l=l;
                reduceKymo=0;
            else %reset things if the length of images is different than before

                
                if ~b.runningBatch
                    if length(l)<length(p.l)
                        

                        quest=(['There are fewer image files (', num2str(length(l)), ') in this folder than in the previous'...
                            ' analysis file (', num2str(length(p.l)), ' images) in this folder. Do you want to reset all analysis '...
                            'or use the found number of ', num2str(length(l)), ' images?']);
                        
                        
                        done=0;
                        while ~done
                            answer = questdlg(quest,'Error','Reset',['use ', num2str(length(l)), ' images'],'Cancel loading','Reset');
                            switch answer
                                case 'Reset'
                                    p.l=l;
                                    p.colonyCenRad=cell(length(p.l),2); %creating empty cell with the nb of pictures
                                    p.RadMean=[];
                                    p.RadMeanUm=[];
                                    errorloading=1;
                                    reduceKymo=-1;
                                    p.KymoChanged=1;
                                    
                                    ProgressInitialize;
                                    resetVariables;
                                    done=1;
                                case ['use ', num2str(length(l)), ' images']
                                    
                                    notMatch=zeros(length(p.l),1);
                                    for i1=1:length(p.l)
                                        for i2=1:length(l)
                                            if strcmp(p.l(i1).name, l(i2).name)
                                                notMatch(i1)=0;
                                                break
                                            else
                                                notMatch(i1)=1;
                                            end
                                        end
                                    end
                                    p.l=p.l(~notMatch);
                                    
                                    
                                    if strcmp(p.operatingMode, 'TL')
                                        try p.KymoTrack=p.KymoTrack(:,~notMatch);catch;end
                                        try p.RadMean=p.RadMean(:,~notMatch);catch;end
                                        try p.RadMeanUm=p.RadMeanUm(:,~notMatch);catch;end
                                        try p.umConversion=p.umConversion(~notMatch);catch;end
                                        reduceKymo=1;
                                        p.KymoChanged=1;
                                        if p.focalframe>length(p.l)
                                            for i3=1:size(p.colonyCenRad,1)
                                                if ~isempty(p.colonyCenRad{i3,1})
                                                    p.focalframe=i3;
                                                    if i3>length(p.l)
                                                        p.colonyCenRad{length(p.l),1}=p.colonyCenRad{i3,1};
                                                        p.colonyCenRad{length(p.l),2}=p.colonyCenRad{i3,2};
                                                        p.focalframe=length(p.l);
                                                        p.colonyCenRad=p.colonyCenRad(~notMatch,:);
                                                    else
                                                        p.colonyCenRad=p.colonyCenRad(~notMatch,:);
                                                    end
                                                    continue
                                                end
                                            end
                                        end
                                    else
                                        p.colonyCenRad=p.colonyCenRad(~notMatch,:);
                                    end
                                    
                                    done=1;
                                case ''
                                    errorloading=0;
                                    return
                                case 'Cancel loading'
                                    errorloading=0;
                                    return
                            end
                        end
                        
                    else
                        if ~isfield(p, 'nChannel')
                            if isfield(p, 'nhannel')
                                p.nChannel = p.nchannel;
                                p.channelPrefix = p.channelprefix;
                            else
                                p.nChannel = [];
                            end
                        else
                            if isfield(p, 'nchannel')
                                if isempty(p.nChannel) && ~isempty(p.nchannel)
                                    p.nChannel = p.nchannel;
                                    p.channelPrefix = p.channelprefix;
                                end
                            end
                        end
                        if p.nChannel > 1
                            p.l=l;
                            reduceKymo=0;
                            p.channelindex = nan(length(p.l),1);
                            for chi = 1:p.nChannel
                                chpat = [p.channelPrefix, num2str(chi)];
                                p.channelindex(arrayfun(@(x) contains(x.name, chpat), p.l)) = chi;
                            end
                            for chi = 2:p.nChannel
                                fieldName = sprintf('l%d', chi); % Construct field name dynamically
                                p.(fieldName) = p.l(p.channelindex == chi);
                            end
                            p.l = p.l(p.channelindex == 1);
                            p.focalframe = length(p.l);
                        else
                            waitfor(errordlg(['There are more image files in this folder than stored in the previous',...
                                ' analysis file. The previous analysis file is discarded.']))
                            p.l=l;
                            p.colonyCenRad=cell(length(p.l),2); %creating empty cell with the nb of pictures
                            p.RadMean=[];
                            p.RadMeanUm=[];
                            errorloading=0;
                            reduceKymo=-1;
                            p.KymoChanged=1;
                            
                            ProgressInitialize;
                            resetVariables;
                        end
                        
                    end
                else
                    b.summary(b.TheOneRunning)=0;
                    
                end
                
            end
        else %nothing found
            if isfield(pback, 'dirS')
                errorloading=1;
                p.colonyCenRad=[];
                return
            end
            
            if ~b.runningBatch
                resetVariables %reset the most important variables
            else
                b.summary(b.TheOneRunning)=0;
                return
            end
            
            p.filextension=filextension;
            errorloading=0;
            if ~isempty(p.l)
                errorloading=1;
                %                errordlg('There are no images in this folder');
                return
            end
        end
        p.iold=0; %this ensures refresh is going to print the image. Is it?
        
        
        %load the kymograph file
        if reduceKymo~=-1
            if ~isempty(dir([dirTemp, filesep, '*','Kymograph','*'])) %found a file countaing "all"
                files=dir([dirTemp, filesep, '*','Kymograph','*']);
                a=nan(length(files),1);
                for ii=1:length(files)%copy the date of each file to a vector to be able to run max on it
                    try
                        a(ii)=datenum(files(ii).date);
                    catch %somehow datenum does not work
                        if ~isempty(strfind(files(ii).date,'Mrz'))
                            files(ii).date=strrep(files(ii).date,'Mrz','Mar');
                            try
                                a(ii)=datenum(files(ii).date);
                            catch
                                if b.batchmode==0
                                    errordlg(['The date of the file ', files(ii).name, ' in the folder you try to load cannot be read. Please delete that and try again.']);
                                    hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                                    return ;
                                end
                            end
                        end
                    end
                    
                end
                [~, ind]=max(a);%find the most recent file and take that to load
                try
                    fileAll=load([dirTemp,filesep,files(ind).name]); %this contains, counts, i, Rad, RadMean, dir, minRad, maxRad and sensitivity
                catch %somehow files can become corrupt, notify the user which one and cancel loading
                    if b.batchmode==0
                        errordlg(['The file called: ', files(ind).name, ' in the folder you try to load is corrupt. Please delete that and try again.']);
                        hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                        return
                    end
                end
                if isfield(fileAll,'Kymo')
                    for fn=fieldnames(fileAll.Kymo)'
                        Kymo.(fn{1}) = fileAll.Kymo.(fn{1});
                        %disp(fn{1}) %will display all loaded fieldnames
                    end
                else %files created by previous versions of CTA
                    for fn=fieldnames(fileAll)'
                        Kymo.(fn{1}) = fileAll.(fn{1});
                        %                     disp(fn{1})
                    end
                end
            end
            try
                if size(Kymo.Kymo{1},1)>length(p.l)
                    reduceKymo=1;
                end
            catch
                reduceKymo=-1;
            end
            
            if reduceKymo==1
                if ~exist('notMatch','var')
                    if ~b.runningBatch
                        quest=(['The number of images (',num2str(length(p.l)),') does not match the length of the Kymograph (' ,...
                            num2str(size(Kymo.Kymo{1},1)),'). Have images been removed from the beginning, end or other times of the timelapse? Choose other, if you do not know']);
                        
                        done=0;
                        while ~done
                            answer = questdlg(quest,'Error','Beginning','End','Other','Beginning');
                            switch answer
                                case 'Beginning'
                                    notMatch=zeros(size(Kymo.Kymo{1},1),1);
                                    ldif=size(Kymo.Kymo{1},1)-length(p.l);
                                    notMatch(1:ldif)=1;
                                    done=1;
                                case 'End'
                                    notMatch=zeros(size(Kymo.Kymo{1},1),1);
                                    ldif=size(Kymo.Kymo{1},1)-length(p.l);
                                    notMatch(size(Kymo.Kymo{1},1)-ldif:size(Kymo.Kymo{1},1))=1;
                                    done=1;
                                case 'Other'
                                    waitfor(errordlg('Sorry, there is no option to insert the information about the missing frames, the Kymograph is deleted'));
                                    notMatch=[];
                                    done=1;
                            end
                            if ~done
                                waitfor(errordlg('Please choose an option. If you do not know, choose other'));
                            end
                        end
                    else
                        notMatch=[];
                    end
                end
                if ~isempty(notMatch)
                    for ii=1:size(Kymo.Kymo, 1)
                        try
                            Kymo.Kymo{ii}=Kymo.Kymo{ii}(~notMatch,:);
                        catch
                            Kymo.Kymo{ii}=[];
                        end
                    end
                else
                    Kymo.Kymo=[];
                end
                p.KymoChanged=1;
            elseif reduceKymo==-1
                Kymo.Kymo=[];
                p.KymoChanged=1;
            end
        end
        
        %load the vornoi edge file
        if ~isempty(dir([dirTemp, filesep, '*','VoronoiEdges','*'])) %found a file countaing "all"
            files=dir([dirTemp, filesep, '*','VoronoiEdges','*']);
            a=nan(length(files),1);
            for ii=1:length(files)%copy the date of each file to a vector to be able to run max on it
                try
                    a(ii)=datenum(files(ii).date);
                catch %somehow datenum does not work
                    if ~isempty(strfind(files(ii).date,'Mrz'))
                        files(ii).date=strrep(files(ii).date,'Mrz','Mar');
                        try
                            a(ii)=datenum(files(ii).date);
                        catch
                            if b.batchmode==0
                                errordlg(['The date of the file ', files(ii).name,...
                                    ' in the folder you try to load cannot be read. Please delete that and try again.']);
                                hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                                return ;
                            end
                        end
                    end
                end
                
            end
            [~, ind]=max(a);%find the most recent file and take that to load
            try
                fileAll=load([dirTemp,filesep,files(ind).name]); %this contains, counts, i, Rad, RadMean, dir, minRad, maxRad and sensitivity
            catch %somehow files can become corrupt, notify the user which one and cancel loading
                if b.batchmode==0
                    errordlg(['The file called: ', files(ind).name,...
                        ' in the folder you try to load is corrupt. Please delete that and try again.']);
                    hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                    return
                end
            end
            if isfield(fileAll,'VorEdg')
                for fn=fieldnames(fileAll.VorEdg)'
                    VorEdg.(fn{1}) = fileAll.VorEdg.(fn{1});
                    %disp(fn{1}) %will display all loaded fieldnames
                end
            end
        end
        
        
        
        %reset to 1 if above max possible
        if p.i>length(p.l)
            p.i=1;
        end
        p.dir=dirTemp;%as otherwise the loaded p.dir is used. wrong if the whole folder was moved
        try
            p.l=rmfield(p.l, 'date');
        catch
        end
        try
            p.l=rmfield(p.l, 'folder');
        catch
        end
        try
            p.l=rmfield(p.l, 'bytes');
        catch
        end
        try
            p.l=rmfield(p.l, 'isdir');
        catch
        end
        try
            p.l=rmfield(p.l, 'datenum');
        catch
        end
        if ~isfield(p, 'nChannelDontAsk')
            p.nChannelDontAsk = true;
            p.nChannel = 1;
            p.channelPrefix = 'Ch';
        end
        if ~p.nChannelDontAsk & isempty(p.nChannel)
            define_nChannel;
        end
    end  %actual data loading
    function backwardCompatTest()
        % Backward compatibility: check if the new variables are there
        % already. if not add these as default values.
        if ~isfield(p, 'coltappV')
            p.coltappV=1;
        end
        if ~isfield(p, 'showNr') %somehow this is not updated with some older versions..?
            p.showNr=false;
        end
        if p.coltappV<1.2
            if ~isfield(p, 'nChannelDontAsk')
                p.nChannelDontAsk = true;
            end
            if p.nChannelDontAsk
                p.nChannel = 1;
                p.channelPrefix = 'Ch';
            else
                p.nChannel = [];
                p.nchannelPrefix = 'Ch';
            end
            p.coltappV = 1.2;
            p.imgFormat = p.imgmode;
            p.operatingMode = p.mode;
            p.operatingModeStr = p.modeStr;
            p.definedOperatingMode = logical(p.definedWhat);
    
            p.modColonyClick=logical(p.mouseaddrem);
            p.showColony=logical(p.ShowCol);
            p.showGrayscale=logical(p.BW);
            p.showCircleScale=p.apR;
            p.showROI=logical(p.vAA);
            p.showList=logical(p.showlist);
            p.ShowVoronoiAreas=logical(p.ShowVoronoiAreas);
            p.ShowVoronoiEdges=logical(p.ShowVoronoiEdges);
    
            p.colonyCenRad=p.counts;
    
            p.roiType=p.AA;%Analysis area: 0=All images,1=Automatically found plate,2=Delimited zone
            p.roiPolygonImg=p.subIMG;%For Delimited zone : polygon vertices
            p.roiPlateRad=p.plateradius;%%For plate:radius of ROI circle in pxl
            p.roiPlateCenter=p.platecenter;%For plate: center of ROI cirlce
    
            p.detectMinRadPx=p.minRadN;
            p.detectMaxRadPx=p.maxRadN;
            p.BlackColony=p.blackcircle;
            p.detectSensitivity=p.sensitivityN;
            p.detectMinFillCircle=p.SensitivityF1;
            p.detectMinFillCircleOverlap=p.SensitivityF2;
            p.detectBinarizeSensitivity=p.circlebinsens;
            p.detectRadStepsize=p.Dt;
            p.detectRescaleBigCol=p.Goodsize;
            p.detectMaxOverlap=p.maxoverlap_comp;
            p.detectBinarizationMethod=p.imGprocess;
            p.detectCircleMode=p.circlemode;
            p.detectBoundingBoxScale=p.boundingboxscale;
            p.detectBlurDiskSize=p.findcirclesblurscale;
            p.detectMaxCircleGradient=p.maxcirclesgradient;
            p.detectMinBorderDist=p.minborderdistance;
            p.detectForegroundBias=p.foregroundbias;
            p.detectMinForground=p.minfillcircles;
            p.detectMaxOverlapCompare=p.maxoverlap_comp;
            p.detectDiscardOvelapMinRadDiff=p.minraddiff;
            p.detectDiscardOvelapMinCentDst=p.mincenterdist;
            p.detectMaxOverlapTotal=p.maxoverlap_total;
            p.detectMaxOverlapStartThresh=p.maxoverlap_startthresh;
            p.detectMinCenterDistFinal=p.mindist_final;
    
            p.registrationFactor=p.registration_factor;
    
            p.radCropAreaScaleFactor=p.Zonesize;
            p.radOverlapScale=p.radoverlapscale;
            p.radzeroRadCutoff=p.ZeroRadCutoff;
            p.radThetaResolution=p.tres;
            p.radOverlapRemoveTheta=logical(p.OlapRem);
            p.radUseEnhancedImg=logical(p.TLimgenhance);
            p.radDefaultKymoMode=p.kymomode;
            p.radKymoBias=p.kymo_tresh_shift;
            p.radzeroRadCutoff = p.ZeroRadCutoff;
    
            p.compFileName=p.loadedComp;%name for loaded comparison file storage
            p.currentName = p.TLname;
    
            p.tappMode=p.TappMode; %can be either 'um' or 'px'. define if the Tapp is calculated via pxl or um thresholding
            p.tappThreshUm=p.RdetThreshUm; %for the Tapp calculation (if mode um)
            p.tappThreshPx=p.RdetThreshPx; %detection threshold in pxl (if mode px)
            p.tappLengthLinFitFrame=p.lengthLinFitFrame; %number of frames in which we fit the linear regression
            p.tappRefMode=p.refMode; %reference mode for growth rate extraction: 'Mean' or 'Quantile'
            p.tappRefQuantile=p.quantileV; %default quantile for reference growth rate extraction (only used if refMode is set to 'Quantile')
            if  isfield(p, 'RdetSafety')
                p.tappStayOverThresh=p.RdetSafety; % Rad needs to stay above the threshold for that many frames otherwise discarded
            end
    
            % reference condition variables
            p.TappRef=p.TdetRef; %reference appearance time
            p.TappRefAll=p.TdetRefAll;%all Tapp for reference folder
    
            p.REGstatus=logical(p.REGstatus);%=1 if TL registration is activated
            p.registrationFactor=p.registration_factor; % //TODO: check what this does
            p.registrationTranslation=p.shift; %Registration translation shift (x,y)
            p.colonyCenRadUnregistered=p.counts_unregistered; %backup the unregistered colony centers and radii
            if isfield(p, 'scalepillboxdef')
                p.kymoScalePillboxdef=p.scalepillboxdef;
                p.kymoWienerFilterSizedef=p.wienersizedef;
                p.kymoMaxIntensityCutoffdef=p.maxIntensitydef;
                p.kymoCannyLowThreshdef=p.cannythresh1def;
                p.kymoCannyHighThreshdef=p.cannythresh2def;
                p.kymoNoiseFilterSizedef=p.noisepixeldef;
                p.kymoVerticalLineRemovaldef=p.scalestraightlineTimedef;
                p.kymoHorizontalLineRemovaldef=p.scalestraightlineRaddef;
                p.kymoCloseFilterLineLendef=p.scaleradclosedef;
                p.kymoCloseFilterLineAngledef=p.anglelineclosedef;
                p.kymoCloseFilterDiskSizedef=p.disksizedef;
                p.kymoMaskScalingdef=p.scalemaskthreshdef;
                p.kymoIterationsdef=p.numberOfIterationsdef;
                p.kymoInvertContourdef=p.flipactcontdef;
                p.kymoInvertKymodef=p.invertkymodef;
                p.kymoDisablePrefilterdef=p.disablefiltdef;

                p.kymoScalePillbox=p.scalepillbox;
                p.kymoWienerFilterSize=p.wienersize;
                p.kymoMaxIntensityCutoff=p.maxIntensity;
                p.kymoCannyLowThresh=p.cannythresh(:,1);
                p.kymoCannyHighThresh=p.cannythresh(:,2);
                p.kymoNoiseFilterSize=p.noisepixel;
                p.kymoVerticalLineRemoval=p.scalestraightlineTime;
                p.kymoHorizontalLineRemoval=p.scalestraightlineRad;
                p.kymoCloseFilterLineLen=p.scaleradclose;
                p.kymoCloseFilterLineAngle=p.anglelineclose;
                p.kymoCloseFilterDiskSize=p.disksize;
                p.kymoMaskScaling=p.scalemaskthresh;
                p.kymoIterations=p.numberOfIterations;
                p.kymoInvertContour=p.flipactcont;
                p.kymoInvertKymo=p.invertkymo;
                p.kymoDisablePrefilter=p.disablefilt;
            end
    
            % Remove old variable names
            old_fields = {'imgmode', 'mode', 'modeStr', 'definedWhat', 'mouseaddrem', 'ShowCol', 'BW', 'apR', 'vAA', 'showlist', ...
                          'counts', 'AA', 'subIMG', 'plateradius', 'platecenter', 'minRadN', 'maxRadN', 'blackcircle', 'sensitivityN', ...
                          'SensitivityF1', 'SensitivityF2', 'circlebinsens', 'Dt', 'Goodsize', 'maxoverlap_comp', 'imGprocess', ...
                          'circlemode', 'boundingboxscale', 'findcirclesblurscale', 'maxcirclesgradient', 'minborderdistance', ...
                          'foregroundbias', 'minfillcircles', 'minraddiff', 'mincenterdist', 'maxoverlap_total', 'maxoverlap_startthresh', ...
                          'mindist_final', 'registration_factor', 'Zonesize', 'radoverlapscale', 'ZeroRadCutoff', 'tres', 'OlapRem', ...
                          'TLimgenhance', 'kymomode', 'kymo_tresh_shift', 'loadedComp', 'TLname', 'TappMode', 'RdetThreshUm', ...
                          'RdetThreshPx', 'lengthLinFitFrame', 'refMode', 'quantileV', 'RdetSafety', 'TdetRef', 'TdetRefAll', ...
                          'shift', 'counts_unregistered', 'scalepillboxdef', 'wienersizedef', 'maxIntensitydef', 'cannythresh1def', ...
                          'cannythresh2def', 'noisepixeldef', 'scalestraightlineTimedef', 'scalestraightlineRaddef', 'scaleradclosedef', ...
                          'anglelineclosedef', 'disksizedef', 'scalemaskthreshdef', 'numberOfIterationsdef', 'flipactcontdef', ...
                          'invertkymodef', 'disablefiltdef', ...
                          'scalepillbox', 'wienersizedef', 'maxIntensitydef', ...
                          'cannythresh1def', 'cannythresh2def', 'noisepixeldef', ...
                          'scalestraightlineTimedef', 'scalestraightlineRaddef', ...
                          'scaleradclosedef', 'anglelineclosedef', 'disksizedef', ...
                          'scalemaskthreshdef', 'numberOfIterationsdef', 'flipactcontdef', ...
                          'invertkymodef', 'disablefiltdef',...
                          'scalepillbox', 'wienersize', 'maxIntensity', ...
                          'cannythresh1', 'cannythresh2', 'noisepixel', ...
                          'scalestraightlineTime', 'scalestraightlineRad', ...
                          'scaleradclose', 'anglelineclose', 'disksize', ...
                          'scalemaskthresh', 'numberOfIterations', 'flipactcont', ...
                          'invertkymo', 'disablefilt'};
            for i = 1:length(old_fields)
                try
                    p = rmfield(p, old_fields{i});
                catch
                    % Field does not exist, do nothing
                end
            end
        elseif p.coltappV>=1.2
            pbck = p;
            loadConfig;
            % Get the field names of struct p
            fields_p = fieldnames(p);
            % Loop through each field in p
            for i = 1:length(fields_p)
                fieldName = fields_p{i};  % Current field name
            
                % Check if the field exists in pbck
                if ~isfield(pbck, fieldName)
                    % If the field doesn't exist in pbck, copy it from p
                    pbck.(fieldName) = p.(fieldName);
                end
            end
            p = pbck;
            clear pbck
        end
        if ~isfield(p, 'nChannelDontAsk')
            p.nChannelDontAsk = true;
        end
        if ~isfield(p, 'nChannel') && p.nChannelDontAsk
            p.nChannel = 1;
            p.channelPrefix = 'Ch';k
        elseif ~isfield(p, 'nChannel') && ~p.nChannelDontAsk
            p.nChannel = [];
            p.nchannelPrefix = 'Ch';
        end
    end %add new variables to old datafiles

    function resetVariables(~,~)
        
        temp.l=p.l;
        temp.dir=p.dir;
        temp.dirS=p.dirS;
        clf
        Layoutcomponents;
        clear p; clear colonies;
        % Initialise variables
        p=struct();%all the data
        loadConfig
        colonies=struct();%struct for tlag comparison
        VorEdg=struct();
        b=struct();
        initialize_gui;
        p.l=temp.l;
        p.dir=temp.dir;
        p.dirS=temp.dirS;
        p.colonyCenRad=cell(length(p.l),2);
        p.progress.open=1;
        p.roiType=zeros(length(p.l),1);
        p.imgFormat=[];
        p.disableSave=0;
        ProgressUpdate;
        UpdateButtonState;%button color change and enabling
    end %reset variables if fresh folder is loaded
    function Classify_callback(~,~)
        abort=0;%goes to 1 if the user aborts that function
        resetting=0; %is turned to 1 if the images were actually already classified
        warning('off','MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero'); %suppress harmless warning
        if p.definedOperatingMode
            if strcmp(p.operatingMode, 'TL')
                msg='Timelapse.';
            else
                msg='single timepoint images.';
            end
            waitfor(errordlg(['Warning: changing the mode will reset all progress made with this dataset! Current mode: ', msg,...
                ' Choose the same in the following question to not reset your progress']));
            resetting=1;
        end
        
        if length(p.l)==1% if there is only 1 image, it can't be a timelapse
            p.operatingMode='single';
            p.definedOperatingMode=1;
        else
            p.definedOperatingMode=0;
        end
        
        %and if not define it now
        while ~p.definedOperatingMode
            question1=questdlg('Are the loaded images from a timelapse or single timepoint images?',...
                'Timelapse or single images?','Timelapse','Single images','Timelapse');
            switch question1
                case 'Timelapse'
                    if resetting && strcmp(p.operatingMode, 'single') % that means the user wants to reset all variables
                        resetVariables;
                        p.focalframe=length(p.l);
                        p.i=length(p.l);
                    end
                    
                    
                    try
                        addT=calculateDT([p.dir, filesep,p.l(1).name],[p.dir, filesep,p.l(2).name]);
                    catch
                        addT=nan;
                    end
                    if sum(isnan(addT)) || isempty(addT) || length(addT)>1 || sum(addT<0) || addT<1 %automatic detection didn't work
                        hs.UserMess.String='Time interval not detected. Set to default 10min.';customdrawnow
                        addT=10;
                    end
                    
                    p.deltaTmin=addT;
                    p.operatingMode='TL';
                    p.definedOperatingMode=1;
                case 'Single images'
                    if resetting && strcmp(p.operatingMode, 'TL') %if reset
                        resetVariables;
                        p.i=1;
                    end
                    p.operatingMode='single';
                    p.definedOperatingMode=1;
                case '' %make it possible for the user to escape the question... But he really should answer that one :)
                    if abort; return; end
                    abort=1;
                    waitfor(errordlg('Please choose an option! If you want to abort loading, close the input query again'));
            end
        end
        % if we disabled asking for the channel
        if p.nChannelDontAsk || strcmp(p.operatingMode, 'single')
            p.nChannel = 1;
            p.channelPrefix = 'Ch';
        end

        define_nChannel;
        
        %update the button string
        if strcmp(p.operatingMode, 'TL')
            p.operatingModeStr='TL mode';
            set(hs.Classify, 'String', p.operatingModeStr);
            hs.SITab.Parent=[];
        elseif strcmp(p.operatingMode,'single')
            p.operatingModeStr='EP mode';
            set(hs.Classify, 'String', p.operatingModeStr);
            hs.TimeLapseTab.Parent=[];
        end
        
        warning('on','MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero');
        if resetting %otherwise not needed
            backwardCompatTest
            refresh(1)
        end
        
        p.del=strfind(p.dirS,filesep); %because windows and mac have different delimiters
        p.currentName = p.dirS(p.del(end)+1:end);
    end%classify folder into EP or TL
    function define_nChannel(~,~)
        while isempty(p.nChannel)
            % Define the prompts
            prompt = {'Enter number channels:', 'Enter prefix of channel number in name:'};
            
            % Define the title of the dialog box
            dlgtitle = 'channel info';
            
            % Define the number of lines the user can input for each answer
            dims = [1 35];
            
            % Define default input values (you can adjust these as needed)
            definput = {'1', 'Ch'};
            
            % Display the input dialog box
            answer = inputdlg(prompt, dlgtitle, dims, definput);
            
            % Process the answers
            if ~isempty(answer) % Check if the user clicked OK and not Cancel
                p.nChannel = str2double(answer{1}); % Convert the first input to an integer
                p.channelPrefix = answer{2}; % The second input is already a string
            else
                waitfor(errordlg('Please insert a channel number'));
            end
        end
    end
    function SaveAsButton_callback(~, ~)
        UserDir=uigetdir(p.dir,'please select the directory to save the analysis');
        if isempty(UserDir) || UserDir==0; return; end
        saveall(UserDir);
    end

% refresh and save .mat files
    function refresh(z)
        if isempty(p.l); return; end %the list doesn't exist
        resetzoom = 0;
        if p.iold~=p.i %changing frame
            if isempty(Fvar.rgb)
                resetzoom = 1;
                ho=0; wo=0;
            elseif strcmp(p.operatingMode, 'single')
                resetzoom = 1;
                ho=0; wo=0;
                Fvar.im = [];
            else
                [ho, wo, ~] = size(Fvar.rgb);
            end
            Fvar.rgb = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
            [h, w, ~] = size(Fvar.rgb);
            if h~=ho || w~=wo
                resetzoom = 1;
            end
            p.col2grayrun=0;
            if Fvar.imgenhanced
                if ~isempty(Fvar.background) %the image enhacement is "on"
                    if strcmp(p.imgFormat, 'rgb') %transform into gray scale
                        Fvar.rgb=customcol2gray(Fvar.rgb);
                        p.showGrayscale=0;
                    end
                    Fvar.rgb = mat2gray(Fvar.rgb - Fvar.background, Fvar.mat2grayRefWhole); %image enhancement
                    if Fvar.imgenhanced2
                        Fvar.rgb=imadjust(Fvar.rgb);
                    end
                else
                    Fvar.imgenhanced =0;
                end
            elseif Fvar.imgenhanced2
                if strcmp(p.imgFormat, 'rgb') %transform into gray scale
                    Fvar.rgb=customcol2gray(Fvar.rgb);
                    p.showGrayscale=1;
                end
                Fvar.rgb=imadjust(Fvar.rgb);
            end
            
            if strcmp(p.operatingMode, 'single')
                Fvar.background=[];
                Fvar.imgenhanced=0; %not keeping the contrast if images are not from timelapse
            end
        end
        if isempty(p.imgFormat)
            if ~ismatrix(Fvar.rgb)
                p.imgFormat='rgb';
                p.radUseEnhancedImg=0;
            elseif ismatrix(Fvar.rgb)
                p.radUseEnhancedImg=0;
                p.imgFormat='grey';
                p.showNrCol='g';
                p.showGrayscale=1;
            end
        end
        xlim=[];ylim=[]; %note that this must come before calling axes 5 lines below.
        
        %         remembering zoom (if z=1, zoom is kept)
        if ~isempty(Fvar.im) && z==1
            ylim = hs.fig.YLim;
            xlim = hs.fig.XLim;
        end
        % delete(hs.fig); %otherwise staking up images, and memory leak
        % hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
        % if isprop(hs.fig, 'Toolbar')
        %     hs.fig.Toolbar.Visible = 'off';
        % end
        
        axes(hs.fig)
        % update image
        showimage;
        hold on
        
        if resetzoom
            imgzoompan(hs.f, 'ImgWidth', w, 'ImgHeight', h, 'Magnify', 2, 'PanMouseButton', 2, 'ResetMouseButton', 0);
        end
        
        %is that really needed?
        % make sure the centers and radii variables are up to date (e.g. for start up)
        if ~isempty(p.colonyCenRad)
            p.centers=p.colonyCenRad{p.i,1};
            p.radii=p.colonyCenRad{p.i,2}; %splitting in two variables
        end
        
        
        %check if we need to overlay the image
        if strcmp(p.operatingMode, 'single')
            if p.overlayIMGstatus==1
                OverlayLoad;
                if p.overlayIMGstatus==1
                    Fvar.imOverlay=imshow((Fvar.rgbOverlay),'InitialMagnification', 40);
                    set(Fvar.imOverlay,'AlphaData',0.5);
                    ax = gca();
                    ax.Toolbar.Visible = 'off';
                end
            else
                if isfield(Fvar, 'imOverlay') && isvalid(Fvar.imOverlay)
                    delete(Fvar.imOverlay);
                end
            end
        end
        
        if ~Fvar.imTBmiss==1
            %Analysis area drawing
            if p.showROI
                drawAA;
            end
            
            %draw the colony circle. blue if in analysis, red if removed
            % green if added after TLrun
            if p.ShowCol & ~isempty(p.colonyCenRad)
                drawColCircle;
            end
            
            %showNr of colonies
            if p.showNr
                drawColNumber;
            end
            if p.ShowVoronoiAreas
                drawVoronoiAreas;
            end
            if p.ShowVoronoiEdges
                drawVoronoiEdges;
            end
            
            hold off
        end
        
        if (p.iold~=p.i || p.iold==-1000) && resetzoom  %changing the original picture, keep initial zoom at max
            orig.h = hs.fig;
            orig.XLim = hs.fig.XLim;
            orig.YLim = hs.fig.YLim;
        end
        %resetting the previous zoom
        if strcmp(p.operatingMode, 'TL')
            if ~isempty(xlim) && z==1  %if image are independant, no zoom is kept
                hs.fig.XLim=xlim;
                hs.fig.YLim=ylim;
            end
        else
            if ~isempty(xlim) && z==1 && (p.i==p.iold || p.iold==-1000) %if image are independant, no zoom is kept
                hs.fig.XLim=xlim;
                hs.fig.YLim=ylim;
            end
        end
        p.iold=p.i;
        
        %updating user messages
        hs.UserMessFrame.String=['frame ',num2str(p.i), ' of ', num2str(length(p.l))];
        if length(p.l)>1 && (p.i>=1 && p.i<=length(p.l))
            set(hs.SetFrameSlider, 'Value', p.i);
            set(hs.setframeinput, 'String', num2str(p.i));
        end
        try %displaying the colonies per frame if in single mode or for each frame the same number if in TL mode
            if strcmp(p.operatingMode, 'single') && ~isempty(p.colonyCenRad{p.i})
                hs.UserMessNumCol.String= [num2str(length(p.colonyCenRad{p.i,2})) ' colonies on image'];
            elseif strcmp(p.operatingMode, 'single') && isempty(p.colonyCenRad{p.i})
                hs.UserMessNumCol.String= '';
            elseif strcmp(p.operatingMode, 'TL') && ~isempty(p.colonyCenRad{p.i})
                hs.UserMessNumCol.String= [num2str(length(p.colonyCenRad{p.i,2})) ' colonies on timelapse'];
            elseif strcmp(p.operatingMode, 'TL') && ~isempty(p.colonyCenRad{p.focalframe})
                hs.UserMessNumCol.String= [num2str(length(p.colonyCenRad{p.focalframe,2})) ' colonies on timelapse'];
            elseif strcmp(p.operatingMode, 'TL') && isempty(p.colonyCenRad{p.focalframe})
                hs.UserMessNumCol.String= '';
            end
        catch %do nothing
        end
        
        
        
        [h, w, ~] = size(Fvar.rgb);
        imgzoompan(hs.f, 'ImgWidth', w, 'ImgHeight', h, 'Magnify', 2, 'PanMouseButton', 2, 'ResetMouseButton', 0);
        
        % refresh the lists names
        for lname=1:(length(p.UserLists.listOptions)-2)
            if sum(readList(lname,p.i))==0
                if ~isempty(strfind(p.UserLists.listOptions{lname},' (E)'))
                    p.UserLists.listOptions{lname}=[p.UserLists.listOptions{lname},' (E)'];
                end
            else %the list is not empty
                if ~isempty(strfind(p.UserLists.listOptions{lname},' (E)'))
                    p.UserLists.listOptions{lname}=p.UserLists.listOptions{lname}(1:(p.UserLists.listOptions{lname}-1));
                end
            end
        end
        set(hs.ListSelect, 'String',p.UserLists.listOptions);
        if isfield(hs,'ListSelect2')
            if isvalid(hs.ListSelect2) %this is in the options menu, it should not enter
                set(hs.ListSelect2, 'String',p.UserLists.listOptions);
            end
        end
        set(hs.f, 'MenuBar', 'none', 'NumberTitle', 'off','HandleVisibility','on', ...
            'Name', 'ColTapp beta', 'ToolBar', 'none');
        figure(hs.f) %setting main gui to gcf
        customdrawnow
        
    end %refresh what is shown to user
    function saveall(dirS)
        % save whole file
        if isfield(p, 'rgb')
            p=rmfield(p, 'rgb');
        end
        if isfield(p, 'background')
            p=rmfield(p, 'background');
        end
        if isfield(p, 'imgray')
            p=rmfield(p, 'imgray');
        end
        if isfield(p, 'im')
            p=rmfield(p, 'im');
        end
        if isfield(p, 'rgbOverlay')
            p=rmfield(p, 'rgbOverlay');
        end
        if isfield(p, 'imOverlay')
            p=rmfield(p, 'imOverlay');
        end
        if verLessThan('Matlab','9.2')
            save([dirS filesep dirS(p.del(end)+1:end) '_all.mat'], 'p', saveV)
            if p.savebackups
                save([dirS filesep dirS(p.del(end)+1:end) date '_all.mat'], 'p', saveV')
            end
            
            if p.KymoChanged
                save([dirS filesep dirS(p.del(end)+1:end) '_Kymograph.mat'], 'Kymo', saveV);
                
                if p.savebackups
                    save([dirS filesep dirS(p.del(end)+1:end) date '_Kymograph.mat'], 'Kymo', saveV)
                end
            end
        else
            save([dirS filesep dirS(p.del(end)+1:end) '_all.mat'], 'p', saveV, '-nocompression')
            if p.savebackups
                save([dirS filesep dirS(p.del(end)+1:end) date '_all.mat'], 'p', saveV, '-nocompression')
            end
            
            if p.KymoChanged
                save([dirS filesep dirS(p.del(end)+1:end) '_Kymograph.mat'], 'Kymo', saveV, '-nocompression');
                
                if p.savebackups
                    save([dirS filesep dirS(p.del(end)+1:end) date '_Kymograph.mat'], 'Kymo', saveV, '-nocompression')
                end
            end
        end
    end %save struct p containing all main data
    function voronoisave(dirS)
        p.voronoichanged=1;
        if ~isempty(p.VoronoiAreas)
            if strcmp(p.operatingMode, 'single')
                if~isempty(p.VoronoiAreas{p.i,1})
                    if ~(size(p.colonyCenRad{p.i,2},1)==size(p.VoronoiAreas{p.i,1},1))
                        p.VoronoiAreas{p.i,1}=[];
                        VorEdg.VoronoiEdges{p.i,1}=[];
                        
                        p.ShowVoronoiAreas=0;
                        p.ShowVoronoiEdges=0;
                        try
                            delete(Fvar.voroThandle)
                        catch
                        end
                        try
                            delete(Fvar.voroAhandle)
                        catch
                        end
                    end
                else
                    p.voronoichanged=0;
                end
            else
                if ~(size(p.colonyCenRad{p.focalframe,2},1)==size(p.VoronoiAreas{p.focalframe,1},1))
                    p.VoronoiAreas=[];
                    VorEdg.VoronoiEdges=[];
                    
                    p.ShowVoronoiAreas=0;
                    p.ShowVoronoiEdges=0;
                    try
                        delete(Fvar.voroThandle)
                    catch
                    end
                    try
                        delete(Fvar.voroAhandle)
                    catch
                    end
                end
            end
        else
            p.voronoichanged=0;
        end
        if verLessThan('Matlab','9.2')
            if p.voronoichanged
                save([dirS filesep dirS(p.del(end)+1:end) '_VoronoiEdges.mat'], 'VorEdg', saveV);
                if p.savebackups
                    save([dirS filesep dirS(p.del(end)+1:end) date '_VoronoiEdges.mat'], 'VorEdg', saveV)
                end
            end
        else
            if p.voronoichanged
                save([dirS filesep dirS(p.del(end)+1:end) '_VoronoiEdges.mat'], 'VorEdg', saveV, '-nocompression');
                if p.savebackups
                    save([dirS filesep dirS(p.del(end)+1:end) date '_VoronoiEdges.mat'], 'VorEdg', saveV, '-nocompression')
                end
            end
        end
    end %save struct VorEdg containing voronoi edges
    function OverlayLoad(~,~)
        p.iOverlay=p.i;
        if isempty(p.dirOverlay) %first time for the tick
            p.dirOverlay=uigetdir(p.dir,'please select the directory with the files to overlay');
            if isempty(p.dirOverlay) | p.dirOverlay==0 %#ok<OR2>
                p.dirOverlay=[];
                p.overlayIMGstatus=0;
                hs.overlay.Value=p.overlayIMGstatus;%reset the overlay toggle
                return;
            end
            
            indx1=strfind(p.l(1).name, '.');
            flx=p.l(1).name(indx1(end)+1:end);
            p.lOverlay=dir([p.dirOverlay, filesep, '*',flx]); %lists all files with filextension
            if isempty(p.lOverlay)
                waitfor(errordlg('There are no images to overlay in this folder!'));
                p.lOverlay=[];p.dirOverlay=[];
                p.overlayIMGstatus=0;
            else
                p.multiEPdirs=sort(unique([p.multiEPdirs;{p.dirOverlay}; {p.dirS}]));
                Fvar.rgbOverlay = imread([p.dirOverlay, filesep,p.lOverlay(p.i).name]); %loading pic
                setoverlayfolders
            end
        elseif p.iold~=p.i || p.iOverlayold~=p.iOverlay
            if isempty(p.lOverlay)
                p.multiEPdirs=p.multiEPdirs(~strcmp(p.multiEPdirs, p.dirOverlay));
                p.lOverlay=[];p.dirOverlay=[];
                p.overlayIMGstatus=0;
                hs.UserMess.String='No images in folder or folder missing';customdrawnow
                setoverlayfolders;
                hs.overlay.Value=p.overlayIMGstatus;%reset the overlay toggle
                return
            end
            if exist([p.dirOverlay, filesep,p.lOverlay(p.i).name], 'file')
                Fvar.rgbOverlay = imread([p.dirOverlay, filesep,p.lOverlay(p.i).name]); %loading pic
            else
                p.multiEPdirs=p.multiEPdirs(~strcmp(p.multiEPdirs, p.dirOverlay));
                p.lOverlay=[];p.dirOverlay=[];
                p.overlayIMGstatus=0;
                hs.UserMess.String='No images in folder or folder missing';customdrawnow
                setoverlayfolders;
                hs.overlay.Value=p.overlayIMGstatus;%reset the overlay toggle
                return
            end
            if ~isfield(p, 'mytform')
                p.mytform=affine2d;
            end
            if length(p.mytform)>=p.i %&& ~p.OLwarped
                Rfixed = imref2d(size(Fvar.rgb));
                Fvar.rgbOverlay = imwarp(Fvar.rgbOverlay,p.mytform(p.i),'FillValues', 255,'OutputView',Rfixed);
                p.OLwarped=1;
            end
            if ~p.disableSave
                saveall(p.dirS);
            end
        end
        
        
        p.iOverlayold=p.iOverlay;
        
    end %load folder to overlay
    function disableGUI(Off)
        if Off
            hs.InterfaceObj1=findobj(hs.DetectTabBox,'Enable','on');
            hs.InterfaceObj2=findobj(hs.ResultsTabBox,'Enable','on');
            hs.InterfaceObj3=findobj(hs.TimelapseTabBox,'Enable','on');
            hs.InterfaceObj4=findobj(hs.LoadSave,'Enable','on');
            hs.InterfaceObj5=findobj(hs.NavigatePics,'Enable','on');
            hs.InterfaceObj6=findobj(hs.FigPanBig,'Enable','on');
            hs.InterfaceObj7=findobj(hs.SITabBox,'Enable','on');
            
            try; set(hs.InterfaceObj1,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj2,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj3,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj4,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj5,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj6,'Enable','inactive'); catch; end
            try; set(hs.InterfaceObj7,'Enable','inactive'); catch; end
        else
            %             hs.InterfaceObj1=findobj(hs.DetectTabBox,'Enable','inactive');
            %             hs.InterfaceObj2=findobj(hs.ResultsTabBox,'Enable','inactive');
            %             hs.InterfaceObj3=findobj(hs.TimelapseTabBox,'Enable','inactive');
            %             hs.InterfaceObj4=findobj(hs.LoadSave,'Enable','inactive');
            %             hs.InterfaceObj5=findobj(hs.NavigatePics,'Enable','inactive');
            %             hs.InterfaceObj6=findobj(hs.FigPanBig,'Enable','inactive');
            
            try; set(hs.InterfaceObj1,'Enable','on'); catch; end
            try; set(hs.InterfaceObj2,'Enable','on'); catch; end
            try; set(hs.InterfaceObj3,'Enable','on'); catch; end
            try; set(hs.InterfaceObj4,'Enable','on'); catch; end
            try; set(hs.InterfaceObj5,'Enable','on'); catch; end
            try; set(hs.InterfaceObj6,'Enable','on'); catch; end
            try; set(hs.InterfaceObj7,'Enable','on'); catch; end
            
            if p.i==1
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            elseif p.i==length(p.l)
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            else
                set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
                set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            end
        end
    end %disable gui

%% navigate, view and manipulate image
    function next_Callback(~,~)
        % moving to next frame
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        Fvar.showImage=1;
        if p.i<length(p.l)
            set_frame(p.i+1);
        end
    end % next frame
    function previous_Callback(~,~)
        % moving to next frame
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        Fvar.showImage=1;
        if p.i>1
            set_frame(p.i-1);
        end
    end % previos frame
    function set_frame_slider(~,~)
        set(hs.setframeinput, 'String', num2str(round(hs.SetFrameSlider.Value)));
        set_frame(round(hs.SetFrameSlider.Value));
    end %set frame by slider
    function set_frame_callback(SF,eventdata)
        %         eventdata.Key
        pause(1/10000);
        switch eventdata.Key
            case 'return'
                i = get(SF,'string');
                i=str2double(i);
                if isempty(i); return; end %user cancelled
            otherwise
                return
        end
        
        if sum(size(p.l))==0; hs.UserMess.String='No images loaded';customdrawnow; return; end %the list doesn't exist
        Fvar.showImage=1;
        %         i=str2double(get(hs.setframeinput, 'String')); %get the string in the field
        
        
        
        if sum(i>0) && sum(i<length(p.l)+1) && sum(p.i~=i) && length(i)==1 %checking it is inside range
            set_frame(i);
            hs.UserMess.String='';customdrawnow
        elseif sum(p.i==i)
            hs.UserMess.String='';customdrawnow
            return
        else
            hs.UserMess.String='Input number out of range or not a number';customdrawnow
        end
    end %set frame by textbox
    function set_frame(i)
        p.i=i; % change frame
        if ~strcmp(p.operatingMode, 'TL') && p.i~=p.iold
            Fvar.background=[];
        end
        if p.i==1
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif p.i==length(p.l)
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif strcmp(hs.LeftButton.Enable,'inactive')
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif strcmp(hs.RightButton.Enable,'inactive')
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        end
        sv=p.disableSave;
        if ~sv
            p.disableSave=1;
        end
        pause(1/10000);
        refresh(1);
        if ~sv
            p.disableSave=0;
        end
        pause(1/10000);
        figure(hs.f) %setting main gui to gcf
        
    end %really set the frame
    function rgbcolG=customcol2gray(rgbcol)
        %         rgbcol=Fvar.rgb;
        ImgMethod=p.imgMethod;
        if strcmp(p.imgFormat, 'rgb')
            if ImgMethod==1
                rgbcolG=mat2gray(rgbcol(:,:,1));
            elseif ImgMethod==2
                rgbcolG=mat2gray(rgbcol(:,:,2));
            elseif ImgMethod==3
                rgbcolG=mat2gray(rgbcol(:,:,3));
                
            elseif ImgMethod==4
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(rgbcolG(:,:,1));
            elseif ImgMethod==5
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)));
            elseif ImgMethod==6
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)));
                
            elseif ImgMethod==7
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1));
            elseif ImgMethod==8
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)));
            elseif ImgMethod==9
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)));
                
            elseif ImgMethod==10
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1));
            elseif ImgMethod==11
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,2));
            elseif ImgMethod==12
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,3));
                
            elseif ImgMethod==13
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1));
            elseif ImgMethod==14
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)));
            elseif ImgMethod==15
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)));
            elseif ImgMethod==0
                rgbcolG=rgbcol;
            elseif ImgMethod==16
                rgbcolG=rgb2gray(rgbcol);
            else
                rgbcolG=mat2gray(rgbcol(:,:,2));
            end
        else
            rgbcolG=(rgbcol);
        end
        %         Fvar.imgray=rgbcolG;
        clear rgbcol;
        p.col2grayrun=1;
    end %function to create grayscale image from rgb image
    function showimage(~,~)
        if Fvar.showImage && ~isempty(Fvar.rgb)
            if p.showGrayscale && strcmp(p.imgFormat, 'rgb') && ~Fvar.imgenhanced && ~Fvar.imgenhanced2
                if ~p.col2grayrun
                    Fvar.imgray=customcol2gray(Fvar.rgb);
                end
                if isempty(Fvar.im)
                    Fvar.im=imshow(Fvar.imgray,'InitialMagnification', 40);
                else
                    set(Fvar.im, 'CData', Fvar.imgray);
                end
            else%or normal
                if isempty(Fvar.im)
                    Fvar.im=imshow(Fvar.rgb,'InitialMagnification', 40);
                else
                    try
                        set(Fvar.im, 'CData', Fvar.rgb);
                    catch
                        Fvar.im=imshow(Fvar.rgb,'InitialMagnification', 40);
                    end
                end
                
                
            end
            % ax = gca;
            % ax.Toolbar.Visible = 'off';
        end
    end%fnc called by refresh for the loading and display of image.

%% draw data on image
    function drawAA(~,~)
        try
            delete(Fvar.roihandle)
        catch
        end
        
        if ~isempty(p.roiType(p.i))%check if something was specified
            hold on
            if p.roiType(p.i)==1%if it is a circle
                try
                    if ~isempty(p.roiPlateRad(p.i)) && ~isnan(p.roiPlateRad(p.i))
                        Fvar.roihandle=viscircles(p.roiPlateCenter(p.i,:),p.roiPlateRad(p.i), 'Color','b');
                    end
                catch
                    p.roiType(p.i)=0;
                end
            elseif p.roiType(p.i)==2 %or a polygon
                if size(p.roiPolygonImg,1)>=p.i
                    if ~isempty(p.roiPolygonImg{p.i})
                        pgon=p.roiPolygonImg{p.i};
                        pg=[pgon;pgon(1,:)];%add the first value in queue so that the polygon closes
                        Fvar.roihandle=plot(pg(:,1),pg(:,2), 'Color','b','LineWidth',1.5);
                    end
                end
            end
            hold off;
        end
        
    end%draw area ofanalysis on image
    function drawColCircle(~,~)
        try
            delete(Fvar.circlehandleR);
        catch
        end
        try
            delete(Fvar.circlehandleG);
        catch
        end
        try
            delete(Fvar.circlehandleB);
        catch
        end
        
        hold on
        if strcmp(p.operatingMode, 'single') && ~isempty(p.colonyCenRad{p.i,1}) %colonies exist and in "single" mode
            Fvar.circlehandleB=viscircles(p.colonyCenRad{p.i,1},p.colonyCenRad{p.i,2}*p.showCircleScale,'Color','b'); %plot the colony circle
            Fvar.circlehandleR=scatter(p.colonyCenRad{p.i,1}(p.colonyCenRad{p.i,2}==0,1),p.colonyCenRad{p.i,1}(p.colonyCenRad{p.i,2}==0,2), 100, '*b');%mark the 0-rad colony with a star
            % adding the colonies off the user list in different color
            if p.showList==1; listdraw; end %show list is activated
            
            %more complicated for TL:
            %display the colony in blue for each frame from the timelapse
            %file if a value is there.
            %If the colony was removed from the following analysis, there
            %will be a nan, so we look in the UNMOD file and draw a red circle. If it is also a
            %nan there, this means the timelapse function was not able to
            %find a radius there, no circle possible to draw.
            % if a colony was added after the TL was done, this will be
            % displayed in green, only on the focalframe
        elseif strcmp(p.operatingMode, 'TL')
            if ~p.progress.TLrun %no timelapse yet, look for the counts file
                if~isempty(p.colonyCenRad{p.i,1}) %no timelapse run: all included
                    Fvar.circlehandleB=viscircles(p.colonyCenRad{p.i,1},p.colonyCenRad{p.i,2}*p.showCircleScale,'Color','b'); %
                    if p.showList==1; listdraw; end %show list is activated
                else
                    Fvar.circlehandleR=viscircles(p.colonyCenRad{p.focalframe,1},p.colonyCenRad{p.focalframe,2}*p.showCircleScale,'Color','r'); %
                    if p.showList==1; listdraw; end %show list is activated
                end
            else %if a TL was run, look in the RadMean file
                %all the non-nan radius in blue:
                areRemoved=sum(isnan(p.RadMean),2)==length(p.l);
                try
                    areNew=size(p.RadMean,1)+1:length(p.colonyCenRad{p.focalframe,2});
                catch
                    areNew=[];
                end
                if p.i==p.focalframe
                    % if ~isempty(p.colonyCenRad{p.i,1}(~areRemoved,:))
                    %     Fvar.circlehandleR=viscircles(p.colonyCenRad{p.i,1}(~areRemoved,:),p.colonyCenRad{p.i,2}(~areRemoved)*p.showCircleScale,'Color','g');
                    % end
                    Fvar.circlehandleB=viscircles(p.colonyCenRad{p.i,1}(~isnan(p.RadMean(1:length(p.colonyCenRad{p.i,2}),p.i)),:), p.RadMean(~isnan(p.RadMean(1:length(p.colonyCenRad{p.i,2}),p.i)),p.i)*p.showCircleScale,'Color','b');
                    try%
                        Fvar.circlehandleR=viscircles(p.colonyCenRad{p.i,1}(areRemoved,:), p.colonyCenRad{p.i,2}(areRemoved)*p.showCircleScale,'Color','r');
                    catch
                        %
                    end
                    if~isempty(areNew)
                        Fvar.circlehandleG=viscircles(p.colonyCenRad{p.i,1}(areNew,:),p.colonyCenRad{p.i,2}(areNew)*p.showCircleScale,'Color','g'); %
                    else
                        if p.showList==1; listdraw; end %show list is activated
                    end
                else
                    
                    Fvar.circlehandleB=viscircles(p.colonyCenRad{p.i,1}(~isnan(p.RadMean(1:length(p.colonyCenRad{p.focalframe,2}),p.i)),:),...
                        p.RadMean(~isnan(p.RadMean(1:length(p.colonyCenRad{p.i,2}),p.i)),p.i)*p.showCircleScale,'Color','b');
                    %now create red circles for the nan values if there is a
                    areZero=find((p.RadMean(:,p.i)==0));
                    
                    if length(areZero)>0
                        % Extract all X and Y coordinates for these centers
                        Xcoords = round(p.colonyCenRad{p.i,1}(areZero, 1));
                        Ycoords = round(p.colonyCenRad{p.i,1}(areZero, 2));
                        Fvar.circlehandleR=scatter(Xcoords, Ycoords, 100, '+', 'b');
                    end
                    
                    if p.showList==1; listdraw; end %show list is activated
                end
                
            end
            %             % also overlay the p.colonyCenRad values as "original vlaues"
            %             if ~isempty(p.colonyCenRad{p.i,1})
            %                     hold on;
            %                     viscircles(p.colonyCenRad{p.i,1},p.colonyCenRad{p.i,2}*p.showCircleScale,'Color','g'); %
            %                     hold off;
            %             end
        end
        hold off
        
    end%draw a circle for each colony
    function drawColNumber(~,~)
        %display number of colony. In single mode, colonies are numbered
        %per plate, if in TL mode, each frame has the same numbering
        %defined from the focalframe
        try
            delete(Fvar.numberhandle);
        catch
        end
        if strcmp(p.operatingMode, 'single')
            % collist is a vector of indices for which you want to place text labels
            collist = 1:size(p.colonyCenRad{p.i,1}, 1);
            
            % Extract the X and Y coordinates
            Xcoords = p.colonyCenRad{p.i,1}(collist, 1);
            Ycoords = p.colonyCenRad{p.i,1}(collist, 2);
        else
            collist=1:size(p.colonyCenRad{p.focalframe,1},1);
            
            % Extract the X and Y coordinates
            Xcoords = p.colonyCenRad{p.focalframe,1}(collist, 1);
            Ycoords = p.colonyCenRad{p.focalframe,1}(collist, 2);
        end
        
        % Create an array of labels
        labels = strtrim(cellstr(num2str(collist'))); % Convert indices to strings and ensure no leading/trailing spaces
        
        % Place the labels on the plot
        Fvar.numberhandle=text(Xcoords, Ycoords, labels, 'FontSize', 12, 'Color', p.showNrCol, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        
    end%draw the colony numbers
    function drawVoronoiAreas(~,~)
        try
            delete(Fvar.voroThandle)
        catch
        end
        if ~isempty(p.VoronoiAreas) && ~isempty(p.VoronoiAreas{p.i,1})
            collist = 1:size(p.colonyCenRad{p.i,1}, 1);
            Fvar.voroThandle = gobjects(size(collist)); % Preallocate for text object handles
            
            for ii = collist
                offsetX = 0; % Default offset values
                offsetY = 0;
                
                % Adjust offset if showing number is enabled
                if(p.showNr ~= 0)
                    offsetX = 120;
                    offsetY = -60;
                end
                
                % Construct the label string
                labelStr = [num2str(p.VoronoiAreas{p.i,1}(ii)), 'VA'];
                
                % Use conditional properties based on `p.showNr` status
                Fvar.voroThandle(ii) = text(p.colonyCenRad{p.i,1}(ii,1) + offsetX, p.colonyCenRad{p.i,1}(ii,2) + offsetY, labelStr, ...
                    'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                    'Color', p.showNrCol); % Using conditional color
            end
        end
        
    end %draw voronoi area values
    function drawVoronoiEdges(~,~)
        try
            delete(Fvar.voroAhandle)
        catch
        end
        if ~isempty(VorEdg.VoronoiEdges)
            test=cellfun('isempty',VorEdg.VoronoiEdges);
            if test(p.i)
            else
                hold on;
                % Preallocate the handle array with a size based on the number of Voronoi edges
                Fvar.voroAhandle = gobjects(size(VorEdg.VoronoiEdges(p.i,:), 2), 1);
                
                for id = 1:size(VorEdg.VoronoiEdges(p.i,:), 2)
                    if (~isempty(VorEdg.VoronoiEdges{p.i,id}))
                        % Assign the plot to an element of the voroAhandle array
                        Fvar.voroAhandle(id) = plot(VorEdg.VoronoiEdges{p.i,id}(:,1), VorEdg.VoronoiEdges{p.i,id}(:,2), '-b');
                    end
                end
                hold off
            end
        else
            return;
        end
    end %draw voronoi edges
    function listdraw()
        if ~isnan(activeList)
            a=find(readList(-activeList,p.i));
            if ~isempty(a)  % list is not empty
                try
                    delete(Fvar.circlehandleG);
                catch
                end
                Fvar.circlehandleG=viscircles(p.colonyCenRad{p.i,1}(a,:),p.colonyCenRad{p.i,2}(a,:)*p.showCircleScale,'Color',[0.75 0.1 0.8]); %plot the colony circle
            else
                hs.UserMess.String='The list is empty';
                %                 p.showList=0;
            end
        else
            p.showList=0;
            set (hs.ShowList, 'String', 'Show')
            hs.UserMess.String='No list selected';
        end
    end %highlight colonies in list
    function a=activeList()
        %returne a negative value to select list, or nan if no list is active
        if hs.ListSelect.Value~=1 % a list is selected, 'none' is not the activated list
            a=-(hs.ListSelect.Value-1);
        else
            a=nan;
        end
    end %get active list for listdraw

%% export data as .csv
    function Export2_callback(~,~)
        % this will open a popup to decide what to export
        % there are 2 possible export files
        % 1) metadata
        % 2) R(fr) and all others
        
        % open the export GUI
        disableGUI(1);
        Choices=ExportGUI(); %Choices contains a list of user Choices
        
        if isempty(Choices)
            hs.UserMess.String='No data exported';customdrawnow
            disableGUI(0);
            return
        end %no export wanted, or cancelled
        if isempty(fieldnames(Choices))
            hs.UserMess.String='No data exported';customdrawnow
            disableGUI(0);
            return
        end
        
        FileName=testRunningBatchfileName;
        % 1) Metadatafile:
        if Choices.TickValues(1) % => export metadata
            metatdataWrite(FileName)
        end
        
        % 2) other variables
        
        % precalculate variables
        [Frames,Colonies]=checkColAndFrExportLists(Choices);
        checkRadCutOff(Choices);
        if strcmp(p.ExportMode,'um')
            UM=p.umConversion;
        else
            UM=ones(size(p.umConversion));
        end
        
        % spatial metrics
        D=Choices.TickValues(strcmp(Choices.Ticklist,'D'));
        D2=Choices.TickValues(strcmp(Choices.Ticklist,'D2'));
        AD=Choices.TickValues(strcmp(Choices.Ticklist,'AD'));
        if D||D2||AD % at least one spatial metric is asked for
            hs.UserMess.String='Calculating distance metrics...';customdrawnow
            CalcSpatialMetricsD(Frames,Colonies,UM,D,D2,AD); %calculated and stored in p.D, etc
        end
        
        % create initial export matrix
        if strcmp(p.operatingMode,'TL')
            cols=repmat(Colonies',numel(Frames),1);
            frs=sort(repmat(Frames',numel(Colonies),1));
        else
            cols=[];frs=[];
            for Fri=Frames
                WhCol2=Colonies(Colonies<=length(p.colonyCenRad{Fri,2}));
                cols=[cols;WhCol2'];
                frs=[frs;ones(numel(WhCol2),1)*Fri];
            end
        end
        mtrxAll=table(cols,frs, 'VariableNames',{'Colonies','Frames'});
        
        % all color/shape are calculated together: this variable is set to 1 when the first color/shape export is done
        Fvar.groupExpC=0; Fvar.groupExpL=0;
        
        % append all exported needs
        for exportN=2:numel(Choices.TickValues) %over all ticks
            if Choices.TickValues(exportN) %the user wants at least 1 export
                mtrx=WhichTableExport(Choices.Ticklist{exportN},Choices,Frames,Colonies,UM); %make an export table
                mtrxAll=[mtrxAll,mtrx]; %append to previous
            end
        end
        
        if size(mtrxAll,2)>2 %only export if user asked for some export
            %sep=strfind(FileName,filesep);
            FO=checkFile(FileName(1:end-4),{'_dat.csv'});if FO;return; end
            writetable(mtrxAll, [FileName(1:end-4),'_dat.csv'], 'Delimiter',Fvar.csvdelimiterssymbol{p.csvdelimiter});
            % tell user
            hs.UserMess.String=['Data was exported in ' FileName(1:end-4),'_dat.csv files'];customdrawnow
        else
            hs.UserMess.String='No data exported';customdrawnow
        end
        disableGUI(0);
    end %called by export
    function FileName=testRunningBatchfileName
        if ~exist('b','var') || ~isstruct(b)
            b=struct();
            b.runningBatch=0;
        end
        if ~isfield(b, 'runningBatch')
            b.runningBatch=0;
        end
        
        if ~b.runningBatch
            FileName=ChooseExportDir();
        else
            FileName=b.xlsxName;
        end
    end %get folder name to save to
    function FileName=ChooseExportDir()
        tmpDir=p.dirS;
        %name the file and choose directory
        prompt = 'Define prefix and directory for the .csv files:';
        if strcmp(p.currentName, 'timelapse') || strcmp(p.currentName, ' single image set')
            p.currentName = p.dirS(p.del(end)+1:end);
        end
        defaultans = matlab.lang.makeUniqueStrings([p.currentName]);%create a sensible name
        defaultans = [tmpDir, filesep, defaultans];
        [FileName,dirUser] = uiputfile('*.csv',prompt,defaultans);
        if FileName==0; hs.UserMess.String='';customdrawnow; return; end %means the user closed the dialog
        FileName=[dirUser,FileName];
    end %called from above
    function Choices=ExportGUI()
        hEC.Choices=struct();
        % the user sets the following values in hEC:
        % WhichFr => which frames to export
        % WhichCol => which cols to export
        % Growth: Tapp, GR, RT
        SiT={'Tapp','GR','RT','Pos'};
        % Lists: L1, L2,... ,Ln
        SiL={};
        for Li=2:(numel(p.UserLists.listOptions)-1)
            SiL{end+1}=['L' num2str(Li)];
        end
        % Density: WhichR, V, D, D2, AD
        SiD={'V','D','D2','AD'};
        % Shape: RGBw, RGBc, GRAYw, GRAYc, TxtStd, TxtEnt, Pstd, Pl, Hrgb, Hgray, HPxlN, HRN
        SiS={'RGBw', 'RGBc', 'GRAYw', 'GRAYc', 'TxtStd', 'TxtEnt', 'Pstd', 'Pl', 'Hrgb', 'Hgray'};
        
        %disableGUI(1); %GUI is disabled while user chooses
        
        %main figure
        hEC.f=figure('Units','normalized','Position',[0.2 0.1 0.4 0.8], 'Name', 'Export',...
            'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off');
        hEC.main=uix.VBox('Parent', hEC.f, 'Padding',10);
        uicontrol('Parent', hEC.main,'Style', 'text','String','Export content','FontSize',15,'FontWeight','bold');
        uix.Empty('Parent', hEC.main);
        
        % some export options
        hEC.Obox=uix.HBox('Parent', hEC.main);
        hEC.Meta=uicontrol('Parent',hEC.Obox,'Style','checkbox','String','Export metadata');
        hEC.UMPX=uix.VBox('Parent',hEC.Obox);
        if ~isempty(p.umConversion)
            hEC.UM=uicontrol('Parent',hEC.UMPX,'Style','checkbox','String','micrometers','Callback',@setmicromExport,'Value',strcmp(p.ExportMode,'um'));
        end
        hEC.PX=uicontrol('Parent',hEC.UMPX,'Style','checkbox','String','pixels','Callback',@setmicromExport,'Value',strcmp(p.ExportMode,'px'));
        uix.Empty('Parent', hEC.Obox);
        hEC.CSVsep=uix.VBox('Parent',hEC.Obox);
        hEC.csvtext=uicontrol('Parent', hEC.CSVsep,'Style', 'text','String','CSV delimiter','FontSize',9, 'HorizontalAlignment', 'left');
        hEC.delimiterdrop= uicontrol('Parent',hEC.CSVsep,'Style', 'popup','String', Fvar.csvdelimiters,'FontSize',9, 'Value', p.csvdelimiter);
        
        %choosing frames and colony numbers
        hEC.info=uicontrol('Parent', hEC.main,'Style', 'text','String',{'';'(use X1,X2,...Xn   or  Start:Gap:End   or    -ListNumber   notations)'}, 'HorizontalAlignment', 'left');
        hEC.ColFr=uix.HBox('Parent',hEC.main);
        uicontrol('Parent', hEC.ColFr,'Style', 'text','String',{'';'Frames n°'}, 'HorizontalAlignment','right');
        hEC.WhichFr=uicontrol('Parent', hEC.ColFr,'Style','edit','String', '0');
        uicontrol('Parent', hEC.ColFr,'Style', 'text','String',{'';'Col n°'}, 'HorizontalAlignment','right');
        hEC.WhichCol=uicontrol('Parent', hEC.ColFr,'Style','edit','String', '0');
        uix.Empty('Parent', hEC.ColFr);uix.Empty('Parent', hEC.ColFr);
        uix.Empty('Parent', hEC.main);
        
        % growth paramters
        
        hEC.Tboxt=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Tboxt,'Style', 'text','String',{'Growth parameters'},'FontSize',12,'FontWeight','bold', 'HorizontalAlignment', 'left');
        uicontrol('Parent',hEC.Tboxt,'Style','checkbox','String','select all', 'Callback',{@setValues,SiT});
        uix.Empty('Parent', hEC.Tboxt);uix.Empty('Parent', hEC.Tboxt);
        hEC.Tbox=uix.HBox('Parent', hEC.main);
        hEC.Tapp=uicontrol('Parent',hEC.Tbox,'Style','checkbox','String','Appearance time');
        hEC.GR=uicontrol('Parent',hEC.Tbox,'Style','checkbox','String','Growth rate');
        if strcmp(p.operatingMode, 'TL') && isempty(p.RadMean) %will export different things depending on mode and if analysis was run
            hEC.RT=uicontrol('Parent',hEC.Tbox,'Style','checkbox','String','Radius (focalframe)');
        elseif strcmp(p.operatingMode, 'TL') && ~isempty(p.RadMean)
            hEC.TboxRT=uix.VBox('Parent',hEC.Tbox);
            hEC.RT=uicontrol('Parent',hEC.TboxRT,'Style','checkbox','String','R(fr)');
            %hEC.WideLong=uicontrol('Parent',hEC.TboxRT,'Style','checkbox','String','(use wide format)','TooltipString',mO.WideLong);
        else
            hEC.RT=uicontrol('Parent',hEC.Tbox,'Style','checkbox','String','Radius');
        end
        hEC.Pos=uicontrol('Parent',hEC.Tbox,'Style','checkbox','String','Position of colonies');
        uix.Empty('Parent', hEC.main);
        
        % User lists
        hEC.Lboxt=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Lboxt,'Style', 'text','String','User Lists','FontSize',12,'FontWeight','bold', 'HorizontalAlignment', 'left');
        uicontrol('Parent',hEC.Lboxt,'Style','checkbox','String','select all', 'Callback',{@setValues,SiL});
        uix.Empty('Parent', hEC.Lboxt);uix.Empty('Parent', hEC.Lboxt);
        
        maxperline=4;perline=1;lineL=1;
        hEC.(['Listnames' num2str(lineL)])=uix.HBoxFlex('Parent',hEC.main); %initialize first line
        for i=2:(numel(p.UserLists.listOptions)-1) %this will depend on list number
            if perline>maxperline
                lineL=lineL+1;
                hEC.(['Listnames' num2str(lineL)])=uix.HBoxFlex('Parent',hEC.main); %add lines
                perline=1;
            end
            hEC.(['L' num2str(i)])=uicontrol('Parent',hEC.(['Listnames' num2str(lineL)]),'Style','checkbox','String',p.UserLists.listOptions{i}(4:end));
            perline=perline+1; %one more per line
        end
        if mod(numel(p.UserLists.listOptions)-2,maxperline)~=0
            for i=1:maxperline-mod(numel(p.UserLists.listOptions)-2,maxperline)
                uix.Empty('Parent', hEC.(['Listnames' num2str(lineL)]));
            end
        end
        uix.Empty('Parent', hEC.main);
        
        % density metrics
        hEC.Dboxt=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Dboxt,'Style', 'text','String','Density metrics','FontSize',12,'FontWeight','bold', 'HorizontalAlignment', 'left');
        uicontrol('Parent',hEC.Dboxt,'Style','checkbox','String','select all', 'Callback',{@setValues,SiD});
        uix.Empty('Parent', hEC.Dboxt);uix.Empty('Parent', hEC.Dboxt);
        
        hEC.RCutOff=uix.HBox('Parent',hEC.main);
        uicontrol('Parent', hEC.RCutOff,'Style', 'text','String',{'';'with radius cut Off:'});
        hEC.WhichR=uicontrol('Parent', hEC.RCutOff,'Style','edit','String', 'Inf');
        hEC.info=uicontrol('Parent', hEC.RCutOff,'Style', 'text','String','(use X1,X2,...Xn  or  Start:Gap:End)');
        uix.Empty('Parent', hEC.RCutOff);
        hEC.Dbox=uix.HBox('Parent', hEC.main);
        hEC.V=uicontrol('Parent',hEC.Dbox,'Style','checkbox','String','Voronoi Area');
        hEC.D=uicontrol('Parent',hEC.Dbox,'Style','checkbox','String','∑(1/D)');
        hEC.D2=uicontrol('Parent',hEC.Dbox,'Style','checkbox','String','∑(1/D^2)');
        hEC.AD=uicontrol('Parent',hEC.Dbox,'Style','checkbox','String','∑(Angular diameter)');
        uix.Empty('Parent', hEC.main);
        
        % Shape metrics
        
        hEC.Sboxt=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sboxt,'Style', 'text','String','Shape and color','FontSize',12,'FontWeight','bold', 'HorizontalAlignment', 'left');
        uicontrol('Parent',hEC.Sboxt,'Style','checkbox','String','select all', 'Callback',{@setValues,SiS});
        uix.Empty('Parent', hEC.Sboxt);uix.Empty('Parent', hEC.Sboxt);
        
        hEC.Sbox1=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sbox1,'Style', 'text','String','RGB color','HorizontalAlignment','left');
        hEC.RGBw=uicontrol('Parent',hEC.Sbox1,'Style','checkbox','String','Whole colony');
        hEC.RGBc=uicontrol('Parent',hEC.Sbox1,'Style','checkbox','String','Center');
        uix.Empty('Parent', hEC.Sbox1);
        
        hEC.Sbox2=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sbox2,'Style', 'text','String','Grayscale value','HorizontalAlignment','left');
        hEC.GRAYw=uicontrol('Parent',hEC.Sbox2,'Style','checkbox','String','Whole colony');
        hEC.GRAYc=uicontrol('Parent',hEC.Sbox2,'Style','checkbox','String','Center');
        uix.Empty('Parent', hEC.Sbox2);
        
        hEC.Sbox3=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sbox3,'Style', 'text','String','Texture','HorizontalAlignment','left');
        hEC.TxtStd=uicontrol('Parent',hEC.Sbox3,'Style','checkbox','String','St. dev.');
        hEC.TxtEnt=uicontrol('Parent',hEC.Sbox3,'Style','checkbox','String','Entropy');
        uix.Empty('Parent', hEC.Sbox3);
        
        hEC.Sbox4=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sbox4,'Style', 'text','String','Perimeter','HorizontalAlignment','left');
        hEC.Pstd=uicontrol('Parent',hEC.Sbox4,'Style','checkbox','String','St. dev.');
        hEC.Pl=uicontrol('Parent',hEC.Sbox4,'Style','checkbox','String','length');
        uix.Empty('Parent', hEC.Sbox4);
        
        hEC.Sbox5=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.Sbox5,'Style', 'text','String','Halo','HorizontalAlignment','left');
        hEC.Hrgb=uicontrol('Parent',hEC.Sbox5,'Style','checkbox','String','RGB');
        hEC.Hgray=uicontrol('Parent',hEC.Sbox5,'Style','checkbox','String','GrayScale');
        uix.Empty('Parent', hEC.Sbox5);
        
        hEC.Sbox6=uix.HBox('Parent', hEC.main);
        hEC.VoidTop=uix.Empty('Parent', hEC.Sbox6);
        uicontrol('Parent', hEC.Sbox6,'Style', 'text','String','Halo until distance:');
        hEC.HPxlN=uicontrol('Parent', hEC.Sbox6,'Style', 'edit','String','10','Callback',@HPxlN_CB);
        function HPxlN_CB(~,~); hEC.HRN.String=''; end
        uicontrol('Parent', hEC.Sbox6,'Style', 'text','String',{'';'pxl'}, 'HorizontalAlignment','left');
        uicontrol('Parent', hEC.Sbox6,'Style', 'text','String','or');
        hEC.HRN=uicontrol('Parent', hEC.Sbox6,'Style', 'edit','String','','Callback',@HRN_CB);
        function HRN_CB(~,~); hEC.HPxlN.String=''; end
        uicontrol('Parent', hEC.Sbox6,'Style', 'text','String',{'';'* col R'}, 'HorizontalAlignment','left');
        uix.Empty('Parent', hEC.main);
        
        %save and quit
        hEC.SQ=uix.HBox('Parent', hEC.main);
        uicontrol('Parent', hEC.SQ, 'String', 'Save file', 'Callback', @SaveExport, 'FontSize',12);
        uicontrol('Parent', hEC.SQ, 'String', 'Cancel', 'Callback', @cancelExport, 'FontSize',12);
        
        function setValues(a,~,Si)
            for S=1:numel(Si)
                hEC.(Si{S}).Value=a.Value;
            end
        end
        function cancelExport(~,~)
            hEC.Choices=struct();
            close(hEC.f);
            axes(hs.fig);
            disableGUI(0);
            return
        end
        function SaveExport(~,~)
            hEC.Choices.Ticklist=[{'Meta'},SiT,SiL,SiD,SiS,]; %the list of tickboxes
            %             if strcmp(p.operatingMode,'TL') %export two more tickboxes
            %                 %hEC.Choices.TLcsts=hEC.TLcsts.Value;
            %                 %hEC.Choices.WideLong=hEC.WideLong.Value;
            %             end
            hEC.Choices.NumFields={'WhichFr','WhichCol','WhichR','HPxlN','HRN'};
            % get values of all tickboxes
            hEC.Choices.TickValues=nan(1,numel(hEC.Choices.Ticklist));
            for Si=1:numel(hEC.Choices.Ticklist)
                hEC.Choices.TickValues(Si)=hEC.(hEC.Choices.Ticklist{Si}).Value;
            end
            
            % get values of numeric fields in Numfields
            hEC.Choices.Nums={};
            for Ni=1:numel(hEC.Choices.NumFields)
                hEC.Choices.Nums{Ni}=hEC.(hEC.Choices.NumFields{Ni}).String;
            end
            
            if sum(hEC.Choices.TickValues)==0 %no tick was chosen
                hEC.Choices=[];
            end
            p.csvdelimiter=hEC.delimiterdrop.Value;
            close(hEC.f);
            axes(hs.fig);
        end
        while ishandle(hEC.f)
            pause(0.05)
            %             if hEC.RT.Value==1 && strcmp(p.operatingMode, 'TL')
            %                 if isempty(p.RadMean)
            %                     heC.RT.String={'Radius';'TL not processed: export localframe radii'};
            %                 end
            %             end
        end
        Choices=hEC.Choices;
    end %mini-GUI showing export options
    function checkRadCutOff(Choices)
        Ri=round(str2num(Choices.Nums{3}));  %#ok<ST2NM>
        p.WhichR=Ri(Ri>0);
    end %fetch distance cutoff
    function [Frames,Colonies]=checkColAndFrExportLists(Choices)
        %checking frames
        OKfr=checkFrList(round(str2num(Choices.Nums{1}))); %#ok<ST2NM> %this saves user list in p.frlist
        if OKfr
            Frames=p.frlist;
        else
            Frames=1:length(p.l);
        end
        
        [~,Colonies]=setpColList2(round(str2num(Choices.Nums{2})),Frames); %#ok<ST2NM> %this saves user list in p.Collist
        
    end %fetch list of things to export
    function FO=checkFile(FN,Suffix)
        lastwarn='';FO=0;
        for fi=1:numel(Suffix)
            if exist([FN, Suffix{fi}], 'file')==2
                delete([FN, Suffix{fi}]);
                if strcmp(lastwarn, 'File not found or permission denied')
                    waitfor(errordlg({'File to write'; [FN, Suffix{fi}] ;'is opened in another software.'; 'Please close it and retry'}));
                    hs.UserMess.String='Export failed';customdrawnow
                    FO=1;
                    return
                end
            end
        end
    end %check for permission to write to file
    function metatdataWrite(FileName)
        if strcmp(p.operatingMode, 'TL')
            if ~isempty(p.umConversion) %spatial calibration
                spatc=p.umConversion(1);
            else
                spatc='notSet';
            end
            if p.roiType==0 %aoi
                aoi='notSet';
                platerad='notSet';
                plateX='notSet';
                plateY='notSet';
            elseif p.roiType==1
                aoi='Plate';
                platerad=p.roiPlateRad(1);
                plateX=p.roiPlateCenter(1,1);
                plateY=p.roiPlateCenter(1,2);
            elseif p.roiType==2
                aoi='Polygon';
                platerad='notSet';
                plateX='notSet';
                plateY='notSet';
            end
            
            if strcmp(p.imgFormat, 'grey') %imagetype
                imgmode='Grayscale';
                imtr='NaN';
            else
                imgmode='RGB';
                imtr=p.imgMethod;
            end
            
            if strcmp(p.tappMode, 'um') %Tappcalc threshold
                Tappthr=p.tappThreshUm;
                Tappnm='TappThresh_um';
            else
                Tappthr=p.tappThreshPx;
                Tappnm='TappThresh_px';
            end
            
            a={'Folder', 'SpatialCalibFact', 'AOItype', 'Plate_X', 'Plate_Y', 'Plate_rad',...
                'ImageType', 'RGB2Gray_method', 'deltaTime_min', Tappnm, 'ExportTime'};
            mtrx = table({p.dirS}, {spatc}, {aoi}, {plateX}, {plateY}, {platerad},...
                {imgmode}, {imtr}, {p.deltaTmin}, {Tappthr}, {datetime('now')}, 'VariableNames', a);
            
            
        else %in SI
            
            npl=length(p.l);
            if ~isempty(p.umConversion) %spatial calibration
                spatc=p.umConversion;
            else
                spatc=cellstr(repmat('notSet', npl, 1));
            end
            aoi=cell(npl, 1);
            platerad=cell(npl, 1);
            plateX=cell(npl, 1);
            plateY=cell(npl, 1);
            for i=1:npl
                if p.roiType(i)==0 %aoi
                    aoi(i)=cellstr('notSet');
                    platerad(i)=cellstr('notSet');
                    plateX(i)=cellstr('notSet');
                    plateY(i)=cellstr('notSet');
                elseif p.roiType(i)==1
                    aoi(i)=cellstr('Plate');
                    platerad(i)={p.roiPlateRad(1)};
                    plateX(i)={p.roiPlateCenter(1,1)};
                    plateY(i)={p.roiPlateCenter(1,2)};
                elseif p.roiType(i)==2
                    aoi(i)=cellstr('Polygon');
                    platerad(i)=cellstr('notSet');
                    plateX(i)=cellstr('notSet');
                    plateY(i)=cellstr('notSet');
                end
            end
            
            if strcmp(p.imgFormat, 'grey') %imagetype
                imgmode=cellstr(repmat('Grayscale', npl, 1));
                imtr=cellstr(repmat('NaN', npl, 1));
            else
                imgmode=cellstr(repmat('RGB', npl, 1));
                imtr=repmat(p.imgMethod, npl, 1);
            end
            
            a={'ImageNr', 'Folder', 'SpatialCalibFact', 'AOItype', 'Plate_X', 'Plate_Y', 'Plate_rad',...
                'ImageType', 'RGB2Gray_method',  'ExportTime'};
            mtrx = table(transpose(1:npl), cellstr(repmat(p.dirS, npl,1)), spatc, aoi, plateX, plateY, platerad,...
                imgmode, imtr, cellstr(repmat(datetime('now'), npl,1)), 'VariableNames', a);
            
        end
        
        FO=checkFile(FileName(1:end-4),{'_Metadata.csv'});if FO;return; end
        writetable(mtrx, [FileName(1:end-4), '_Metadata.csv'], 'Delimiter',...
            Fvar.csvdelimiterssymbol{p.csvdelimiter});
        
    end %write metadata
    function mtrx=WhichTableExport(VarN,Choices, WhFr,WhCol,UM)
        mtrx=[];
        % this function exports Var(t) or Var(fr) to a Var file.
        % it exports p.colonyCenRad => colonies found and corrected and...
        % ... for timelapse, it also exports RadMean
        % the function acts as a sorting function, because all variables
        % are stored differently.
        % most variables have different formats. All are prepared in long format
        if strcmp(VarN,'RT')
            mtrx=makeTableExportRT(WhFr,WhCol,UM);
        elseif strcmp(VarN,'Tapp')
            mtrx=makeTableExportTA(WhFr,WhCol);
        elseif strcmp(VarN,'GR')
            mtrx=makeTableExportGR(WhFr,WhCol);
        elseif strcmp(VarN(1),'L') && ~Fvar.groupExpL%this is a list
            mtrx=makeTableExportL(WhFr,WhCol,Choices);
            Fvar.groupExpL=1;
        elseif strcmp(VarN,'V')
            mtrx=makeTableExportV(WhCol,WhFr,UM);
        elseif strcmp(VarN, 'D') || strcmp(VarN, 'D2') || strcmp(VarN, 'AD')
            %create table titles that correspond to cutoff radii
            ttl=[];
            for Ri=1:numel(p.WhichR)
                ttl=[ttl,{[VarN,'Rcut_',num2str(p.WhichR(Ri))]}];
            end
            %export table
            mtrx=array2table(p.(VarN)(:,3:end),'VariableNames',ttl);
        elseif strcmp(VarN,'Pos')
            mtrx=makeTableExportPos(WhFr,WhCol,UM);
        elseif Fvar.groupExpC==0 %this is a shape or color metric (all same data format)
            % this can be lengthy, tell user
            hs.UserMess.String='Calculating shape/color metrics...';customdrawnow
            ExportColorsData(WhFr,WhCol,Choices); %this function requires to extract images, and thus calculates all the needed color metrics as one
            mtrx=array2table(p.coloniesColors.Tbl(:,3:end),'VariableNames',p.coloniesColors.Titles(3:end));
            Fvar.groupExpC=1; %the data on shape and color is exported together, so no need to run the function several times
        end
    end %write main variables
    function mtrx=makeTableExportV(WhCol,WhFr,UM)
        %this function prepares a Voronoi export matrix
        
        % preparing an export conversion rate;
        umConv=UM.^2;
        
        if ~isempty(p.VoronoiAreas)
            if strcmp(p.operatingMode, 'TL')
                mtrx=table(repmat(p.VoronoiAreas{1}(WhCol)*umConv(1),numel(WhFr),1),'VariableNames',{'VA'});
            else %EP mode
                rN=[];
                for Fri=WhFr
                    if ~isempty(p.VoronoiAreas{Fri})
                        WhCol2=WhCol(WhCol<=length(p.VoronoiAreas{Fri})); %only export colonies within range
                        if numel(WhCol2)>0
                            rN=[rN;p.VoronoiAreas{Fri}(WhCol2)*umConv(Fri)];
                        end
                    end
                end
                mtrx=table(rN,'VariableNames',{'Voronoi'});
            end
        else %the variable was not calculated
            mtrx=exportMSg(WhFr,WhCol,'Voronoi area','Voronoi');
        end
    end %export voronoi
    function mtrx=makeTableExportL(WhFr,WhCol,Choices)
        % creates a matrix for lists export
        FirstL=[];
        for nm=1:numel(Choices.Ticklist)
            FirstL=[FirstL,Choices.Ticklist{nm}(1)];
        end
        whichList=Choices.TickValues(FirstL=='L');
        
        %Making variable names
        titlesL={};
        for Li=1:sum(FirstL=='L')
            if whichList(Li)
                Ln=p.UserLists.listOptions{Li+1}(4:end);
                Ln(Ln==' ')='_';
                titlesL=[titlesL,Ln];
            end
        end
        
        %initialize
        ListList=[];
        
        WhCol2=WhCol;
        % put all lists in the same matrix
        for fr=WhFr
            WhCol=WhCol2(WhCol2<=length(p.colonyCenRad{fr,2}));
            if numel(WhCol)>0
                colm=0; %initialize column number
                for Li=1:sum(FirstL=='L') %over all lists
                    if whichList(Li) %if the list is selected
                        colm=colm+1;
                        if colm==1
                            whi=size(ListList,1)+(1:numel(WhCol));
                        else
                            whi=size(ListList,1)-numel(WhCol)+1:size(ListList,1);
                        end
                        if strcmp(p.operatingMode, 'TL')
                            ListList(whi,colm)=p.UserLists.l.(['List',num2str(Li)]).fr0(WhCol);
                        else
                            ListList(whi,colm)=p.UserLists.l.(['List',num2str(Li)]).(['fr',num2str(fr)])(WhCol);
                        end
                    end
                end
            end
        end
        mtrx=array2table(ListList,'VariableNames',titlesL);
    end %export lists
    function mtrx=makeTableExportPos(WhFr,WhCol,UM)
        ListList=[];
        for fr=WhFr
            WhCol2=WhCol(WhCol<=length(p.colonyCenRad{fr,2}));
            if numel(WhCol2) %at least one colony
                ListList(end+1:end+numel(WhCol2),1:2)=p.colonyCenRad{fr,1}(WhCol2,:)*UM(fr);
            end
        end
        mtrx=array2table(ListList,'VariableNames',{'X','Y'});
    end %export positions
    function mtrx=makeTableExportRT(WhFr,WhCol,UM)
        % exporting the radius depends on conditions:
        if strcmp(p.operatingMode, 'TL')
            if isempty(p.RadMean) || WhCol(end)>size(p.RadMean,1)%the time lapse analysis wasn't run, or not up to date
                mtrx=table(repmat(p.colonyCenRad{p.focalframe}(WhCol)*UM(p.focalframe),numel(WhFr),1),'VariableNames',{['Rad' p.ExportMode num2str(p.focalframe)]});
            else
                % Preallocate a struct or cell array to store each channel's data
                RT_all = cell(1, p.nChannel);       % Each cell will hold the vector for that channel
                colNames = cell(1, p.nChannel);     % Variable names for the table columns
                
                for chi = 1:p.nChannel
                    RT=[];
                    if chi == 1
                        for fri=WhFr
                            RT=[RT;p.RadMean(WhCol,fri).*UM(fri)];
                        end
                        RT_all{chi} = RT;
                        colNames{chi} = ['Radius' p.ExportMode];
                    else
                        fname = sprintf('RadMeanCh%d', chi); % Use chi for channel number
                        for fri=WhFr
                            RT=[RT;p.(fname)(WhCol,fri).*UM(fri)];
                        end
                        RT_all{chi} = RT;
                        colNames{chi} = [sprintf('RadiusCh%d', chi) p.ExportMode];
                    end
                end

                % Convert cell array to a table with dynamic variable names
                mtrx = table(RT_all{:}, 'VariableNames', colNames);
            end
        else %SI mode
            rN=[];
            
            for Fri=WhFr
                
                WhCol2=WhCol(WhCol<=length(p.colonyCenRad{Fri,2}));
                if isfield(p, 'counts1')
                    if numel(WhCol2)
                        tmp=[];
                        for mui=1:length(p.multiEPdirs)
                            tmp(:,mui)=p.(['counts',num2str(mui)]){Fri,2}(WhCol2)*p.(['umConversion',num2str(mui)])(Fri);
                        end
                        
                        rN=[rN;tmp];
                    end
                else
                    if numel(WhCol2)
                        rN=[rN;p.colonyCenRad{Fri,2}(WhCol2)*UM(Fri)];
                    end
                end
                
            end
            
            if isfield(p, 'counts1')
                radname={};
                for mui=1:length(p.multiEPdirs)
                    radname{mui}=['Radius_folder',num2str(mui),'_', p.ExportMode];
                end
                mtrx=array2table(rN,'VariableNames',radname);
            else
                radname={['Radius' p.ExportMode]};
                mtrx=table(rN,'VariableNames',radname);
            end
            
        end
    end %export radius
    function mtrx=makeTableExportTA(WhFr,WhCol)
        if (~isempty(p.Tapp) || ~isempty(p.estTapp)) && (WhCol(end)<=length(p.Tapp) || WhCol(end)<=length(p.estTapp))
            if strcmp(p.operatingMode,'TL')
                % Preallocate a struct or cell array to store each channel's data
                Tapp_all = cell(1, p.nChannel);       % Each cell will hold the vector for that channel
                colNames = cell(1, p.nChannel);     % Variable names for the table columns
                
                for chi = 1:p.nChannel
                    if chi == 1
                        Tapp_all{chi} = repmat(p.Tapp(WhCol),numel(WhFr),1);
                        colNames{chi} = 'Tapp';
                    else
                        fname = sprintf('TappCh%d', chi); % Use chi for channel number
                        Tapp_all{chi} = repmat(p.(fname)(WhCol), numel(WhFr), 1);
                        colNames{chi} = fname;
                    end
                end

                % Convert cell array to a table with dynamic variable names
                mtrx = table(Tapp_all{:}, 'VariableNames', colNames);

            else %in EP mode
                Tapp=[];
                for fri=WhFr
                    WhCol2=WhCol(WhCol<=length(p.colonyCenRad{fri,2}));
                    Tapp=[Tapp;p.estTapp(WhCol2,fri)];
                    mtrx=table(Tapp,'VariableNames',{'Tapp'});
                end
            end
        else %the values of Tapp are not up to date
            mtrx=exportMSg(WhFr,WhCol,'Appearance time','Tapp');
        end
        % TappRef is exported if exists
        if ~isempty(p.TappRef)
            mtrx=[table(repmat(p.TappRef,numel(mtrx),1), 'VariableNames',{'TappRef'}),mtrx];
        end
    end %export appearance time
    function mtrx=makeTableExportGR(WhFr,WhCol)
        if ~isempty(p.GR) && WhCol(end)<=length(p.GR) %exists, and right size
            if strcmp(p.operatingMode,'TL')

                % Preallocate a struct or cell array to store each channel's data
                GR_all = cell(1, p.nChannel);       % Each cell will hold the vector for that channel
                colNames = cell(1, p.nChannel);     % Variable names for the table columns
                
                for chi = 1:p.nChannel
                    if chi == 1
                        GR_all{chi} = repmat(p.GR(WhCol), numel(WhFr), 1);
                        colNames{chi} = 'GR';
                    else
                        fname = sprintf('GRCh%d', chi); % Use chi for channel number
                        GR_all{chi} = repmat(p.(fname)(WhCol), numel(WhFr), 1);
                        colNames{chi} = fname;
                    end
                end

                % Convert cell array to a table with dynamic variable names
                mtrx = table(GR_all{:}, 'VariableNames', colNames);
                
            else
                cs=ismember(p.GR(:,1),WhCol) & ismember(p.GR(:,2),WhFr);
                for gri=1:length(p.timepoints)-1
                    GRnames{gri}=['GR:', num2str(p.timepoints(gri)), 'h-', num2str(p.timepoints(gri+1)), 'h'];
                end
                mtrx=array2table(p.GR(cs,3:end), 'VariableNames',GRnames);
                
            end
        else
            mtrx=exportMSg(WhFr,WhCol,'Growth rate','GR');
        end
        if ~isempty(p.GRRef)
            mtrx=[table(repmat(p.GRRef,size(mtrx,1),1), 'VariableNames',{'GRRef'}),mtrx];
        end
    end
    function mtrx=exportMSg(WhFr,WhCol,Name,Varname)
        %creates a warning matrx so users knows why not exported
        if strcmp(p.operatingMode, 'TL')
            mtrx=table(repmat({[Name ' should be calculated prior to export']},numel(WhFr)*numel(WhCol),1),'VariableNames',{Varname});
        else % in EP mode
            nblines=0;
            for fri=WhFr
                nblines=nblines+sum(WhCol<=length(p.colonyCenRad{fri,2}));
            end
            mtrx=table(repmat({[Name ' need to be calculated prior to export']},nblines,1),'VariableNames',{Varname});
        end
    end
    function CalcSpatialMetricsD(WhFr,WhCol,UM,D,D2,AD)
        % calculates the spatial metrics
        % this will only calculate the ones needed for frames
        
        distances=[];
        if D2;p.D2=[];end
        if D;p.D=[];end
        if AD;p.AD=[];end
        
        for Fri=WhFr
            WhCol2=WhCol(WhCol<=length(p.colonyCenRad{Fri,2}));%take only existig colonies
            if numel(WhCol2)>0
                
                if D2;p.D2(end+1:end+numel(WhCol2),1)=WhCol2; end
                if D;p.D(end+1:end+numel(WhCol2),1)=WhCol2;end
                if AD;p.AD(end+1:end+numel(WhCol2),1)=WhCol2;end
                colm=1;
                colm=colm+1;
                if D2;p.D2(end-numel(WhCol2)+1:end,colm)=ones(1,numel(WhCol2))*Fri;end
                if D;p.D(end-numel(WhCol2)+1:end,colm)=ones(1,numel(WhCol2))*Fri;end
                if AD;p.AD(end-numel(WhCol2)+1:end,colm)=ones(1,numel(WhCol2))*Fri;end
                
                if ~strcmp(p.operatingMode,'TL') || isempty(distances) % only calculate distances once for TL
                    distances=squareform(pdist(p.colonyCenRad{Fri,1}));
                    distances(distances==0)=NaN; %remove distance to itself
                    distances=distances*UM(Fri); %conversion to micrometer
                end
                for di=p.WhichR*UM(Fri) %for each interaction range
                    % create a truncated distance matrix
                    distances2=distances;
                    distances2(distances>di)=nan;
                    %calculate densities
                    colm=colm+1;
                    d2=sum(1./(distances2.^2));d=sum(1./(distances2));
                    if D2;p.D2(end-numel(WhCol2)+1:end,colm)=d2(WhCol2); end%sum of 1/D^2
                    if D;p.D(end-numel(WhCol2)+1:end,colm)=d(WhCol2); end %sum of 1/D^2
                    
                    if AD
                        % calculate angular diameters, which depends on radii
                        if strcmp(p.operatingMode,'TL') && ~isempty(p.RadMean)
                            if size(distances2,2)==numel(p.RadMean(:,Fri))
                                allAD=sum(2*atan(UM(Fri)*p.RadMean(:,Fri)./(2*distances2)),2)';
                            else
                                allAD=nan(size(distances2,2),1);
                            end
                        elseif strcmp(p.operatingMode,'TL') && isempty(p.RadMean)
                            allAD=sum(2*atan(UM(Fri)*p.colonyCenRad{p.focalframe,2}./(2*distances2)),2)';%angular diam from frame
                        else
                            allAD=sum(2*atan(UM(Fri)*p.colonyCenRad{Fri,2}./(2*distances2)),2)';%angular diam
                        end
                        p.AD(end-numel(WhCol2)+1:end,colm)=allAD(WhCol2);
                    end
                end %for each cutoff radius
            end %If there is a colony
        end %for each frame
    end %calculate spatial metrics
    function ExportColorsData (frames,cols2,choices)
        %creates color and shape variables from colonies as asked in
        %whichcalc is a 1x6 vector which values are 1 to calculate the metrics in names:
        whichcalc=choices.TickValues(find(strcmp(choices.Ticklist,'RGBw')):end);
        %names=choices.TickValues(13:end);
        
        %initialize/reset variables
        p.coloniesColors=struct;p.coloniesColors.Tbl=[];p.coloniesColors.Titles=[];
        
        %  1{'RGBw'} 2{'RGBc'} 3{'GRAYw'} 4{'GRAYc'} 5{'TxtStd'} 6{'TxtEnt'} 7{'Pstd'} 8{'Pl'} 9{'Hrgb'} 10{'Hgray'}
        maketitlsColors(whichcalc,size(Fvar.rgb,3)); %create titles for the matrix
        dispi=-1; tic; totcol=0;
        for fr=frames
            dispi=dispi+1;
            %             if dispi/1==round(dispi/1)
            %                 hs.UserMess.String=['Calculating shape/color metrics (' num2str(100*dispi/numel(frames),2) '%)'];customdrawnow
            %             end
            img = imread([p.dir, filesep,p.l(fr).name]); %loading pic
            if sum(whichcalc([3:8,10]))>=1 %at least one needs a gray image
                im=getgray(img);
            end
            cols=cols2(cols2<=numel(p.colonyCenRad{fr,2})); %in not TL, this is needed because not all frames have same number of colonies
            
            % create a meshgrid for colony masks
            [xDim,yDim] = size(img,1:2);
            [xx,yy] = meshgrid(1:yDim,1:xDim);
            mask0 = false(xDim,yDim);
            
            dispic=-1;
            for col=cols
                
                % this can be long, user message
                dispic=dispic+1; totcol=totcol+1;
                if totcol/5==round(totcol/5)
                    tmn=toc;
                    timeElapsed=floor(tmn);
                    percDone=round((numel(cols)*dispi+dispic)/(numel(cols)*numel(frames))*100);
                    remT=floor((1-percDone/100)*timeElapsed/percDone*100);
                    mess=sec2timestr(remT);
                    txtMsg= [num2str(floor(percDone)), '% done; Estimated ',mess, ' remain' ]; customdrawnow
                    axes(hs.Progress1); fill([0 0 percDone/100 percDone/100],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none');customdrawnow %#ok<LAXES>
                    text(0.25, 0.5, txtMsg,'Fontsize', 14);customdrawnow
                end
                
                %uodate col and frame in table
                p.coloniesColors.Tbl(end+1,1)=col; colm=1;
                colm=colm+1;p.coloniesColors.Tbl(end,colm)=fr;
                
                % extract a smaller image before binarization. Then find edges
                center=[round(p.colonyCenRad{fr,1}(col,2)),round(p.colonyCenRad{fr,1}(col,1))]; %contains the centers of colonies
                Zone=ZoneDef(center,col,im,fr);
                mini_img=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:); % 3 colors
                
                if sum(whichcalc([3:8,10]))>=1 %at least one needs a gray image
                    mini_im=im(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone); % 3 colors
                end
                
                % create a meshgrid for colony masks
                [mini_xDim,mini_yDim] = size(mini_img,[1,2]);
                [mini_xx,mini_yy] = meshgrid(1:mini_yDim,1:mini_xDim);
                mini_mask0 = false(mini_xDim,mini_yDim);
                
                % measures with mask of whole colony
                if sum(whichcalc([1,3,5,6]))
                    maskColW=createCirclesMask(mini_img,round(size(mini_img)/2),p.colonyCenRad{fr,2}(col),mini_xx,mini_yy, mini_mask0);
                end
                if sum(whichcalc([2,4])) % "colony center" based mask
                    exportCenterRadius=5;
                    maskColC=createCirclesMask(mini_img,round(size(mini_img)/2),exportCenterRadius,mini_xx,mini_yy, mini_mask0);
                end
                
                if whichcalc(1) %MeanColVal
                    for dim=1:size(img,3)
                        a=mini_img(:,:,dim);
                        colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(a(maskColW==1),'all', 'omitnan');
                    end
                end
                if whichcalc(2) % center color Val
                    for dim=1:size(img,3)
                        a=mini_img(:,:,dim);
                        colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(a(maskColC==1),'all', 'omitnan');
                    end
                end
                if whichcalc(3) %MeangrayVal
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(mini_im(maskColW), 'omitnan');
                end
                if whichcalc(4) %Center grey Val
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(mini_im(maskColC), 'omitnan');
                end
                if whichcalc(5) % Std Val
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=nanstd(double(mini_im(maskColW)));
                end
                if whichcalc(6) %Entropy Val
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=entropy(mini_im(maskColW));
                end
                
                if sum(whichcalc(7:10)) %affected by other colonies touching
                    dist=pdist2(p.colonyCenRad{fr,1}(col,:),p.colonyCenRad{fr,1},'euclidean'); %distances between colonies
                    dist2=dist-p.colonyCenRad{fr,2}(:)'-p.colonyCenRad{fr,2}(col); % removing the radii of both colonies
                    tooclose=dist2<0; tooclose(col)=0;
                    AlphaSum=0;
                    % we want to calculate the angle of the arc of interaction between colonies
                    if sum(tooclose(:))>0 %if colonies touch
                        for touchCi=find(tooclose) %over all touching colonies
                            d=dist(touchCi); r1=p.colonyCenRad{fr,2}(col); r2=p.colonyCenRad{fr,2}(touchCi);
                            if r2>dist %the colony is fully engulfed
                                alpha=2*pi;
                            else
                                %the angle of interaction is calculated from the r1,r2,d triangle, where cos(angle/2) is calculated using al-Kashi's theorem
                                alpha=rad2deg(2*acos((r1^2+d^2-r2^2)/(2*r1*d)));
                            end
                            AlphaSum=AlphaSum+alpha;
                        end
                    end
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=AlphaSum;
                end
                
                if sum(whichcalc(7:8)) %perimeters needs an edge calc
                    % binarize the small image
                    binim=imbinarize(mini_im); edgim=edge(binim);
                    
                    % create a bigger mask than the colony to remove potential other objects, remove edges
                    maskColB=createCirclesMask(mini_img,round(size(mini_img)/2),p.colonyCenRad{fr,2}(col)*1.1,mini_xx,mini_yy, mini_mask0);
                    edgim(~maskColB)=0; %remove the edges that are not within 10% of colsize
                    
                    %                     if sum(tooclose(:))>0 %if colonies touch
                    %                         for touchCi=find(tooclose)
                    %                             maskOthercol=createCirclesMask(im,p.colonyCenRad{fr,1}(touchCi,:),p.colonyCenRad{fr,2}(touchCi));
                    %                             edgim(maskOthercol)=0; %remove colony from pic
                    %                         end
                    %                     end
                end
                
                if whichcalc(7) %perimeter std
                    [row,column] = find(edgim); %get the valid pixels
                    if ~isempty(row)
                        distP=pdist2(round(size(mini_img,[1,2])/2),[row,column],'euclidean');
                        colm=colm+1;p.coloniesColors.Tbl(end,colm)=nanstd(distP(:));
                    else %no perimeter found
                        colm=colm+1;p.coloniesColors.Tbl(end,colm)=nan;
                    end
                end
                if whichcalc(8) %perimeter length
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=sum(edgim(:));
                end
                
                if sum(whichcalc(9:10)) % halo based
                    if sum(tooclose(:))==0 %no colonies touch, we use a small image
                        HS=getHalosize(choices,p.colonyCenRad{fr,2}(col)); % This halo is in pixels
                        
                        if (HS+p.colonyCenRad{fr,2}(col))>(size(mini_img,1)/2) % the small image is smaller than rad+Halo
                            Zone=p.colonyCenRad{fr,2}(col)+HS+2;
                            mini_img=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:); % 3 colors
                            
                            % create a meshgrid for colony masks
                            [mini_xDim,mini_yDim] = size(mini_img,[1,2]);
                            [mini_xx,mini_yy] = meshgrid(1:mini_yDim,1:mini_xDim);
                            mini_mask0 = false(mini_xDim,mini_yDim);
                        end
                        maskColH=createCirclesMask(mini_im,round(size(mini_img)/2),p.colonyCenRad{fr,2}(col)+HS,mini_xx,mini_yy, mini_mask0);
                        maskCol=createCirclesMask(mini_im,round(size(mini_img)/2),p.colonyCenRad{fr,2}(col),mini_xx,mini_yy, mini_mask0);
                        maskCol=maskColH-maskCol;
                        imH=getgray(mini_img);imgH=mini_img;
                    else %if colonies touch, we use the whole picture
                        maskColH=createCirclesMask(img,p.colonyCenRad{fr,1}(col,:),p.colonyCenRad{fr,2}(col)+HS,xx,yy, mask0);
                        maskCol=createCirclesMask(img,p.colonyCenRad{fr,1}(col,:),p.colonyCenRad{fr,2}(col),xx,yy, mask0);
                        maskCol=maskColH-maskCol;
                        
                        imH=im; imgH=img;
                        for touchCi=find(tooclose)
                            maskOthercol=createCirclesMask(img,p.colonyCenRad{fr,1}(touchCi,:),p.colonyCenRad{fr,2}(touchCi),xx,yy, mask0);
                            imH(maskOthercol)=nan; %remove colony from pic
                            imgH(repmat(maskOthercol,[1,1,size(img,3)]))=nan; %same in rgb
                        end
                    end
                end
                if whichcalc(9) %Halo, rgb
                    for dim=1:size(img,3)
                        a=imgH(:,:,dim);
                        colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(a(maskCol==1),'all', 'omitnan');
                    end
                end
                if whichcalc(10) %Halo, gray
                    colm=colm+1;p.coloniesColors.Tbl(end,colm)=mean(imH(maskCol==1), 'omitnan');
                end
            end
            
            
        end
    end %export color
    function maketitlsColors(whichcalc,dim)
        p.coloniesColors.Titles={'col','frame'};
        if whichcalc(1)
            if dim==3
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'MeanR'},{'MeanG'},{'MeanB'}];
            else
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'MeanColor'}];
            end
        end
        if whichcalc(2)
            if dim==3
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'CntrR'},{'CntrG'},{'CntrB'}];
            else
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'CntrColor'}];
            end
        end
        if whichcalc(3)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'MeanGray'}];
        end
        if whichcalc(4)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'CntrGray'}];
        end
        if whichcalc(5)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'TxturStd'}];
        end
        if whichcalc(6)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'TxturEnt'}];
        end
        if sum(whichcalc(7:10))%colonies that touch affect measure
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'AlphaRemov'}];
        end
        if whichcalc(7)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'PerimStd'}];
        end
        if whichcalc(8)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'PerimLength'}];
        end
        if whichcalc(9)
            if dim==3
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'HaloR'},{'HaloG'},{'HaloB'}];
            else
                p.coloniesColors.Titles=[p.coloniesColors.Titles,{'HaloColor'}];
            end
        end
        if whichcalc(10)
            p.coloniesColors.Titles=[p.coloniesColors.Titles,{'HaloGrey'}];
        end
    end %create color title for export
    function HS=getHalosize(Choices,Rcol)
        if ~isempty(Choices.Nums{4})
            HS=Choices.Nums(4);
            HS=str2double(HS{1}); %only one halosize is possible, several will give nan.
        elseif ~isempty(Choices.Nums{5})
            HS=Choices.Nums(5);
            HS=(str2double(HS{1})-1)*Rcol; %same here
        else
            HS=nan;
        end
    end %fetch size of halo to use
    function im=getgray(img)
        if size(img,3)==3
            im=customcol2gray(img);
        else
            im=img;
        end
    end %get grayimage
    function mask = createCirclesMask(~,centers, radii, xx, yy, mask)
        % adapted from MAtlab central
        % Brett Shoelson (2020). createCirclesMask.m (https://www.mathworks.com/matlabcentral/fileexchange/47905-createcirclesmask-m), MATLAB Central File Exchange. Retrieved April 27, 2020.
        % xDim,yDim,centers,radii)
        % Create a binary mask from circle centers and radii
        %
        % SYNTAX:
        % mask = createCirclesMask([xDim,yDim],centers,radii);
        % OR
        % mask = createCirclesMask(I,centers,radii);
        %
        % INPUTS:
        % [XDIM, YDIM]   A 1x2 vector indicating the size of the desired
        %                mask, as returned by [xDim,yDim,~] = size(img);
        %
        % I              As an alternate to specifying the size of the mask
        %                (as above), you may specify an input image, I,  from which
        %                size metrics are to be determined.
        %
        % CENTERS        An m x 2 vector of [x, y] coordinates of circle centers
        %
        % RADII          An m x 1 vector of circle radii
        %
        % OUTPUTS:
        % MASK           A logical mask of size [xDim,yDim], true where the circles
        %                are indicated, false elsewhere.
        %
        %
        % Brett Shoelson, PhD
        % 9/22/2014
        % Comments, suggestions welcome: brett.shoelson@mathworks.com
        
        % Copyright 2014 The MathWorks, Inc.
        
        %[xDim,yDim] = size(im);
        xc = centers(:,1);
        yc = centers(:,2);
        %[xx,yy] = meshgridMat(1:yDim,1:xDim);
        % mask = false(xDim,yDim);
        for ii = 1:numel(radii)
            mask = mask | hypot(xx - xc(ii), yy - yc(ii)) <= radii(ii);
        end
    end %create mask of the circle

%% List functions
    function ChangeUserList_callBack(a,~)
        % this function reates a new list if user asks "new"
        
        %if ~isfield(p,'listOptions'); return; end %was used before an update of lists
        
        if a.Value==length(p.UserLists.listOptions) %user selected new
            prompt = {'New list name:'}; dlg_title = 'New list'; num_lines = 1; defaultans = {['List' num2str(a.Value-1)]};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            if isempty(answer)||isempty(answer{1}); return; end %user cancelled or entered empty name
            
            %changing the list of lists names
            p.UserLists.listOptions{end+1}='new';p.UserLists.listOptions{end-1}=['-',num2str(a.Value-1),' ',answer{1}];
            
            % create a new list
            chngList(a.Value-1,0,zeros(length(p.colonyCenRad{p.i,2}),1))
        end
        
        set(hs.ListSelect, 'Value',a.Value);
        if isfield(hs, 'ListSelect2')
            if isvalid(hs.ListSelect2) %field removed exist but are not valid
                set(hs.ListSelect2, 'Value',a.Value);
                set(hs.ListSelect2, 'String',p.UserLists.listOptions);
            else %in main gui
                refresh(1);
            end
        else
            refresh(1);
        end
    end %change active list from dropdown
    function UpdateListNewCol(NumberCol)
        %the function updates alls lists by adding/removing lines
        % it takes 3 possible entries:
        % 1) 'all', this resets the list to the current size of p.colonyCenRad
        % 2) N>0 (adds N colonies at the end of existing lists
        % 3) N<0 (removes colonies marked by N)
        
        if strcmp(NumberCol, 'all')
            % resetting all the lists to the new colonies counts
            for listnum=1:numel(fieldnames(p.UserLists.l))
                chngList(listnum,p.i,zeros(length(p.colonyCenRad{p.i,2}),1));
            end
        elseif NumberCol>0
            % adapting all the lists to the new colonies counts
            for listnum=1:numel(fieldnames(p.UserLists.l))
                L=readList(listnum,p.i);
                chngList(listnum,p.i,[L;zeros(1,NumberCol)]);
            end
        elseif sum(NumberCol<0) %at leas one value is negative
            % adapting all the lists to the new colonies counts
            for listnum=1:numel(fieldnames(p.UserLists.l))
                L=readList(listnum,p.i);
                chngList(listnum,p.i,L(setdiff(1:end,-NumberCol)));
            end
        end
    end %update active list
    function chngList(listNumber,numfr,L)
        %this function makes a new list or resets the list at list number
        lname=['List',num2str(listNumber)];
        if strcmp(p.operatingMode, 'TL') %in timelapse mode, only one vector needed for all frames (per list)
            p.UserLists.l.(lname).fr0=L;
        else % in end point image mode
            if numfr==0 %all lists
                for fr=1:size(p.colonyCenRad,1) %one list is needed for each frame
                    p.UserLists.l.(lname).(['fr',num2str(fr)])=zeros(length(p.colonyCenRad{fr,2}),1);
                end
            else
                p.UserLists.l.(lname).(['fr',num2str(numfr)])=L;
            end
        end
    end %do list change
    function L=readList(listNumber,numfr)
        lname=['List',num2str(listNumber)];
        if strcmp(p.operatingMode, 'TL')
            L=p.UserLists.l.(lname).fr0;
        else
            L=p.UserLists.l.(lname).(['fr',num2str(numfr)]);
        end
    end %read current list

%% batch run
    function MergeRun(~,~)
        % check if a file exists
        % p.batchFile=[]; was created at start. Should the program find one
        % automatically
        
        %
        disableGUI(1);%disable the GUI
        %create figure
        hs.c = figure('units','norm','Position',[0.1 0.1 0.7 0.7], 'KeyPressFcn', @WindowKeyPressFcn,...
            'MenuBar', 'none', 'NumberTitle', 'off','HandleVisibility','on',...
            'Name','Batch functions');
        %hs.datalist=[];
        
        hs.comp=uix.HBox('Parent', hs.c);
        hs.button=uix.VBox('Parent', hs.comp);
        hs.List=uix.VBox('Parent', hs.comp);
        hs.button1=uix.HBox('Parent', hs.button);
        hs.button2=uix.HBox('Parent', hs.button);
        
        hs.loadfromfile=uicontrol('Parent', hs.button1, 'String', 'Load from csv file', 'Callback', @loadFromFile);
        hs.addDirectory=uicontrol('Parent', hs.button1, 'String', 'Add a directory', 'Callback', @addDirectory);
        
        hs.removeDir=uicontrol('Parent', hs.button2, 'String', 'Remove directories', 'Callback', @RemoveDirectories);
        
        hs.saveList=uicontrol('Parent', hs.button, 'String', 'Save list to...', 'Callback', @SavebatchList_Callback);
        hs.RunFunction=uicontrol('Parent', hs.button, 'String', 'Batch run function...', 'Callback', @RunBatchFunction);
        
        hs.TitleFolderList=uicontrol('Parent', hs.List, 'Style', 'Text', 'FontSize', 10, 'String', 'Folder list');
        hs.ListFolders=uicontrol('Parent', hs.List, 'Style', 'Text', 'FontSize', 10);
        if ~isstruct(b)
            b=struct();
        end
        if ~isfield(b, 'batchFile')
            b.batchFile=[];
        end
        if ~isempty(b.batchFile)
            set(hs.ListFolders,'String', b.batchFile, 'Fontsize', 12 ,'Max', 2);
        end
        
        while ishandle(hs.c)
            pause(0.5)
        end
        disableGUI(0); %re-enabling main GUI
        if ~isfield(b, 'MergeFolder')
            b.MergeFolder=b.batchFile{1};
        end
        % saving the MergeFile
        SavebatchList(b.MergeFolder)
        
    end %create new window
    function addDirectory(~,~)
        %this function adds directories to the directory list of batchFile
        newdir=uigetdir2(p.dir, 'Select the folders containg the data'); %the function uigetdir2 allows multiple selection, but also allow selecting files
        
        % removing file names
        newdir2=cell(0);
        for i=1:length(newdir)
            if isfolder(newdir{i}) %isdir
                newdir2{end+1}=newdir{i};
            end
        end
        
        if iscell(newdir2)
            b.batchFile=unique([b.batchFile;newdir2']);
        end
        set(hs.ListFolders,'String', b.batchFile, 'Fontsize', 12 ,'Max', 2);
    end % add a directory
    function loadFromFile(~,~)
        % this function adds the content of file list to current
        % b.batchfile
        [b.MergeFile, b.MergeFolder]=uigetfile({'*.csv'; '*.xlsx'});
        
        % different delimiter for different operating systems
        lim=filesep;
        tableB=readtable([b.MergeFolder,lim,b.MergeFile], 'ReadVariableNames', 0,'Delimiter', 'comma');
        b.batchFile=table2cell(tableB);
        set(hs.ListFolders,'String', b.batchFile, 'Fontsize', 12 ,'Max', 2);
    end %load list of dir from csv
    function RemoveDirectories(~,~)
        b.batchFile=[];
        set(hs.ListFolders,'String', b.batchFile, 'Fontsize', 12 ,'Max', 2);
    end %remove all dirs
    function SavebatchList_Callback(~,~)
        if isempty(b.batchFile); return; end
        if ~isfield(b, 'MergeFolder')
            b.MergeFolder=b.batchFile{1};
        end
        dirUser=uigetdir(b.MergeFolder,'Select folder to save list of batch folders');
        if dirUser==0; return; end %user cancelled
        b.MergeFolder=dirUser;
        SavebatchList(b.MergeFolder)
    end %save dir list to csv from button
    function SavebatchList(savedir)
        if ~isempty(b.batchFile)
            try
                MergeFileSaved=cell2table(b.batchFile); %
                
                %MergeFileSaved=removeTableNans(MergeFileSaved);
                writetable(MergeFileSaved, [savedir,'/BatchFile.csv'], 'WriteVariableNames', 0)
            catch
                errordlg('Saving the list of folders for the batch function failed');
            end
        end
    end  %do the save
    function RunBatchFunction(~,~)
        if isempty(b.batchFile);return;end
        b.summary=nan(1,length(b.batchFile)); %this will contain 1 if the function could be run , 0 otherwise
        b.runningBatch=1;
        b.umConversionMissing=nan(1,length(b.batchFile));
        
        % which function?
        quest1=questdlg('Running batch mode, which functions?','Choose function', 'Time Lapse','Find Colonies','Cancel', 'Time Lapse');
        if strcmp(quest1,'Cancel')
            return
        end
        
        b.comptime=nan(length(b.batchFile),1);
        b.meanrad=nan(length(b.batchFile),1);
        b.Ncol=nan(length(b.batchFile),1);
        b.Nframes=nan(length(b.batchFile),1);
        %%running the function for all folders in b.batchfile
        for i=1:length(b.batchFile)
            try
                b.summary(i)=1; %this indicate if an error occured
                b.TheOneRunning=i; %this is the i stored in a struct so it is accessible everywhere
                p.dir=cell2mat(b.batchFile(i));
                p.dirS=p.dir;
                chngDir(); %loading all the parameters
                if b.summary(i)==0 %if already in the loading an error occured, don't go through the rest of the for loop
                    continue
                end
                if length(p.dir)>30%display dir name in GUI
                    hs.UserMessDir.String = ['...' p.dir(end-30:end)];
                else
                    hs.UserMessDir.String = [p.dir];
                end
                backwardCompatTest(); %backward compatibility testing
                p.dir=cell2mat(b.batchFile(i));
                p.dirS=p.dir;
                switch quest1
                    case 'Time Lapse'
                        %check if the px to um conversion rate is missing.
                        %That does not interfere with the TL run but it is
                        %good to know and the user can add that afterwards
                        if isempty(p.umConversion) || sum(isnan(p.umConversion))>0
                            b.umConversionMissing(i)=1;
                        else
                            b.umConversionMissing(i)=0;
                        end
                        %call the TL function
                        tic;
                        FindTimeCol_Callback;
                        b.comptime(i)=toc;
                        b.meanrad(i)=mean(p.colonyCenRad{p.focalframe,2}, 'omitnan');
                        b.Ncol(i)=length(p.colonyCenRad{p.focalframe,2});
                        b.Nframes(i)=length(p.l);
                        if verLessThan('Matlab','9.2')
                            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV)
                        else
                            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV, '-nocompression')
                        end
                    case 'Find Colonies'
                        tic
                        if strcmp(p.operatingMode, 'TL')%we are in timelapse mode, colonies are found on the current frame
                            frameList=length(p.l);
                            p.focalframe=frameList;
                        else %we are in single mode, so multiple frames can be selected
                            frameList= 1:length(p.l);
                        end
                        
                        p.iold=0;
                        indx=1;
                        set_frame(frameList(1));
                        for i2=frameList
                            refresh(0) %refreshing image on which to find colonies
                            FindColonies %this finds all colonies on search zone, and resets the whole colonies to what was found
                            UpdateListNewCol('all') %refreshes all lists to match the new colonies
                            saveall(p.dirS);
                            %% message to user
                            tmn=toc;
                            timeElapsed=floor(tmn);
                            percDone=round(indx/length(frameList)*100);
                            remT=floor((1-percDone/100)*timeElapsed/percDone*100);
                            mess=sec2timestr(remT);
                            txtMsg= [num2str(floor(percDone)), '% done; Estimated ',mess, ' remain' ]; customdrawnow
                            axes(hs.Progress1); fill([0 0 percDone/100 percDone/100],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none');customdrawnow %#ok<LAXES>
                            text(0.25, 0.5, txtMsg,'Fontsize', 14);customdrawnow
                            
                            indx=indx+1;
                            if p.i~=frameList(end)
                                p.i=frameList(indx);
                                set_frame(p.i);
                            end
                        end
                        
                        if p.progress.found==0
                            ProgressUpdate;
                            %                                 UpdateButtonState;
                            p.progress.found=1;
                        end
                        if strcmp(p.operatingMode, 'TL')
                            if p.REGstatus
                                ResetTLRegistration_Callback
                            end
                            p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
                            p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
                        end
                        saveall(p.dirS);
                        voronoisave(p.dirS);
                        b.summary(i)=1;
                        b.comptime(i)=toc;
                        if strcmp(p.operatingMode, 'TL')
                            b.meanrad(i)=mean(p.colonyCenRad{p.focalframe,2}, 'omitnan');
                            b.Ncol(i)=length(p.colonyCenRad{p.focalframe,2});
                        else
                            allc=[];
                            Ncol=0;
                            for nfr=1:length(p.l)
                                allc=[allc; p.colonyCenRad{nfr,2}];
                                Ncol=Ncol+length(p.colonyCenRad{nfr,2});
                            end
                            b.Ncol(i)=Ncol;
                            b.meanrad(i)=mean(allc, 'omitnan');
                        end
                        b.Nframes(i)=length(p.l);
                        if verLessThan('Matlab','9.2')
                            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV)
                        else
                            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV, '-nocompression')
                        end
                end
                
            catch %something else went wrong
                if isnan(b.comptime(i))
                    b.comptime(i)=toc;
                end
                b.summary(i)=0;
            end
        end
        
        %create a msgbox with a nice output
        b.txt='';
        for i=1:length(b.batchFile)
            if b.summary(i)==1
                b.txt=[b.txt, cell2mat(b.batchFile(i)), ' successful, '];
            else
                b.txt=[b.txt, cell2mat(b.batchFile(i)), ' failed, '];
            end
            if b.umConversionMissing(i)==1
                b.txt=[b.txt, 'spatial calibration factor missing, '];
            end
        end
        if verLessThan('Matlab','9.2')
            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV)
        else
            save([b.batchFile{1}, filesep, 'batchfilereport.mat'], 'b', saveV, '-nocompression')
        end
        msgbox(b.txt);
        b.runningBatch=0;
    end %run the corresponding function

%% Options
% figure creation, save and close
    function Options_Callback(~,~)%the user can see and change the program's options.
        % We turn the interface off for processing.
        disableGUI(1);%disable the GUI
        restore1=p;
        hs.o = figure('units','norm','Position',[0.5 0.1 0.25*Fvar.figscale 0.8], 'KeyPressFcn', @WindowKeyPressFcn,...
            'MenuBar', 'none', 'NumberTitle', 'off','HandleVisibility','on',...
            'Name','Options');
        hs.options=uix.VBox('Parent', hs.o);
        hs.tabs=uix.HBox('Parent', hs.options);
        hs.lower=uix.HBox('Parent', hs.options);
        
        hs.tgroup = uitabgroup('Parent', hs.tabs);
        hs.Globaltab = uitab('Parent', hs.tgroup, 'Title', 'Global');
        hs.Detecttab = uitab('Parent', hs.tgroup, 'Title', 'Detect');
        hs.SItab= uitab('Parent', hs.tgroup, 'Title', 'Main-EP');
        hs.Timelapsetab = uitab('Parent', hs.tgroup, 'Title', 'Main-TL');
        hs.Resultstab = uitab('Parent', hs.tgroup, 'Title', 'Visualize');
        
        hs.GlobaltabBox=uix.VBox('Parent', hs.Globaltab,'Padding', 20);
        hs.DetecttabBox=uix.VBox('Parent', hs.Detecttab,'Padding', 20);
        hs.SItabBox= uix.VBox('Parent', hs.SItab,'Padding', 20);
        hs.TimelapsetabBox=uix.VBox('Parent', hs.Timelapsetab,'Padding', 20);
        hs.ResultstabBox=uix.VBox('Parent', hs.Resultstab,'Padding', 10);
        
        % Global tab
        hs.graystr=uicontrol('Style', 'text','Parent',hs.GlobaltabBox, 'String', {'Color to grayscale method selection'},'FontSize',10, 'FontWeight','bold');
        hs.grayp=uix.HBox('Parent', hs.GlobaltabBox);
        hs.grayopt1= uicontrol('Parent',hs.grayp,'Style','text','String','RGB to grayscale method:','FontSize',10);
        hs.grayopt2= uicontrol('Parent',hs.grayp,'Style', 'popup','String', Fvar.grayoptions,'FontSize',10, 'Value', p.imgMethod);
        hs.CheckMethod=uix.HBox('Parent',hs.GlobaltabBox);
        hs.CheckMethod1=uicontrol('Parent',hs.CheckMethod, 'String', 'Select RGB to grayscale method from examples','FontSize',10, 'Callback', @SetImgMethod_Callback);
        hs.Voidgray=uix.Empty('Parent', hs.GlobaltabBox);
        %Visualize on image
        hs.VStrg=uicontrol('Style', 'text','Parent',hs.GlobaltabBox, 'String', {'Visualize on image'},'FontSize',10, 'FontWeight','bold');
        hs.toggles1=uix.HBox('Parent', hs.GlobaltabBox);
        hs.VisGray=uicontrol('Parent',hs.toggles1, 'String','Grayscale','Style','checkbox','Value',p.showGrayscale,'FontSize',10,'Callback',@BWCheckboxchange_Callback);
        hs.VisAA=uicontrol('Parent',hs.toggles1, 'String','See area of interest','Style','checkbox','Value',p.showROI,'FontSize',10,'Callback',@vAACheckboxchange_Callback);
        hs.toggles2=uix.HBox('Parent', hs.GlobaltabBox);
        hs.SeeC=uicontrol('Parent',hs.toggles2, 'String','See circles','Style','checkbox','Value', p.ShowCol, 'FontSize',10,'Callback',@ShowColCheckboxchange_Callback);
        hs.SeeN=uicontrol('Parent',hs.toggles2, 'String','See numbers','Style','checkbox','Value', p.showNr,'FontSize',10,'Callback',@ShowNrCheckboxchange_Callback);
        hs.toggles3=uix.HBox('Parent', hs.GlobaltabBox);
        hs.SeeVoronoiArea=uicontrol('Parent',hs.toggles3, 'String','See Voronoi areas','Style','checkbox', 'FontSize',10, 'Value',p.ShowVoronoiAreas, 'Callback',@ShowVoronoiAreasCheckboxchange_Callback);
        hs.SeeVertices=uicontrol('Parent',hs.toggles3, 'String','See Voronoi edges','Style','checkbox','FontSize',10,'Value',p.ShowVoronoiEdges ,'Callback',@ShowVoronoiEdgesCheckboxchange_Callback);
        hs.enhance=uix.HBox('Parent',hs.GlobaltabBox);
        hs.enhance1=uicontrol('Parent',hs.enhance, 'String', 'Redefine lighting correction area','FontSize',10, 'Callback', @ReEnhanceImage_Callback);
        hs.Void=uix.Empty('Parent', hs.GlobaltabBox);
        %Reference growth data
        hs.refStr=uicontrol('Style', 'text','Parent',hs.GlobaltabBox, 'String', {'Reference growth data'},'FontSize',10, 'FontWeight','bold');
        hs.refmode=uix.HBox('Parent',hs.GlobaltabBox);
        hs.refmodepanel=uibuttongroup('Parent',hs.refmode,'Title','Averaging strategy','FontSize',10);
        hs.refmodemean=uicontrol(hs.refmodepanel,'Style','radiobutton','String','Mean','FontSize',10,'Units','normalized','Position',[.1 .2 .3 .7]);
        hs.refmodequantile=uicontrol(hs.refmodepanel,'Style','radiobutton','String','Quantile','FontSize',10, 'Units','normalized','Position',[.6 .2 .3 .7]);
        hs.refmodequantilevalue=uix.HBox('Parent', hs.GlobaltabBox);
        hs.refmodeqv= uicontrol('Parent',hs.refmodequantilevalue,'Style','text','String','Which quantile','FontSize',10);
        hs.refmodeqv2= uicontrol('Parent',hs.refmodequantilevalue,'Style','edit','String',num2str(p.tappRefQuantile),'FontSize',10);
        set(hs.refmodeqv2,'Value',p.tappRefQuantile);
        hs.VoidRef=uix.Empty('Parent', hs.GlobaltabBox);
        hs.savestring=uicontrol('Style', 'text','Parent',hs.GlobaltabBox, 'String', {'Save options'},'FontSize',10, 'FontWeight','bold');
        hs.autosave=uix.HBox('Parent', hs.GlobaltabBox);
        hs.autosave1=uicontrol('Parent',hs.autosave, 'String','Autosave','Style','checkbox','Value', ~p.disableSave, 'FontSize',10,'Callback',@disableSave_Callback);
        hs.backupsave=uicontrol('Parent',hs.autosave, 'String','Backupsave','Style','checkbox','Value', p.savebackups, 'FontSize',10,'Callback',@switchbackup_Callback);
        %List
        hs.Voidl=uix.Empty('Parent', hs.GlobaltabBox);
        hs.resetList=uix.HBox('Parent',hs.GlobaltabBox);
        hs.resetList1=uicontrol('Parent',hs.resetList, 'String', 'Reset active list','FontSize',10, 'Callback', @ResetUserList_Callback);
        
        %In the detect tab:
        %Define parameters
        hs.DPStrg=uicontrol('Style', 'text','Parent',hs.DetecttabBox, 'String', {'Image preprocessing'},'FontSize',10, 'FontWeight','bold');
        hs.ADP=uix.HBox('Parent',hs.DetecttabBox);
        hs.IMGp=uix.HBox('Parent', hs.DetecttabBox);
        hs.IMGp1= uicontrol('Parent',hs.IMGp,'Style','text','String','Image binarization','FontSize',10);
        hs.IMGp2= uicontrol('Parent',hs.IMGp,'Style', 'popup','String', {'Adaptive (local)','Otsu (global)','None'},'FontSize',10);
        set(hs.IMGp2,'Value',p.detectBinarizationMethod);
        hs.binsens=uix.HBox('Parent', hs.DetecttabBox);
        hs.binsens1= uicontrol('Parent',hs.binsens,'Style','text','String','Binarization sensitivity','FontSize',10);
        hs.binsens2= uicontrol('Parent',hs.binsens,'Style','edit','String',num2str(p.detectBinarizeSensitivity),'FontSize',10);
        hs.invert=uix.HBox('Parent', hs.DetecttabBox);
        hs.invert1=uicontrol('Parent',hs.invert, 'String','Dark colonies on bright background','Style','checkbox', 'FontSize',10, 'Value',p.BlackColony, 'Callback',@BlackColonyCheckboxchange_Callback);
        hs.Voidl=uix.Empty('Parent', hs.DetecttabBox);
        hs.DPStrg=uicontrol('Style', 'text','Parent',hs.DetecttabBox, 'String', {'Colony detection parameters'},'FontSize',10, 'FontWeight','bold');
        hs.circlemode=uix.HBox('Parent', hs.DetecttabBox);
        hs.circlemode1= uicontrol('Parent',hs.circlemode,'Style','text','String','Circle detection','FontSize',10);
        hs.circlemode2= uicontrol('Parent',hs.circlemode,'Style', 'popup','String', {'Regionprops','Direct'},'FontSize',10);
        set(hs.circlemode2,'Value',p.detectCircleMode);
        hs.S=uix.HBox('Parent', hs.DetecttabBox);
        hs.S1= uicontrol('Parent',hs.S,'Style','text','String','imfindcircle sensitivity','FontSize',10);
        hs.S2= uicontrol('Parent',hs.S,'Style','edit','String',num2str(p.detectSensitivity),'FontSize',10);
        hs.MR=uix.HBox('Parent', hs.DetecttabBox);
        hs.MR1= uicontrol('Parent',hs.MR,'Style','text','String','Minimal Radius [pixel]','FontSize',10);
        hs.MR2= uicontrol('Parent',hs.MR,'Style','edit','String',num2str(p.detectMinRadPx),'FontSize',10);
        hs.MXR=uix.HBox('Parent', hs.DetecttabBox);
        hs.MXR1= uicontrol('Parent',hs.MXR,'Style','text','String','Maximal Radius [pixel]','FontSize',10);
        hs.MXR2= uicontrol('Parent',hs.MXR,'Style','edit','String',num2str(p.detectMaxRadPx),'FontSize',10);
        hs.bxsc=uix.HBox('Parent', hs.DetecttabBox);
        hs.bxsc1= uicontrol('Parent',hs.bxsc,'Style','text','String','Scale bounding box','FontSize',10);
        hs.bxsc2= uicontrol('Parent',hs.bxsc,'Style','edit','String',num2str(p.detectBoundingBoxScale),'FontSize',10);
        hs.mndst=uix.HBox('Parent', hs.DetecttabBox);
        hs.mndst1= uicontrol('Parent',hs.mndst,'Style','text','String','Min distance from border [pixel]','FontSize',10);
        hs.mndst2= uicontrol('Parent',hs.mndst,'Style','edit','String',num2str(p.detectMinBorderDist),'FontSize',10);
        hs.fbias=uix.HBox('Parent', hs.DetecttabBox);
        hs.fbias1= uicontrol('Parent',hs.fbias,'Style','text','String','Foreground bias','FontSize',10);
        hs.fbias2= uicontrol('Parent',hs.fbias,'Style','edit','String',num2str(p.detectForegroundBias),'FontSize',10);
        hs.fmin=uix.HBox('Parent', hs.DetecttabBox);
        hs.fmin1= uicontrol('Parent',hs.fmin,'Style','text','String','Min area foreground [proportion]','FontSize',10);
        hs.fmin2= uicontrol('Parent',hs.fmin,'Style','edit','String',num2str(p.detectMinForground),'FontSize',10);
        hs.mxov=uix.HBox('Parent', hs.DetecttabBox);
        hs.mxov1= uicontrol('Parent',hs.mxov,'Style','text','String','Max overlap (2 circles) [proportion]','FontSize',10);
        hs.mxov2= uicontrol('Parent',hs.mxov,'Style','edit','String',num2str(p.detectMaxOverlapCompare),'FontSize',10);
        hs.minrddif=uix.HBox('Parent', hs.DetecttabBox);
        hs.minrddif1= uicontrol('Parent',hs.minrddif,'Style','text','String','Min rad difference (overlap) [pixel]','FontSize',10);
        hs.minrddif2= uicontrol('Parent',hs.minrddif,'Style','edit','String',num2str(p.detectDiscardOvelapMinRadDiff),'FontSize',10);
        hs.mincdif=uix.HBox('Parent', hs.DetecttabBox);
        hs.mincdif1= uicontrol('Parent',hs.mincdif,'Style','text','String','Min center distance (overlap) [pixel]','FontSize',10);
        hs.mincdif2= uicontrol('Parent',hs.mincdif,'Style','edit','String',num2str(p.detectDiscardOvelapMinCentDst),'FontSize',10);
        hs.mxovtot=uix.HBox('Parent', hs.DetecttabBox);
        hs.mxovtot1= uicontrol('Parent',hs.mxovtot,'Style','text','String','Max total overlap [proportion]','FontSize',10);
        hs.mxovtot2= uicontrol('Parent',hs.mxovtot,'Style','edit','String',num2str(p.detectMaxOverlapTotal),'FontSize',10);
        hs.stthre=uix.HBox('Parent', hs.DetecttabBox);
        hs.stthre1= uicontrol('Parent',hs.stthre,'Style','text','String','Start iterative overlap [proportion]','FontSize',10);
        hs.stthre2= uicontrol('Parent',hs.stthre,'Style','edit','String',num2str(p.detectMaxOverlapStartThresh),'FontSize',10);
        hs.mindistfin=uix.HBox('Parent', hs.DetecttabBox);
        hs.mindistfin1= uicontrol('Parent',hs.mindistfin,'Style','text','String','Final min center distance [pixel]','FontSize',10);
        hs.mindistfin2= uicontrol('Parent',hs.mindistfin,'Style','edit','String',num2str(p.detectMinCenterDistFinal),'FontSize',10);
        hs.Void=uix.Empty('Parent', hs.DetecttabBox);
        
        
        if strcmp(p.tappMode, 'um')
            thr1=p.tappThreshUm;
            if isempty(thr1)
                thr1=200;
            end
        else
            thr1=p.tappThreshPx;
        end
        
        %In the SI tab:
        %Additional possibilities
        hs.SIonly=uicontrol('Style', 'text','Parent',hs.SItabBox, 'String', {'Additional possibilities'},'FontSize',10, 'FontWeight','bold');
        hs.ApplyConversion=uix.HBox('Parent',hs.SItabBox);
        hs.ApplyConversion1=uicontrol('Parent',hs.ApplyConversion, 'String', 'Apply spatial calibration factor to all frames','FontSize',10, 'Callback', @ApplyConversion_Callback);
        hs.ApplyAA=uix.HBox('Parent',hs.SItabBox);
        hs.ApplyAA1=uicontrol('Parent',hs.ApplyAA, 'String', 'Apply area of interest to all frames','FontSize',10, 'Callback', @ApplyAA_Callback);
        hs.ApplyBoth=uix.HBox('Parent',hs.SItabBox);
        hs.ApplyBoth1=uicontrol('Parent',hs.ApplyBoth, 'String', 'Apply both to all frames','FontSize',10, 'Callback', @ApplyAA_Conversion_Callback);
        hs.RemoveMultiEP=uix.HBox('Parent',hs.SItabBox);
        hs.RemoveMultiEP1=uicontrol('Parent',hs.RemoveMultiEP, 'String', 'Remove linked & overlay folders','FontSize',10, 'Callback', @RemoveMultiEP_Callback);%add callback once it exists
        hs.Void=uix.Empty('Parent', hs.SItabBox);
        
        %In the timelapse tab:
        %Define parameters
        hs.DP2Strg=uicontrol('Style', 'text','Parent',hs.TimelapsetabBox, 'String', {'Define radii tracking parameters'},'FontSize',10, 'FontWeight','bold');
        hs.rF=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.rF1= uicontrol('Parent',hs.rF,'Style','text','String','Reference frame','FontSize',10);
        hs.rF2= uicontrol('Parent',hs.rF,'Style','edit','String',num2str(p.focalframe),'FontSize',10);
        hs.dT=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.dT1= uicontrol('Parent',hs.dT,'Style','text','String','Time interval [min]','FontSize',10);
        hs.dT2= uicontrol('Parent',hs.dT,'Style','edit','String',num2str(p.deltaTmin),'FontSize',10);
        hs.regfactor=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.regfactor1= uicontrol('Parent',hs.regfactor,'Style','text','String','Registration factor','FontSize',10);
        hs.regfactor2= uicontrol('Parent',hs.regfactor,'Style','edit','String',num2str(p.registrationFactor),'FontSize',10);
        hs.kymothresh=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.kym1= uicontrol('Parent',hs.kymothresh,'Style','text','String','Kymograph threshold shift','FontSize',10);
        hs.kym2= uicontrol('Parent',hs.kymothresh,'Style','edit','String',num2str(p.radKymoBias),'FontSize',10);
        hs.radolap=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.radolap1= uicontrol('Parent',hs.radolap,'Style','text','String','Scale radius for overlap','FontSize',10);
        hs.radolap2= uicontrol('Parent',hs.radolap,'Style','edit','String',num2str(p.radOverlapScale),'FontSize',10);
        hs.togglesTL=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.OverlapRem=uicontrol('Parent',hs.togglesTL, 'String','Overlap exclusion','Style','checkbox','Value', p.radOverlapRemoveTheta, 'FontSize',10,'Callback',@OlapRem_Callback);
        hs.EnhancedImage=uicontrol('Parent',hs.togglesTL, 'String','Use enhanced images','Style','checkbox','Value', p.radUseEnhancedImg, 'FontSize',10,'Callback',@TLimgenhance_Callback);
        hs.KymoMode=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.KymoModePanel=uibuttongroup('Parent',hs.KymoMode,'Title','Default kymograph processing','FontSize',10);
        hs.KymoMode1=uicontrol(hs.KymoModePanel,'Style','radiobutton','String','Global threshold','FontSize',10,'Units','normalized','Position',[.1 .2 .3 .7]);
        hs.KymoMode2=uicontrol(hs.KymoModePanel,'Style','radiobutton','String','Edge detection','FontSize',10, 'Units','normalized','Position',[.6 .2 .3 .7]);
        hs.Void=uix.Empty('Parent', hs.TimelapsetabBox);
        hs.TappStrgH=uicontrol('Style', 'text','Parent',hs.TimelapsetabBox, 'String', {'Define appearance time parameters'},'FontSize',10, 'FontWeight','bold');
        hs.tappModePanel=uibuttongroup('Parent',hs.TimelapsetabBox,'Title','Appearance time threshold mode','FontSize',10);
        hs.tappModeUm=uicontrol(hs.tappModePanel,'Style','radiobutton','String','Micrometer','FontSize',10,'Units','normalized','Position',[.1 .2 .3 .7]);
        hs.tappModePx=uicontrol(hs.tappModePanel,'Style','radiobutton','String','Pixel','FontSize',10, 'Units','normalized','Position',[.6 .2 .3 .7]);
        hs.DetThresh=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.DetThresh1= uicontrol('Parent',hs.DetThresh,'Style','text','String','Detection threshold radius','FontSize',10);
        hs.DetThresh2= uicontrol('Parent',hs.DetThresh,'Style','edit','String',num2str(thr1),'FontSize',10);
        hs.linfitframe=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.linfitframe1= uicontrol('Parent',hs.linfitframe,'Style','text','String','Number of frames for fit','FontSize',10);
        hs.linfitframe2= uicontrol('Parent',hs.linfitframe,'Style','edit','String',num2str(p.tappLengthLinFitFrame),'FontSize',10);
        hs.linfitsafety=uix.HBox('Parent', hs.TimelapsetabBox);
        hs.linfitsafety1= uicontrol('Parent',hs.linfitsafety,'Style','text','String','Number of frames continued R>Rthresh','FontSize',10);
        hs.linfitsafety2= uicontrol('Parent',hs.linfitsafety,'Style','edit','String',num2str(p.tappStayOverThresh),'FontSize',10);
        hs.Void=uix.Empty('Parent', hs.TimelapsetabBox);
        %Additional possibilities
        hs.Ap2Strg=uicontrol('Style', 'text','Parent',hs.TimelapsetabBox, 'String', {'Additional possibilities'},'FontSize',10, 'FontWeight','bold');
        hs.SubseTL=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.SubseTL1=uicontrol('Parent',hs.SubseTL, 'String', 'Process timelapse subset','FontSize',10, 'Callback', @SubsetTL_Callback);
        hs.channTL=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.channTL1=uicontrol('Parent',hs.channTL, 'String', 'Process alternate channel','FontSize',10, 'Callback', @altChannelTL_Callback);
        hs.CheckTLRadius=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.CheckTLRadius1=uicontrol('Parent',hs.CheckTLRadius, 'String', 'Manually process the timelapse','FontSize',10, 'Callback', @checkTL_Callback);
        hs.calckymo2=uicontrol('Parent',hs.TimelapsetabBox, 'String', 'Recalculate kymograph radius', 'Callback', @CalcRadKymo2_Callback,'FontSize',10);
        hs.SelDelRe=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.SelDelRe1=uicontrol('Parent',hs.SelDelRe, 'String', 'Select curves to delete','FontSize',10, 'Callback', @sel_and_del_callback);
        hs.SelDelRe2=uicontrol('Parent',hs.SelDelRe, 'String', 'Restore deleted curves','FontSize',10, 'Callback', @restore_callback);
        hs.resetregistration=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.resetregistration1=uicontrol('Parent',hs.resetregistration, 'String', 'Reset registration','FontSize',10, 'Callback', @ResetTLRegistration_Callback);
        hs.Failed=uix.HBox('Parent',hs.TimelapsetabBox);
        hs.Failed1=uicontrol('Parent',hs.Failed, 'String', 'Delete radius data of selected frames','FontSize',10, 'Callback', @FailedFrames_Callback);
        hs.Failed1=uicontrol('Parent',hs.Failed, 'String', 'Scale detected radius','FontSize',10, 'Callback', @CorrectRad_CallBack);
        
        %In the visualize tab:
        hs.DP3Strg=uicontrol('Style', 'text','Parent',hs.ResultstabBox, 'String', {'Define parameters'},'FontSize',10, 'FontWeight','bold');
        hs.SF=uix.HBox('Parent', hs.ResultstabBox);
        hs.SF1= uicontrol('Parent',hs.SF,'Style','text','String','Smoothing Factor','FontSize',10);
        hs.SF2= uicontrol('Parent',hs.SF,'Style','edit','String',num2str(p.smoothFrames),'FontSize',10);
        hs.PT=uix.HBox('Parent', hs.ResultstabBox);
        hs.PT1= uicontrol('Parent',hs.PT,'Style','text','String','Plot units','FontSize',10);
        hs.PT2 = uicontrol('Parent',hs.PT,'Style', 'popup','String', {'pxl vs frame','mu vs hours','log(mu) vs hours','all'},'FontSize',10);
        set(hs.PT2,'Value',p.plotUnit);
        hs.rT=uix.HBox('Parent', hs.ResultstabBox);
        hs.rT1= uicontrol('Parent',hs.rT,'Style','text','String','Raw Title','FontSize',10);
        hs.rT2= uicontrol('Parent',hs.rT,'Style','edit','String',p.rawTitle,'FontSize',10);
        hs.sT=uix.HBox('Parent', hs.ResultstabBox);
        hs.sT1= uicontrol('Parent',hs.sT,'Style','text','String','Smooth Title','FontSize',10);
        hs.sT2= uicontrol('Parent',hs.sT,'Style','edit','String',p.smoothTitle,'FontSize',10);
        hs.lT=uix.HBox('Parent', hs.ResultstabBox);
        hs.lT1= uicontrol('Parent',hs.lT,'Style','text','String','Log Title','FontSize',10);
        hs.lT2= uicontrol('Parent',hs.lT,'Style','edit','String',p.logTitle,'FontSize',10);
        hs.HistNum=uix.HBox('Parent', hs.ResultstabBox);
        hs.HistNum1= uicontrol('Parent',hs.HistNum,'Style','text','String','Number of histogram bins','FontSize',10);
        hs.HistNum2= uicontrol('Parent',hs.HistNum,'Style','edit','String',p.histbins,'FontSize',10);
        hs.Void=uix.Empty('Parent', hs.ResultstabBox);
        hs.tosave=uix.HBox('Parent', hs.lower);
        hs.cancel= uicontrol('Parent', hs.tosave, 'String', 'Cancel','Callback', @cancel_options_Callback);
        hs.save= uicontrol('Parent', hs.tosave, 'String', 'Save','Callback', @save_options_Callback);
        
        hs.options.Heights=[-450, -40];
        hs.GlobaltabBox.Heights=[25 25 25 25 25 25 25 25 25 25 25 40 25 25 25 25 25 25];
        hs.SItabBox.Heights=[25 25 25 25 25 25];
        hs.DetecttabBox.Heights=repmat(25, length(hs.DetecttabBox.Heights),1);
        hs.TimelapsetabBox.Heights=[25 25 25 25 25 25 25 50 25 25 50 25 25 25 25 25 25 25 25 25 25 25 25];
        hs.ResultstabBox.Heights=[25 25 25 25 25 25 25 25];
        
        if p.radDefaultKymoMode==1
            hs.KymoMode1.Value=1;
            hs.KymoMode2.Value=0;
        else
            hs.KymoMode1.Value=0;
            hs.KymoMode2.Value=1;
        end
        
        if strcmp(p.tappMode, 'um')
            hs.tappModeUm.Value=1;
            hs.tappModePx.Value=0;
        else
            hs.tappModeUm.Value=0;
            hs.tappModePx.Value=1;
        end
        
        
        if strcmp(p.tappRefMode, 'mean')
            hs.refmodemean.Value=1;
            hs.refmodequantile.Value=0;
        else
            hs.refmodemean.Value=0;
            hs.refmodequantile.Value=1;
        end
        
        
        if strcmp(p.operatingMode, 'single')
            hs.Timelapsetab.Parent=[];
        elseif strcmp(p.operatingMode, 'TL')
            hs.SItab.Parent=[];
        end
        while ishandle(hs.o)
            pause(0.01)
        end
        disableGUI(0);
    end
    function cancel_options_Callback(~,~)
        p=restore1;
        close_options_Callback;
    end%discard changes
    function close_options_Callback (~,~)
        restore1=struct();
        if ishandle(hs.o)
            close(hs.o);
        end
        axes(hs.fig);
        set(hs.EnhanceImage2, 'Value', Fvar.imgenhanced);
        set(hs.EnhanceImage, 'Value', Fvar.imgenhanced2);
        disableGUI(0);
        refresh(0);
    end%close options
    function save_options_Callback (~,~)
        %Check values are correct and update them
        %In detect
        p.detectBinarizationMethod=hs.IMGp2.Value;
        p.detectCircleMode=hs.circlemode2.Value;
        if p.imgMethod~=hs.grayopt2.Value
            Fvar.background=[];
            Fvar.imgenhanced=0;
            p.imgMethod=hs.grayopt2.Value;
            p.iold=0; %in order to ensure that image is reloaded and calculated
        elseif p.i==p.iold
            p.iold=p.i;
        end
        
        
        test=str2double(hs.S2.String);
        if isempty(test)||sum(test<=0)||sum(isnan(test))||length(test)>1
            errordlg('Error in setting the sensitivity. Changes to this parameter not stored');
        else
            p.detectSensitivity=test;
        end
        test=str2double(hs.binsens2.String);
        if isempty(test)||sum(test<=0)||sum(isnan(test))||length(test)>1||test<0||test>1
            errordlg('Error in setting the binarization sensitivty. Changes to this parameter not stored');
        else
            p.detectBinarizeSensitivity=test;
        end
        test=str2double(hs.MR2.String);
        if isempty(test)||sum(test<=4)||sum(isnan(test))||length(test)>1|| mod(test,1)
            errordlg('Error in setting the minimal radius. Changes to this parameter not stored');
        else
            p.detectMinRadPx=test;
        end
        test=str2double(hs.MXR2.String);
        if isempty(test)||sum(isnan(test))||length(test)>1|| mod(test,1)
            errordlg('Error in setting the maximal radius. Changes to this parameter not stored');
        else
            p.detectMaxRadPx=test;
        end
        %In timelapse
        
        
        if strcmp(p.operatingMode, 'TL')
            test=str2double(hs.rF2.String);
            if isempty(test)||sum(test<=0)||sum(test>=length(p.l)+1)||sum(isnan(test))||length(test)>1|| mod(test,1)
                errordlg('Error in setting the reference frame. Changes to this parameter not stored');
            else
                p.focalframe=test;
            end
        end
        
        test=str2double(hs.dT2.String);
        if isempty(test)||sum(test<=0)||sum(isnan(test))||length(test)>1
            errordlg('Error in setting the delta T. Changes to this parameter not stored');
        else
            p.deltaTmin=test;
        end
        
        %In results
        test=round(str2double(hs.SF2.String));
        if isempty(test)||sum(test<=0)||sum(isnan(test))||length(test)>1
            errordlg('Error in setting the smoothing factor. Changes to this parameter not stored');
        else
            p.smoothFrames=test;
        end
        
        test=str2double(hs.HistNum2.String);
        if isempty(test)||sum(test<8)||sum(isnan(test))||length(test)>1 ||sum(test>100)
            errordlg('Error in setting the number of histogram bins (min is 8, max is 100). Changes to this parameter not stored');
        else
            p.histbins=round(test);
        end
        
        p.rawTitle=hs.rT2.String;
        p.smoothTitle=hs.sT2.String;
        p.logTitle=hs.lT2.String;
        p.plotUnit=hs.PT2.Value;
        
        if strcmp(hs.KymoModePanel.SelectedObject.String,'Global threshold')
            p.radDefaultKymoMode=1;
        else
            p.radDefaultKymoMode=2;
        end
        
        if strcmp(hs.tappModePanel.SelectedObject.String,'Micrometer')
            p.tappMode='um';
        else
            p.tappMode='px';
        end
        
        if strcmp(hs.refmodepanel.SelectedObject.String,'Mean')
            p.tappRefMode='mean';
        else
            p.tappRefMode='quantile';
        end
        
        if strcmp(p.operatingMode, 'TL')
            test=round(str2double(hs.linfitframe2.String));
            if isempty(test)||sum(test<5)||sum(isnan(test))||length(test)>1
                errordlg('Error in setting the number of frames for the linear fit (min is 5). Changes not stored');
            else
                p.tappLengthLinFitFrame=test;
            end
            
            test=round(str2double(hs.linfitsafety2.String));
            if isempty(test)||sum(test<0)||sum(isnan(test))||length(test)>1
                errordlg('Error in setting the number of frames for continuous R>Rthresh for the linear fit (min is 0). Changes not stored');
            else
                p.tappStayOverThresh=test;
            end
        end
        
        if strcmp(p.operatingMode, 'TL')
            test=str2double(hs.DetThresh2.String);
            if isempty(test)||sum(test<1)||sum(isnan(test))||length(test)>1
                errordlg('Error in setting the detection threshold. Changes not stored');
            else
                if strcmp(p.tappMode, 'um')
                    p.tappThreshUm=test;
                else
                    p.tappThreshPx=test;
                end
            end
        end
        
        test=str2double(hs.radolap2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0.001||test>10
            errordlg(['Error in setting the scaling factor for overlap detection. Choose a value in the range of',...
                ' [0.001, 10]. Changes to this parameter not stored']);
        else
            p.radOverlapScale=test;
        end
        
        test=str2double(hs.kym2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1
            errordlg('Error in setting the Kymograph threshold shift. Changes to this parameter not stored');
        else
            if test~=p.radKymoBias
                quest=questdlg('The kymograph threshold changed. Do you want to recalculate radius for all colonies?',...
                    'Kymograph threshold', 'Yes', 'No, but store value change','No, delete value change', 'Yes');
                
                switch quest
                    case 'Yes'
                        p.radKymoBias=test;
                        p.AutoThresh=0;
                        hs.UserMess.String='Recalculation of radius started, please wait...';customdrawnow
                        CalcRadKymo2;
                        hs.UserMess.String='Recalculation of radius finished';customdrawnow
                    case 'No, but store value change'
                        p.radKymoBias=test;
                    case 'No, delete value change'
                    case ''
                        
                end
                
            end
            
        end
        
        test=str2double(hs.bxsc2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0.1||test>3
            errordlg(['Error in setting the scaling factor for bounding box. Choose a value in the range of',...
                ' [0.1, 3]. Changes to this parameter not stored']);
        else
            p.detectBoundingBoxScale=test;
        end
        
        test=str2double(hs.mndst2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1000
            errordlg(['Error in setting min distance from border. Choose a value in the range of',...
                ' [0, 1000]. Changes to this parameter not stored']);
        else
            p.detectMinBorderDist=test;
        end
        
        test=str2double(hs.fbias2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||abs(test)>1
            errordlg(['Error in setting the foreground bias value. Choose a value in the range of',...
                ' [-1, 1]. Changes to this parameter not stored']);
        else
            p.detectForegroundBias=test;
        end
        
        test=str2double(hs.fmin2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1
            errordlg(['Error in setting min proportion of foreground within circle. Choose a value in the range of',...
                ' [0, 1]. Changes to this parameter not stored']);
        else
            p.detectMinForground=test;
        end
        
        test=str2double(hs.mxov2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1
            errordlg(['Error in setting max overlap proportion comparing 2 circles. Choose a value in the range of',...
                ' [0, 1]. Changes to this parameter not stored']);
        else
            p.detectMaxOverlapCompare=test;
        end
        
        test=str2double(hs.minrddif2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1000
            errordlg(['Error in setting min radius difference comparing 2 circles. Choose a value in the range of',...
                ' [0, 1000]. Changes to this parameter not stored']);
        else
            p.detectDiscardOvelapMinRadDiff=test;
        end
        
        test=str2double(hs.mincdif2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1000
            errordlg(['Error in setting min center distance comparing 2 circles. Choose a value in the range of',...
                ' [0, 1000]. Changes to this parameter not stored']);
        else
            p.detectDiscardOvelapMinCentDst=test;
        end
        
        test=str2double(hs.mxovtot2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1
            errordlg(['Error in setting total max overlap area of a circle. Choose a value in the range of',...
                ' [0, 1]. Changes to this parameter not stored']);
        else
            p.detectMaxOverlapTotal=test;
        end
        
        test=str2double(hs.stthre2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1
            errordlg(['Error in setting start value of iterative thresholding on max overlap area of a circle. Choose a value in the range of',...
                ' [0, 1]. Changes to this parameter not stored']);
        else
            p.detectMaxOverlapStartThresh=test;
        end
        
        test=str2double(hs.mindistfin2.String);
        if isempty(test)||sum(isnan(test))>0||length(test)>1||test<0||test>1000
            errordlg(['Error in setting final minimal center distance. Choose a value in the range of',...
                ' [0, 1000]. Changes to this parameter not stored']);
        else
            p.detectMinCenterDistFinal=test;
        end
        
        
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        %Close a refresh
        close_options_Callback;
    end %save changes
% Global tab
    function SetImgMethod_Callback(~,~)
        if strcmp(p.imgFormat,'grey')
            waitfor(msgbox('The loaded images are in greyscale. No conversion needed.')); return
        end
        save_options_Callback;
        %let user choose which of the atm 16 image transformation to use for the TL analysis
        %this helps dealing with various kinds of plate and colony colors and image
        %quality. Maybe you have an idea how to define which method is the best automatically.
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        
        
        %find the col centers
        
        %ask for which frame and colony the examples should be shown
        prompt = {'For which colony do you want to see examples to choose which method to use?',...
            [newline,newline,'From which frame do you want to see examples?']};
        defCol=1;
        correct=0;%turns to 1 if every input was correct
        p.abortParent=1;
        p.UserColNb=defCol;
        while ~correct
            dlg_title = 'Frame and Colony'; num_lines = 1;
            defaultans = {num2str(defCol),num2str(p.i)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer); return; end %user cancelled
            
            %first store the value in a "temporary" file
            p.UserColNb=round(str2double(answer{1})); %user input
            %do some checks if the input was in a sensible way, if not give
            %error and lets user to repeat
            if sum(p.UserColNb<=0) || isempty(p.UserColNb) || sum(isnan(p.UserColNb))
                waitfor(errordlg('The input for the colony was in a wrong format. Also, only 1 colony possible. Try again.'));p.UserColNb=0; continue;
            end
            
            %then save the colonies list into the p.colList. if the input was
            %0, add all colonies to the list
            if sum(p.UserColNb==0)>=1 % contains a zero: over all colonies
                p.colList=1:size(p.colonyCenRad{p.focalframe,2},1); %over all colonies
            elseif size(p.UserColNb,2)>=1 %user input more than one colony
                p.colList=p.UserColNb;
            else
                waitfor(errordlg('The input for the colonies was in a wrong format. Try again.'));p.UserColNb=0; continue;
            end
            if sum(p.UserColNb<0) || sum(isnan(p.UserColNb))
                waitfor(errordlg('The input for the colonies was in a wrong format. Try again.'));p.UserColNb=0; continue;
            end
            p.colList=unique(sort(p.colList));
            
            startT=str2double(answer{2});
            if sum(startT<1) || sum(isnan(startT)) || isempty(startT) || length(startT)>1 || mod(startT,1)
                waitfor(errordlg('The input for the frame was in a wrong format. Try again.'));continue
            else
                correct=1;
            end
            timeList2=startT;
        end
        p.timeList=fliplr(timeList2);%all frames list
        p.abortParent=0;
        
        if p.abortParent
            return
        end
        p.i=p.timeList;
        
        if isempty(p.colonyCenRad{p.i,1})
            errordlg('There are no colonies on the chosen frame. Please detect colonies or specify other frame');return;
        end
        
        if length(p.colList)>1
            p.colList=randsample(p.colList,1);
        end
        
        if p.colList>size((p.colonyCenRad{p.i,1}),1)
            p.colList=randsample(1:size((p.colonyCenRad{p.i,1})),1);
        end
        
        img = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
        hs.UserMess.String='Image examples are calculated. Please wait..';customdrawnow
        disableGUI(1);%disable the GUI
        for whichCol=p.colList
            center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
            
            Zone=ZoneDef(center,whichCol,img,p.i);
            try
                rgbcol=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:);
            catch
                waitfor(errordlg(['Something is wrong with  colony ', num2str(whichCol), '...']));
                continue
            end
            
            s=cell(15,1);
            a=cell(15,1);
            
            %calculate all image examples contained in s struct are the
            %images and in a the names
            s{1}=mat2gray(rgbcol(:,:,1));
            s{2}=mat2gray(rgbcol(:,:,2));
            s{3}=mat2gray(rgbcol(:,:,3));
            a{1}='RGB, R channel';
            a{2}='RGB, G channel';
            a{3}='RGB, B channel';
            
            labT=rgb2lab(rgbcol);
            s{4}=mat2gray(labT(:,:,1));
            s{5}=mat2gray(imcomplement(labT(:,:,2)));
            s{6}=mat2gray(imcomplement(labT(:,:,3)));
            a{4}='Lab, L channel';
            a{5}='Lab, a channel';
            a{6}='Lab, b channel';
            
            nts=rgb2ntsc(rgbcol);
            s{7}=mat2gray(nts(:,:,1));
            s{8}=mat2gray(imcomplement(nts(:,:,2)));
            s{9}=mat2gray(imcomplement(nts(:,:,3)));
            a{7}='YIQ, Y channel';
            a{8}='YIQ, I channel';
            a{9}='YIQ, Q channel';
            
            cie=rgb2xyz(rgbcol);
            s{10}=mat2gray(cie(:,:,1));
            s{11}=mat2gray(cie(:,:,2));
            s{12}=mat2gray(cie(:,:,3));
            a{10}='CIE, X channel';
            a{11}='CIE, Y channel';
            a{12}='CIE, Z channel';
            
            ycbcr = rgb2ycbcr(rgbcol);
            s{13}=mat2gray(ycbcr(:,:,1));
            s{14}=mat2gray(imcomplement(ycbcr(:,:,2)));
            s{15}=mat2gray(imcomplement(ycbcr(:,:,3)));
            a{13}='YCbCr, Y channel';
            a{14}='YCbCr, Cb channel';
            a{15}='YCbCr, Cr channel';
            
            s{16}=mat2gray(rgb2gray(rgbcol));
            a{16}='RGB to grayscale';
            
            
            %open fullscreen new figure
            fig=figure('units','normalized','outerposition',[0 0 1*Fvar.figscale 1]); impos=1;
            
            %go over all 15 methods, display image and the mean Zinterp
            %curve
            for xii=1:16
                subplot(6,3,impos);
                imshow(s{xii});  %axis square %#ok<*UNRCH>
                title(['Opt. ',num2str(xii) ,a(xii)]);
                impos=impos+1;
                ax = gca;
                ax.Toolbar.Visible = 'off';
            end
            
            %done, ask user which method he wants
            prompt = {'Insert number of method you want to use'};
            dlg_title = 'Image transformation method'; num_lines = 1;
            defaultans = {num2str(p.imgMethod)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer)
                close(fig); axes(hs.fig);refresh(1); %#ok<LAXES>
                hs.UserMess.String=['Image method set to previous Nr. ',num2str(p.imgMethod)];
                return;
            end  %user cancelled
            
            %repeat question until input was valid...
            while isnan(str2double(answer{1,1})) || round(str2double(answer{1,1}))<1||...
                    round(str2double(answer{1,1}))>16 || length(round(str2double(answer{1,1})))>1
                errordlg('The input was not a number or was out of the possible range. Try again');
                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            end %the list doesn't exist
            
            %save the answer
            p.imgMethod=round(str2double(answer{1,1}));
            
            close(fig); axes(hs.fig);refresh(1); %#ok<LAXES>
            hs.UserMess.String=['Image method set to Nr. ',num2str(p.imgMethod)];
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        Fvar.background=[];
        Fvar.imgenhanced=0;
        disableGUI(0);%disable the GUI
    end %set rgb2grey method with examples
    function BWCheckboxchange_Callback(~,~)
        p.showGrayscale=~p.showGrayscale;%toggle
        p.col2grayrun=0;
        p.iold=0;
        if p.showGrayscale
            p.showNrCol='r';
        else
            p.showNrCol='k';
            Fvar.imgenhanced2=0;
            Fvar.imgenhanced=0;
        end
    end %grayscale checkbox
    function ShowColCheckboxchange_Callback(~,~)
        p.ShowCol=~p.ShowCol; %toggle
    end %colony circle checkbox
    function ShowNrCheckboxchange_Callback(~,~)
        p.showNr=~p.showNr; %toggle
    end %colony nr checkbox
    function ShowVoronoiAreasCheckboxchange_Callback(~,~)
        p.ShowVoronoiAreas=~p.ShowVoronoiAreas; %toggle
        if p.ShowVoronoiAreas && isempty(p.VoronoiAreas)
            Voronoi_Callback
        elseif ~p.ShowVoronoiAreas
            try
                delete(Fvar.voroThandle)
            catch
            end
        end
    end %voronoi area value checkbox
    function ShowVoronoiEdgesCheckboxchange_Callback(~,~)
        p.ShowVoronoiEdges=~p.ShowVoronoiEdges; %toggle
        if p.ShowVoronoiEdges && isempty(p.VoronoiAreas)
            Voronoi_Callback
        elseif ~p.ShowVoronoiEdges
            try
                delete(Fvar.voroAhandle)
            catch
            end
        end
    end %voronoi edge checkbox
    function vAACheckboxchange_Callback(~,~)
        p.showROI=~p.showROI; %toggle
    end %AOI display checkbox
    function ReEnhanceImage_Callback(~,~)
        Fvar.background=[];
        Fvar.rgb = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
        hs.EnhanceImage2.Value=0;
        close_options_Callback
        EnhanceImage2_Callback
        hs.EnhanceImage2.Value=1;
    end %redefine area for enhance lighting
    function disableSave_Callback(~,~)
        %just update the p.disableSave and the string on the button
        p.disableSave=~p.disableSave;
    end %disable save checkbox
    function switchbackup_Callback(~,~)
        p.savebackups=~p.savebackups;
    end %disable backup save checkbox
    function ResetUserList_Callback(~,~)
        if ~isnan(activeList) %the active list is a userlist
            close_options_Callback;
            chngList(-activeList,p.i,zeros(length(p.colonyCenRad{p.i,2}),1));
            hs.UserMess.String=['User-List ',num2str(activeList),' was emptied'];customdrawnow
        else
            hs.UserMess.String='no list is active';customdrawnow
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
    end %reset active list
% Detect tab
    function BlackColonyCheckboxchange_Callback(~,~)
        p.BlackColony=~p.BlackColony;%toggle
    end %switch to darker colonies than background
% Main-EP
    function ApplyConversion_Callback(~,~)
        save_options_Callback;
        if isnan(p.umConversion(p.i))
            errordlg('Please first set spatial calibration factor on the current frame');return;
        else
            p.umConversion(:)=p.umConversion(p.i);
        end
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        hs.UserMess.String='Spatial calibration applied to all frames';customdrawnow
        refresh(0);
    end %apply spatial calibration to all frames
    function ApplyAA_Callback(~,~)
        if ishandle(hs.o)
            save_options_Callback;
        end
        if isempty(p.roiType(p.i))
            errordlg('Please first delimit the area of analysis on the current frame');return;
        else
            p.roiType(:)=p.roiType(p.i);
            if p.roiType(p.i)==1 && ~isempty(p.roiPlateRad(p.i)) && ~isnan(p.roiPlateRad(p.i))
                for j=1:length(p.l)
                    p.roiPlateRad(j)=p.roiPlateRad(p.i);
                    p.roiPlateCenter(j,:)=p.roiPlateCenter(p.i,:);
                end
            end
            if p.roiType(p.i)==2 && ~isempty(p.roiPolygonImg{p.i})
                for j=1:length(p.l)
                    p.roiPolygonImg{j}=p.roiPolygonImg{p.i};
                end
            end
        end
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        hs.UserMess.String='AOI applied to all frames';customdrawnow
        refresh(0);
    end %apply AOI to all frames
    function ApplyAA_Conversion_Callback(~,~)
        ApplyConversion_Callback;
        ApplyAA_Callback;
        hs.UserMess.String='Spatial calibration and AOI applied to all frames';customdrawnow
    end %apply spatial calibration and AOI to all frames
    function RemoveMultiEP_Callback(~,~)
        for i=1:length(p.multiEPdirs)
            try
                p=rmfield(p, ['counts',num2str(i)]);
                p=rmfield(p, ['umConversion',num2str(i)]);
                p=rmfield(p, ['l',num2str(i)]);
            catch
                continue
            end
        end
        
        p.multiEPdirs=[];
        p.multiEPdirsShort=[];
        p.multiEPdirs={p.dirS};
        
        p.dirOverlay=[];
        p.overlayIMGstatus=0;
        try, close_options_Callback; catch;end %#ok<NOCOMMA>
        
        set(hs.overlay,'Value',0);
        setoverlayfolders;
        
        set(hs.showmultiEP, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        set(hs.plot, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        set(hs.GRmultiEP, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0)
    end %remove all linked folders
% Main-TL
    function OlapRem_Callback(~,~)
        p.radOverlapRemoveTheta=~p.radOverlapRemoveTheta;
    end %overlap tickbox
    function TLimgenhance_Callback(~,~)
        if ~strcmp(p.imgFormat, 'rgb')
            p.radUseEnhancedImg=~p.radUseEnhancedImg;
        else
            p.radUseEnhancedImg=0;
        end
    end %use enhanced images
    function SubsetTL_Callback(~,~)
        save_options_Callback;
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        
        %the following call is to get the centers of the colonies
        if isempty(p.focalframe) || p.focalframe==0 %user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=length(p.l);
            if isempty(p.colonyCenRad{p.focalframe,1})
                errordlg('Set the frame to the one where you detected colonies for a reference or define it with the button and try again');return;
            end
        end
        prompt = {'Indicate which colonies should be analysed, seperated by space. 0 for all colonies; -1 for User-List.',...
            [newline,newline,'Which frames do you want to process?',newline, 'Starting frame:'], 'Stepsize:', 'Ending frame:'};
        GetColAndTime(prompt, 0, 1);
        if p.abortParent
            return
        end
        
        if p.nChannel>1
            question1=questdlg(['Run timelapse analysis for all ', num2str(p.nChannel),' channels?'],...
                'multichannel TL','All','Only channel 1','Cancel','All');

            prompt = 'Which channel to process? Enter 0 for all or seperated by space';
            dlg_title = 'Timelapse channel for subset'; num_lines = 1;
            defaultans = {num2str(0)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer); return; end %user cancelled
            channlist=round(str2num(answer{1})); %#ok<ST2NM> %user input
            for nchi = channlist
                p.channelprocessing = nchi;
                StartTL;%function call for the start
            end
        else
            p.channelprocessing = 1;
            StartTL;%function call for the start
        end
    end%let user specify which col and which frames
    function altChannelTL_Callback(~,~)
        save_options_Callback;
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        
        %the following call is to get the centers of the colonies
        if isempty(p.focalframe) || p.focalframe==0 %user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=length(p.l);
            if isempty(p.colonyCenRad{p.focalframe,1})
                errordlg('Set the frame to the one where you detected colonies for a reference or define it with the button and try again');return;
            end
        end
        if p.nChannel<2
            errordlg('This option is only valid for multichannel images');return;
        end
        
        chanchoose = {};
        for chi = 2:p.nChannel
            chpat = [p.channelPrefix, num2str(chi)];
            chanchoose{chi-1} = chpat;
        end
        if length(chanchoose)>1
            [idx, tf] = listdlg('ListString', chanchoose,...
                'SelectionMode', 'Single', 'PromptString', 'Select channel to process', 'Initialvalue', 1,'Name', '');
            
            if tf
                p.channelprocessing = str2double(extract(chanchoose{idx}, digitsPattern));
                
            else
                return % user canceled or closed dialog
            end
        else
            p.channelprocessing = str2double(extract(chanchoose{1}, digitsPattern));
        end
        %start the callback
        StartTL;
    end
    function checkTL_Callback(~,~)
        Fvar.clickdisable=1;
        %This function is here for manual checking of the timelapse. Colonies to
        %check as well frames to check can be chosen. There is also the possibility
        % to only check not every frame eg 1:2:250 for every other frame. The not
        % checked frames are replaced by nan
        save_options_Callback;
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        if isempty(p.RadMean);errordlg('Run Time Lapse before'); return; end
        if strcmp(p.operatingMode, 'single')
            errordlg('This function is only intended for timelapse series.'); return
        end
        
        curf=p.i;
        if isempty(p.focalframe)%user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=length(p.l);
            if isempty(p.colonyCenRad{p.focalframe,1})
                errordlg('Set the frame to the one where you detected colonies for a reference and try again');return;
            end
        end
        
        hs.UserMess.String='starting correction process...';customdrawnow
        
        prompt = {'Indicate which colonies should be checked, seperated by space. If all colonies, insert 0.',...
            [newline,newline,'Which frames do you want to check?',newline, 'Starting frame:'],...
            'Stepsize (warning: if set to higher values than 1, radius for selected colonies in between selected frames will be set to NaN):',...
            'Ending frame:'};
        GetColAndTime(prompt, 0, p.i);
        if p.abortParent
            return
        end
        
        imgMethodBck=p.imgMethod;
        if strcmp(p.imgFormat, 'rgb')
            ColOrGray=questdlg('Do want to see images in color or in grayscale (with the transformation method defined for the timelapse)?',...
                'Color or grayscale', 'Color', 'Grayscale', 'Color');
            switch ColOrGray
                case 'Color'
                    %                 ImgMethod=p.imgMethod; %for backup
                    p.imgMethod=0;
                case 'Grayscale'
                    %use the existing method
                    %                 p.imgMethod=p.imgMethod;
                case ''
                    return
            end
        else
            p.imgMethod=0;
        end
        
        p.showNr=0; p.showGrayscale=0; p.ShowCol=0;Fvar.showImage=0; Fvar.TLrunning=1;
        
        %         if p.i==1
        %             set_frame(p.i+1);
        %         end
        
        set_frame(p.focalframe);
        
        tic
        
        makeUndo(1); %saving for undo purposes
        
        tic
        imgIndx=1;
        alldone=0;
        disableGUI(1);%disable the GUI
        for whichTime=p.timeList %over all frames
            
            clear img;
            delete(hs.fig); %otherwise staking up images, and memory leak
            hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
            set(hs.fig, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %creating axes in it
            %             refresh(0);%needed to update the frame
            
            p.i=whichTime;
            hs.UserMessFrame.String=['frame ',num2str(p.i), ' of ', num2str(length(p.l))];
            if ~sum(p.timeList==p.i)%if next frame is not one to be corrected, set to nan
                %                     p.RadMean(whichCol,p.i)=nan;
                continue
            end
            
            indx=1;%count for progress bar
            
            img = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
            AllCol=length(p.colList);
            for whichCol=p.colList%for which colonies
                
                hs.UserMess.String=['Colony Nr. ',num2str(whichCol), ', Radius = ', num2str(round(p.RadMean(whichCol,p.i))), 'px'];customdrawnow
                axes(hs.fig); %#ok<LAXES>
                
                rgbcolG=getSmallImage(whichCol, img);%call to get the small image displaying only the colony in grayscale.
                M=double(rgbcolG);   %convert to double for calculation
                
                
                X0=size(M,1)/2; Y0=size(M,2)/2;%center of the image shown
                
                axes(hs.fig); set(hs.fig, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %#ok<LAXES> %creating axes in it
                imshow(rgbcolG) ; axis square %#ok<*UNRCH>
                ax = gca;
                ax.Toolbar.Visible = 'off';
                hold on
                viscircles([X0,Y0],p.RadMean(whichCol,p.i),'Color','r'); %show the circle of the colony
                
                scatter(X0,Y0,500,'+');hold off;%add the center as +
                
                %now, decide if it is correct, need to corrected or if all
                %following frames are set to zero.
                
                choice = questdlg('Is the radius correct?', 'Colony Radius','Yes','No. Correct here','Set zero','Yes');
                
                % Handle response
                switch choice
                    case 'Yes'%nothing needs to be done. If it was rad=0, set all following to 0 and remove that col from list
                        if p.RadMean(whichCol,p.i)==0
                            p.RadMean(whichCol,1:p.i)=0;%update the current Radius
                            p.colList(p.colList==whichCol)=[];
                            
                            if isempty(p.colList)
                                saveall(p.dirS);
                                delete(hs.fig); %otherwise staking up images, and memory leak
                                hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
                                set(hs.fig, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %creating axes in it
                                p.ShowCol=1; p.showGrayscale=0; p.showNr=1;Fvar.TLrunning=0;
                                previous_Callback;
                                p.imgMethod=imgMethodBck;
                                delete(hs.Progress2)
                                delete(hs.Progress1)
                                hs.Progress1=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                                hs.Progress2=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                                hs.UserMess.String='Finished radius correction';customdrawnow
                                
                                alldone=1;
                                break;
                            end
                        end
                    case 'No. Correct here'
                        % instructions to users
                        hs.UserMess.String='click to place center, drag radius and click again to save';customdrawnow
                        
                        %get colony center
                        if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale && ~Fvar.imgenhanced && p.imgMethod==0
                            [X1, Y1] = ginput(1);
                        else
                            [X1, Y1] =  ginputCustom(1);
                        end
                        hold on;
                        h = plot(X1, Y1, 'b');
                        %get radius from a second click
                        set(gcf, 'WindowButtonMotionFcn', {@mousemove, h, [X1 Y1]}); %to have an updating circle
                        k = waitforbuttonpress;
                        set(gcf, 'WindowButtonMotionFcn', ''); %unlock the graph
                        r = norm([h.XData(1) - X1 h.YData(1) - Y1]); %circle coordinates are in h object
                        hold off
                        
                        p.RadMean(whichCol,p.i)=r;%update the current Radius
                        
                        %assuming that the radius does not change much
                        %in one step, also set the radius on the
                        %following frame to the same value. This
                        %reduces work the user has to do. But maybe you
                        %decide to remove this option
                        if p.i~=1
                            p.RadMean(whichCol,p.i-1)=r;%update the current Radius
                        end
                        
                        
                    case 'Set zero'
                        %set all frames from 1 to p.i to the zero value
                        p.RadMean(whichCol,1:p.i)=0;%update the current Radius
                        p.colList(p.colList==whichCol)=[];
                        
                        if isempty(p.colList)
                            saveall(p.dirS);
                            delete(hs.fig); %otherwise staking up images, and memory leak
                            hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
                            set(hs.fig, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %creating axes in it
                            p.ShowCol=1; p.showGrayscale=0; p.showNr=1;Fvar.TLrunning=0;
                            previous_Callback;
                            delete(hs.Progress2)
                            delete(hs.Progress1)
                            hs.Progress1=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                            hs.Progress2=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                            p.imgMethod=imgMethodBck;
                            hs.UserMess.String='Finished radius correction';customdrawnow
                            %                                 p.imgMethod=ImgMethod;
                            alldone=1;
                            break;
                        end
                        
                    case ''
                        saveall(p.dirS);
                        delete(hs.fig); %otherwise staking up images, and memory leak
                        hs.fig=axes('Parent', hs.FigPan, 'Color', [0.9 0.9 0.8], 'Position', [0 0 1 1]); %creating axes
                        set(hs.fig, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]); %creating axes in it
                        
                        %                  refresh(0)
                        delete(hs.Progress2)
                        delete(hs.Progress1)
                        hs.Progress1=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                        hs.Progress2=axes('Parent', hs.UserMessage, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                        hs.UserMess.String='';
                        p.imgMethod=imgMethodBck;
                        hs.UserMess.String='Aborted radius correction';customdrawnow
                        p.imgMethod=imgMethodBck;
                        % axes(hs.Progress2); fill([0 0 1 1],[0,1,1,0],[0.5 0.7 0.8]); set(hs.Progress2,'Xlim',[0 1],'Ylim',[0 1],'Xcolor','none','Ycolor','none'); customdrawnow
                        alldone=1;
                        break;
                end
                
                
                
                %if all col set to zero, break out of the loop
                
                
                %progress bar
                a=(indx/AllCol);
                axes(hs.Progress2); fill([0 0 a a],[0,1,1,0],[0.5 0.7 0.8]); set(hs.Progress2,'Xlim',[0 1],'Ylim',[0 1],'Xcolor','none','Ycolor','none'); customdrawnow %#ok<LAXES>
                text(0.25, 0.5, ['analysed ' num2str(indx) ' of ' num2str(AllCol) ' colonies'],'Fontsize', 10);
                indx=indx+1;
                saveall(p.dirS);
                %break loop if all are set to zero
                
            end
            if alldone; break; end
            %progress bar
            a=floor(100*(1-((whichTime-(p.timeList(1)-p.timeList(2)))/(length(p.timeList)))));
            textMsg=([num2str(floor(a)),'% done, est. ' sec2timestr((100*toc/a-toc)), ' remaining']);
            axes(hs.Progress1); fill([0 0 a/100 a/100],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow %#ok<LAXES>
            text(0.25, 0.5, ['Frame ',num2str(imgIndx),' of ' num2str(length(p.timeList)),' analysed'],'Fontsize', 10);
            hs.UserMess.String=textMsg;
            imgIndx=imgIndx+1;
            %             p.imgMethod=ImgMethod;
            
        end
        %and restore the normal image
        
        p.ShowCol=1; p.showGrayscale=0; p.showNr=1;Fvar.TLrunning=0;Fvar.showImage=1;
        p.imgMethod=imgMethodBck;
        if p.iold==curf
            curf=curf-1;
        end
        if p.i==curf && curf~=length(p.l)
            set_frame(curf+1);
            set_frame(curf);
        elseif p.i==curf && curf==length(p.l)
            set_frame(curf-1);
            set_frame(curf);
        else
            set_frame(curf);
        end
        hs.UserMess.String='Finished radius correction';customdrawnow
        if ~p.disableSave
            saveall(p.dirS);
        end
        disableGUI(0);%disable the GUI
        Fvar.clickdisable=~p.modColonyClick;
    end%check the timelapse manually
    function CalcRadKymo2_Callback(~,~)
        %         initializeedges
        save_options_Callback;
        hs.UserMess.String='Please wait...';customdrawnow
        p.showplot=0;
        p.colList=1:size(Kymo.Kymo,1);
        %     p.kymoScalePillbox=[];
        if isempty(p.kymoScalePillbox) || length(p.kymoScalePillbox) ~= size(Kymo.Kymo,1)
            initializeedges;
        end
        %     if isempty(p.kymomode)
        p.kymomode(1:size(Kymo.Kymo,1),1)=p.radDefaultKymoMode;
        %     end
        disableGUI(1);%disable the GUI
        if p.showplot
            hs.figkymo=figure;
        end
        
        indx=1;
        
        for whichCol=p.colList
            if p.kymomode(whichCol)==1
                CalcRadKymo1(whichCol);
            else
                CalcRadKymo2(whichCol);
            end
            
            if (indx==1) || mod(indx,5)==0 || indx==length(p.colList)
                a=(indx/(length(p.colList)));
                fill([0 0 a a],[0,1,1,0],[0.5 0.7 0.8],'parent', hs.Progress2); set(hs.Progress2,'Xlim',[0 1],'Ylim',[0 1],'Xcolor','none','Ycolor','none'); customdrawnow
                text(0.25, 0.5, ['analysed ' num2str(indx) ' of ' num2str(length(p.colList)) ' colonies'],'Fontsize', 10, 'parent', hs.Progress2);customdrawnow
            end
            
            indx=indx+1;
        end
        
        refresh(0);
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
        hs.UserMess.String='Calculations finished';customdrawnow
        
        
        disableGUI(0);%disable the GUI
    end %recalc kymograph derived radius with default method
    function sel_and_del_callback(~,~)
        save_options_Callback;
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
        %if isempty(p.RadMeanBack); p.RadMeanBack=p.RadMean; end
        makeUndo(1); %saving for undo purposes
        
        hs.seldelwindow = figure('units','norm','Position',[0.1 0.1 0.6 0.6], 'KeyPressFcn', @WindowKeyPressFcn,...
            'MenuBar', 'none', 'NumberTitle', 'off','HandleVisibility','on',...
            'Name','Select & delete timelapse curves');
        hs.sd=uix.VBox('Parent', hs.seldelwindow);
        hs.curvesfig=uix.HBox('Parent', hs.sd);
        hs.lower2=uix.HBox('Parent', hs.sd);
        
        hs.sd.Heights=[-450, -40];
        hs.FigPanel=uipanel('Parent', hs.curvesfig); %in order to be able to use subplot, creating a panel for the figure
        hs.fig1=axes('Parent', hs.FigPanel, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
        
        hs.showdelsav=uix.HBox('Parent', hs.lower2);
        hs.show= uicontrol('Parent', hs.showdelsav, 'String', 'Show col.','Callback', @show_colony_curve_Callback);
        hs.ARList= uicontrol('Parent', hs.showdelsav, 'String', 'Put/remove from list','Callback', @mark_on_list_Callback);
        hs.SHList= uicontrol('Parent', hs.showdelsav, 'String', 'Show list','Callback', @Show_Hide_list_Callback);
        hs.ListSelect2=uicontrol('Parent',hs.showdelsav, 'Style', 'popup','String',p.UserLists.listOptions,'FontSize',15,...
            'BackgroundColor', hs.btnCol.gray,'Callback', @ChangeUserList_callBack);
        if ~isnan(activeList)
            set(hs.ListSelect2,'Value', -activeList)
        end
        hs.delete= uicontrol('Parent', hs.showdelsav, 'String', 'Delete','Callback', @delete_colony_curve_Callback);
        hs.save= uicontrol('Parent', hs.showdelsav, 'String', 'Quit','Callback', @quit_colony_curve_Callback);
        
        plot(p.RadMean');%plot raw data
        if ~isnan(activeList)
            L=readList(-activeList,0);
            if  sum(L)>0 %and something is on the list
                hold on; % just rewriting on top of curves
                for i=find(L==1)
                    plot(p.RadMean(i,:)','r','LineWidth',1.2);
                end
                hold off;
            end
        end
        
        xlabel('time (frames)'); ylabel('radius (pixels)'); title(p.rawTitle);
        hs.dcm_obj = datacursormode(gcf);   %activate the datacursor
        set(hs.dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','on','Enable','on');
        hs.text=[]; %no text has been displayed on the image yet
        hs.del=0; %no curve has been deleted yet
    end %display radial growth curves, click on to display colony number and delete
    function show_colony_curve_Callback(~,~)
        c_info = getCursorInfo(hs.dcm_obj);
        
        if isempty(c_info);errordlg('please select a curve'); return; end %is a curve selected ?
        if ~isempty(hs.text)%a curve was previously selected
            delete(hs.text);  %we delete the text displayed for that curve
            if hs.del==0  %and if it has not been deleted
                if isfield(hs,'remCurve')
                    if isvalid(hs.remCurve)
                        set(hs.remCurve,'LineWidth',0.5); %we restore the previous colony linewidth to the default one
                    end
                end
            end
        end
        hs.remCurve=c_info.Target;%get the current curve selected
        remPos=c_info.Position;%get the position on plot
        
        set(hs.remCurve,'LineWidth',3); % Make selected line wider
        [row,~,~] = find(p.RadMean(:,remPos(1))==remPos(2),1);   %find the corresponding row and col in RadMean(deleted col and v outputs -not used)
        hs.colonytodelete=row;
        hs.text=text(remPos(1),remPos(2),['Colony Nr. ',num2str(row)],'FontSize',15);%,'HorizontalAlignment',placement,'FontSize',15);
        hs.del=0;
    end %highlight curve
    function mark_on_list_Callback(~,~)
        c_info = getCursorInfo(hs.dcm_obj);
        if isempty(c_info);errordlg('please select a curve'); return; end %is a curve selected ?
        selectPos=c_info.Position;%get the position on plot
        [row,~,~] = find(p.RadMean(:,selectPos(1))==selectPos(2),1);   %find the corresponding row and col in RadMean(deleted col and v outputs -not used)
        
        plot(p.RadMean');%plot raw data
        
        if isnan(activeList) || activeList>=-Fvar.numNonUserList  %no list is active or those are non modifiable lists
            errordlg('please select a editable user list first');
            return
        else
            delete (hs.text)
            L=readList(-activeList,0); %reading current active list
            L(row)=(L(row)-1)^2; %invert value
            if L(row)==1
                hs.text=text(0.5,0.95,['Col.' num2str(row),' added to list'], 'Units', 'Normalized','HorizontalAlignment','center');
            else
                hs.text=text(0.5,0.95,['Col.' num2str(row),' removed from list'], 'Units', 'Normalized','HorizontalAlignment','center');
            end
            chngList(-activeList,0,L) %write list change
        end
        
        % refreshing plot
        hold on; % just rewriting on top of curves
        if ~isnan(activeList)
            L=readList(-activeList,0);
            for i=find(L==1)
                plot(p.RadMean(i,:)','r','LineWidth',1.2);
            end
        end
        hold off;
        hs.del=1;
        if ~p.disableSave
            saveall(p.dirS);
        end
    end %add colony nr
    function Show_Hide_list_Callback(~,~)
        %this function allows user to show/hide list selection in the
        %select and delete gui
        
        if isnan(activeList)
            hs.text=text(0.5,0.95,'No list selected', 'Units', 'Normalized','HorizontalAlignment','center');
            return
        end
        L=readList(-activeList,0);
        if sum(L)==0
            hs.text=text(0.5,0.95,'Active list is empty', 'Units', 'Normalized','HorizontalAlignment','center');
            plot(p.RadMean');%plot raw data
            return
        end
        
        if ~isfield(hs,'shMarker') %this function was not used yet
            hs.shMarker=1;
        end
        
        %   refresh plot
        plot(p.RadMean');%plot raw data
        
        if hs.shMarker==1
            hs.shMarker=0; %toggle marker
            set(hs.SHList, 'String', 'Hide list');
            hold on; % just rewriting on top of curves
            L=readList(-activeList,0);
            for whichcol=find(L==1)
                plot(p.RadMean(whichcol,:)','r','LineWidth',1.2);
            end
            hold off;
        else
            hs.shMarker=1; %toggle marker
            set(hs.SHList, 'String', 'Show list');
        end
    end %highlight list colonies
    function delete_colony_curve_Callback(~,~)
        hs.del=1;
        if isnan(p.RadMean(hs.colonytodelete,:))
            errordlg('please first select and show a curve'); return; end
        
        makeUndo(1); %saving for undo purposes
        p.RadMean(hs.colonytodelete,:)=nan;%replace values in RadMean with NaN
        p.RadMeanUm(hs.colonytodelete,:)=nan;%replace values in RadMean with NaN
        plot(p.RadMean');%plot raw data
        xlabel('time (frames)'); ylabel('radius (pixels)'); title(p.rawTitle);
        if ~p.disableSave
            saveall(p.dirS);
        end
        return;
    end %delete highlighted curve
    function quit_colony_curve_Callback(~,~)
        close(hs.seldelwindow);
        hs=rmfield(hs,'seldelwindow');
        refresh(0);
    end %close
    function restore_callback(~,~)
        %decide which colony should be checked. value 0 = all.
        save_options_Callback;
        prompt = {'Indicate which colonies radii should be restored, seperated by space. If all colonies, insert 0.'};
        dlg_title = 'Restore radius'; num_lines = 1;
        defaultans = {'0'};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        
        if isempty(answer); return; end %user cancelled
        
        %colonies
        p.UserColNb=str2num(answer{1,1}); %#ok<ST2NM> %user input
        if sum(p.UserColNb==0)>=1 % contains a zero: over all colonies
            p.colList=1:size(p.RadMean,1); %over all colonies
        elseif size(p.UserColNb,2)>=1 %user input more than one colony
            p.colList=p.UserColNb; %at the risk of doing several time the last one...
        else
            errordlg('The input for the colonies was in a wrong format. Try again.');return;
        end
        
        %set the list which colonies should be analyzed
        
        
        
        if ~isempty(p.RadMean1) %something was saved
            try
                p.RadMean(p.colList,:)=p.RadMean1(p.colList,:); %this is not a proper undo, so no call to undo function
            catch
                errordlg('Sorry, no backup was saved for one of the selected colonies. Restoring not possible'); return;
            end
        else
            errordlg('Sorry, no backup was saved. Restoring not possible'); return;
        end
        if sum(p.UserColNb==0)>=1
            hs.UserMess.String='All colony radius restored';customdrawnow
        else
            hs.UserMess.String='Radius for indicated colonies restored';customdrawnow
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(1);
    end %restore deleted curves
    function ResetTLRegistration_Callback(~,~)
        try %because it's also called from find circles...
            save_options_Callback;
        catch
        end
        if ~isempty(p.registrationTranslation)
            if ~isempty(p.colonyCenRadUnregistered{p.focalframe,1})
                p.colonyCenRad=p.colonyCenRadUnregistered;
            else
                for i=1:size(p.colonyCenRad,1)
                    p.colonyCenRad{i,1}=p.colonyCenRad{p.focalframe,1};
                    p.colonyCenRad{i,2}=p.colonyCenRad{p.focalframe,2};
                end
            end
            p.REGstatus=0;
            p.overlayIMGstatus=0;
            p.registrationTranslation=[];
            set(hs.registration,'Value',0);
            
        end
        hs.UserMess.String='Image registration removed';customdrawnow
    end %reset registration
    function FailedFrames_Callback(~,~)
        prompt = {'Frame numbers of which radius data should be replaced with NaN (seperate by space):'};
        dlg_title = 'Delete data'; num_lines = 1;
        defaultans = {num2str(1)};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if isempty(answer); return; end %user cancelled
        timeList2=round(str2num(answer{1,1})); %#ok<ST2NM>
        
        if sum(timeList2<1) || sum(timeList2>length(p.l)) || sum(isnan(timeList2))
            errordlg('The indicated frame is outside of the image range or was not a number. Try again.');return;
        end
        
        p.RadMean(:, timeList2)=NaN;
        save_options_Callback;
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0);
    end %delete radius data of given frame
    function CorrectRad_CallBack(~,~)
        save_options_Callback
        colC=[];
        %creating figure
        colC.figCorrColSize=figure('Numbertitle','off',...
            'units','normalized','outerposition',[0 0 1 1],...
            'Color',[0.9 0.9 .9],...
            'Toolbar','none',...
            'MenuBar','none',...
            'Name','Make sure all colonies radius are the size of colonies on last frame');
        
        %Horizontal split
        colC.CorrAllColSize=uix.HBox('Parent', colC.figCorrColSize);
        colC.ColSizePan=uipanel('Parent', colC.CorrAllColSize);
        colC.AxesPic=axes('Parent',colC.ColSizePan);
        
        %reading and displaying the picture, getting data from p
        colC.rgb = imread([p.dir, filesep,p.l(p.focalframe).name]);
        colC.AxesPic=imshow(colC.rgb);
        ax = gca;
        ax.Toolbar.Visible = 'off';
        colC.colsXY=p.colonyCenRad{p.focalframe,1}; %getting the colonies values
        colC.colsR=p.colonyCenRad{p.focalframe,2};
        colC.colsR2=p.colonyCenRad{p.focalframe,2};
        colC.focalframe=p.focalframe;
        viscircles(colC.colsXY,colC.colsR,'Color','b');
        
        % creating the buttons
        colC.ButtonsCorrAllColSize=uix.VBox('Parent', colC.CorrAllColSize);
        
        colC.rF=uix.HBox('Parent', colC.ButtonsCorrAllColSize);
        colC.rFtxt= uicontrol('Parent',colC.rF,'Style','text','String','Last (Reference) frame','FontSize',12,'callback',@RefFr_callBack);
        colC.rFVal= uicontrol('Parent',colC.rF,'Style','edit','String',num2str(colC.focalframe),'FontSize',12, 'Callback', @RefFr_callBack);
        
        colC.txtSiz=uicontrol('Parent', colC.ButtonsCorrAllColSize,'Style','text','String','Set new size:','FontSize',12);
        colC.slSiz=uicontrol('Parent',colC.ButtonsCorrAllColSize,'style','slider','min',0.25,'max',4, 'Value', 1,'callback',@slSizfn);
        %slSiz.Value=1;
        %uicontrol(slSiz)
        
        colC.txtVar=uicontrol('Parent', colC.ButtonsCorrAllColSize,'Style','text','String','Heterogeneous correction','FontSize',12);
        colC.btns=uibuttongroup('Parent',colC.ButtonsCorrAllColSize,'SelectionChangedFcn',@Heterogeneous_Callback);
        colC.r1 = uicontrol(colC.btns,'Style','radiobutton','String','Smallest colonies', 'Position',[15 150 110 30]);
        colC.r2 = uicontrol(colC.btns,'Style','radiobutton','String','Small colonies', 'Position',[15 120 110 30]);
        colC.r3 = uicontrol(colC.btns,'Style','radiobutton','String','All colonies', 'Position',[15 90 110 30]);
        colC.r4 = uicontrol(colC.btns,'Style','radiobutton','String','Big colonies', 'Position',[15 60 110 30]);
        colC.r5 = uicontrol(colC.btns,'Style','radiobutton','String','Biggest colonies', 'Position',[15 30 110 30]);
        set(colC.btns,'SelectedObject',colC.r3);  % Set the object.
        
        colC.BtnStop = uicontrol('Parent', colC.ButtonsCorrAllColSize,'Callback',@BtnApply_callBack,'String','Apply & Continue','FontSize',12);
        colC.BtnStop = uicontrol('Parent', colC.ButtonsCorrAllColSize,'Callback',@BtnStop_callBack,'String','Abort','FontSize',12);
        colC.BtnSave = uicontrol('Parent', colC.ButtonsCorrAllColSize,'Callback',@BtnSave_callBack,'String','Save&Quit','FontSize',12);
        
        set(colC.figCorrColSize, 'units','normalized','outerposition',[0 0 1 1])
        colC.CorrAllColSize.Widths=[-3,-0.5];
        colC.ButtonsCorrAllColSize.Heights=[-0.25,-0.25,-0.25,-0.25,-1,-1,-1,-1];
        
        function slSizfn(~,~)
            set(colC.txtSiz, 'String',['Set new size: x' num2str(colC.slSiz.Value,3)])
            CalcColR
            refreshColR
        end
        function BtnApply_callBack(~,~)
            colC.colsR=colC.colsR2;
        end
        function BtnStop_callBack(~,~)
            close(colC.figCorrColSize)
            refresh(1);
        end
        function BtnSave_callBack(~,~)
            p.focalframe=colC.focalframe; %saving focal frame
            p.colonyCenRad{p.focalframe,1}=colC.colsXY; %getting the colonies values
            if isfield(colC,'focalframe') %The radius was modified at one point
                for i=1:length(p.l)
                    p.colonyCenRad{i,2}=colC.colsR2;
                    p.colonyCenRadUnregistered{i,2}=colC.colsR2;
                end
            end
            colC.SizeEnd=0;
            close(colC.figCorrColSize)
            if ~p.disableSave
                saveall(p.dirS);
            end
            refresh(1);
        end
        function Heterogeneous_Callback(~,event)
            colN=length(colC.colsR);
            R=colC.slSiz.Value;
            if ~isfield(hs,'colOrder') %the colonies were never sorted before
                [~,idx]=sort(colC.colsR);
                [~,idx]=sort(idx);
            end
            colC.lastEvent=event;
            switch event.NewValue.String
                case 'Smallest colonies' %the 25% smallest
                    a=colN/4;
                    i=idx(idx<=a);
                    RH(idx<=a)=R+(i-1)*(1-R)/a; %linear decrease until
                    RH(idx>a)=1;
                case 'Small colonies' % the 50% smallest
                    a=colN/2;
                    i=idx(idx<=a);
                    RH(idx<=a)=R+(i-1)*(1-R)/a; %linear decrease until
                    RH(idx>a)=1;
                case 'All colonies'
                    RH=R;
                case 'Big colonies'
                    a=colN/2;
                    i=idx(idx>=a);
                    RH(idx>=a)=1+(i-a)*(R-1)/a;
                    RH(idx<a)=1;
                case 'Biggest colonies'
                    a=3/4*colN;
                    i=idx(idx>=a);
                    RH(idx>=a)=1+(R-1)/colN*4*(i-3/4*colN);
                    RH(idx<a)=1;
            end
            colC.RH=RH; %intermediary variable
            colC.colsR2=colC.colsR.*RH';
            refreshColR;
        end
        function RefFr_callBack(H,~)
            a = get(H,'string');
            a=str2double(a);
            if ~isempty(a) %the input was a number
                if a<=size(p.colonyCenRad,1) && a>0 && a==round(a)
                    colC.focalframe=a; %update focal frame
                    %update picture
                    colC.rgb = imread([p.dir, filesep,p.l(colC.focalframe).name]);
                    refreshColR
                end
            else
                colC.rFVal.Value=colC.focalframe;
            end
        end
        function refreshColR
            colC.AxesPic=imshow(colC.rgb);
            ax = gca;
            ax.Toolbar.Visible = 'off';
            if isfield(colC,'colsR2') %a correction was issued
                viscircles(colC.colsXY,colC.colsR2,'Color','b');
            else
                viscircles(colC.colsXY,colC.colsR,'Color','b');
            end
        end
        function CalcColR
            %this function calculates the new radius
            if ~isfield(colC,'RH') %stayed in default mode, never used
                colC.lastEvent.NewValue.String='All colonies';
            end
            Heterogeneous_Callback(NaN,colC.lastEvent)
        end
    end %scale detected radius

%% interface functions
    function mousemove(~, ~, h, bp)
        %from http://stackoverflow.com/questions/13840777/select-a-roi-circle-and-square-in-matlab-in-order-to-aply-a-filter
        cp = get(gca, 'CurrentPoint');
        r = norm([cp(1,1) - bp(1) cp(1,2) - bp(2)]);
        theta = 0:.1:2*pi;
        xc = r*cos(theta)+bp(1);
        yc = r*sin(theta)+bp(2);
        set(h, 'XData', xc);
        set(h, 'YData', yc);
    end % Mouse movement
    function WindowKeyPressFcn(~,eventdata)
        switch eventdata.Key
            case 'c'
                Addcol_callback
            case 't'
                ClearZone_Callback
            case'o'
                LoadButton_callback
            case 'z'
                ClearOutZone_Callback
            case 'leftarrow'
                previous_Callback
            case 'backspace'
                Undo_Callback
            case 'rightarrow'
                next_Callback
            case 'l'
                Add_to_List_Callback
            case 'r'
                %RemoveCol_Callback
                RemoveCol2_Callback
            case 'n'
                AddNonGrowing_callback
            case 'b'
                OverlayCheckboxchange_Callback
                hs.overlay.Value= ~hs.overlay.Value;
            otherwise
                return; % ignore keypress
        end
        
    end %keypresses

%% Detect tab
    function umRef_Callback(~,~)
        Fvar.clickdisable=1;
        if isempty(p.umConversion) || length(p.umConversion)~=length(p.l)
            p.umConversion=nan(length(p.l),1);
        end
        disableGUI(1);%disable the GUI
        %main figure;
        hs.umRefFig = figure('units','norm','Position',[0.5 0.5 0.32*Fvar.figscale 0.12], 'KeyPressFcn', @WindowKeyPressFcn,...
            'MenuBar', 'none', 'NumberTitle',...
            'off','HandleVisibility','on','Name','Choose option to calculate conversion');
        hs.all0=uix.VBox('Parent', hs.umRefFig);
        hs.all=uix.HBox('Parent', hs.all0);
        
        %plate ref part
        hs.plate=uix.VBox('Parent', hs.all);
        hs.Pl1= uicontrol('Parent',hs.plate,'Style','text','String','Known circle diameter [um]','FontSize',10);
        hs.Pl2= uicontrol('Parent',hs.plate,'Style','edit','String',p.petriDishUmSize,'FontSize',10);
        hs.PlBut= uicontrol('Parent',hs.plate,'Style','pushbutton','String','Use reference circle','FontSize',10, 'Callback', @PlateRef_Callback);
        hs.Void=uix.Empty('Parent', hs.all);
        
        %distance ref part
        hs.dist=uix.VBox('Parent', hs.all);
        hs.dist1= uicontrol('Parent',hs.dist,'Style','text','String','Known distance [um]','FontSize',10);
        hs.dist2= uicontrol('Parent',hs.dist,'Style','edit','String',10000,'FontSize',10);
        hs.distBut= uicontrol('Parent',hs.dist,'Style','pushbutton','String','Use reference distance','FontSize',10, 'Callback', @DistRef_Callback);
        hs.Void=uix.Empty('Parent', hs.all);
        
        %direct ref part
        hs.direct=uix.VBox('Parent', hs.all);
        hs.direct1= uicontrol('Parent',hs.direct,'Style','text','String','1 pixel = x um','FontSize',10);
        hs.direct2= uicontrol('Parent',hs.direct,'Style','edit','String',[],'FontSize',10);
        hs.directBut= uicontrol('Parent',hs.direct,'Style','pushbutton','String','Use direct conversion','FontSize',10, 'Callback', @DirectRef_Callback);
        
        hs.all.Widths=[-1 20 -1 20 -1];
        
        % export micrometers
        hs.ExportUm=uix.HBox('Parent', hs.all0);
        uicontrol('Parent',hs.ExportUm,'Style','text','String','For CSV Export use');
        hs.UM=uicontrol('Parent',hs.ExportUm,'Style','checkbox','String','micrometers','Callback',@setmicromExport,'Value',strcmp(p.ExportMode,'um'));
        hs.PX=uicontrol('Parent',hs.ExportUm,'Style','checkbox','String','pixels','Callback',@setmicromExport,'Value',strcmp(p.ExportMode,'px'));
        
        hs.all0.Heights=[-3,-1];
        hs.plate.Heights=[25 -1 -1];
        hs.dist.Heights=[25 -1 -1];
        hs.direct.Heights=[25 -1 -1];
        while ishandle(hs.umRefFig)% as long this figure is open, the GUI stays disabled.
            pause(0.5)
        end
        
        disableGUI(0);%disable the GUI
        Fvar.clickdisable=~p.modColonyClick;
    end %mini-gui for spatial calibration
    function setmicromExport(~,c)
        wh=c.Source.Parent; % getting the parent caller
        if strcmp(p.ExportMode,'px')
            p.ExportMode='um';
            for kids=1:numel(wh.Children)
                if strcmp(wh.Children(kids).String,'pixels')
                    wh.Children(kids).Value=0;
                else
                    wh.Children(kids).Value=1;
                end
            end
        else
            p.ExportMode='px';
            for kids=1:numel(wh.Children)
                if strcmp(wh.Children(kids).String,'pixels')
                    wh.Children(kids).Value=1;
                else
                    wh.Children(kids).Value=0;
                end
            end
        end
    end %define spatial calibration
    function PlateRef_Callback(~,~)
        refUm=str2double(hs.Pl2.String)/2;%get the value. As this is the diameter, and we work with rad, so divide by 2
        if isempty(refUm) || isnan(refUm) || length(refUm)>1 || refUm<0 %don't close the figure as long as the value is not valid
            waitfor(errordlg('The input was not in a correct format. Please try again.'));
            set(hs.Pl2, 'String', p.petriDishUmSize); return
        end
        close(hs.umRefFig)%now close the figure, gui is enabled again
        % if a AA was displayed, disable that to have a clearer image
        vAAstate=p.showROI;
        if p.showROI; p.showROI=0; refresh(0); end
        %resize image to improve speed
        small=imresize(Fvar.rgb,0.05);
        if strcmp(p.imgFormat,'rgb')
            if ~Fvar.imgenhanced
                binsmall= imbinarize(rgb2gray(small));
            else
                binsmall=imbinarize(small);
            end
        else
            binsmall=imbinarize(small);
        end
        % automatically find plates
        dim=min(size(binsmall))/2;
        %find a circle on the small image
        [Csmall, refPxlsmall]=imfindcircles(binsmall,round([0.5*dim 0.99*dim]),'ObjectPolarity', 'dark', 'Method', 'twostage', 'Sensitivity', 0.9);
        try
            if length(refPxlsmall)>1%if more than one cirlce was found, take the biggest
                [refPxlsmall, idx]=max(refPxlsmall);
                refPxl=refPxlsmall/0.05;%rescale the info
                C=Csmall(idx,:)/0.05;
            else %only one circle
                refPxl=refPxlsmall/0.05;
                C=Csmall/0.05;
            end
            hold on;
            a=viscircles(C,refPxl, 'Color','g');
            hold off;
            done=0;
            if ~isempty(refPxl)
                quest1=questdlg('Is the green circle correct?','Plate circle','Yes','No, correct','Yes');
                switch quest1
                    case 'Yes'
                        done=1;
                    case 'No, correct'
                        pause(0.00001);
                    case ''
                        return
                end
                delete(a);
            end
        catch %do nothing.
        end
        
        
        %if no circle was possible to detect or the user wants to change
        %the circle, go here
        while ~done
            hs.UserMess.String='Select three non-colinear points to delimit the petri dish surface';customdrawnow
            if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale && ~Fvar.imgenhanced
                [X, Y] = ginput(3);
            else
                [X, Y] =  ginputCustom(3);
            end
            hold on;
            borders=[X,Y];
            [refPxl,xcyc] =fit_circle_through_3_points(borders);
            C=[xcyc(1),xcyc(2)];
            p.roiPlateCenter=C;
            p.roiPlateRad=refPxl;
            a=viscircles(C,refPxl, 'Color','g');
            quest1=questdlg('Is the green circle correct?','Plate circle','Yes','No, correct','Yes');
            switch quest1
                case 'Yes'
                    done=1;
                case 'No, correct'
                    pause(0.00001);
                case ''
                    return
            end
            delete(a);
        end
        
        if strcmp(p.operatingMode,'TL')%different handling of the conversion rate for TL and single mode
            p.umConversion(:)=refUm/refPxl;
            RadUmCalc
        else
            p.umConversion(p.i)=refUm/refPxl;
        end
        %RadUmCalc MB:is not necessary, is it?
        hs.UserMess.String=['Spatial calibration: 1 pxl = ',num2str(p.umConversion(p.i)), 'um'];customdrawnow
        if p.showROI~=vAAstate
            p.showROI=vAAstate;
            refresh(0)
        end
        
        if p.roiType(p.i)==0
            p.showROI = 1;
            p.roiPlateRad(p.i)=refPxl;
            p.roiPlateCenter(p.i,:)=C;
            p.roiType(p.i) = 1;
            if strcmp(p.operatingMode,'TL')
                for i=1:length(p.l)
                    p.roiType(i) = 1;
                    p.roiPlateRad(i)=p.roiPlateRad(p.i);
                    p.roiPlateCenter(i,:)=p.roiPlateCenter(p.i,:);
                end
            end
            refresh(1)
        end
        p.ExportMode='um';
        if ~p.disableSave
            saveall(p.dirS);
        end
    end %as plate/circle
    function DistRef_Callback(~,~)
        refUm=str2double(hs.dist2.String);%get the value
        if isempty(refUm) || isnan(refUm) || length(refUm)>1 || refUm<0
            waitfor(errordlg('The input was not in a correct format. Please try again.'));
            set(hs.dist2, 'String', ''); return
        end
        close(hs.umRefFig)
        hs.UserMess.String='Place the ruler on the distance you indicated and hit enter when you are done';customdrawnow
        vAAstate=p.showROI;%if there is a AA displayed, disable that for a clearer image
        if p.showROI; p.showROI=0; refresh(0); end
        
        %get ruler onto the image
        h = imdistline(gca);
        api = iptgetapi(h);
        fcn = makeConstrainToRectFcn('imline',...
            get(gca,'XLim'),get(gca,'YLim'));
        api.setDragConstraintFcn(fcn);
        while ~waitforbuttonpress %wait until enter was pressed
            pause(0.1)
        end
        
        refPxl=getDistance(h);%get the distance in pxl
        api = iptgetapi(h);
        api.delete();%delete the ruler

        if strcmp(p.operatingMode,'TL')%different handling of the conversion rate storage for TL and single mode
            p.umConversion(:)=refUm/refPxl;
            RadUmCalc
        else
            p.umConversion(p.i)=refUm/refPxl;
        end
        %RadUmCalc MB: is not necessary is it
        hs.UserMess.String=['Spatial calibration: 1 pxl = ',num2str(p.umConversion(p.i)), 'um'];customdrawnow
        if p.showROI~=vAAstate
            p.showROI=vAAstate;
            refresh(1)
        end
        p.ExportMode='um';
        if ~p.disableSave
            saveall(p.dirS);
        end
    end %as distance
    function DirectRef_Callback(~,~)
        refUm=str2double(hs.direct2.String);%get value
        if isempty(refUm) || isnan(refUm) || length(refUm)>1 || refUm<0
            waitfor(errordlg('The input was not in a correct format. Please try again.'));
            set(hs.direct2, 'String', ''); return
        end
        refPxl=1;
        close(hs.umRefFig)
        if strcmp(p.operatingMode,'TL')%different storage for TL and single mode
            p.umConversion(:)=refUm/refPxl;
            RadUmCalc
        else
            p.umConversion(p.i)=refUm/refPxl;
        end
        %RadUmCalc . MB: is not necessessary, is it?
        hs.UserMess.String=['Spatial calibration: 1 pxl = ',num2str(p.umConversion(p.i)), 'um'];customdrawnow
        p.ExportMode='um';
        if ~p.disableSave
            saveall(p.dirS);
        end
    end %as direct value
    function DelimitAreaPlate_Callback(~,~)
        Fvar.clickdisable=1;
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exis
        
        % Handle response
        disableGUI(1);%disable the GUI
        %disp([choice ''])
        p.roiType(p.i) = 1;
        p.showROI=1;
        if isempty(p.roiPlateRad)
            p.roiPlateRad=nan(length(p.l),1);
            p.roiPlateCenter=nan(length(p.l),2);
        end
        % resize
        small=imresize(Fvar.rgb,0.05);
        if size(small,3)>1
            smallGrey=rgb2gray(small);
        else
            smallGrey=small;
        end
        binsmall= imbinarize(smallGrey);
        % automatically find plates
        dim=min(size(binsmall))/2;
        p.roiPlateRad(p.i)=nan;
        refresh(0);
        [p.roiPlateCentersmall, p.roiPlateRadsmall]=imfindcircles(binsmall,round([0.5*dim 0.99*dim]),'ObjectPolarity', 'dark', 'Method', 'twostage', 'Sensitivity', 0.9);
        done=0;
        try
            if length(p.roiPlateRadsmall)>1
                [p.roiPlateRadsmall, idx]=max(p.roiPlateRadsmall);
                p.roiPlateRad(p.i)=p.roiPlateRadsmall/0.05;
                p.roiPlateCenter(p.i,:)=p.roiPlateCentersmall(idx,:)/0.05;
            else
                p.roiPlateRad(p.i)=p.roiPlateRadsmall/0.05;
                p.roiPlateCenter(p.i,:)=p.roiPlateCentersmall/0.05;
            end
            hold on;
            a=viscircles(p.roiPlateCenter(p.i,:),p.roiPlateRad(p.i), 'Color','b');
            hold off;
            quest1=questdlg('Is the blue circle correct?','Plate circle','Yes','No, correct','Yes');
            switch quest1
                case 'Yes'
                    done=1;
                case 'No, correct'
                    pause(0.00001);
                case ''
                    return
            end
            delete(a);
        catch
            
        end
        
        while ~done
            if isnan(p.roiPlateRad(p.i))
                hs.UserMess.String='No circle was found. Manually click on three points to define circle for analysis area';customdrawnow
            else
                hs.UserMess.String='Click on three points to define circle for analysis area';customdrawnow
            end
            if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale
                [X, Y] = ginput(3);
            else
                [X, Y] =  ginputCustom(3);
            end
            hold on;
            borders=[X,Y];
            [R,xcyc] =fit_circle_through_3_points(borders);
            C=[xcyc(1),xcyc(2)];
            p.roiPlateRad(p.i)=R;
            p.roiPlateCenter(p.i,:)=C;
            a=viscircles(p.roiPlateCenter(p.i,:),p.roiPlateRad(p.i), 'Color','b');
            quest1=questdlg('Is the Blue circle correct?','Plate circle','Yes','No, correct','Yes');
            switch quest1
                case 'Yes'
                    done=1;
                case 'No, correct'
                    pause(0.00001);
                case ''
                    return
            end
            delete(a);
        end
        
        if strcmp(p.operatingMode,'TL')
            for i=1:length(p.l)
                p.roiType(i) = 1;
                p.roiPlateRad(i)=p.roiPlateRad(p.i);
                p.roiPlateCenter(i,:)=p.roiPlateCenter(p.i,:);
            end
        end
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0);
        disableGUI(0);%disable the GUI
        Fvar.clickdisable=~p.modColonyClick;
        hs.UserMess.String='Plate AOI defined';customdrawnow
    end %AOI as plate/circle
    function DelimitAreaPolygon_Callback(~,~)
        Fvar.clickdisable=1;
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exis
        % Handle response
        disableGUI(1);%disable the GUI
        
        if isempty(p.roiPolygonImg)
            p.roiPolygonImg=cell(length(p.l),1);
        end
        p.roiType(p.i)= 2;
        p.showROI=1;
        poly=impoly; %#ok<IMPOLY>
        p.roiPolygonImg{p.i}=getPosition(poly);
        if strcmp(p.operatingMode,'TL')
            for i=1:length(p.l)
                p.roiPolygonImg{i}=p.roiPolygonImg{p.i};
            end
        end
        delete(poly);
        
        if strcmp(p.operatingMode,'TL')
            for i=1:length(p.l)
                p.roiType(i)=p.roiType(p.i);
            end
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0);
        disableGUI(0);%disable the GUI
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable=~p.modColonyClick;
        hs.UserMess.String='Polygon AOI defined';customdrawnow
    end %AOI as polygon
    function DelimitAreaWhole_Callback(~,~)
        Fvar.clickdisable=1;
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exis
        
        % Handle response
        disableGUI(1);%disable the GUI
        p.roiType(p.i)= 0;
        p.showROI=0;
        
        if strcmp(p.operatingMode,'TL')
            for i=1:length(p.l)
                p.roiType(i)=p.roiType(p.i);
            end
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0);
        disableGUI(0);%disable the GUI
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable=~p.modColonyClick;
        hs.UserMess.String='AOI removed';customdrawnow
    end %remove AOI
    function EnhanceImage_Callback(~,~)
        Fvar.imgenhanced2= ~Fvar.imgenhanced2;
        p.iold=-1000;
        refresh(1)
    end %autocontrast
    function EnhanceImage2_Callback(~,~)
        Fvar.clickdisable=1;
        %         check if there is already a background image stored. This is
        %         gonna be deleted everytime the user switches frame if in single
        %         mode (we don't want to store all the images in the RAM...)
        if isempty(Fvar.background)
            disableGUI(1);%disable the GUI
            ibck=p.i;
            p.iold=p.i;
            se = strel('disk',round(size(Fvar.rgb, 1)/75)); %set a size to blur image to get rid of glares and circles in first image
            if strcmp(p.operatingMode, 'TL') && p.i~=p.focalframe
                set_frame(p.focalframe); %the calculation is done on the focal frame
            end
            hs.UserMess.String='Draw rectangle to define max & min intensity. Doubleclick to confirm';customdrawnow
            
            h=imrect(); %#ok<IMRECT>
            position = wait(h); %user inputs rectange for fast calculation
            hs.UserMess.String='Please wait...';customdrawnow
            
            if strcmp(p.operatingMode, 'single') %get indexes to reset to proper frame later
                indx1 = p.i;
                indx2 = p.i;
            else
                indx1 = 1;
                indx2 = p.focalframe;
            end
            
            
            if strcmp(p.imgFormat, 'rgb') %transorming into gray scale image if rgb
                Fvar.background = imread([p.dir, filesep,p.l(indx1).name]);
                Fvar.background = customcol2gray(Fvar.background);
                Fvar.background = imopen(Fvar.background, se); %loading pic
            else
                Fvar.background = imopen(imread([p.dir, filesep,p.l(indx1).name]), se); %loading pic
            end
            %             Fvar.background=double(Fvar.background);
            last=imread([p.dir, filesep,p.l(indx2).name]); %also loading the last frame
            if strcmp(p.imgFormat, 'rgb')
                last= customcol2gray(last);
            end
            
            last=imcrop(last, position); %crop images to user input rectangle
            bckgrcrop=imcrop(Fvar.background, position);
            
            %Bluring the image to get rid of potential glares (more realistic cutoff value for colonies)
            dsize = round(size(last,1)/240);
            if dsize<7
                dsize=7;
            end
            h = fspecial('disk',dsize);
            blurred = imfilter(last,h,'replicate');
            blurred=blurred-bckgrcrop;
            blurred(blurred==0)=nan;
            Fvar.mat2grayRefWhole=[]; %this will contain min and max values
            Fvar.mat2grayRefWhole(1)=quantile(blurred(:), 0.02); %min value
            Fvar.mat2grayRefWhole(2)=quantile(blurred(:), 0.98); %max value
            
            
            %not setting p.iold because we want refresh to reload the initial picture.
            if strcmp(p.operatingMode, 'TL')
                p.i=ibck; %jumping back to user frame
                p.iold=p.i-1;
                set_frame(p.i);
            end
            
            Fvar.imgenhanced=0;
            disableGUI(0);%disable the GUI
        end
        displayEnhancedImage()
    end %improve lighting
    function displayEnhancedImage()
        if ~Fvar.imgenhanced %was not enhanced
            Fvar.rgb=imread([p.dir, filesep,p.l(p.i).name]); %loading pic
            if strcmp(p.imgFormat, 'rgb') %transform into gray scale
                Fvar.rgb=imread([p.dir, filesep,p.l(p.i).name]); %loading pic
                Fvar.rgb=customcol2gray(Fvar.rgb);
                p.showGrayscale=1;
            end
            
            Fvar.rgb = mat2gray(Fvar.rgb - Fvar.background, Fvar.mat2grayRefWhole); %image enhancement
            
            Fvar.imgenhanced=1;
            refresh(1);
            
        else
            Fvar.rgb = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
            Fvar.imgenhanced=0;
            refresh(1);
        end
        
        %         end
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable=~p.modColonyClick;
        
    end %display lighting enhanced image
    function AutomaticallyDefineParameters_Callback(~,~)
        if ~isempty(p.colonyCenRad{p.i,1}) && size(p.colonyCenRad{p.i,1},1)>1
            p.detectMinRadPx=floor(min(p.colonyCenRad{p.i,2}));
            p.detectMaxRadPx=ceil(max(p.colonyCenRad{p.i,2}));
            if p.detectMinRadPx<=5
                p.detectMinRadPx=4;
                hs.UserMess.String=['Lower boundary set to minimum possible 4px; maximum radius set to: ', num2str(p.detectMaxRadPx), 'px'];customdrawnow
            else
                hs.UserMess.String=['Minimum radius: ', num2str(p.detectMinRadPx), 'px; maximum radius: ', num2str(p.detectMaxRadPx), 'px'];customdrawnow
            end
            
            if ~p.disableSave
                saveall(p.dirS);
            end
        else
            errordlg('Please detect at least 2 colonies on the actual frame, or go to the frame where you already detected some colonies and try again.');return;
        end
    end %define radius range
    function FindColonies_Callback(~,~)
        if isempty(p.detectMaxOverlap); p.detectMaxOverlap=0.9; end
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exist
        if ~isempty(p.RadMean)
            warning1=questdlg(['Warning! A timelapse analysis was already done. If you want to add or delete colonies, ',...
                'use either the buttons in the manual correction section or the select lines to delete function in the options',...
                'If you want to use the find colonies function again, all the timelapse data will be deleted'],...
                'Warning: Timelapse already done', 'Delete timelapse data', 'Cancel', 'Delete timelapse data');
            switch warning1
                case 'Delete timelapse data'
                    makeUndo(1); %saving for undo purposes
                    p.RadMean=[]; p.RadMeanUm=[];
                    p.colonyCenRad=cell(length(p.l),2);
                    p.focalframe=p.i;
                    ProgressUpdate;
                case 'Cancel'
                    return
                case ''
                    return
            end
        end
        if p.roiType(p.i)==0 %The analysis area is the whole image
            choice = questdlg('The analysis area is the whole image, do you wish to restrain it to a specific area?',...
                'Analysis area','Plate','Polygon','No, keep whole image and continue', 'No, keep whole image and continue');
            switch choice
                case 'Plate'
                    DelimitAreaPlate_Callback;
                case 'No, keep whole image and continue'
                    pause(0.001);
                case 'Polygon'
                    DelimitAreaPolygon_Callback;
                case ''
                    return;
            end
        end
        
        if strcmp(p.operatingMode, 'TL')%we are in timelapse mode, colonies are found on the current frame
            frameList=p.i;
            p.focalframe=frameList;
        else %we are in single mode, so multiple frames can be selected
            frameList= UserChoiceFrames('detect colonies on');
            if isempty(frameList)% the user canceled ,abort
                hs.UserMess.String='';customdrawnow
                return;
            end
            frameList=sort(unique(frameList));
            if p.i~=frameList(1)
                set_frame(frameList(1));
            end
        end
        
        hs.UserMess.String='Finding colonies...';customdrawnow
        indx=1;
        disableGUI(1);%disable the GUI
        tic;% istart=p.i; %initialise time calculations
        for i=frameList
            refresh(0) %refreshing image on which to find colonies
            if ~isempty(Fvar.background)
                if p.radUseEnhancedImg
                    EnhanceImage_Callback;
                end
            end
            FindColonies %this finds all colonies on search zone, and resets the whole colonies to what was found
            UpdateListNewCol('all') %refreshes all lists to match the new colonies
            if ~p.disableSave
                saveall(p.dirS);
            end
            %% message to user
            tmn=toc;
            timeElapsed=floor(tmn);
            percDone=round(indx/length(frameList)*100);
            remT=floor((1-percDone/100)*timeElapsed/percDone*100);
            mess=sec2timestr(remT);
            txtMsg= [num2str(floor(percDone)), '% done; Estimated ',mess, ' remain' ]; customdrawnow
            axes(hs.Progress1); fill([0 0 percDone/100 percDone/100],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none');customdrawnow %#ok<LAXES>
            text(0.25, 0.5, txtMsg,'Fontsize', 14);customdrawnow
            
            indx=indx+1;
            if p.i~=frameList(end)
                set_frame(frameList(indx));
            end
        end
        
        %% check if the next sets of buttons can be activated
        check=0;
        if p.progress.found==0
            for i3=1:length(p.l)
                baa=(p.colonyCenRad{i3,:});
                if ~isempty(baa)
                    check=1; break
                end
            end
        end
        
        if p.progress.found==0 && check
            ProgressUpdate;
            UpdateButtonState;
            p.progress.found=1;
        end
        if strcmp(p.operatingMode, 'TL')
            if p.REGstatus
                ResetTLRegistration_Callback
            end
            p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
            p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
        end
        
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
        refresh(0);
        disableGUI(0);%disable the GUI
        hs.UserMess.String='Colony search completed';customdrawnow
        
    end %find colonies button press
    function FindColonies
        hs.UserMess.String='searching for colonies...';customdrawnow
        %% check if should use smaller images
        %         tic
        if p.roiType(p.i)==0 %the whole image is kept by the user
            rgbT=Fvar.rgb;%taking whole image
        else %an area (either polygon or plate) has been selected->we can use a subimage
            if p.roiType(p.i)==1
                cropY=p.roiPlateCenter(p.i,1)-1.05*p.roiPlateRad(p.i);%define x1 to crop
                cropX=p.roiPlateCenter(p.i,2)-1.05*p.roiPlateRad(p.i);%define y1 to crop
                cropW=2.1*p.roiPlateRad(p.i);%as we crop a square, this is used for x2 and y2 calculation
                rect=[cropX,cropY,cropW,cropW]; %overwrite final crop rectangle
                poly=round(CreatePolyCircle(p.roiPlateCenter(p.i,:),p.roiPlateRad(p.i)));
            elseif p.roiType(p.i)==2
                subIMG=round(p.roiPolygonImg{p.i});
                rect=[min(subIMG(:,2)),min(subIMG(:,1)),max(subIMG(:,2))-min(subIMG(:,2)),max(subIMG(:,1))-min(subIMG(:,1))]; %overwrite
                poly=round(p.roiPolygonImg{p.i});
            end
            %% cut image
            xstart=round(rect(1)); xend=round(rect(1)+rect(3)-1);
            ystart=round(rect(2)); yend=round(rect(2)+rect(4)-1);
            if xstart<1; xstart=1; end
            if xend>size(Fvar.rgb,1); xend=size(Fvar.rgb,1); end
            if ystart<1; ystart=1; end
            if yend>size(Fvar.rgb,2); yend=size(Fvar.rgb,2); end
            if strcmp(p.imgFormat, 'rgb')
                rgbT=Fvar.rgb(xstart:xend,ystart:yend,:); %taking sub-image
            else
                rgbT=Fvar.rgb(xstart:xend,ystart:yend);
            end
        end
        if size(rgbT,3)>1 %this is a rgb image
            grayimg=customcol2gray(rgbT);
        else
            grayimg=rgbT;
        end
        % tophat filtering:
        
        
        %% preprocess image
        %         if p.detectCircleMode==1
        %             p.detectBinarizeSensitivity=0.01;
        %         else
        %             p.detectBinarizeSensitivity=0.09;
        %         end
        
        if p.BlackColony
            grayimg=imcomplement(grayimg);
        end
        if p.nChannel == 1
            se = strel('disk',round(min(p.detectMinRadPx*5, p.detectMaxRadPx*1.5)));
            grayimg=mat2gray(imtophat(grayimg, se));
        end
        switch p.detectBinarizationMethod
            case 1
                rgbT=AdaptiveBin(grayimg);
            case 2
                rgbT=OtsuBin(grayimg);
            case 3 %no process
        end
        
        % remove small objects
        areaSmallCol=round(pi*p.detectMinRadPx*p.detectMinRadPx*0.7);
        BW = bwareaopen(rgbT,areaSmallCol);
        
        % use small closing for smoother edges and potentially cut small areas
        se = strel('disk',1);
        BW=imclose(BW, se);
        
        % get labels (pixel index and extent) for every blob
        [labeledImage, ~] = bwlabel(BW);
        blb = regionprops(labeledImage,...
            'PixelIdxList', 'Extent');
        
        % Initial removal of low extent objects. Usually, these are artifacts and
        % plate borders
        bb=BW; clear BW;
        for i=1:size(blb,1)
            if blb(i).Extent<0.1
                bb(blb(i).PixelIdxList)=0;
            end
        end
        
        % if AOI is a circle, set all pixels outside circle =0 to increase speed.
        % Enalarge circle by 5% by increasing radius
        if p.roiType(p.i)==1
            imageSizeX = size(bb,2);
            imageSizeY = size(bb,1);
            [columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
            centerX = p.roiPlateCenter(p.i,2)-xstart;
            centerY = p.roiPlateCenter(p.i,1)-ystart;
            radius = p.roiPlateRad(p.i)*1.05;
            circlePixels = (rowsInImage - centerY).^2 ...
                + (columnsInImage - centerX).^2 <= radius.^2;
            bb(~circlePixels)=0;
        elseif p.roiType(p.i)==2 %if AOI is polygon, create mask and set outside =0
            mask=poly2mask(p.roiPolygonImg{p.i}(:,1)-rect(2),p.roiPolygonImg{p.i}(:,2)-rect(1), size(bb,1), size(bb,2));
            se = strel('disk',round(min(size(mask))/100));
            mask=imdilate(mask, se); %increase mask slightly
            bb(~mask)=0;
        end
        
        % calculate distance transform based on inverse image, and invert
        % this
        D = -bwdist(~bb);
        % create mask to filter the minima found
        mask = imextendedmin(D,1);
        % impose the mask onto the watershed
        D2 = imimposemin(D,mask);
        % repeat the watershed on the newly created image
        Ld2 = watershed(D2);
        %         Lrgb = label2rgb(Ld2,'jet','w','shuffle');
        
        % create binary image based on watershed
        bb(Ld2 == 0) = 0;
        
        
        % get new labels (pixel index and extent) for every blob
        [labeledImage, ~] = bwlabel(bb);
        blb = regionprops(labeledImage,...
            'PixelIdxList', 'Extent');
        
        % only after these, set also the pixels of each blob to 0
        % which has a low extent (ratio of pixels==1 within minimal
        % bounding box
        for i=1:size(blb,1)
            if blb(i).Extent<0.4
                bb(blb(i).PixelIdxList)=0;
            end
        end
        %         toc
        %         tic
        %% find the circles
        if p.detectCircleMode==1
            regionpropcirclesearch(grayimg, bb);
        else
            globalcirclesearch(bb);
        end
        
        if ~isempty(p.radii)
            % the very last quality check: calculate the distance of all centers and
            % remove centers that are closer than (default=2px)
            Distances=squareform(pdist(p.centers)); %calculate distance (same col=NaN)
            
            ind=~((sum(Distances<p.detectMinCenterDistFinal)-1)>0)';
            p.centers=p.centers(ind,:);
            p.radii=p.radii(ind);
        end
        %         toc
        %% Save colonies
        % finally, backcalculate position on initial image based on AOI
        if ~isempty(p.radii)
            
            for i2=1:length(p.radii)
                %          then, go over each other circle
                for i3=1:length(p.radii)
                    if isnan(p.radii(i2)); break; end
                    if isnan(p.radii(i3)); continue; end
                    if i3==i2; continue; end
                    %                 fill distance and radius difference matrix:
                    d=sqrt((p.centers(i2,1)-p.centers(i3,1))^2+(p.centers(i2,2)-p.centers(i3,2))^2);
                    r1=p.radii(i2); r2=p.radii(i3);
                    if d>r1+r2; continue; end %they don't overlap, skip this comparison
                    %                 if not, calculate overlap intersection points
                    t = sqrt((d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(-d+r1+r2));
                    if ~isreal(t) %if not real, one contains the other completely
                        if p.radii(i2)>p.radii(i3)
                            p.radii(i3)=nan;
                            continue
                        else
                            p.radii(i2)=nan;
                            continue
                        end
                    end
                end
            end %end of 5th quality check
            p.centers=p.centers(~isnan(p.radii),:);
            p.radii=p.radii(~isnan(p.radii));
            
            if p.roiType(p.i)~=0
                rect=[xstart,ystart];
                %centers are placed according to total image
                p.centers=p.centers+repmat(fliplr(rect(1:2))-1,[size(p.centers,1),1]);
                
                %if a polygon area is present, remove all col that were found outside
                in=inpolygon(p.centers(:,1),p.centers(:,2),poly(:,1),poly(:,2));
                p.centers=p.centers(in,:);
                p.radii=p.radii(in); %remove from radii
            end
            p.colonyCenRad{p.i,1}=p.centers;
            p.colonyCenRad{p.i,2}=p.radii;
        else
            p.colonyCenRad{p.i,1}=[];
            p.colonyCenRad{p.i,2}=[];
        end
        warning('on','images:imfindcircles:warnForLargeRadiusRange')
        pause(0.0001)
        hs.UserMess.String=['calculated for image Nr.' num2str(p.i)];customdrawnow
    end %create clean binary images
    function BW=AdaptiveBin(i1)
        if islogical(i1)
            return
        end
        
        if size(i1,1)*size(i1,2)<2e6
            BW=imbinarize(i1);
        else
            BW=imbinarize(i1, 'adaptive', 'Sensitivity', p.detectBinarizeSensitivity);
        end
        
    end %adaptive binarization
    function BW=OtsuBin(i1)
        if islogical(i1)
            return
        end
        BW=imbinarize(i1);
    end %otsu binarization
    function globalcirclesearch(rgbT)
        [p.centers,p.radii, qual]= findCircles(rgbT); %find circles in image that are in the polygon poly
        %calculate colony filling
        if size(rgbT,3)>1
            qual2=ones(size(qual));
        else
            qual2=CalcAllColFill(p.centers,p.radii, rgbT); %this may be long...
        end
        %% remove all colonies with a bad filling
        p.radii=p.radii(qual2>=p.detectMinForground);
        qual=qual(qual2>=p.detectMinForground);
        if isempty(qual)
            hs.UserMess.String='Error, no colonies found';customdrawnow
            return
        end
        X=p.centers(:,1); X=X(qual2>=p.detectMinForground);
        Y=p.centers(:,2); Y=Y(qual2>=p.detectMinForground);
        p.centers=[X,Y];
        qual2=qual2(qual2>=p.detectMinForground);
        [p.centers, idx1]=sortrows(p.centers);
        p.radii= p.radii(idx1);
        %% choose the best circles
        [p.centers,p.radii, ~, ~]=AreOverlapping2(p.centers,p.radii,qual, qual2);
    end %direct circle detection
    function [c,r,q]=findCircles(img)
        % uses imfincircles to find circles in image
        warning('off','images:imfindcircles:warnForLargeRadiusRange');
        
        % search if user already defined colonies to decide Rmin or Rmax
        Rmin=p.detectMinRadPx; Rmax=p.detectMaxRadPx;
        
        %% iterate the search on image
        c=[];r=[]; q=[];
        for i=Rmin:p.detectRadStepsize:Rmax
            % //TODO: do we need that resizer??
            if i>20
                resizer=p.detectRescaleBigCol/i; %imfindcircles works well with radius at p.detectRescaleBigCol pxl, and image can be resized
            else
                resizer=1;
            end
            %avoid the case i==p.detectRescaleBigCol
            range=sort([p.detectRescaleBigCol round(resizer*i+p.detectRadStepsize*resizer-1)]);
            if i==p.detectRescaleBigCol
                range=i; %imfincircle doesn't work with [a a] range;
            end
            [c1,r1, q1]=imfindcircles(imresize(img,resizer),range, 'ObjectPolarity', 'bright','sensitivity', p.detectSensitivity ,'Method', 'Twostage');
            c=[c;c1/resizer]; r=[r;r1/resizer]; q=[q; q1];
        end
        
    end %part of global
    function qual=CalcAllColFill(c,r,BW)
        qual=nan(length(r));
        % calulates all colonies filling from the BW image
        for i=1:length(r) %over all colonies
            % delimit mask size
            ci=round(c(i,:)); ri=round(r(i)); %let's work with integer pixels values
            poly=CreatePolyCircle(ci,ri); %create a polygonal circle (for mask)
            poly(:,1)=poly(:,1)-ci(1)+ri+1; % diplace to normalised x
            poly(:,2)=poly(:,2)-ci(2)+ri+1; % diplace to normalised y
            maskC=poly2mask(poly(:,1),poly(:,2), 2*(ri+1),2*(ri+1));
            try
                colBW=logical(BW(ci(2)-(ri):ci(2)+ri+1,ci(1)-(ri):ci(1)+(ri+1)));
                qual(i)=sum(sum(maskC.*colBW))/sum(sum(maskC));
            catch %if the colony is too much on the border
                qual(i)=nan;
            end
        end
        
    end %part of global
    function [centers, radii,qual,qual2]=AreOverlapping2(XY,R,qual,qual2)
        % sort out cicles that have a problem
        %         figure;
        for c=1:length(qual)
            if ~isnan(qual(c)) %might be already deleted
                for c2=1:length(qual)
                    if c==c2; continue; end %avoid comparing same circles
                    if ~isnan(qual(c2))&& c~=c2 && ~isnan(qual(c)) %might be already deleted
                        dist=sqrt((XY(c,1)-XY(c2,1))^2+(XY(c,2)-XY(c2,2))^2);
                        d=dist; r1=R(c); r2=R(c2);
                        if d>r1+r2; continue; end
                        t = sqrt((d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(-d+r1+r2));
                        if isreal(t)
                            A = r1^2*atan2(t,d^2+r1^2-r2^2)+r2^2*atan2(t,d^2-r1^2+r2^2)-t/2;
                            A1 = pi*r1^2;
                            A2 = pi*r2^2;
                            pA1=A/A1;
                            pA2=A/A2;
                            if pA1>p.detectMinForground
                                qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                                continue
                            elseif pA2>p.detectMinForground
                                qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                                continue
                            elseif pA1<(1-p.detectMinForground^2) && pA2<(1-p.detectMinForground^2)
                                continue
                            end
                            if d<p.detectMinForground*r1 || d<p.detectMinForground*r2
                                break
                            end
                        else
                            if r1>r2 && qual2(c)>p.detectMaxOverlapCompare
                                qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                            elseif  r1>r2 && qual2(c2)>p.detectMaxOverlapCompare
                                qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                            end
                            A=nan;
                            A1=nan; pA1=nan; %#ok<NASGU>
                            A2=nan; pA2=nan; %#ok<NASGU>
                        end
                        if dist<max(R(c),R(c2))+min(R(c),R(c2))*(1-p.detectMaxOverlapCompare^10) %overlap of more than p.detectMaxOverlap
                            if qual2(c)>p.detectMinFillCircleOverlap && qual2(c2)>p.detectMaxOverlapCompare %they are both well filled
                                if R(c2)<p.detectMinFillCircle*R(c) %delete the smallest, here the parameter is used as radius test
                                    if isnan(A) || pA2>p.detectMinForground
                                        qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                                    end
                                elseif p.detectMinForground*R(c2)>R(c) %if they have the same radius, keep the best quality of circle fit
                                    if isnan(A) || pA1>p.detectMinForground
                                        qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                                    end
                                else %if they have similar radius, keep the best quality of circle fit
                                    if qual(c)>qual(c2)
                                        qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                                    elseif qual(c)<qual(c2)
                                        qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                                    else
                                        %                                         if r1>r2
                                        %                                             qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                                        %                                         else
                                        %                                             qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                                        %                                         end
                                    end
                                end
                            elseif qual(c)<p.detectMaxOverlapCompare && qual2(c)<p.detectMaxOverlapCompare %they are both bad
                                if qual(c)>qual(c2) %keep the best quality circle fit
                                    qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                                else
                                    qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                                end
                            elseif qual2(c)<p.detectMaxOverlapCompare %the c is bad
                                qual(c)=nan; XY(c,:)=nan; R(c)=nan; qual2(c)=nan;
                            elseif qual2(c2)<p.detectMaxOverlapCompare %the c2 is bad
                                qual(c2)=nan; XY(c2,:)=nan; R(c2)=nan; qual2(c2)=nan;
                            end
                        end
                    end
                end
            end
        end
        radii=R(~isnan(R));
        a=XY(~isnan(XY));
        centers=reshape(a,[length(a)/2,2]);
        qual=qual(~isnan(R));
        qual2=qual2(~isnan(R));
    end%part of global
    function regionpropcirclesearch(i1, bb)
        % get new labels for the remaining blobs
        [labeledImage, ~] = bwlabel(bb);
        blb = regionprops(labeledImage,'BoundingBox', 'MajorAxisLength',...
            'MinorAxisLength');
        p.showplot=0; waittime=1;
        % go over all blobs, cut the bounding box of each
        % and get the auto graythesh value and 60% quantile of image intensities
        vls=nan(size(blb,1), 2);
        for i=1:size(blb,1)
            crpbx=blb(i).BoundingBox;
            crpbx(1)=crpbx(1)-crpbx(3)*(p.detectBoundingBoxScale-1)/2;
            crpbx(2)=crpbx(2)-crpbx(4)*(p.detectBoundingBoxScale-1)/2;
            crpbx(3)=crpbx(3)*p.detectBoundingBoxScale;
            crpbx(4)=crpbx(4)*p.detectBoundingBoxScale;
            crp=imcrop(i1, crpbx);
            %         vls(i,1)=graythresh(crp);
            vls(i,2)=quantile(crp(:), 0.6);
        end
        %    mnv=mean(vls(:,1)); %average graythresh value
        mxv=mean(vls(:,2), 'omitnan'); %average 60% quantile value
        
        % range of circles to look for
        range=[p.detectMinRadPx, p.detectMaxRadPx];
        
        %    initialize centers and raddi
        p.centers=[]; p.radii=[];
        
        for i=1:size(blb,1)
            %     for i=38
            %     create subimage based on enlarged bounding box
            crpbx=blb(i).BoundingBox;
            crpbx(1)=crpbx(1)-crpbx(3)*(p.detectBoundingBoxScale-1)/2;
            crpbx(2)=crpbx(2)-crpbx(4)*(p.detectBoundingBoxScale-1)/2;
            crpbx(3)=crpbx(3)*p.detectBoundingBoxScale;
            crpbx(4)=crpbx(4)*p.detectBoundingBoxScale;
            crpbx=round(crpbx);
            crp=imcrop(i1, crpbx);
            
            
            %    there is no colony on the blob if less than 5% of pixels intensity is
            %    above mean graythresh value OR if more than 95% are over average 60%
            %    quantile
            if sum(crp(:)>mxv)/length(crp(:)) < 0.05 || sum(crp(:)>mxv)/length(crp(:)) > 0.95
                continue
            end
            
            %    slight blurring with disk shape. Size of disk is defined by scaling
            %    the smaller of the two image dimensions.
            %    Additionally, auto contrasting is applied
            h = fspecial('disk',floor(min(size(crp))*p.detectBlurDiskSize)+1);
            crp2=imadjust(imfilter(crp,h,'replicate'));
            
            
            [c1,r11, q1]=imfindcircles(crp2,range,...
                'ObjectPolarity', 'bright','sensitivity', p.detectSensitivity,'Method', 'Twostage');
            
            % sort circles by descending radius size
            [r11, srt] = sort(r11, 'descend');
            c1 = c1(srt, :);
            q1 = q1(srt);
            
            %     display all initial circles if p.showplot in red
            if p.showplot
                imshow(crp2); hold on
                ax = gca;
                ax.Toolbar.Visible = 'off';
                title(['c',num2str(i)])
                viscircles(c1,r11, 'Color','r');
                for ii=1:length(r11)
                    text(c1(ii,1),c1(ii,2),['c',num2str(ii), ' b',num2str(i)],'FontSize',12,'Color',...
                        'red','FontWeight','bold','HorizontalAlignment','center');
                end
            end
            
            
            %     if there are more than 1 circle found, exclude all circles close to
            %     image border (min distance default=5). Also only do that if both image dimensions are bigger
            %     than 10*the defined min distance
            if sum(size(crp2)>p.detectMinBorderDist*10)==2
                for i2=1:length(r11)
                    if sum(c1(i2,:)<p.detectMinBorderDist/p.detectBoundingBoxScale)>0 ||...
                            c1(i2,1)>(size(crp2,2)-p.detectMinBorderDist/p.detectBoundingBoxScale) ||...
                            c1(i2,2)>(size(crp2,1)-p.detectMinBorderDist/p.detectBoundingBoxScale)
                        q1(i2)=nan;
                    elseif c1(i2,1)-r11(i2) < -(p.detectMinBorderDist/p.detectBoundingBoxScale)^2 ||...
                            c1(i2,1)+r11(i2) > size(crp,2)+(p.detectMinBorderDist/p.detectBoundingBoxScale)^2 ||...
                            c1(i2,2)-r11(i2) < -(p.detectMinBorderDist/p.detectBoundingBoxScale)^2 ||...
                            c1(i2,2)-r11(i2) > size(crp,1)+(p.detectMinBorderDist/p.detectBoundingBoxScale)^2
                        q1(i2)=nan;
                    end
                end
            end
            
            %     remove these circles
            c1=c1(~isnan(q1),:);
            r11=r11(~isnan(q1));
            q1=q1(~isnan(q1));
            
            
            
            
            
            
            
            %    create binary image with bias towards categorizing more pixel as
            %    foreground.
            crpbin=imbinarize(crp2,graythresh(crp2)-p.detectForegroundBias);
            
            %     first round of quality checks: remove circles with low proportion of
            %     foreground pixels
            for i2=1:length(r11)
                if isnan(r11(i2)); continue; end %if it is a nan, skip
                
                %             get mask of the focal circle:
                imageSizeX = size(crp,2);
                imageSizeY = size(crp,1);
                [columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
                centerX = c1(i2,1);
                centerY = c1(i2,2);
                radius = r11(i2);
                circlePixels = (rowsInImage - centerY).^2 ...
                    + (columnsInImage - centerX).^2 <= radius.^2;
                
                %          remove circle if less than 60% are white in binary image
                if sum(crpbin(circlePixels))/sum(circlePixels(:))<p.detectMinForground
                    c1(i2, :)=nan;
                    r11(i2)=nan;
                    continue
                end
                
                %          if there are more than 1 circle, remove based on quality
                if length(q1)>1 &&  q1(i2)<0.5/(length(q1)*1.5)
                    c1(i2, :)=nan;
                    r11(i2)=nan;
                    continue
                end
            end % end of first round of circle quality checks
            
            %         remove circles which became nan in last round
            c1=c1(~isnan(r11),:);
            q1=q1(~isnan(r11));
            r11=r11(~isnan(r11));
            
            
            %         second round of quality checks: check overlap region of each
            %         circle and discard high overlap & low quality circles
            for i2=1:length(r11)
                %             skip if nan
                if isnan(r11(i2)); continue; end
                r1=r11(i2); %store radius easy accessible of first circle
                A1 = pi*r1^2; %calculate area of this circle
                %                 and over every other circle as well
                for i3=1:length(r11)
                    %                 skip if index of 1st and 2nd loop are same or if nan
                    if isnan(r11(i3)); continue; end
                    if i2==i3; continue; end
                    
                    %                 calculate distance of these 2 circles
                    d=sqrt((c1(i2,1)-c1(i3,1))^2+(c1(i2,2)-c1(i3,2))^2);
                    r2=r11(i3);
                    
                    if d>r1+r2; continue; end %they don't overlap, skip this comparison
                    
                    %                 if not, calculate overlap intersection points
                    t = sqrt((d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(-d+r1+r2));
                    if isreal(t) %if not real, one contains the other completely
                        %                     if real, overlap area can be calculated
                        A = r1^2*atan2(t,d^2+r1^2-r2^2)+r2^2*atan2(t,d^2-r1^2+r2^2)-t/2;
                        %                     calculate area of 2nd circle and fraction of each
                        %                     overlap per colony:
                        A2 = pi*r2^2;
                        pA1=A/A1;
                        pA2=A/A2;
                        
                        %                     if overlap is more than 90% (default) and overlap fraction of
                        %                     1st circle is bigger than fraction of 2nd circle,
                        %                     exclude first. Same applies for 2nd circle
                        if pA1>p.detectMaxOverlapCompare && pA1>pA2
                            c1(i2, :)=nan;
                            r11(i2)=nan;
                            continue
                        elseif pA2>p.detectMaxOverlapCompare && pA1<pA2
                            c1(i3, :)=nan;
                            r11(i3)=nan;
                            continue
                        end
                        
                    else %one circle contains the other completely
                        %                     intuitively, the bigger should be the better but not
                        %                     infrequently, imfindcircles finds 1 big circle
                        %                     containing 3 smaller circles and the 3 smaller
                        %                     circles are the actual colonies. Therefore, we also
                        %                     take quality into consideration to decide if we
                        %                     exclude a circle or not.
                        if q1(i2)>q1(i3) && r11(i2)>r11(i3)
                            c1(i3, :)=nan;
                            r11(i3)=nan;
                            continue
                        elseif q1(i2)<q1(i3) && r11(i2)<r11(i3)
                            c1(i2, :)=nan;
                            r11(i2)=nan;
                            continue
                        else
                            continue
                        end
                    end
                    
                end %of going over every other colony
            end %of 2nd round of circle quality checks
            
            %         remove circles which became nan in last round
            c1=c1(~isnan(r11),:);
            q1=q1(~isnan(r11));
            r11=r11(~isnan(r11));
            
            
            % 3rd + 4th round of quality checks: only done if there are more than 1 circle.
            % 3r: discard one of 2 circles if both have very close centers and
            % very similar radius -> keep the one with higher quality
            % additionally: calculate and store the area of each remaining circle for 4th quality
            % check round
            if length(r11)>1
                %     initialize variables
                dist1=zeros(length(r11),length(r11)); %distance matrix
                rdif=zeros(length(r11),length(r11)); %radius difference matrix
                carea=cell(length(r11),1); %cell containing the area of each circle
                for i2=1:length(r11)
                    %             get area of 1st circle, store in carea
                    imageSizeX = size(crp,2);
                    imageSizeY = size(crp,1);
                    [columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
                    centerX = c1(i2,1);
                    centerY = c1(i2,2);
                    radius = r11(i2);
                    carea{i2} = (rowsInImage - centerY).^2 ...
                        + (columnsInImage - centerX).^2 <= radius.^2;
                    
                    %          then, go over each other circle
                    for i3=1:length(r11)
                        if isnan(q1(i2)); break; end
                        if isnan(q1(i3)); continue; end
                        if i3==i2; continue; end
                        %                 fill distance and radius difference matrix:
                        dist1(i2,i3)=sqrt((c1(i2,1)-c1(i3,1))^2+(c1(i2,2)-c1(i3,2))^2);
                        rdif(i2,i3)=abs(r11(i2)-r11(i3));
                        
                        %                 discard a circle if both are close to each other
                        %                 default= <20px) and have a similar radius (default=
                        %                 <10px) :
                        if rdif(i2,i3)<p.detectDiscardOvelapMinRadDiff && dist1(i2,i3)<p.detectDiscardOvelapMinCentDst
                            if q1(i2)>q1(i3)
                                q1(i3)=nan;
                                continue
                            else
                                q1(i2)=nan;
                                continue
                            end
                        end
                    end
                end %end of 3rd quality check
                
                %         4th quality check round:
                %         area contains proportion of circle pixel which are overlaping
                %         with any circle
                oarea=zeros(length(r11),1);
                for i2=1:length(r11)
                    if isnan(q1(i2)); continue; end
                    ct=1; %count variable for each colony to track how many circles are overlapping.
                    ol=zeros(size(carea{i2})); %initialize overlap pixel count
                    for i3=1:length(r11)
                        if i2==i3; continue; end
                        if isnan(q1(i3)); continue; end
                        if ct==1
                            %                     if first circle comparison, take element wise product
                            %                     of the two circle's area
                            ol=carea{i2}.*carea{i3};
                        else %do same plus add the existing one
                            ol=carea{i2}.*carea{i3} + ol;
                        end
                        ct=ct+1;
                    end
                    ol=logical(ol); %transform into logical: any value >0 --> 1
                    %             calculate the proportion of pixels in ol (all overlap) over
                    %             all cirlce pixels
                    oarea(i2)=sum(ol(ol>0)) / sum(carea{i2}(:));
                end %end of 4th quality check
                
                %         remove circles with more than (default=95%) of their area
                %         overlapping with any circle
                q1(oarea>p.detectMaxOverlapTotal)=nan;
                oarea(isnan(q1))=nan;
                
                % if there are still more than 1 circle left, start with lower max overlap
                % proportion threshold and increase until min 1 circle is kept
                if sum(~isnan(oarea))>1
                    %     gradually increase overlap thresh
                    thresh=p.detectMaxOverlapStartThresh;
                    while thresh<=1 && sum(oarea<thresh)<1
                        thresh=thresh*1.05;
                    end
                    c1=c1(oarea<thresh,:);
                    r11=r11(oarea<thresh);
                    q1=q1(oarea<thresh);
                end
                
                % remove all nan circles
                c1=c1(~isnan(q1),:);
                r11=r11(~isnan(q1));
                q1=q1(~isnan(q1));
                
                
                
                % 5th quality check
                % if there are still circles left which are contained within another circle
                % discard the lower quality circle
                for i2=1:length(r11)
                    %          then, go over each other circle
                    for i3=1:length(r11)
                        if isnan(q1(i2)); break; end
                        if isnan(q1(i3)); continue; end
                        if i3==i2; continue; end
                        %                 fill distance and radius difference matrix:
                        d=sqrt((c1(i2,1)-c1(i3,1))^2+(c1(i2,2)-c1(i3,2))^2);
                        r1=r11(i2); r2=r11(i3);
                        if d>r1+r2; continue; end %they don't overlap, skip this comparison
                        %                 if not, calculate overlap intersection points
                        t = sqrt((d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(-d+r1+r2));
                        if ~isreal(t) %if not real, one contains the other completely
                            if q1(i2)>q1(i3)
                                q1(i3)=nan;
                                continue
                            else
                                q1(i2)=nan;
                                continue
                            end
                        end
                    end
                end %end of 5th quality check
            end %of 3rd, 4th and 5th checks
            
            c1=round(c1);
            for i2=1:length(r11)
                mask=ismember(labeledImage, i);
                mask=imcrop(mask, crpbx);
                if ~mask(c1(i2,2), c1(i2,1))
                    q1(i2)=nan;
                end
            end
            % remove all nan circles
            c1=c1(~isnan(q1),:);
            r11=r11(~isnan(q1));
            
            
            
            if p.showplot %display kept circles in blue
                viscircles(c1,r11, 'color', 'blue');
                hold off
                if waittime>0
                    pause(waittime)
                else
                    pause()
                end
            end
            if isempty(r11); continue; end
            
            
            %     these are the finally kept circles. Calculate actual center
            %     positions:
            clear creal;
            creal(:,1)=c1(:,1)+crpbx(1);
            creal(:,2)=c1(:,2)+crpbx(2);
            
            p.centers=[p.centers;creal];
            p.radii=[p.radii; r11];
        end
    end %regionprops based circle detection
    function EnablemodColonyClick_Callback(~,~)
        p.modColonyClick=~p.modColonyClick;
        if p.modColonyClick
            hs.UserMess.String='left-click and hold to add | middle-click to remove';customdrawnow
        else
            hs.UserMess.String='click to add and remove disabled';customdrawnow
        end
        Fvar.clickdisable=~p.modColonyClick;
    end %enable mouse clicks to add/remove
    function Addcol_callback(~,~)
        Fvar.clickdisable=1;
        % user clicks on current image to delimit a circle
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %No image list exist
        
        TLrunAdd=0;
        if strcmp(p.operatingMode,'TL')
            if isempty(p.colonyCenRad{p.focalframe,1})
                p.focalframe=p.i;
            elseif p.focalframe~=p.i %if in TL mode and not on the focalframe, be able to add a colony anyway
                TLrunAdd=1;
            end
        end
        
        if TLrunAdd %then they need to be reloaded from the focaframe
            %             p.centers=p.colonyCenRad{p.focalframe,1};
            %             p.radii=p.colonyCenRad{p.focalframe,2}; %splitting in two variables
        end
        
        makeUndo(0); %saving for undos
        
        % instructions to users
        hs.UserMess.String='click and hold on center of colony, drag radius to border, release & click again to confirm';customdrawnow
        
        if ~Fvar.clickcall
            %get colony center
            if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale && ~Fvar.imgenhanced &&  ~Fvar.imgenhanced2
                [X1, Y1] = ginput(1);
            else
                [X1, Y1] =  ginputCustom(1);
            end
            if X1<1 || Y1<1 || X1>size(Fvar.rgb,2) || Y1>size(Fvar.rgb,1) %outside of image range
                hs.UserMess.String=''; customdrawnow
                Fvar.clickdisable=0;
                return
            end
            
            if ~TLrunAdd
                hold on;
                h = plot(X1, Y1, 'r');
                %get radius from a second click
                set(gcf, 'WindowButtonMotionFcn', {@mousemove, h, [X1 Y1]}); %to have an updating circle
                k = waitforbuttonpress;
                set(gcf, 'WindowButtonMotionFcn', ''); %unlock the graph
            end
        else
            hs.UserMess.String='hold & drag to border of colony, release & click again to confirm';customdrawnow
            
            
            Fvar.clickcall=0;
            hold on;
            seedPt = get(hs.fig, 'CurrentPoint'); % Get init mouse position
            X1=seedPt(1,1);
            Y1=seedPt(1,2);
            tempcross = scatter(X1, Y1,100,'+', 'b');
            if X1<1 || Y1<1 || X1>size(Fvar.rgb,2) || Y1>size(Fvar.rgb,1) %outside of image range
                hs.UserMess.String=''; customdrawnow
                Fvar.clickdisable=0;
                return
            end
            if ~TLrunAdd
                hold on;
                h = plot(X1, Y1, 'r');
                %get radius from a second click
                set(gcf, 'WindowButtonMotionFcn', {@mousemove, h, [X1 Y1]}); %to have an updating circle
                k = waitforbuttonpress;
                set(gcf, 'WindowButtonMotionFcn', ''); %unlock the graph
            end
            
            
        end
        
        
        try
            if ~TLrunAdd
                r = norm([h.XData(1) - X1 h.YData(2) - Y1]); %circle coordinates are in h object
            else
                r = median(p.radii, 'omitnan');
            end
        catch
            hs.UserMess.String=''; customdrawnow
            Fvar.clickdisable=0;
            return
        end
        
        %add cells
        if size(p.centers,1)>=1 %add to existing list
            a=[p.centers(:,1);X1] ;
            bb=[p.centers(:,2);Y1] ;
            p.centers=[a bb];
            p.radii=[p.radii;r];
            
        else %or to empty matrix
            p.centers=[X1,Y1];
            p.radii=r;
        end
        
        
        if strcmp(p.operatingMode, 'TL')
            if p.REGstatus
                ResetTLRegistration_Callback
            end
        end
        if ~TLrunAdd %on that frame, and no timelapse was run
            % Update handles structure
            p.colonyCenRad{p.i,1}=p.centers;
            p.colonyCenRad{p.i,2}=p.radii;
        else %on the focalframe a timelapse was run
            p.colonyCenRad{p.focalframe,1}=p.centers;
            p.colonyCenRad{p.focalframe,2}=p.radii;
        end
        if strcmp(p.operatingMode, 'TL')
            p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
            p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
            p.colonyCenRadUnregistered=p.colonyCenRad;
        end
        UpdateListNewCol(1) %adds one colony to all lists to match the new colonies
        
        if p.progress.TLrun %update the RadMean files with a nan line for that colony
            makeUndo(2); %saving for undo purposes
            p.RadMean(end+1,:)=nan;
            if p.nChannel>1
                for chi=2:p.nChannel
                    radname = sprintf('RadMeanCh%d', chi); % Construct field name dynamically
                    p.(radname)(end+1,:)=nan;
                end
            end
        end
        %refresh Graph
        
        if ~TLrunAdd %only if not in that mode
            %check if the next sets of buttons can be activated
            if p.progress.found==0 && ~isempty(p.colonyCenRad{p.i,1})
                p.progress.found=1;
                ProgressUpdate;
            end
        end
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
        try
            delete(tempcross)
        catch
        end
        try
            delete(h)
        catch
        end
        
        refresh(1);
        hs.UserMess.String=['Added colony with radius=',num2str(round(r)),'px'];customdrawnow
        Fvar.clickdisable= ~p.modColonyClick;
    end %add colony
    function RemoveCol2_Callback(~,~)
        %user clicks on an existing circle, and the function removes it from the colony list
        Fvar.clickdisable=1;
        if isempty(p.colonyCenRad{p.i,1}); return; end
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exist
        
        if strcmp(p.operatingMode,'TL')
            if isempty(p.colonyCenRad{p.focalframe})
                p.focalframe=p.i;
            end
        end
        
        % instructions to users
        hs.UserMess.String='Click on colony to remove';customdrawnow
        
        in=click_Colony; %get colony which have been clicked on
        if sum(in)==0
            return
        end
        deleteCol(in); % call the function to delete
        
        if length(find(in==1))==1
            hs.UserMess.String=['Colony Nr. ' num2str(find(in==1)) ' deleted'];customdrawnow
        else
            hs.UserMess.String=[num2str(length(find(in==1))) 'colonies deleted'];customdrawnow
        end
        Fvar.clickdisable= ~p.modColonyClick;
    end %remove colony
    function ClearZone_Callback(~,~)
        Fvar.clickdisable=1;
        hs.UserMess.String='click to place polygon corners, double click to finish';customdrawnow
        cleanzone(0)
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable= ~p.modColonyClick;
    end %clear inside of polygon
    function ClearOutZone_Callback(~,~)
        Fvar.clickdisable=1;
        hs.UserMess.String='click to place polygon corners, double click to finish';customdrawnow
        cleanzone(1)
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable= ~p.modColonyClick;
    end %clear outside of polygon
    function cleanzone(InOut)
        % When one of the clean zoe buttons is pressed,
        % user delimitates a zone, all cells inside (in==1) or outside
        %(in==0) the zone are deleted
        
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exist
        
        if strcmp(p.operatingMode,'TL')
            if isempty(p.colonyCenRad{p.focalframe})
                p.focalframe=p.i;
            end
        end
        
        makeUndo(0); %saving for undos
        disableGUI(1);%disable the GUI
        Fvar.UserMess='choose zone to remove cells';
        [~,xi,yi]=roipoly(); %user inputs a polygon
        
        %remove for current frame
        try %because the user can start polygon function and not do anything...
            in=inpolygon(p.centers(:,1),p.centers(:,2),xi,yi); %all cells in polygon
        catch
            hs.UserMess.String='';customdrawnow
            return
        end
        if InOut
            in=~in;
        end
        deleteCol(in)
        
        disableGUI(0);%disable the GUI
        hs.UserMess.String='';customdrawnow
    end %find colonies within polygon
    function deleteCol(in)
        
        makeUndo(0); %savinf for undos
        if strcmp(p.operatingMode, 'TL')
            if p.REGstatus
                ResetTLRegistration_Callback
            end
            p.centers=p.centers(in==0,:); %remove from centers
            p.radii=p.radii(in==0); %remove from radii
            p.colonyCenRad{p.focalframe,1}=p.colonyCenRad{p.focalframe,1}(in==0,:);
            p.colonyCenRad{p.focalframe,2}=p.colonyCenRad{p.focalframe,2}(in==0);
            
            p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
            p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
            p.colonyCenRadUnregistered=p.colonyCenRad;
            
            if p.progress.TLrun
                makeUndo(2); %saving for undo purposes
                p.RadMean=p.RadMean(~in,:);
                if p.nChannel>1
                    for chi=2:p.nChannel
                        radname = sprintf('RadMeanCh%d', chi); % Construct field name dynamically
                        p.(radname)=p.(radname)(~in,:);
                    end
                end
            end
            
        else %in EndPoint mode
            p.centers=p.centers(in==0,:); %remove from centers
            p.radii=p.radii(in==0); %remove from radii
            p.colonyCenRad{p.i,1}=p.centers;
            p.colonyCenRad{p.i,2}=p.radii;
        end
        UpdateListNewCol(-find(in==1)) %removes colonies to all lists to match the new number of colonies
        
        %check if the next sets of buttons can be activated
        check=0;
        if p.progress.found==1
            for i3=1:length(p.l)
                baa=(p.colonyCenRad{i3,:});
                if ~isempty(baa)
                    check=1; break
                end
            end
        end
        
        if p.progress.found==1 && ~check
            p.progress.found=0;
            ProgressUpdate;
            UpdateButtonState;
        end
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
        refresh(1);
    end %delete colony
    function Undo_Callback(~,~)
        if sum(size(p.l))==0; return; end %the list doesn't exist, nothing to undo!
        
        if Fvar.lastUndo(end)==0 %the last action was colony placement/removal
            varUndos={'colonyCenRad', 'centers','radii','UserLists'}; %the 3 variables that can be undone
            for i=1:8 %refresh the 7 possible undos
                for j=1:length(varUndos)
                    if i==1
                        p.([varUndos{j}])=Fvar.([varUndos{j},num2str(i)]);
                    elseif i==8
                        Fvar.([varUndos{j},num2str(i-1)])=[];
                    else
                        Fvar.([varUndos{j},num2str(i-1)])=Fvar.([varUndos{j},num2str(i)]);
                    end
                end
            end
        elseif Fvar.lastUndo(end)==1 || Fvar.lastUndo(end)==2%the last action was TL related
            if p.progress.TLrun %is this necessary?
                p.RadMean=Fvar.RadMean1;
                Fvar.RadMean1=Fvar.RadMean2; Fvar.RadMean2=Fvar.RadMean3; Fvar.RadMean3=[];
                if p.nChannel>1
                    for chi=2:p.nChannel
                        radname = sprintf('RadMeanCh%d', chi); % Construct field name dynamically
                        p.(radname)=Fvar.([radname, num2str(1)]);
                        Fvar.([radname, num2str(1)])=Fvar.([radname, num2str(2)]);
                        Fvar.([radname, num2str(2)])=Fvar.([radname, num2str(3)]);
                        Fvar.([radname, num2str(3)])=[];
                    end
                end
            end
        end
        
        % if a colonie was deleted / added after a timelapse was calculated, one needs to undo both the colony list and the p.radmean.
        % This means that the undo should first fix the radmean (which was
        % change last in add/remove functions, then fix the
        % addition/deletion of the colonies.
        if Fvar.lastUndo(end)==2
            varUndos={'colonyCenRad', 'centers','radii','UserLists'}; %the 3 variables that can be undone
            for i=1:8 %refresh the 7 possible undos
                for j=1:length(varUndos)
                    if i==1
                        p.([varUndos{j}])=Fvar.([varUndos{j},num2str(i)]);
                    elseif i==8
                        Fvar.([varUndos{j},num2str(i-1)])=[];
                    else
                        Fvar.([varUndos{j},num2str(i-1)])=Fvar.([varUndos{j},num2str(i)]);
                    end
                end
            end
            Fvar.lastUndo(2:end)=Fvar.lastUndo(1:end-1); Fvar.lastUndo(1)=nan;
        end
        
        % Updating list of actions:
        Fvar.lastUndo(2:end)=Fvar.lastUndo(1:end-1); Fvar.lastUndo(1)=nan;
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        
        
        refresh(1)
    end %undo button
    function makeUndo(whichUndo)
        % this function prepares a list of undos on p.centers, p.radii and
        % p.colonyCenRad if called with 0; or with p.Radmean if called with 1
        
        % refresh the lastUndo tracker
        Fvar.lastUndo(1:end-1)=Fvar.lastUndo(2:end); Fvar.lastUndo(end)=whichUndo;
        
        if whichUndo==0 %last action is related to add/remove cols
            varUndos={'colonyCenRad', 'centers','radii','UserLists'}; %the 3 variables that can be undone
            for i=7:-1:1 %I chose 7 undos... ¯\_(ツ)_/¯
                for j=1:length(varUndos)
                    if i==1 %this is actually done last
                        Fvar.([varUndos{j},num2str(i)])=p.([varUndos{j}]);
                    else
                        Fvar.([varUndos{j},num2str(i)])=Fvar.([varUndos{j},num2str(i-1)]);
                    end
                end
            end
        elseif whichUndo==1 || whichUndo==2
            for chi=1:p.nChannel
                if chi == 1
                    varUndos ='RadMean'; %the 1 variables that can be undone
                else
                    varUndos = sprintf('RadMeanCh%d', chi); % Construct field name dynamically
                end
                
                for i=3:-1:1 %I chose 3 undos... ¯\_(ツ)_/¯
                    if i==1 %this is done last
                        Fvar.([varUndos,num2str(i)])=p.(varUndos);
                    else
                        Fvar.([varUndos,num2str(i)])=Fvar.([varUndos,num2str(i-1)]);
                    end
                end
            end
            
        end
    end %creating an undo variable
    function HighlightCol_Callback(~,eventdata)
        pause(5/1000);
        whichCol=[];
        if exist('eventdata', 'var')~=0
            if strcmp(eventdata.EventName, 'KeyPress')
                switch eventdata.Key
                    case 'return'
                        whichCol=str2num(get(hs.HLinput, 'String')); %#ok<ST2NM> %get the string in the field
                        if isempty(whichCol);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
                    otherwise
                        return
                end
            elseif strcmp(eventdata.EventName, 'Action')
                whichCol=str2double(get(hs.HLinput, 'String')); %get the string in the field
                if isempty(whichCol);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
            end
            %         else
            %             whichCol=find(p.UserLists(:,1));
        end
        
        if isempty(whichCol);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
        if strcmp(p.operatingMode, 'TL') %different frames to get the colony centers from
            ckfram=p.focalframe;
        elseif strcmp(p.operatingMode, 'single')
            ckfram=p.i;
        end
        lnck=length(p.colonyCenRad{ckfram,2}); %got some weird errors if I used it directly...
        if  isempty(whichCol) || sum(isnan(whichCol))>0 || sum(whichCol<1)>0 || sum(whichCol>lnck)>0
            %do nothing if the input is not correct apart from telling the
            %user that
            hs.UserMess.String='please enter a valid colony number';customdrawnow
            return
        end
        ColList=whichCol;
        for i=ColList
            whichCol=i;
            if strcmp(p.operatingMode, 'TL')
                if p.i==p.focalframe
                    %show the circle from p.colonyCenRad if on focalframe
                    viscircles(p.colonyCenRad{p.i,1}(whichCol,:),p.colonyCenRad{p.i,2}(whichCol)*p.showCircleScale,'Color','m'); %
                    text(p.colonyCenRad{p.focalframe,1}(whichCol,1),p.colonyCenRad{p.focalframe,1}(whichCol,2),num2str(whichCol),'FontSize',12,'Color','m','FontWeight','bold','HorizontalAlignment','center');
                else
                    %show the one from the p.RadMean file. If that is a nan,
                    %at least the number is shown
                    try
                        viscircles(p.colonyCenRad{p.focalframe,1}(whichCol,:), p.RadMean(whichCol,p.i)*p.showCircleScale,'Color','m');
                    catch
                        viscircles(p.colonyCenRad{p.focalframe,1}(whichCol,:), p.colonyCenRad{p.focalframe,2}(whichCol,:)*p.showCircleScale,'Color','m');
                    end
                    text(p.colonyCenRad{p.focalframe,1}(whichCol,1),p.colonyCenRad{p.focalframe,1}(whichCol,2),num2str(whichCol),'FontSize',12,'Color','m','FontWeight','bold','HorizontalAlignment','center');
                end
                
            elseif strcmp(p.operatingMode, 'single') %easy
                viscircles(p.colonyCenRad{p.i,1}(whichCol,:),p.colonyCenRad{p.i,2}(whichCol)*p.showCircleScale,'Color','m'); %plot the colony circle
                text(p.colonyCenRad{p.i,1}(whichCol,1),p.colonyCenRad{p.i,1}(whichCol,2),num2str(whichCol),'FontSize',12,'Color','m','FontWeight','bold','HorizontalAlignment','center');
            end
        end
        %just another message
        if length(ColList)==1
            hs.UserMess.String=['Highlighted colony ',num2str(whichCol)];customdrawnow
        else
            hs.UserMess.String=['Highlighted ',num2str(length(ColList)), ' colonies'];customdrawnow
        end
    end %highlight colony
    function DeleteHighlightCol_Callback(~,~)
        whichCol=str2num(get(hs.HLinput, 'String')); %#ok<ST2NM> %get the string in the field
        if isempty(whichCol);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
        if sum(whichCol>length(p.colonyCenRad{p.i,2}))>0
            hs.UserMess.String='Selected colonies out of bounds';customdrawnow
            return
        end
        ToDelete=zeros(length(p.radii),1); ToDelete(whichCol)=1;%ToDelete=~ToDelete;
        deleteCol(logical(ToDelete))
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
    end %delete highlighted colony
    function Add_to_List_Callback(~,~)
        %this function will let user click on a colony, and toggle list membership
        disableGUI(1);%disable the GUI
        makeUndo(0); %creating an undo
        Fvar.clickdisable=1;
        if activeList>=-Fvar.numNonUserList || isnan(activeList)
            hs.UserMess.String='select a user list that can be modified';customdrawnow
            disableGUI(0);
            return;
        end
        
        if isempty(p.colonyCenRad{p.i,1})
            hs.UserMess.String='No colonies on the image';customdrawnow
            disableGUI(0);
            return;
        end
        
        hs.UserMess.String='Click inside a colony to add or place polygon by clicking outside a colony';customdrawnow
        if isempty(p.colonyCenRad{p.i,1}); return; end
        if sum(size(p.l))==0; return; end %the list doesn't exist
        
        in=click_Colony; %adding a colony by clicking on it
        if sum(in)==0 %no colony was selected, use polygon mode
            [~,xi,yi]=roipoly(); %user inputs a polygon
            if length(xi)<2
                hs.UserMess.String='';customdrawnow
                return
            end
            in=inpolygon(p.centers(:,1),p.centers(:,2),xi,yi); %all cols in polygon
        end
        
        L=readList(-activeList,p.i);
        L=(L-in).^2; %convert 0 to 1,1 to 0
        chngList(-activeList,p.i,L)
        
        if ~p.disableSave
            saveall(p.dirS);
        end
        
        refresh(1)
        if sum(in)==1
            hs.UserMess.String=['Added colony n°' num2str(find(in==1)) ' to the user list'];customdrawnow
        else
            hs.UserMess.String=['Added ' num2str(sum(in==1)) ' colonies to the user list'];customdrawnow
        end
        disableGUI(0);%disable the GUI
        Fvar.clickdisable= ~p.modColonyClick;
    end %add to list
    function Show_UserList_Callback(~,~)
        p.showList=(p.showList-1)^2;
        if p.showList
            set (hs.ShowList, 'String', 'Hide')
        else
            set (hs.ShowList, 'String', 'Show')
        end
        refresh(1);
    end %highlight list
    function Voronoi_Callback(~,~)
        if ~license('checkout','map_toolbox')
            errordlg('The Mapping Toolbox is missing, please install it to use this functionality.');
            return;
        end
        p.ShowVoronoiAreas=0;
        p.ShowVoronoiEdges=0;
        if isempty(p.colonyCenRad)
            errordlg('No colonies detected');
            hs.UserMess.String='Aborted';customdrawnow
            return;
        end
        %Check if already calculated Voronoi, and give the user a chance to cancel recalculation
        
        if strcmp(p.operatingMode, 'TL')%we are in timelapse mode, voronoi calc will be done on the focal frame
            frameList=p.focalframe;
            if ~isempty(p.VoronoiAreas)
                cellfun(@isempty,p.VoronoiAreas(p.focalframe))
                warningDLG=questdlg('The Voronoi was already calculated',...
                    'Voronoi already calculated', ...
                    'Recalculate','Cancel','Cancel');
                switch warningDLG
                    case 'Cancel'
                        return;
                    case 'Recalculate'
                        p.VoronoiAreas=[];
                        VorEdg.VoronoiEdges=[];
                end
            end
            if(isempty(p.roiPlateCenter))
                warning1=questdlg('The plate boundary is not defined',...
                    'Plate not defined yet', ...
                    'Cancel','Define it now','Define it now');
                switch warning1
                    case 'Cancel'
                        return;
                    case 'Define it now'
                        DelimitAreaPlate_Callback;
                end
            end
        else %we are in single mode, so multiple frames can be selected
            frameList= UserChoiceFrames('calculate the voronoi of');
            if isempty(frameList)% the user canceled ,abort
                hs.UserMess.String='';customdrawnow
                return;
            end
            frameList=sort(unique(frameList));
            if p.i~=frameList(1)
                set_frame(frameList(1));
            end
            if ~isempty(p.VoronoiAreas)
                if sum(~cellfun(@isempty,p.VoronoiAreas(frameList)))% some of the selected frames had the voronoi calculated already
                    which=find(~cellfun(@isempty,p.VoronoiAreas(frameList)));
                    if (length(which)==length(frameList))
                        text1='all';
                        text2='.';
                    elseif (length(which))>10
                        text1=[num2str(length(which)),' of'];
                        text2='.';
                    elseif (length(which))==1
                        text1=[num2str(length(which)),' of'];
                        text2=[': frame ', num2str(frameList(which(1:end)))];
                    elseif (length(which))>1 &&(length(which))<10
                        text1=[num2str(length(which)),' of'];
                        text2=[': frames ', num2str(frameList(which(1:end)))];
                    end
                    warning2=questdlg(['The Voronoi was already calculated on ',text1,' these frames', text2],...
                        'Voronoi already calculated', ...
                        'Recalculate for all anyway','Cancel','Cancel');
                    switch warning2
                        case 'Cancel'
                            return;
                        case 'Recalculate for all anyway'
                            for i=frameList
                                p.VoronoiAreas{i,1}=[];
                                VorEdg.VoronoiEdges{i,1}=[];
                            end
                    end
                end
            end
            val=CheckVariableOnFrames(p.roiPlateCenter,'the plate boundary ',frameList);
            if val~=0; return; end
        end
        
        hs.UserMess.String='Voronoi area is calculated. Please wait...';customdrawnow
        indx=1;
        tfc=0;
        obc=0; %too few colonies on plate, some colonies out of the plate boundary
        tic;% istart=p.i; %initialise time calculations
        for i=frameList
            refresh(0) %refreshing image on which to find colonies
            [tfci,obci]=CalculateVoronoiAreas();
            tfc=tfc+tfci;
            obc=obc+obci;
            if ~p.disableSave
                saveall(p.dirS);
                voronoisave(p.dirS);
            end
            %% message to user
            timeElapsed=floor(toc);
            percDone=round(indx/length(frameList)*100);
            remT=floor((1-percDone/100)*timeElapsed/percDone*100);
            mess=sec2timestr(remT);
            txtMsg= [num2str(floor(percDone)), '% done; Estimated ',mess, ' remain' ]; customdrawnow
            axes(hs.Progress1); fill([0 0 percDone/100 percDone/100],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none');customdrawnow %#ok<LAXES>
            text(0.25, 0.5, txtMsg,'Fontsize', 14);customdrawnow
            indx=indx+1;
            if p.i~=frameList(end)
                set_frame(frameList(indx));
            end
            
        end
        if tfc~=0
            if frameList==1
                waitfor(errordlg('Voronoi area cannot be calculated, because there are less than 5 colonies on the plate'));
            else
                waitfor(errordlg('On ',tfc,' frame(s) Voronoi area could not be calculated, because there are less than 5 colonies on the plate'));
            end
        end
        if obc~=0
            if frameList==1
                waitfor(errordlg('Some colonies are ouside of the plate area, correct this and try again, please.'));
            else
                waitfor(errordlg('On ',obc,' frame(s), colonies are ouside of the plate area, correct this and try again, please.'));
            end
        end
        p.ShowVoronoiAreas=1;
        p.ShowVoronoiEdges=1;
        refresh(0)
        hs.UserMess.String='Voronoi area calculation finished';customdrawnow
    end %calculate vornoi
    function [tfc,obc]=CalculateVoronoiAreas(~,~)
        AAr=p.roiPlateRad(p.i);
        AAc=p.roiPlateCenter(p.i,:);
        c=p.colonyCenRad{p.i,1};
        tfc=0;
        obc=0;
        if size(c,1)<=4 %are there more than 5 colonies on the plate?
            tfc=1;
            return;
        end
        bs_ext=CreatePolyCircle(AAc,AAr); % creates a plate boundary polygon (circle)
        in=inpolygon(c(:,1),c(:,2),bs_ext(:,1),bs_ext(:,2)); % checks if some colonies are out of the circle
        if ~all(in) %are all colonies within the plate boundary?
            obc=1;
            return;
        end
        [V,C,XY]=VoronoiLimit(c(:,1),c(:,2),'bs_ext',bs_ext,'figure','off'); % calculates Voronoi limits
        % V contains all vertices and C contains all vertices for each individual point.
        %That is: V(C{ij},:) will give you the vertices of the ij'th data point.
        %The order of polygon vertices are given in a counter-clockwise manner.
        %XY contains updated xy coordinates as limited by any input boundaries.
        % Now we need to reorder and calculate the cell Area for each colony
        %In the coordinates vector XY of VoronoiLimit output, the colonies are not ordered like in the counts file.
        %Thus, reordering the data.
        N=length(XY);
        for i=1:N
            [~,N(i)]=ismember(XY(i,:),c,'rows');% N(i) contains the row i of c which corresponds to XY(i)
        end
        %We reconstruct a cell M from the cell C obtained (just changing the order of the value to be coherent with our counts file order).
        %(so that each value of the vectors will correspond to the right value in the radius vector)
        for i=1:size(N,2)
            j=N(1,i);
            M{j,1}=C{i,1};
        end
        
        %Calculating the cell Area for each colony
        for i=1:size(c,1)
            CellArea(i,1)=polyarea(V(M{i},1),V(M{i},2)); %here, one wants to possibly bound it
        end
        
        %Initialising p.VoronoiAreas, VorEdg.VoronoiEdges
        if strcmp(p.operatingMode, 'TL')||(strcmp(p.operatingMode, 'single')&&isempty(p.VoronoiAreas))
            % if we are in single mode and some frames have values already, we don't want to reinitialise those
            p.VoronoiAreas=cell(length(p.l),1);
            VorEdg.VoronoiEdges=cell(length(p.l),length(C));
        end
        %Assigning the cell Area and the voronoi edges for
        %each colony on this frame
        p.VoronoiAreas{p.i,1}=round(log(CellArea),1);%CellArea;
        for id=1:length(C)
            VorEdg.VoronoiEdges{p.i,id}=[V(C{id},1),V(C{id},2)];
        end
        %if we are in timelapse mode, then this applies for all frames
        if strcmp(p.operatingMode, 'TL')
            p.VoronoiAreas(:,1)=p.VoronoiAreas(p.i,1);
            for id=1:length(C)
                VorEdg.VoronoiEdges(:,id)=VorEdg.VoronoiEdges(p.i,id);
            end
        end
    end  %Calculates the voronoi areas

%% Main-EP tab
    function OverlayCheckboxchange_Callback(~,~)
        p.overlayIMGstatus=~p.overlayIMGstatus;
        if ~p.disableSave
            saveall(p.dirS);
        end
        if ~isfield(p, 'counts1')
            if p.overlayIMGstatus
                set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            else
                set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            end
            set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        end
        
        refresh(1)
    end %overlay toggle
    function ChangeOverlayFolder_callBack(~,~)
        if isempty(hs.overlayselect.Value);return;end
        temp2=hs.overlayselect.String{hs.overlayselect.Value};
        for i=1:length(p.multiEPdirs)
            spos=strfind(p.multiEPdirs(i), filesep);
            if length(spos{1})>2
                temp=p.multiEPdirs{i};
                temp=['...', temp(spos{1}(end-1):end)];
                if strcmp(temp, temp2)
                    p.dirOverlay=p.multiEPdirs{i};
                    break
                end
            end
        end
        indx1=strfind(p.l(1).name, '.');
        flx=p.l(1).name(indx1(end)+1:end);
        p.lOverlay=dir([p.dirOverlay, filesep, '*',flx]); %lists all files with filextension
        p.iOverlayold=0;
        % refresh(1);
    end %change overlay folder from dropdown
    function setoverlayfolders(~,~)
        p.multiEPdirsShort=p.multiEPdirs;
        for i=1:length(p.multiEPdirs)
            spos=strfind(p.multiEPdirs(i), filesep);
            if length(spos{1})>2
                temp=p.multiEPdirsShort{i};
                temp=['...', temp(spos{1}(end-1):end)];
                p.multiEPdirsShort{i}=temp;
            end
        end
        if isempty(p.dirOverlay)
            vl=1;
        else
            vl=find(strcmp(p.multiEPdirs(~strcmp(p.multiEPdirs, p.dirS)), p.dirOverlay));
        end
        p.multiEPdirsShort=p.multiEPdirsShort(~strcmp(p.multiEPdirs, p.dirS));
        if ~isempty(p.multiEPdirsShort)
            set(hs.overlayselect, 'String', p.multiEPdirsShort, 'Value', vl, 'Enable', 'on', 'BackgroundColor', 'white');
            ChangeOverlayFolder_callBack;
        else
            set(hs.overlayselect, 'String', 'disabled', 'Enable', 'inactive', 'BackgroundColor', hs.btnCol.gray);
        end
    end %set overlay folder
    function AddNonGrowing_callback(~,~)
        % user clicks on current image to delimit a circle
        Fvar.clickdisable=1;
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %the list doesn't exist
        if strcmp(p.operatingMode, 'TL')
            waitfor(errordlg('This function is only valid for single image sets')); return
        end
        
        makeUndo(0); %saving for undos
        
        % instructions to users
        hs.UserMess.String='click on image to place colony with radius = 0';customdrawnow
        
        %get colony center
        if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale
            [X1, Y1] = ginput(1);
        else
            [X1, Y1] =  ginputCustom(1);
        end
        if X1<1 || Y1<1 || X1>size(Fvar.rgb,2) || Y1>size(Fvar.rgb,1)
            hs.UserMess.String=''; customdrawnow
            return
        end
        %         hold on;
        %         h = plot(X1, Y1, 'r');
        %         %get radius from a second click
        %         set(gcf, 'WindowButtonMotionFcn', {@mousemove, h, [X1 Y1]}); %to have an updating circle
        %         k = waitforbuttonpress; %#ok<NASGU>
        %         set(gcf, 'WindowButtonMotionFcn', ''); %unlock the graph
        r = 0; %circle coordinates are in h object
        
        %add cells
        if size(p.centers,1)>=1 %add to existing list
            a=[p.centers(:,1);X1] ;%to check
            ba=[p.centers(:,2);Y1] ;%to check
            p.centers=[a ba];
            p.radii=[p.radii;r];
        else %or to empty matrix
            p.centers=[X1,Y1];
            p.radii=r;
        end
        
        % Update handles structure
        p.colonyCenRad{p.i,1}=p.centers;
        p.colonyCenRad{p.i,2}=p.radii;
        
        %check if the next sets of buttons can be activated
        
        if p.progress.found==0 && ~isempty(p.colonyCenRad{p.i,1})
            p.progress.found=1;
            ProgressUpdate;
        end
        %refresh Graph
        if ~p.disableSave
            saveall(p.dirS);
            voronoisave(p.dirS);
        end
        refresh(1);
        hs.UserMess.String='';customdrawnow
        Fvar.clickdisable= ~p.modColonyClick;
    end %add a zero radius colony
    function MultiEPLoad_Callback(~,~)
        newdir=uigetdir2(p.dir, 'Select folders containing different timepoints');
        %the function uigetdir2 allows multiple selection, but also allow selecting files
        if isempty(newdir); return; end %click cancel
        %% removing file names
        newdir2=cell(0);
        for i=1:length(newdir)
            if isfolder(newdir{i}) %isdir
                newdir2{end+1}=newdir{i};
            end
        end
        
        if ~isfield(p, 'multiEPdirs')
            p.multiEPdirs=[];
        end
        if iscell(newdir2)
            p.multiEPdirs=sort(unique([p.multiEPdirs;newdir2'; p.dirS]));
        end
        %         pback=struct();
        p.flist=1:length(p.l);
        loader=MultiEP_LoadCenter;
        if loader
            for i=1:length(p.multiEPdirs)
                try
                    p=rmfield(p, ['counts',num2str(i)]);
                    p=rmfield(p, ['umConversion',num2str(i)]);
                    p=rmfield(p, ['l',num2str(i)]);
                catch
                    continue
                end
            end
            return
        end
        MultiEP_MatchCenters
        set(hs.showmultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        set(hs.plot, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        set(hs.GRmultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        setoverlayfolders
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0)
        hs.UserMess.String=[num2str(length(p.multiEPdirs)), ' multi-EP folders loaded'];customdrawnow
        
    end %load linked folders button
    function loader=MultiEP_LoadCenter
        pback=p;
        loader=0;
        for i=1:length(p.multiEPdirs)
            p.dir=pback.multiEPdirs{i};
            p.l=[];
            er=chngDir;
            if ~er || isempty(p.colonyCenRad)
                p=pback;
                loader=1;
                hs.UserMess.String=[p.multiEPdirs{i}, ' does not contain data. Process aborted.'];customdrawnow
                return
            end
            if length(p.l)~=length(pback.l)
                p=pback;
                hs.UserMess.String=[p.multiEPdirs{i},...
                    ' contains not equal number of images as in loaded folder. Process aborted.'];customdrawnow
                loader=1;
                return
            end
            
            pback.(['counts',num2str(i)])(pback.flist,:)=p.colonyCenRad(pback.flist,:);
            try
                pback.(['umConversion',num2str(i)])(pback.flist,:)=p.umConversion(pback.flist,:);
            catch
                waitfor(errordlg(['Spatial calibration is missing for at least one iamge in folder ', p.dir]));
                pback.(['umConversion',num2str(i)])(pback.flist,:)=nan(length(pback.umConversion(pback.flist,:)),1);
            end
            pback.(['l',num2str(i)])(pback.flist,:)=p.l(pback.flist,:);
        end
        p=pback;
        pback=struct();
    end %load the data
    function MultiEP_MatchCenters(~,~)
        mismatchcenter=[];
        mismatchfolder=[];
        refolder=find(strcmp(p.dirS, p.multiEPdirs));
        for i=1:length(p.multiEPdirs)
            if i==refolder; continue; end
            for i2=1:length(p.l)
                %                 if sum(i2==mismatchcenter); continue; end
                if length(p.(['counts',num2str(refolder)]){i2,1})<length(p.(['counts',num2str(i)]){i2,1})
                    mismatchcenter=[mismatchcenter, i2];
                    mismatchfolder=[mismatchfolder, p.multiEPdirs(i)];
                    continue
                end
                if size(p.(['counts',num2str(refolder)]){i2,1},1)==0
                    continue
                end
                dst=pdist2(p.(['counts',num2str(refolder)]){i2,1}, p.(['counts',num2str(i)]){i2,1});
                val=nan(size(dst,1),1);
                idx=nan(size(dst,1),1);
                for i3=1:size(dst,1)
                    [val(i3), idx(i3)]=min(dst(i3,:));
                end
                
                p.(['counts',num2str(i)]){i2,1}=p.(['counts',num2str(i)]){i2,1}(idx,:);
                p.(['counts',num2str(i)]){i2,2}=p.(['counts',num2str(i)]){i2,2}(idx);
            end
        end
        
        if ~isempty(mismatchcenter)
            msglist=[];
            for i2=1:length(mismatchcenter)
                p.(['counts',num2str(i)]){mismatchcenter(i2),1}=[];
                p.(['counts',num2str(i)]){mismatchcenter(i2),2}=[];
                p.(['counts',num2str(refolder)]){mismatchcenter(i2),1}=[];
                p.(['counts',num2str(refolder)]){mismatchcenter(i2),2}=[];
                msglist=[msglist, 'folder: ', mismatchfolder(i2),...
                    ', frame: ', num2str(mismatchcenter(i2)), '; '];
            end
            
            msg=['Number of detected colonies of main folder is lower than in in: ',cell2mat(msglist),...
                '. Colonies on these frames are discarded for all multiple timepoint EP mode. ',...
                'If you want to use the data of these colonies, re-open the folders and ',...
                'ensure matching number of colonies.'];
            waitfor(errordlg(msg,'Mismatching number of colonies'));
        end
        
        
    end %match centers based on distance
    function MultiEPShow_Callback(~,~)
        refresh(1)
        col=colormap();
        col=col(round(linspace(1, size(col,1), length(p.multiEPdirs))), :);
        for i=1:length(p.multiEPdirs)
            i2=p.i;
            if isempty(p.(['counts',num2str(i)]){i2,1})
                hs.UserMess.String='No sequence data for this frame loaded';customdrawnow
                return
            end
            viscircles(p.(['counts',num2str(i)]){i2,1}, p.(['counts',num2str(i)]){i2,2}+1, 'Color', col(i,:));
            for ix=1:length(p.(['counts',num2str(i)]){i2,2})
                text(p.(['counts',num2str(i)]){i2,1}(ix,1),p.(['counts',num2str(i)]){i2,1}(ix,2),...
                    ['tp',num2str(i),':c',num2str(ix)], ...
                    'FontSize',12,'Color',col(i,:),'FontWeight','bold','HorizontalAlignment','center');
            end
        end
    end %display circles of each timepoint
    function MultiEPRegister_Callback(~,~)
        
        flist= UserChoiceFrames('plot');
        if isempty(flist)% the user canceled ,abort
            hs.UserMess.String='';customdrawnow
            return;
        end
        
        
        
        
        if isfield(p, 'counts1')
            %             get folders to compare to currently loaded one
            compdirs=flip(p.multiEPdirs(~strcmp(p.dirS, p.multiEPdirs)));
            
            MultiEP_LoadCenter
        else
            compdirs={p.dirOverlay};
        end
        compls=1:length(p.multiEPdirs);
        compls=flip(compls(~strcmp(p.dirS, p.multiEPdirs)));
        iback=p.i;
        p.flist=flist;
        for frms=flist
            p.i=frms;
            %             if size(p.colonyCenRad{frms,1},1)==0
            %                 continue
            %             end
            %         get grayscale image
            
            %         i2 -> get 2 points for each image
            for i2=1:2
                cnt=1; %count value for point matrix
                %             i -> do for all folders
                for i=1:length(p.multiEPdirs)
                    
                    if i==1
                        hs.UserMess.String='Click on a point on the reference image';customdrawnow
                    else
                        hs.UserMess.String='Click on the same point on the image to align';customdrawnow
                    end
                    
                    if i==1 %the reference image, get fixed points
                        Fvar.rgb = imread([p.dir, filesep,p.l(p.i).name]); %loading pic
                        if strcmp(p.imgFormat, 'rgb')
                            Fvar.imgray=customcol2gray(Fvar.rgb);
                            Fvar.im=imshow(Fvar.imgray);
                        else
                            Fvar.im=imshow(Fvar.rgb);
                        end
                        ax = gca;
                        ax.Toolbar.Visible = 'off';
                        [X1, Y1] =  ginputCustom(1);
                        if X1<1 || Y1<1 || X1>size(Fvar.rgb,2) || Y1>size(Fvar.rgb,1)
                            hs.UserMess.String=''; customdrawnow
                            return
                        end
                        fixedPoints(i2,1)=X1; fixedPoints(i2,2)=Y1;
                        
                    else %any of the folders to align
                        if strcmp(compdirs{i-1},{p.dirOverlay})
                            if ~exist([compdirs{i-1}, filesep, p.lOverlay(p.i).name], 'file')
                                p.i=iback;
                                p.iold=0;
                                refresh(0);
                                hs.UserMess.String=['No images or folder ', compdirs{i-1}, ' missing'];customdrawnow
                            end
                        elseif ~exist([compdirs{i-1}, filesep, p.(['l',num2str(compls(i-1))])(p.i).name], 'file')
                            p.i=iback;
                            p.iold=0;
                            refresh(0);
                            hs.UserMess.String=['No images or folder ', compdirs{i-1}, ' missing'];customdrawnow
                            return
                        end
                        if isfield(p, 'counts1')
                            overgray=imread([compdirs{i-1}, filesep, p.(['l',num2str(compls(i-1))])(p.i).name]);
                        else
                            overgray=imread([compdirs{i-1}, filesep, p.lOverlay(p.i).name]);
                        end
                        if strcmp(p.imgFormat, 'rgb')
                            overgray=customcol2gray(overgray);
                        end
                        Fvar.im=imshow(overgray);
                        ax = gca;
                        ax.Toolbar.Visible = 'off';
                        [X1, Y1] =  ginputCustom(1);
                        
                        if X1<1 || Y1<1 || X1>size(overgray,2) || Y1>size(overgray,1)
                            hs.UserMess.String=''; customdrawnow
                            return
                        end
                        
                        if i2==1 %save point
                            movingPoints(cnt,1)=X1; movingPoints(cnt,2)=Y1;
                        else
                            movingPoints(cnt+1,1)=X1; movingPoints(cnt+1,2)=Y1;
                        end
                        cnt=cnt+2;
                    end
                end
            end
            
            %         finally apply the transform to the centers
            cnt=1;
            for i=1:length(compls)
                tform = fitgeotrans(movingPoints(cnt:cnt+1,:), fixedPoints,'nonreflectivesimilarity');
                if strcmp(compdirs{i},p.dirOverlay)
                    p.mytform(p.i)=tform;
                end
                
                if isfield(p, 'counts1')
                    p.(['counts',num2str(compls(i))]){p.i,1}=transformPointsForward(tform, ...
                        cell2mat(p.(['counts',num2str(compls(i))])(p.i,1)));
                    cnt=cnt+2;
                end
            end
        end
        if isfield(p, 'counts1')
            MultiEP_MatchCenters
        end
        saveall(p.dirS);
        p.i=iback;
        p.iold=0;
        refresh(0);
        hs.UserMess.String='All images aligned';customdrawnow
    end %register EP images
    function MultiEPGR_Callback(~,~)
        %         get timepoints
        failed=EP_timepoints;
        if failed;return;end
        %         now, go over all frames, gather radius data, calculate GR
        flist=1:length(p.l);
        rowstart=1;
        spmis=0;
        for fr=flist
            if isempty(p.(['counts',num2str(1)]){fr,2})
                hs.UserMess.String='Sequence data for at least one frame/folder is missing';customdrawnow
                continue
            end
            rad=nan(length(p.(['counts',num2str(1)]){fr,2}), length(p.multiEPdirs));
            for i=1:length(p.multiEPdirs)
                rad(:,i)=p.(['counts',num2str(i)]){fr,2};
                try
                    rad(:,i)=rad(:,i)*p.(['umConversion',num2str(i)])(fr);
                    if isnan(p.(['umConversion',num2str(i)])(fr))
                        spmis=1;
                    end
                catch
                    spmis=1;
                    hs.UserMess.String='Spatial calibration for at least one frame/folder is missing';customdrawnow
                    %                     return
                end
            end
            
            GR=[];
            for i=1:length(p.multiEPdirs)-1
                GR(:,i)=(rad(:,i+1)-rad(:,i)) / (p.timepoints(i+1)-p.timepoints(i));
                GR(rad(:,i)==0,i)=nan;
                GR(rad(:,i+1)==0,i)=nan;
            end
            p.GR(rowstart:rowstart+size(rad,1)-1,1)=1:size(rad,1);
            p.GR(rowstart:rowstart+size(rad,1)-1,2)=fr;
            p.GR(rowstart:rowstart+size(rad,1)-1,3:3+size(GR,2)-1)=GR;
            
            rowstart=rowstart+size(rad,1);
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        set(hs.GRdist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        hs.UserMess.String='Growth rate calculated';customdrawnow
        if spmis
            hs.UserMess.String='Spatial calibration for at least one frame/folder is missing';customdrawnow
        end
    end %calculate linear GR as slope
    function failed=EP_timepoints(~,~)
        %         gather time data for each folder from user
        failed=0;
        prompt = {'1. timepoint [h]:'};
        dlg_title = 'Define time'; num_lines = 1;
        for i=2:length(p.multiEPdirs)
            prompt(i)={[num2str(i), '. timepoint [h]:']};
        end
        
        if length(p.timepoints)~=length(p.multiEPdirs)
            p.timepoints=nan(length(p.multiEPdirs), 1);
            answer = inputdlg(prompt,dlg_title,num_lines);
        else
            defaults=cellstr(num2str(p.timepoints));
            answer = inputdlg(prompt,dlg_title,num_lines, defaults);
        end
        
        if isempty(answer)
            hs.UserMess.String='';customdrawnow
            return
        end
        %         check if all are in correct format
        for i=1:length(p.multiEPdirs)
            tst=str2double(answer{i});
            if length(tst)>1 || sum(isnan(tst)) || ...
                    sum(tst<0) || sum(isempty(tst))
                hs.UserMess.String='Please enter valid numbers for time';customdrawnow
                failed=1;
                return
            end
            p.timepoints(i)=tst;
        end
    end %define EP timepoints
    function GiveRef_Callback(~,~)
        choice = questdlg('Would you like to manually input the reference parameters or extract them automatically from an analyzed TL growth control experiment?',...
            'Reference growth parameters (GR, Tapp)','Manually input','Extract from an analyzed TL','Cancel','Cancel');
        % Handle response
        switch choice
            case 'Manually input'
                prompt = {'Reference GR', 'Reference appearance time'};
                dlg_title = 'Reference paramteres'; num_lines = 1;
                
                defaultans = {num2str(p.GRRef), num2str(p.TappRef)};
                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
                if isempty(answer);hs.UserMess.String='';customdrawnow; return; end
                p.GRRef=str2double(answer{1});
                p.TappRef=str2double(answer{2});
            case 'Extract from an analyzed TL'
                LoadRef();
                p.TappRef=AverageRef(p.TappRefAll);
                p.GRRef=AverageRef(p.GRRefAll);
            case 'Cancel'
                return;
        end
        
        UpdateButtonState
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(1);
        hs.UserMess.String=['Reference growth rate: ',num2str(round(p.GRRef,2)),...
            ' Reference appearance time: ', num2str(round(p.TappRef,2))]; customdrawnow
    end %define reference growth parameters
    function LoadRef(~,~)
        done2=0;
        while ~done2
            c1='arbitraryNameNoOneUses439';%will save the infos from the folder temporarily into the colonies structure
            dirUser=uigetdir(p.dir,'Reference folder...');
            
            if dirUser==0; return; end %user cancelled
            colonies.(c1).dir=dirUser;
            
            if ~isempty(dir([colonies.(c1).dir, filesep, '*','all','*'])) %found a file containg "all"
                %             l=colonies.(c1).l; %saving the list variable
                files=dir([colonies.(c1).dir, filesep, '*','all','*']);
                a=nan(length(files),1);
                for ii=1:length(files)
                    try
                        a(ii)=datenum(files(ii).date);
                    catch %somehow datenum does not work
                        if ~isempty(strfind(files(ii).date,'Mrz'))
                            files(ii).date=strrep(files(ii).date,'Mrz','Mar');
                            try
                                a(ii)=datenum(files(ii).date);
                            catch
                                errordlg(['The date of the file ', files(ii).name, ' in the folder you try to load cannot be read. Please delete that and try again.']);
                                hs.UserMess.String='Error. Loading cancelled.'; customdrawnow
                                return ;
                            end
                        end
                    end
                end
                [~, ind]=max(a);
                try
                    fileAll=load([colonies.(c1).dir,filesep,files(ind).name]); %this contains, counts, i, Rad, RadMean, dir, minRad, maxRad and sensitivity
                catch
                    waitfor(errordlg(['The file called ',files(ind).name, 'is corrupt. Plese open the folder an delete this file.']));
                end
                if isfield(fileAll,'p')
                    for fn=fieldnames(fileAll.p)'
                        colonies.(c1).(fn{1}) = fileAll.p.(fn{1});
                        %                         disp(fn{1})
                    end
                else %files created by previous versions of CTA
                    for fn=fieldnames(fileAll)'
                        colonies.(c1).(fn{1}) = fileAll.(fn{1});
                        %                         disp(fn{1})
                    end
                end
                if ~isempty(colonies.(c1).GR)
                    p.TappRefAll=colonies.(c1).Tapp;
                    p.GRRefAll=colonies.(c1).GR;
                    done2=1;
                else
                    waitfor(errordlg(''));
                    colonies=rmfield(colonies,c1);
                    return;
                end
                
                colonies=rmfield(colonies,c1);
                
            else %nothing found
                waitfor(errordlg('there is no analysis file in this folder. Try another folder'));
                return
            end
            
        end
    end %load from folder
    function av=AverageRef(parameter)
        if strcmp(p.tappRefMode, 'Mean')
            av=mean(parameter, 'omitnan');
        else
            av=quantile(parameter,p.tappRefQuantile);
        end
        
    end %mean or quantile
    function TappEst_Callback(~,~)
        if isempty(p.thistimepoint)
            prompt = {'From which timepoint are these images? (input time in h)'};
            dlg_title = 'Timepoint'; num_lines = 1;
            defaultans = {num2str(p.thistimepoint)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            p.thistimepoint=str2double(answer{1});
        end
        flist=1:length(p.l);
        maxcol=max(cellfun(@length, p.colonyCenRad),1);
        p.estTapp=nan(max(maxcol(:,1)),length(p.l));
        
        choice = questdlg('Would you like to use ',...
            'Which growth rate?','Reference growth rate','Individual colony growth rate','Cancel','Cancel');
        % Handle response
        switch choice
            case 'Reference growth rate'
                if isempty(p.GRRef)
                    GiveRef_Callback();
                end
                for fr=flist
                    p.estTapp(1:length(p.colonyCenRad{fr,2}),fr)=p.thistimepoint-(p.colonyCenRad{fr,2}*p.umConversion(fr)-p.tappThreshUm)/p.GRRef;
                end
            case 'Individual colony growth rate'
                
                for fr=flist
                    for i=1:length(p.colonyCenRad{fr,2})
                        if isempty(p.GR)
                            hs.UserMess.String='Please estimate growth rates first';customdrawnow
                            return
                        end
                        growthrates=p.GR(p.GR(:,2)==fr,3:end);
                        idx=find(sum(~isnan(growthrates(i,:)),1) > 0, 1 ,'first');
                        firstnonNanGR(i,1)= growthrates(i,idx);
                        p.estTapp(i,fr)=p.thistimepoint-(p.colonyCenRad{fr,2}(i)*p.umConversion(fr)-p.tappThreshUm)/firstnonNanGR(i,1);
                    end
                end
            case 'Cancel'
                return;
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        ProgressUpdate
        hs.UserMess.String='Apperance times estimated'; customdrawnow
    end %Tapp estimation
    function EP_intensityRadius_Callback(~,~)
        DLG=questdlg('Double circle (circle pairs, one containing th other) or single circle?',...
            'Circle mode', ...
            'Single','Double','Cancel');
        switch DLG
            case 'Double'
                doublecircle = true;
            case 'Single'
                singlecircle = false;
            case 'Cancel'
                return
            case ''
                return
        end

        hs.UserMess.String=['Please wait for intensity calculation to finish...'];customdrawnow

        T = table([], [], [], [], [], 'VariableNames', {'frame', 'colony', 'radius', 'intensity', 'insidecircle'});
        lname = 'l';
        p.channelprocessing = -1;
        TimeIdx=1;%index for counting the frames that were already processed
        p.timeList = 1:length(p.l);
        % disableGUI(1)
        Fvar.clickdisable=1;
        tic
        for whichFrame = p.timeList
            p.i = whichFrame;
            centers = p.colonyCenRad{p.i,1};
            radii = p.colonyCenRad{p.i,2};

            N = size(centers,1);
            contains = cell(N, 1); % contains{j} = indices of circles contained in j

            for j = 1:N
                in_j = [];
                for i = 1:N
                    if i ~= j
                        dist = norm(centers(i,:) - centers(j,:));
                        if dist + radii(i) <= radii(j)
                            % Circle i is contained in circle j
                            in_j = [in_j, i];
                        end
                    end
                end
                contains{j} = in_j;
            end

            

            img = imread([p.dir, filesep,p.(lname)(p.i).name]); %loading pic once per timepoint.
            p.colList = 1:length(radii);
            p.overlapTL = cell(1, numel(p.colList));
            p.focalframe = p.i;
            p.mat2grayRef=[];%initialize
            mat2grayRef
            indx = 1;
            for whichCol = p.colList
                if doublecircle
                    if isempty(contains{whichCol})
                        continue
                    end
                end
                rgbcolG=getSmallImage(whichCol,img);
                center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
                Zone=ZoneDef(center,whichCol,img,p.i);
                rres=2*Zone; % # of grid points for R coordinate. (change to needed binning)
    
                Zinterp = getRadiusIntenstity(p, rgbcolG, whichCol, rres);
                intensity = mean(Zinterp, 'omitnan');%store that in the kymograph

                radius = (1:length(intensity))*p.umConversion(p.i);
                r_big = radii(whichCol) * p.umConversion(p.i);
                
                insidecircle = (radius <= r_big); % logical vector: 1 if inside big circle, 0 otherwise
                
                if doublecircle
                    r_small = radii(contains{whichCol}) * p.umConversion(p.i);
                    insidecircle = 2 * insidecircle; % set all inside big to 2
                    insidecircle(radius <= r_small) = 1; % set all inside small to 1
                end

                n = numel(radius); % Number of elements

                % Create a new table row block
                newRows = table(...
                    repmat(whichFrame, n, 1), ...
                    repmat(whichCol, n, 1), ...
                    radius(:), ...
                    intensity(:), ...
                    insidecircle(:), ...
                    'VariableNames', {'frame', 'colony', 'radius', 'intensity', 'insidecircle'});
                
                % Append to the main table
                T = [T; newRows];

                if (indx==1) || mod(indx,5)==0
                    a=(indx/(length(p.colList)));
                    fill([0 0 a a],[0,1,1,0],[0.5 0.7 0.8],'parent', hs.Progress2); set(hs.Progress2,'Xlim',[0 1],'Ylim',[0 1],'Xcolor','none','Ycolor','none'); customdrawnow
                    text(0.25, 0.5, ['analysed ' num2str(indx) ' of ' num2str(length(p.colList)) ' colonies'],'Fontsize', 10, 'parent', hs.Progress2);customdrawnow
                end
                
                indx=indx+1;
            end
            
            a=floor(100*((TimeIdx)/(length(p.timeList))));
            textMsg=([num2str(floor(a)),'% done, est. ' sec2timestr((100*toc/a-toc)), ' remaining']);
            hs.UserMess.String=textMsg; customdrawnow
            fill([0 0 a/100 a/100],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
            TimeIdx=TimeIdx+1;
        end
        
        
        try
            filename = fullfile(p.dirS, 'radius_intensity.csv')
            writetable(T, filename, 'Delimiter',Fvar.csvdelimiterssymbol{p.csvdelimiter});
            % tell user
            hs.UserMess.String=['Data saved as ' filename];customdrawnow
        catch
            % tell user
            hs.UserMess.String=['ERROR! Could not save data, likely because file is open: ' filename];customdrawnow
        end
        
        p.channelprocessing = 1;
        disableGUI(0)
        Fvar.clickdisable=~p.modColonyClick;
    end

%% Main-TL tab
    function RegistrationCheckboxchange_Callback(~,~)
        p.REGstatus=~p.REGstatus;
        if p.REGstatus==1
            if ~isempty(p.registrationTranslation)
                for i=1:length(p.l)%get each image
                    if~isempty(p.colonyCenRadUnregistered{i,1})
                        p.colonyCenRad{i,1}=p.colonyCenRadUnregistered{i,1}+p.registrationTranslation(i,:);
                    else
                        TLRegistration
                    end
                end
                hs.UserMess.String='Registration finished';customdrawnow
            else
                TLRegistration;
            end
        else
            p.colonyCenRad=p.colonyCenRadUnregistered;
            %                p.colonyCenRadUnregistered=cell(length(p.l),2);
            hs.UserMess.String='Back to unregistered';customdrawnow
        end
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(1)
    end %registration toggle
    function TLRegistration(~,~)
        disableGUI(1)
        Fvar.clickdisable=1;
        %unzooom if zoomed in?!
        if p.i~=p.focalframe
            p.i=p.focalframe;
            refresh(0);
        end
        hs.UserMess.String='Draw rectangle. Doubleclick to confirm';customdrawnow
        h=imrect(); %#ok<IMRECT>
        position = wait(h);
        hs.UserMess.String='Please wait...';customdrawnow
        p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
        p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
        p.colonyCenRadUnregistered=p.colonyCenRad;
        if strcmp(p.imgFormat, 'rgb')
            recref= customcol2gray(imcrop(Fvar.rgb,position));
        else
            recref=imcrop(Fvar.rgb,position);
        end
        croppedlist=cell(1,length(p.l));
        for i=1:length(p.l)%get each image
            if strcmp(p.imgFormat, 'rgb')
                croppedlist{i}=customcol2gray(imcrop(imread([p.dir, filesep,p.l(i).name]),position));%and crop the area (rectangle) of interest
            else
                croppedlist{i}=(imcrop(imread([p.dir, filesep,p.l(i).name]),position));%and crop the area (rectangle) of interest
            end
            [output,~]=dftregistration(fft2(croppedlist{i}),fft2(recref),p.registrationFactor);
            p.registrationTranslation(i,:)=round([output(4),output(3)]);
            if(~isempty(p.colonyCenRad{i,1}))
                p.colonyCenRad{i,1}=p.colonyCenRadUnregistered{i,1}+p.registrationTranslation(i,:);
            end
        end
        try
            delete(h)
        catch
        end
        refresh(1);
        Fvar.clickdisable=~p.modColonyClick;
        disableGUI(0);%disable the GUI
        if ~p.disableSave
            saveall(p.dirS);
        end
        hs.UserMess.String='Registration finished';customdrawnow
    end  %actual registration function
    function AutoCenter_Callback(~,~)
        % Fvar.rgb=i90;
        
        geti=p.i;
        
        % function CenterCheck_Callback(~,~)%allows the user to check and correct the centers
        %         close_options_Callback;
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        if isempty(p.focalframe) || p.focalframe==0 %user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=p.i;
            if isempty(p.colonyCenRad{p.focalframe,1})
                errordlg('Set the frame to the one where you detected colonies for a reference and try again. If you did not detected colonies at all, do that, preferentially on the last frame.');return;
            end
        end
        
        
        
        prompt = {'Colonies to correct centers. Insert 0 for all:', 'Frame to use for correction:',...
            'Time to see center corrected image per colony in secs. Insert 0 for no display',...
            'Min radius in pxl:', 'Max radius in pxl:', 'Minimal center distance'};
        dlg_title = 'Auto correct centers'; num_lines = 1;
        defaultans = {'0', '70', '0', '4', '15', '5'};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if isempty(answer);hs.UserMess.String='';customdrawnow; return; end %user cancelled
        timeList2=round(str2double(answer{2,1}));
        waittime=str2double(answer{3,1});
        range=[round(str2double(answer{4,1})), round(str2double(answer{5,1}))];
        mindist=str2double(answer{6,1});
        %error if not in range of colonies
        
        colList1=round(str2num(answer{1,1})); %#ok<ST2NM>
        OK=setpColList(colList1); %this function sets variable p.ColList
        if OK==0; return; end %there was an error in the list
        
        if length(timeList2)>1; errordlg('Please insert only one frame number'); return; end
        if timeList2<1 || timeList2>length(p.l) || isnan(timeList2)
            errordlg('The indicated frame is outside of the image range or was not a number. Try again.');return;
        end
        
        if length(waittime)>1; errordlg('Please insert only one number for waittime'); return; end
        if isnan(waittime) || waittime<0 || waittime>10
            errordlg('Please enter a positive number lower than 10s for waittime');return;
        end
        
        if length(range)>2 || sum(isnan(range))>0 || sum(range<2)>0 || sum(range>50)
            errordlg('Please enter positive numbers in the range of [2 50] for min and max radius');return;
        end
        
        if length(mindist)>1 || sum(isnan(mindist))>0 || sum(mindist<0)>0 || sum(mindist>50)
            errordlg('Please enter a positive number in the range of [0 50] for minimal center distance');return;
        end
        p.ShowCol=0; p.showGrayscale=0; p.showNr=0;
        p.i=timeList2;
        refresh(0);
        
        %         disableGUI(1);%disable the GUI
        
        hs.UserMess.String='Center correction ongoing...';customdrawnow
        disableGUI(1);%disable the GUI
        done=0;
        toosmall = [];
        warn1 = 'images:imfindcircles:warnForSmallRadius';
        warn2 = 'images:imfindcircles:warnForLargeRadiusRange';
        warning('off', warn1); warning('off', warn2);
        
        %         for the grayscale image calculation, we need threshold values
        %         if size(p.mat2grayRef,1)~=size(p.colonyCenRad{p.i},1)
        %             OlapRembck=p.radOverlapRemoveTheta;
        %             p.radOverlapRemoveTheta=0;
        %             mat2grayRef
        %             p.radOverlapRemoveTheta=OlapRembck;
        %         end
        
        hs.UserMess.String='Please wait, center correction ongoing...';customdrawnow
        chngList(1,p.i,zeros(size(p.colonyCenRad{1},1),1));
        
        while ~done
            refresh(0);
            hs.UserMess.String='Center correction ongoing...';customdrawnow
            if ~isempty(Fvar.background) && ~Fvar.imgenhanced
                EnhanceImage_Callback
            end
            if ~ismatrix(Fvar.rgb)
                img=customcol2gray(Fvar.rgb);
            else
                img=Fvar.rgb;
            end
            
            hs.UserMess.String='Center correction ongoing...';customdrawnow
            
            for whichCol=p.colList%for which colonies
                
                center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
                centers_Others=[round(p.colonyCenRad{p.i,1}(:,2)),round(p.colonyCenRad{p.i,1}(:,1))]; %calculate the relative centers of other colonies to show on image
                centers_Others(whichCol,:)=[nan,nan]; %remove focal colony
                
                Zone=ZoneDef(center,whichCol,img,p.i);
                try
                    rgbcolG=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:);
                    %                     rgbcolG=getSmallImage(whichCol, img);
                catch
                    waitfor(errordlg(['Something is wrong with  colony ', num2str(whichCol), '... sorry :)']));
                    continue
                end
                M=double(rgbcolG);   %convert to double for calculation
                X0=(size(M,1)/2); Y0=(size(M,2)/2);%center of the image shown
                
                BW=imbinarize(rgbcolG, graythresh(rgbcolG));
                %c1=[]; r1=[];
                
                [c1,r1, ~]=imfindcircles(BW,range, 'ObjectPolarity', 'bright','sensitivity', p.detectSensitivity ,'Method', 'Twostage');
                if isempty(c1) || length(c1)>10
                    toosmall = [toosmall, whichCol];
                    continue
                end
                
                if waittime>0
                    hs.fig = imshow(rgbcolG) ; axis square %#ok<*UNRCH>
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    hold on
                    viscircles(c1,r1,'Color','r'); %plot the colony circle
                end
                
                
                
                if size(c1,1)>1
                    dist = NaN(size(c1,1),1);
                    for i=1:size(c1,1)
                        Xdif=round(X0-c1(i,1));
                        Ydif=round(Y0-c1(i,2));
                        dist(i) = (Xdif^2 + Ydif^2)^(1/2);
                    end
                    [d1,closest] = min(dist);
                    if d1>0.5*X0
                        toosmall = sort(unique([toosmall, whichCol]));
                        hold off
                        continue
                        
                    end
                    Y1 = c1(closest,2);
                    X1 = c1(closest,1);
                    viscircles(c1(closest,:),r1(closest),'Color','g'); %plot the colony circle
                    rd = r1(closest);
                elseif size(c1,1)==1
                    Y1 = c1(1,2);
                    X1 = c1(1,1);
                    rd = r1;
                    viscircles(c1,r1,'Color','g'); %plot the colony circle
                else
                    toosmall = [toosmall, whichCol];
                    hold off
                    continue
                end
                Xdif=round(X0-X1);
                Ydif=round(Y0-Y1);
                
                if waittime>0
                    if strcmp(p.imgFormat, 'rgb')
                        tx=text(X0, 0.05*size(rgbcolG,1),['Colony Nr. ',num2str(whichCol), ', Radius: ',...
                            num2str(rd)],'FontSize',15,'Color','b','FontWeight','bold','HorizontalAlignment','center');
                    else
                        tx=text(X0, 0.05*size(rgbcolG,1),['Colony Nr. ',num2str(whichCol), ', Radius: ',...
                            num2str(rd)],'FontSize',15,'Color','g','FontWeight','bold','HorizontalAlignment','center');
                    end
                    hold off
                end
                
                newCenter=[center(1)-Ydif, center(2)-Xdif];
                %                 dist = NaN(size(centers_Others,1),1);
                Ydif = -centers_Others(:,1)+round(newCenter(1));
                Xdif = -centers_Others(:,2)+round(newCenter(2));
                dist = (Xdif.^2 + Ydif.^2).^(1/2);
                %                     for i=1:size(centers_Others,1)
                %                         Xdif=round(newCenter(1)-centers_Others(i,1));
                %                         Ydif=round(newCenter(2)-centers_Others(i,2));
                %                         dist(i) = (Xdif^2 + Ydif^2)^(1/2);
                %                     end
                [d1,othercol] = min(dist);
                if d1<mindist
                    L=readList(1,p.i);
                    L(whichCol)=1; L(othercol)=1; chngList(1,p.i,L);
                    p.colList=p.colList(p.colList~=whichCol);
                    p.colList=p.colList(p.colList~=othercol);
                    hold off
                    continue
                end
                
                %assign the corrected center
                if ~p.REGstatus %if not registered, assign center to all frames
                    for indr=1:length(p.l)
                        p.colonyCenRad{indr,1}(whichCol,2)=newCenter(1);
                        p.colonyCenRad{indr,1}(whichCol,1)=newCenter(2);
                    end
                    p.colonyCenRadUnregistered=p.colonyCenRad; %update unregistered
                else %if registered
                    p.colonyCenRad{p.i,1}(whichCol,2)=newCenter(1); %assign center to current frame
                    p.colonyCenRad{p.i,1}(whichCol,1)=newCenter(2);
                    
                    %backcalc the unregistered center
                    p.colonyCenRadUnregistered{p.i,1}(whichCol,1)=p.colonyCenRad{p.i,1}(whichCol,1)-p.registrationTranslation(p.i,1);
                    p.colonyCenRadUnregistered{p.i,1}(whichCol,2)=p.colonyCenRad{p.i,1}(whichCol,2)-p.registrationTranslation(p.i,2);
                    for indr=1:length(p.l)
                        p.colonyCenRadUnregistered{indr,1}(whichCol,1)=p.colonyCenRadUnregistered{p.i,1}(whichCol,1);
                        p.colonyCenRadUnregistered{indr,1}(whichCol,2)=p.colonyCenRadUnregistered{p.i,1}(whichCol,2);
                        
                        %and recalc the registered
                        p.colonyCenRad{indr,1}=p.colonyCenRadUnregistered{indr,1}+p.registrationTranslation(indr,:);
                    end
                end
                if waittime>0
                    pause(waittime);
                    delete(tx)
                end
                
                
                
            end
            if ~isempty(toosmall)
                p.colList = toosmall;
                toosmall = [];
                
                if p.i>length(p.l)
                    p.i=length(p.l);
                elseif p.i==length(p.l)
                    done=1;
                else
                    p.i = p.i+10;
                    if p.i>length(p.l); p.i=length(p.l); end
                end
            else
                done=1;
            end
            
            
        end
        warning('on', warn1); warning('on', warn2);
        
        p.ShowCol=1; p.showGrayscale=0; p.showNr=1;
        p.i=geti;
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(0);
        disableGUI(0);%disable the GUI
        hs.UserMess.String='All centers corrected!';customdrawnow
        
        L=readList(1,p.i);L(p.colList)=1;chngList(1,p.i,L);
        if sum(L)>0
            errordlg(['Auto center correction for ', num2str(sum(L)),...
                ' colonies failed or moved them too close to another colony. ',...
                'Please use manual correction for these. You can access all these with list -1'])
        end
        
        %     end
    end %auto center correction
    function CenterCheck_Callback(~,~)
        %         close_options_Callback;
        curf=p.i;
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %the list doesn't exist
        if isempty(p.focalframe) || p.focalframe==0 %user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=length(p.l);
            if isempty(p.colonyCenRad{p.focalframe,1})
                p.focalframe=p.i;
                if isempty(p.colonyCenRad{p.focalframe,1})
                    errordlg('Set the frame to the one where you detected colonies for a reference and try again. If you did not detected colonies at all, do that, preferentially on the last frame.');return;
                end
            end
        end
        
        
        prompt = {'Which colony do you want to check? If you want to check all, insert 0. -1 for User-List; -2 for close centers list:',...
            'Choose a frame at which the colonies are smaller but still visible. Default framenumber is 2/5 of the last frame'};
        dlg_title = 'Manual colony center correction'; num_lines = 1;
        defaultans = {'0', num2str(round(length(p.l)/5*2))};
        
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        if isempty(answer);hs.UserMess.String='Center correction aborted';customdrawnow; return; end %user cancelled
        colList1=round(str2num(answer{1,1})); %#ok<ST2NM>
        OK=setpColList(colList1); %this function sets variable p.ColList
        if OK==0; return; end %there was an error in the list
        
        
        timeList2=round(str2double(answer{2,1}));
        
        if timeList2<1 || timeList2>length(p.l) || isnan(timeList2)
            errordlg('The indicated frame is outside of the image range or was not a number. Try again.');return;
        end
        
        
        
        p.ShowCol=0; p.showGrayscale=0; p.showNr=0;
        set_frame(timeList2);
        
        if ~isempty(Fvar.background) && ~Fvar.imgenhanced
            EnhanceImage_Callback
        end
        
        disableGUI(1);%disable the GUI
        if strcmp(p.imgFormat, 'rgb') && ~Fvar.imgenhanced
            btnval=255;
            btncol='b';
        elseif ~strcmp(p.imgFormat, 'rgb') && ~Fvar.imgenhanced
            btnval=255;
            btncol='g';
        else
            btnval=1;
            btncol='g';
        end
        
        
        
        
        SmallList=[];
        BigList=[];
        framInit=p.i;
        p.allDone=0;
        disbtn='start';
        
        while p.allDone~=1
            
            if ~isempty(Fvar.background)
                if ~Fvar.imgenhanced
                    EnhanceImage_Callback;
                end
            end
            img=Fvar.rgb;
            p.CntrBtn=12;
            %             col2mod=p.colList(1);
            %             p.colList=[p.colList, p.colList(end)];
            ndct=0;
            for whichCol=p.colList%for which colonies
                %             pause(0.001)
                
                
                center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colony
                Relative_centers_Others=[round(p.colonyCenRad{p.i,1}(:,2))-center(1),round(p.colonyCenRad{p.i,1}(:,1))-center(2)]; %calculate the relative centers of other colonies to show on image
                Relative_centers_Others(whichCol,:)=[nan,nan]; %remove focal colony
                Zone=ZoneDef(center,whichCol,img,p.i);
                try
                    rgbcol=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:);
                    if ~ismatrix(rgbcol)
                        rgbcolG=customcol2gray(img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:));
                    else
                        rgbcolG=rgbcol;
                    end
                catch
                    waitfor(errordlg(['Something is wrong with  colony ', num2str(whichCol), '... sorry :)']));
                    continue
                end
                M=double(rgbcolG);   %convert to double for calculation
                X0=size(M,1)/2; Y0=size(M,2)/2;%center of the image shown
                
                sz=size(rgbcolG,1);
                
                if ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toobig')
                    toobigX=ceil(7*sz/8);
                    toobigY=ceil(sz/15);
                    rgbcolG(1:toobigX,1:toobigY,:)=btnval;
                end
                
                if ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toosmall')
                    toosmallX=ceil(7*sz/8);
                    toosmallY=ceil(sz/15);
                    rgbcolG(1:toosmallX,sz-toosmallY:sz,:)=btnval;
                end
                
                saveX=ceil(sz/15);
                saveY=ceil(sz/15);
                rgbcolG(sz-saveX:sz, saveY:sz-saveY,:)=btnval;
                
                
                Fvar.im = imshow(rgbcolG); axis square %#ok<*UNRCH>
                % hs.fig= imshow(rgbcolG); axis square %#ok<*UNRCH>
                ax = gca;
                ax.Toolbar.Visible = 'off';
                hold on
                
                scatter(X0,Y0,500,'+');%add the center as +
                X1=Relative_centers_Others(:,1)+X0; %Relative to image center
                Y1=Relative_centers_Others(:,2)+Y0;
                X2=X1(X1>0 & X1<(2*X0) & Y1>0 & Y1<(2*Y0)); %Remove all those outside image
                Y2=Y1(X1>0 & X1<(2*X0) & Y1>0 & Y1<(2*Y0));
                numX=1:length(X1);numX=numX(X1>0 & X1<(2*X0) & Y1>0 & Y1<(2*Y0));
                if ~isempty(X2)
                    scatter(Y2,X2,500,'o','r');
                    text(Y2,X2,num2cell(numX),'Color','r','HorizontalAlignment','center');
                end
                
                tx=text(X0, 0.05*size(rgbcolG,1),['Colony Nr. ',num2str(whichCol)],'FontSize',15,'Color',btncol,...
                    'FontWeight','bold','HorizontalAlignment','center');
                
                if ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toobig')
                    txBig=text(toobigY/2, X0,'Too big','FontSize',15,'Color','k',...
                        'FontWeight','bold','HorizontalAlignment','center', 'Rotation', 90);
                end
                
                if ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toosmall')
                    txSmall=text((sz-saveY+sz)/2, X0,'Too small','FontSize',15,'Color','k',...
                        'FontWeight','bold','HorizontalAlignment','center', 'Rotation', 90);
                end
                
                txSave=text(X0, (sz-saveX+sz)/2,'Save & Exit','FontSize',15,'Color','k',...
                    'FontWeight','bold','HorizontalAlignment','center');
                
                hold off;
                
                hs.UserMess.String='click to place new center';customdrawnow
                %get colony center
                if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale && ~Fvar.imgenhanced
                    [X1, Y1] = ginput(1);
                else
                    [X1, Y1] =  ginputCustom(1);
                end
                
                
                if X1 <= toobigY && Y1 <= toobigX && ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toobig')
                    a='toobig';
                elseif X1 >= sz-toosmallY && Y1 <= toobigX && ~strcmp(disbtn, 'both') && ~strcmp(disbtn, 'toosmall')
                    a='toosmall';
                elseif X1 >= saveX && X1 <= sz-saveX && Y1 >= sz-saveY
                    a='save';
                else
                    a='corr';
                end
                
                
                
                
                
                if strcmp(a, 'corr')
                    Xdif=round(X0-X1);
                    Ydif=round(Y0-Y1);
                    
                    newCenter=[center(1)-Ydif, center(2)-Xdif];
                    if ~p.REGstatus %if not registered, assign center to all frames
                        for indr=1:length(p.l)
                            p.colonyCenRad{indr,1}(whichCol,2)=newCenter(1);
                            p.colonyCenRad{indr,1}(whichCol,1)=newCenter(2);
                        end
                        p.colonyCenRadUnregistered=p.colonyCenRad; %update unregistered
                    else %if registered
                        p.colonyCenRad{p.i,1}(whichCol,2)=newCenter(1); %assign center to current frame
                        p.colonyCenRad{p.i,1}(whichCol,1)=newCenter(2);
                        
                        %backcalc the unregistered center
                        p.colonyCenRadUnregistered{p.i,1}(whichCol,1)=p.colonyCenRad{p.i,1}(whichCol,1)-p.registrationTranslation(p.i,1);
                        p.colonyCenRadUnregistered{p.i,1}(whichCol,2)=p.colonyCenRad{p.i,1}(whichCol,2)-p.registrationTranslation(p.i,2);
                        for indr=1:length(p.l)
                            p.colonyCenRadUnregistered{indr,1}(whichCol,1)=p.colonyCenRadUnregistered{p.i,1}(whichCol,1);
                            p.colonyCenRadUnregistered{indr,1}(whichCol,2)=p.colonyCenRadUnregistered{p.i,1}(whichCol,2);
                            
                            %and recalc the registered
                            p.colonyCenRad{indr,1}(whichCol,:)=p.colonyCenRadUnregistered{indr,1}(whichCol,:)+p.registrationTranslation(indr,:);
                        end
                    end
                    
                    pause(0.00001)
                    delete(tx)
                    
                    if ismember(whichCol, BigList)
                        BigList(BigList==whichCol)=[];
                    end
                    if ismember(whichCol, SmallList)
                        SmallList(SmallList==whichCol)=[];
                    end
                    
                elseif strcmp(a, 'toobig') %too big, go back 5 frames
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,2)=center(1);
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,1)=center(2);
                    BigList=unique([BigList, whichCol]);
                    pause(0.00001)
                    %                         delete(tx)
                    %                         continue
                elseif strcmp(a, 'toosmall') %too small, go ahead 5 frames
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,2)=center(1);
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,1)=center(2);
                    SmallList=unique([SmallList, whichCol]);
                    pause(0.00001)
                    %                         delete(tx)
                    %                         continue
                elseif strcmp(a, 'save')
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,2)=center(1);
                    %                         p.colonyCenRad{p.focalframe,1}(col2mod,1)=center(2);
                    
                    p.allDone=1;
                    p.colList=[];
                    SmallList=[];
                    BigList=[];
                    pause(0.00001)
                    ndct=1; %#ok<NASGU>
                    break
                    
                end
                if ndct; break; end
                
                
            end
            
            
            if ~isempty(BigList)
                p.i=p.i-10;
                disbtn='toosmall';
                if p.i<1
                    p.i=1;
                    %                 waitfor(msgbox('This is the first frame, no more backtracking possible.'));
                    disbtn='both';
                end
                refresh(0)
                %                 set_frame(p.i);
                p.colList=BigList;
                %             p.colList=[p.colList, p.colList(end)];
                BigList=[];
                %             col2mod=p.colList(1);
                
            elseif ~isempty(SmallList)
                disbtn='toobig';
                if p.i<framInit
                    p.i=framInit;
                end
                p.i=p.i+10;
                if p.i>length(p.l)
                    p.i=length(p.l);
                    %                 waitfor(msgbox('This is the last frame, no more backtracking possible.'));
                    disbtn='both';
                end
                refresh(0)
                %                 set_frame(p.i);
                p.colList=SmallList;
                %             p.colList=[p.colList, p.colList(end)];
                %             col2mod=p.colList(1);
                SmallList=[];
            else
                p.allDone=1;
            end
            
        end
        
        
        %         delete(TooBig);
        %         delete(TooSmall);
        %         delete(quitsave);
        try
            delete(txBig); delete(txSmall); delete(txSave);
        catch
        end
        saveall(p.dirS);
        p.ShowCol=1; p.showGrayscale=0; p.showNr=1;
        p.i=curf;
        Fvar.im = [];
        refresh(0);
        set_frame(curf);
        if ~p.disableSave
            saveall(p.dirS);
        end
        disableGUI(0);%disable the GUI
        if strcmp(a, 'save')
            hs.UserMess.String='Center correction saved';customdrawnow
        else
            hs.UserMess.String='All centers corrected!';customdrawnow
        end
    end %manual center correction
    function closecenter_Callback(~,eventdata)
        hs.UserMess.String='Looking for close centers';customdrawnow
        pause(1/1000);
        if strcmp(eventdata.EventName, 'KeyPress')
            switch eventdata.Key
                case 'return'
                    cutoffrad=str2double(get(hs.closecenterinput, 'String')); %get the string in the field
                    if isempty(cutoffrad);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
                otherwise
                    return
            end
        elseif strcmp(eventdata.EventName, 'Action')
            cutoffrad=str2double(get(hs.closecenterinput, 'String')); %get the string in the field
            if isempty(cutoffrad);hs.UserMess.String=''; customdrawnow; return; end %user cancelled
        end
        
        chngList(1,p.i,zeros(size(p.RadMean,1),1));
        
        Distances=squareform(pdist(p.colonyCenRad{p.focalframe})); %calculate distance (smae col=NaN)
        chngList(1,p.i,((sum(Distances<cutoffrad)-1)>0)');
        if ~p.disableSave
            saveall(p.dirS);
        end
        HighlightCol_Callback();
        L=readList(1,p.i);
        if sum(L)>0
            hs.UserMess.String=['Found ', num2str(sum(L)) ,' colonies less than ',num2str(cutoffrad),' pxl appart, now in list n°-2'];customdrawnow
        else
            hs.UserMess.String=['Found no colonies less than ',num2str(cutoffrad),' pxl appart'];customdrawnow
        end
    end %detect close centers
    function FindTimeCol_Callback(~,~)
        if sum(size(p.l))==0&& b.runningBatch==0
            errordlg('please load an image series'); return;
        elseif sum(size(p.l))==0 && b.runningBatch==1
            b.summary(b.TheOneRunning)=0;
            return
        end %the list doesn't exist
        
        %the following call is used to get the colony centers
        if isempty(p.focalframe) || p.focalframe==0 %user didn't define a focal frame
            p.focalframe=p.i; %take actual frame
        end
        if isempty(p.colonyCenRad{p.focalframe,1})
            p.focalframe=length(p.l);
            if isempty(p.colonyCenRad{p.focalframe,1}) && b.runningBatch==0
                errordlg('Set the frame to the one where you detected colonies for a reference or define it with the button and try again');return;
            elseif isempty(p.colonyCenRad{p.focalframe,1}) && b.runningBatch==1
                b.summary(b.TheOneRunning)=0;
                return
            end
        end
        
        %as we want to go over all colonies and all frames, set these
        %variables up accordingly
        p.colList=1:size(p.colonyCenRad{p.focalframe,2},1); %over all colonies
        p.timeList=length(p.l):-1:1;%all frames list
        p.radUseEnhancedImg=0;
        tic
        if p.nChannel>1
            prompt = 'Which channel to process? Enter 0 for all or seperated by space';
            dlg_title = 'Timelapse channel for subset'; num_lines = 1;
            defaultans = {num2str(0)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer); return; end %user cancelled
            channlist=round(str2num(answer{1})); %#ok<ST2NM> %user input
            for nchi = channlist
                p.channelprocessing = nchi;
                StartTL;%function call for the start
            end
        else
            p.channelprocessing = 1;
            StartTL;%function call for the start
        end
        Fvar.rgb = [];
        Fvar.im = [];
        
        refresh(1)
        
    end% track radii
    function StartTL(~,~)
        %if the kymotrack is empty, a TL was never started, so intialize
        %all the variables
        if ~isstruct(b)
            b=struct();  b.runningBatch=0;
        end
        if ~isfield(b, 'runningBatch')
            b.runningBatch=0;
        end
        if p.channelprocessing == 1
            kymoname = 'Kymo'; % Construct field name dynamically
            radname = 'RadMean';
            kymomodename = 'kymomode';
        else
            kymoname = sprintf('KymoCh%d', p.channelprocessing); % Construct field name dynamically
            kymomodename = sprintf('kymomodeCh%d', p.channelprocessing); % Construct field name dynamically
            radname = sprintf('RadMeanCh%d', p.channelprocessing); % Construct field name dynamically
            if ~isfield(p, radname)
                p.(radname) = nan(size(p.RadMean)); %detection threshold in pxl
            end
            if ~isfield(p, radname)
                p.(radname) = nan(size(p.RadMean)); %detection threshold in pxl
            end
        end
        %initialize radMean with nans if empty
        if isempty(p.(radname))
            p.(radname)=nan(length((p.colonyCenRad{p.focalframe,1})), length(p.l)); %same, but will contain mean radii. A matrix is enough
        end
        
        if ~p.REGstatus
            p.colonyCenRad(:,1)=p.colonyCenRad(p.focalframe,1);
            p.colonyCenRad(:,2)=p.colonyCenRad(p.focalframe,2);
        end
        
        
        %initialize the kymograph and the tracking if not done already. The
        %KymoTrack will turn from 0 to 1 for each colony and frame
        %combination. This also means no timelapse was done yet so start
        %with a fresh one.
        if ~isfield(Kymo, kymoname)
            Kymo.(kymoname)=cell(length((p.colonyCenRad{p.focalframe,1})),1);%the kymograph. A cell field per colony
        elseif isempty(Kymo.(kymoname))
            Kymo.(kymoname)=cell(length((p.colonyCenRad{p.focalframe,1})),1);%the kymograph. A cell field per colony
        end
        if isempty(p.KymoTrack) || isempty(find(any(p.KymoTrack==1),1)) || size(p.KymoTrack,1)~=length((p.colonyCenRad{p.focalframe,1}))
            p.KymoTrack=logical(false(size(p.RadMean)));%track if the kymograph was calculated. same size as RadMean
            %two different user messages, either for a subset or a complete set
            if length(p.colList)==length((p.colonyCenRad{p.focalframe,1}))
                hs.UserMess.String='Started new timelapse analysis';customdrawnow
            else
                hs.UserMess.String='Started new subset timelapse analysis';customdrawnow
            end
            
            %else, ask the user if he wants to restart or resume. first do that
            %only for complete set TL call
        elseif ~isempty(p.KymoTrack) && length(p.colList)==length((p.colonyCenRad{p.focalframe,1})) && length(p.timeList)==length(p.l)
            stopped=find(~any(p.KymoTrack==0),1);%find at which frame the complete set was stopped
            if isempty(stopped); stopped=1; end
            if stopped~=1%if it was not stopped at the 1st  frame, we are at some frame, ask user to resume, start again or cancel
                if b.runningBatch==0 %this is not in batch mode
                    question1=questdlg(['An unfinished analysis was found which was terminated at frame ',num2str(stopped),'. Resume or start again?'],...
                        'Resume analysis','Resume','Start again','Cancel','Resume');
                end
                %if it is stopped and the number of field of RadMean is the same as
                %the number of fields of the Kymotrack==1 or number of
                %fields of the Kymotrack==1 - number of colonies, it is
                %finished already
            elseif stopped==1 && (numel(p.(radname))==(numel(p.KymoTrack(p.KymoTrack==1))+size(p.(radname),1)) || numel(p.(radname))==(numel(p.KymoTrack(p.KymoTrack==1))))
                
                if b.runningBatch==0 %this is not in batch mode
                    question1=questdlg('The analysis is already finished. Do you want to start again?',...
                        'Restart analysis','Start again','Cancel','Start again');
                end
                
            elseif stopped==1 && sum(sum(isnan(p.(radname)))) == numel(p.(radname)) && b.runningBatch==0%that means that only the CalcRadKymo was not called yet. So call the last few lines
                textMsg=('100% done. Wait a second for the final calculation...');
                hs.UserMess.String=textMsg; customdrawnow
                axes(hs.Progress1); fill([0 0 1 1],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
                text(0.25, 0.2, 'Time points','Fontsize', 10);
                
                for whichCol=p.colList
                    Kymo.(kymoname){whichCol}=mat2gray(Kymo.(kymoname){whichCol});
                    if p.kymomode(whichCol)==1
                        CalcRadKymo1(whichCol);
                    else
                        CalcRadKymo2(whichCol);
                    end
                end
                hs.UserMess.String='Completed radius calculation.'; customdrawnow
                axes(hs.Progress1); fill([0 0 1 1],[0,1,1,0],[0.5 0.7 0.8]), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
                
                p.ShowCol=1; p.showNr=0; Fvar.showImage=1;Fvar.TLrunning=0;
                textMsg=('Radius calculation finished');
                hs.UserMess.String=textMsg; customdrawnow
                fill([0 0 0 0],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
                
                refresh(0);
                return
            else
                question1= 'Start again';
            end
            if b.runningBatch==1
                question1= 'Start again';
            end
            %here comes the questiondialog switch
            switch question1
                case 'Resume'
                    p.timeList=stopped:-1:1;
                    hs.UserMess.String='Resumed timelapse analysis';customdrawnow
                case 'Start again'
                    p.(radname)=nan(length((p.colonyCenRad{p.focalframe,1})), length(p.l)); %same, but will contain mean radii. A matrix is enough
                    Kymo.(kymoname)=cell(length((p.colonyCenRad{p.focalframe,1})),1);%the kymograph. A cell field per colony
                    p.KymoTrack=zeros(size(p.RadMean));%track if the kymograph was calculated. same size as RadMean
                    hs.UserMess.String='Started new timelapse analysis';customdrawnow
                case 'Cancel'
                    return
                case ''
                    return
            end
            
            %similar thing for subset TL
        else
            %find the last frame that was done for all colonies of the subset
            stopped=find(any(p.KymoTrack(p.colList, fliplr(p.timeList))==0,1),1);
            
            %this is not the actual framenumber if a subset of frames was
            %chosen but only the index. so we need to find the actual frame
            if length(p.timeList)~=length(p.l)
                tmp=fliplr(p.timeList);
                stopped=tmp(stopped);%actual frame
            end
            if isempty(stopped)%all frames were done, so set stopped to 1
                stopped=1;
            end
            if b.runningBatch==0
                if stopped~=1
                    question1=questdlg(['An unfinished subset analysis was found which was terminated at frame ',num2str(p.timeList(stopped)),'. Resume or start again?'],...
                        'Resume analysis','Resume','Start again','Cancel','Resume');
                else
                    question1=questdlg('The analysis for this subset is already finished. Do you want to start again for the subset?',...
                        'Restart analysis','Start again','Cancel','Start again');
                end
            end
            if b.runningBatch==1 %in batch mode, everything is overwritten
                question1= 'Start again';
            end
            switch question1
                case 'Resume'
                    p.timeList=p.timeList(find(p.timeList==stopped):end);%find the index of the last frame and continue to the end of the list
                    hs.UserMess.String='Resumed timelapse analysis';customdrawnow
                case 'Start again'
                    if length(p.timeList)==length(p.l)
                        for i1=1:length(p.colList)%reset kymographs
                            Kymo.(kymoname){p.colList(i1)}=[];
                        end
                    else
                        for i1=1:length(p.colList)
                            Kymo.(kymoname){p.colList(i1)}(p.timeList,:)=nan;%reset kymographs
                        end
                    end
                    
                    p.KymoTrack(p.colList,p.timeList)=0;%reset kymo tracking
                    p.(radname)(p.colList, p.timeList)=0; %and radius
                    
                    hs.UserMess.String='Started new subset timelapse analysis';customdrawnow
                case 'Cancel'
                    return
                case ''
                    return
            end
            
        end
        
        
        hs.UserMess.String='Please wait. Variables are set up...';customdrawnow
%         if p.i==p.focalframe
%             p.i=1;
%             refresh(0);
%         end
%         p.i=p.focalframe;
%         refresh(0);
%         
%         if strcmp(p.imgFormat, 'rgb')
%         else
%         end
        
        % Create an 800x800 pixel image with a grayscale value of 0.3
        img = ones(800, 800) * 0.3;
        
        % Convert the image to uint8 format as insertText requires it
        % Note: grayscale values in img are from 0 to 1, so scale to 0-255
        imgUint8 = uint8(img * 255);
        
        % Define the text and its position
        text = ['Please wait, channel ', num2str(p.channelprocessing), newline, 'time-lapse processing...'];
        position = [400 400]; % Approximate center, you may adjust based on text size
        
        % Define text properties
        textColor = 'white';
        fontSize = 30; % Choose a font size that is readable
        
        % Use insertText to add the text to the image
        imgWithText = insertText(imgUint8, position, text, ...
            'FontSize', fontSize, 'BoxOpacity', 0, 'TextColor', textColor, 'AnchorPoint', 'Center');
        
        % Display the final image
        Fvar.rgb = [];
        Fvar.im = []; drawnow
        Fvar.im=imshow(imgWithText,'InitialMagnification', 40);
        if p.radUseEnhancedImg && p.channelprocessing == 1
            if b.runningBatch==1 && isempty(Fvar.mat2grayRefWhole)
                p.radUseEnhancedImg=0;
            elseif b.runningBatch==1 && ~isempty(Fvar.mat2grayRefWhole)
                se = strel('disk',round(size(Fvar.rgb, 1)/75));
                Fvar.background = imopen(imread([p.dir, filesep,p.l(1).name]), se); %loading pic
            else
                EnhanceImage_Callback;
            end
        end
        hs.UserMess.String='Please wait. Variables are set up...';customdrawnow
        p.showNr=0; p.showGrayscale=0; p.ShowCol=0; Fvar.showImage=0; p.showROI=0; Fvar.TLrunning=1;
        p.ShowVoronoiEdges=0; p.ShowVoronoiAreas=0;
        if p.i==p.focalframe
            p.i=1;
            refresh(0);
        end
        
        p.i=p.focalframe;
        refresh(0);
        %disable all image things
        
        p.i=p.focalframe;
        if p.radOverlapRemoveTheta
            OverlapTest;
        else
            p.overlapTL=cell(size(p.colonyCenRad{p.focalframe,1},1),1);%for each colony, which are overlapping
            p.overlapCoord=cell(size(p.colonyCenRad{p.focalframe,1},1),1); %and for each colony, where are the coordinates
            p.overlapCoordSmall=p.overlapCoord;
        end
        
        
        %         if isempty(p.mat2grayRef) || size(p.mat2grayRef,1)~=length(p.colonyCenRad{p.focalframe})
        mat2grayRef;%get the threshold values for the mat2gray call
        %         end
        
        tic
        hs.UserMess.String='starting analysis';customdrawnow
        
        %         disableGUI(1);%disable the gui during the TL run
        TimeIdx=1;%index for counting the frames that were already processed
        disableGUI(1);%disable the GUI
        %         p.i=p.timeList(1);%set frame to the first of the timelist
        for whichTime=p.timeList %over times
            p.i=whichTime;%set frame
            hs.UserMessFrame.String=['frame ',num2str(p.i), ' of ', num2str(length(p.l))];
            findColonies2;%actual kymograph calculation function
            
            % telling user how long remains
            a=floor(100*((TimeIdx)/(length(p.timeList))));
            textMsg=([num2str(floor(a)),'% done, est. ' sec2timestr((100*toc/a-toc)), ' remaining']);
            hs.UserMess.String=textMsg; customdrawnow
            fill([0 0 a/100 a/100],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
            %             text(0.25, 0.5, 'Time points','Fontsize', 10,'Parent',hs.Progress1);
            
            %only save to the HD every 10 frames
            if mod(TimeIdx,20)==0 || whichTime==1
                p.KymoChanged=1;
                saveall(p.dirS);
                p.KymoChanged=0;
            end
            TimeIdx=TimeIdx+1;
        end %over all times
        
        %         %now, call for all images the mat2gray function.
        %         for i=p.colList
        %             p.Kymo{i}=mat2gray(p.Kymo{i});
        %         end
        
        p.showplot=0;
        initializeedges;
        p.(kymomodename)(1:size(Kymo.(kymoname),1),1)=p.radDefaultKymoMode;
        p.BinThresh=nan(size(Kymo.(kymoname),1),1);
        for whichCol=p.colList
            if p.channelprocessing == 1
                Kymo.(kymoname){whichCol}=mat2gray(Kymo.(kymoname){whichCol});
            end
            if p.(kymomodename)(whichCol)==1
                CalcRadKymo1(whichCol);
            else
                CalcRadKymo2(whichCol);
            end
        end
        
        p.KymoChanged=1;
        saveall(p.dirS);
        p.KymoChanged=0;
        textMsg=('100% done. Wait a second for the final calculation...');
        hs.UserMess.String=textMsg; customdrawnow
        fill([0 0 1 1],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
        % text(0.25, 0.2, 'Time points','Fontsize', 10, 'Parent',hs.Progress1);
        
        p.ShowCol=1; p.showNr=0; Fvar.showImage=1; p.showROI; Fvar.TLrunning=0;
        disableGUI(0);%enable the GUI again
        
        fill([0 0 0 0],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
        
        set_frame(length(p.l));
        pause(0.01);
        
        %         free some space
        if isfield(p, 'overlapCoord')
            p=rmfield(p, 'overlapCoord');
        end
        if isfield(p, 'overlapCoordSmall')
            p=rmfield(p, 'overlapCoordSmall');
        end
        if isfield(p, 'overlapTL')
            p=rmfield(p, 'overlapTL');
        end
        ProgressUpdate %update progess & buttons
        RadUmCalc;%calculate the umradius
        if ~p.disableSave
            saveall(p.dirS);
        end
        Fvar.im=[];
        disableGUI(0);%disable the GUI
        refresh(0);
        hs.UserMess.String='Radius calculation finished'; customdrawnow
        
    end %intialize the TL run
    function mat2grayRef(~,~)
        %with this function we calculate the reference max and min values
        %the image for each colony can have for the mat2gray transformation
        %done in the findColonies2 function
        
        if size(p.mat2grayRef, 1)~=length(p.colonyCenRad{p.focalframe})
            p.mat2grayRef=nan(length(p.colonyCenRad{p.focalframe}),2);%initialize
        else
            p.mat2grayRef(p.colList,:)=nan;%initialize
        end
        
        if p.channelprocessing ~= 1
            p.mat2grayRef(:,1) = 0;
            fieldName = sprintf('l%d', p.channelprocessing); % Construct field name dynamically
            if p.channelprocessing == -1
                fieldName = 'l';
            end
            img = imread([p.dir, filesep,p.(fieldName)(length(p.(fieldName))).name]); %loading pic once per timepoint.
            if isa(img, 'uint16')
                maxval = 2^16;
            elseif isa(img, 'uint8')
                maxval = 2^8;
            else
                maxval = max(img(:));
                if maxval <1
                    maxval  = 1;
                end
            end
            p.mat2grayRef(:,2) = maxval;
            return
        end
        
        if p.radUseEnhancedImg
            %            img = mat2gray(imread([p.dir, filesep,p.l(p.focalframe).name]), Fvar.mat2grayRefWhole) - mat2gray(Fvar.background, Fvar.mat2grayRefWhole);
            if p.channelprocessing == 1
                img = mat2gray(imread([p.dir, filesep,p.l(length(p.l)).name]) - Fvar.background, Fvar.mat2grayRefWhole);
            else
                fieldName = sprintf('l%d', p.channelprocessing); % Construct field name dynamically
                p.(fieldName) = p.l(p.channelindex == chi);
                img = mat2gray(imread([p.dir, filesep,p.(fieldName)(length(p.(fieldName))).name]) - Fvar.background, Fvar.mat2grayRefWhole);
            end
        else
            if p.channelprocessing == 1
                img = imread([p.dir, filesep,p.l(length(p.l)).name]); %loading pic once per timepoint.
            else
                fieldName = sprintf('l%d', p.channelprocessing); % Construct field name dynamically
                img = imread([p.dir, filesep,p.(fieldName)(length(p.(fieldName))).name]); %loading pic once per timepoint.
            end
            
        end
        if p.channelprocessing == 1 && p.BlackColony
            img = imcomplement(img);
        end
        
        for whichCol=p.colList %going over all colonies in list
            center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
            Zone=ZoneDef(center,whichCol,img,p.i);
            
            if strcmp(p.imgFormat, 'rgb')
                try
                    rgbcol=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:); % 3 colors
                catch%if that was not possible, the radius in the counts file of the focalframe reaches outside the image. remove that colony
                    p.colList(p.colList==whichCol)=[];
                    continue
                end
            else
                try
                    rgbcolG=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone);
                catch
                    p.colList(p.colList==whichCol)=[];
                    continue
                end
            end
            
            ImgMethod=p.imgMethod;
            
            %transform the small image. here we do NOT want to have the
            %mat2gray option as we want to know the min and max values
            if strcmp(p.imgFormat, 'rgb')
                if ImgMethod==1
                    rgbcolG=(rgbcol(:,:,1));
                elseif ImgMethod==2
                    rgbcolG=(rgbcol(:,:,2));
                elseif ImgMethod==3
                    rgbcolG=(rgbcol(:,:,3));
                    
                elseif ImgMethod==4
                    rgbcolG=rgb2lab(rgbcol);rgbcolG=(rgbcolG(:,:,1));
                elseif ImgMethod==5
                    rgbcolG=rgb2lab(rgbcol);rgbcolG=(imcomplement(rgbcolG(:,:,2)));
                elseif ImgMethod==6
                    rgbcolG=rgb2lab(rgbcol);rgbcolG=(imcomplement(rgbcolG(:,:,3)));
                    
                elseif ImgMethod==7
                    rgbcolG=rgb2ntsc(rgbcol); rgbcolG=(rgbcolG(:,:,1));
                elseif ImgMethod==8
                    rgbcolG=rgb2ntsc(rgbcol); rgbcolG=(imcomplement(rgbcolG(:,:,2)));
                elseif ImgMethod==9
                    rgbcolG=rgb2ntsc(rgbcol); rgbcolG=(imcomplement(rgbcolG(:,:,3)));
                    
                elseif ImgMethod==10
                    rgbcolG=rgb2xyz(rgbcol); rgbcolG=(rgbcolG(:,:,1));
                elseif ImgMethod==11
                    rgbcolG=rgb2xyz(rgbcol); rgbcolG=(rgbcolG(:,:,2));
                elseif ImgMethod==12
                    rgbcolG=rgb2xyz(rgbcol); rgbcolG=(rgbcolG(:,:,3));
                    
                elseif ImgMethod==13
                    rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=(rgbcolG(:,:,1));
                elseif ImgMethod==14
                    rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=(imcomplement(rgbcolG(:,:,2)));
                elseif ImgMethod==15
                    rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=(imcomplement(rgbcolG(:,:,3)));
                elseif ImgMethod==16
                    rgbcolG=rgb2gray(rgbcol);
                else
                    rgbcolG=(rgbcol(:,:,2));
                end
            end
            
            %finally store these values:
            %the minimum is derived from the unblurred image
            p.mat2grayRef(whichCol,1)=(min(min(rgbcolG)));
            
            %then we blur the image to hopefully get rid of potential
            %glares to give a more realistic cutoff value for colonies
            h = fspecial('disk',size(rgbcolG,1)/12);
            blurred = imfilter(rgbcolG,h,'replicate');
            
            p.mat2grayRef(whichCol,2)=(max(max(blurred)));
            
            %this is for the overlap coordinations. need to get these for
            %the small image as well
            if p.radOverlapRemoveTheta
                for tst=1:size(p.overlapCoord{whichCol},1)
                    if ~isnan(p.overlapCoord{whichCol}(tst,1))
                        distX1=center(2)-p.overlapCoord{whichCol}(tst,1);
                        distY1=center(1)-p.overlapCoord{whichCol}(tst,2);
                        
                        distX2=center(2)-p.overlapCoord{whichCol}(tst,3);
                        distY2=center(1)-p.overlapCoord{whichCol}(tst,4);
                        
                        p.overlapCoordSmall{whichCol}(tst,1)=round(size(rgbcolG,1)/2-distX1);
                        p.overlapCoordSmall{whichCol}(tst,2)=round(size(rgbcolG,1)/2-distY1);
                        
                        p.overlapCoordSmall{whichCol}(tst,3)=round(size(rgbcolG,1)/2-distX2);
                        p.overlapCoordSmall{whichCol}(tst,4)=round(size(rgbcolG,1)/2-distY2);
                    end
                end
            end
        end
    end%calculate the reference values (min, max) for the mat2gray function
    function rgbcolG=getSmallImage(whichCol,img)
        %this isc alled by findColonies2 to calculate the small image of a
        %colony in grayscale based also on the reference values for max and
        %min colors to be transformed by the mat2gray call
        center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
        Zone=ZoneDef(center,whichCol,img,p.i);
        
        try
            rgbcol=img(center(1)-Zone:center(1)+Zone,center(2)-Zone:center(2)+Zone,:); % 3 colors
        catch%if that was not possible, the radius in the counts file of the focalframe reaches outside the image. remove that colony
            p.colList(p.colList==whichCol)=[];
            rgbcolG = [];
            return
        end
        
        ImgMethod=p.imgMethod;
        
        %transform the small image. the mat2gray ensures that the
        %values of the small iamges are always in [0 1]. By using the
        %mat2grayRef values that were defined for the focalframe where
        %there are definitly some colonies, we prevent the mat2gray
        %function to automatically define cutoff values from the image that
        %is loaded into the mat2gray function. If that would be allowed, it
        %could be possible that the images with no colony on it are
        %brighter than the ones with colonies.
        if strcmp(p.imgFormat, 'rgb')
            
            if ImgMethod==1
                rgbcolG=mat2gray(rgbcol(:,:,1), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==2
                rgbcolG=mat2gray(rgbcol(:,:,2), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==3
                rgbcolG=mat2gray(rgbcol(:,:,3), p.mat2grayRef(whichCol,:));
                
            elseif ImgMethod==4
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(rgbcolG(:,:,1), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==5
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==6
                rgbcolG=rgb2lab(rgbcol);rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)), p.mat2grayRef(whichCol,:));
                
            elseif ImgMethod==7
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==8
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==9
                rgbcolG=rgb2ntsc(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)), p.mat2grayRef(whichCol,:));
                
            elseif ImgMethod==10
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==11
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,2), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==12
                rgbcolG=rgb2xyz(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,3), p.mat2grayRef(whichCol,:));
                
            elseif ImgMethod==13
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(rgbcolG(:,:,1), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==14
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,2)), p.mat2grayRef(whichCol,:));
            elseif ImgMethod==15
                rgbcolG=rgb2ycbcr(rgbcol); rgbcolG=mat2gray(imcomplement(rgbcolG(:,:,3)), p.mat2grayRef(whichCol,:));
                
            elseif ImgMethod==0
                rgbcolG=rgbcol;
            elseif ImgMethod==16
                rgbcolG=mat2gray(rgb2gray(rgbcol), p.mat2grayRef(whichCol,:));
            else
                rgbcolG=mat2gray(rgbcol(:,:,2), p.mat2grayRef(whichCol,:));
            end
            
        else
            rgbcolG=mat2gray(rgbcol, p.mat2grayRef(whichCol,:));
        end
        
    end%to calculate the small grayscale image of 1 colony
    function OverlapTest(~,~)
        %this detects for each colony the colonies with which it overlaps.
        %Then it calculates the 2 points in which the colony circle
        %intercepts with each other
        p.overlapTL=cell(size(p.colonyCenRad{p.focalframe,1},1),1);%for each colony, which are overlapping
        p.overlapCoord=cell(size(p.colonyCenRad{p.focalframe,1},1),1); %and for each colony, where are the coordinates
        % for each col in p.overlapCoord:
        % p.overlapCoord{focusColony}(overlapping colony)=[P1 x, P1 y, P2 x, P2 y]
        
        for foc=p.colList %over all colonies
            allOthers=1:size(p.colonyCenRad{p.focalframe,1},1);%the list of all other colonies
            allOthers=allOthers(allOthers~=foc);%remove the focal colony (do not need to compare with itself...)
            ovlps=[];%reset
            p.overlapCoord{foc}=nan(size(p.colonyCenRad{p.focalframe,1},1),4);%create cell for the coords
            for chk=allOthers%for all colonies potentially overlapping
                x1=p.colonyCenRad{p.focalframe,1}(foc,1);%x of focalcolony
                y1=p.colonyCenRad{p.focalframe,1}(foc,2);%y of focalfolony
                x2=p.colonyCenRad{p.focalframe,1}(chk,1);%x of comparison colony
                y2=p.colonyCenRad{p.focalframe,1}(chk,2); %y of comparison colony
                r1=p.colonyCenRad{p.focalframe,2}(foc)*p.radOverlapScale; %rad of focal colony
                r2=p.colonyCenRad{p.focalframe,2}(chk); %rad of comparison colony
                d2 = (x2-x1)^2+(y2-y1)^2; %distance between centers
                d = sqrt(d2);
                t = ((r1+r2)^2-d2)*(d2-(r2-r1)^2); %the test if these circles overlap
                if t >= 0 % The circles overlap
                    %that would calculate the area of the overlap region (from
                    %web)
                    %            A = r1^2*acos((r1^2-r2^2+d2)/(2*d*r1)) ...
                    %               +r2^2*acos((r2^2-r1^2+d2)/(2*d*r2)) ...
                    %               -1/2*sqrt(t);
                    ovlps=[ovlps, chk]; %store that colony nr together with all overlapping
                    a=(r1^2-r2^2+d2)/(2*d); %distance from focal col center to line between the two circle intersection points
                    h=sqrt(r1^2-a^2); %half of distance between the two intersection points
                    P1=round([x2+h*(y2-y1)/d, y2+h*(x2-x1)/d]); %point 1
                    P2=round([x2-h*(y2-y1)/d, y2-h*(x2-x1)/d]); %point 2
                    p.overlapCoord{foc}(chk,:)=[P1, P2]; %store these points
                elseif d > r1+r2  % The circles are disjoint
                    %            A = 0;
                else  % One circle is contained entirely within the other
                    %            A = pi*min(r1,r2)^2;
                end
                
            end
            p.overlapTL{foc}=ovlps; %store
        end
        p.overlapCoordSmall=p.overlapCoord;
    end %detect overlapping colonies and the corresponding angles
    function findColonies2(~,~)
        %The find colonies function for the timelapse. Uses max of derivative for
        %rad detection. If that fails somehow, the old method based on threshold is
        %used
        indx=1; %counts the colonies
        %         upd=1:round(length(p.colList)/20):length(p.colList);
        errid='MATLAB:scatteredInterpolant:TooFewPtsInterpWarnId';
        
        warning('off',errid);
        if p.channelprocessing == 1
            kymoname = 'Kymo'; % Construct field name dynamically
            lname = 'l';
        else
            kymoname = sprintf('KymoCh%d', p.channelprocessing); % Construct field name dynamically
            lname = sprintf('l%d', p.channelprocessing); % Construct field name dynamically
        end
        
        if p.radUseEnhancedImg
            img = mat2gray(imread([p.dir, filesep,p.(lname)(p.i).name]) - Fvar.background, Fvar.mat2grayRefWhole);
        else
            img = imread([p.dir, filesep,p.(lname)(p.i).name]); %loading pic once per timepoint.
        end
        
        if p.channelprocessing == 1 && p.BlackColony
            img = imcomplement(img);
        end
        
        for whichCol=p.colList %over all/userdefined Number colonies
            rgbcolG=getSmallImage(whichCol, img);%call to get the small image displaying only the colony in grayscale.
            if isempty(rgbcolG)
                continue
            end

            center=[round(p.colonyCenRad{p.i,1}(whichCol,2)),round(p.colonyCenRad{p.i,1}(whichCol,1))]; %contains the centers of colonies
            Zone=ZoneDef(center,whichCol,img,p.i);
            rres=2*Zone; % # of grid points for R coordinate. (change to needed binning)

            if isempty(Kymo.(kymoname){whichCol}) %means no values have yet been assigned. initialize with zeros
                Kymo.(kymoname){whichCol}=zeros(length(p.l), rres);
            end

            Zinterp = getRadiusIntenstity(p, rgbcolG, whichCol, rres);
            if isempty(Zinterp)
                Kymo.(kymoname){whichCol}(p.i,:)=0;
                p.KymoTrack(whichCol,p.i)=1;
                continue
            end
            
            Kymo.(kymoname){whichCol}(p.i,:)=mean(Zinterp, 'omitnan');%store that in the kymograph
            p.KymoTrack(whichCol,p.i)=1;%track which colony and frame combinations were done already for resume purpose
            
            % %                         figure;
            % %                         imagesc(Zinterp); hold on;
            % %                         title(['ColNr ',num2str(whichCol)]);
            % %                         pause(1);
            % %                         try
            % %                         close(ff);
            % %                         catch
            % %                         end
            
            % telling user how long remains
            
            
            
            if (indx==1) || mod(indx,5)==0
                a=(indx/(length(p.colList)));
                fill([0 0 a a],[0,1,1,0],[0.5 0.7 0.8],'parent', hs.Progress2); set(hs.Progress2,'Xlim',[0 1],'Ylim',[0 1],'Xcolor','none','Ycolor','none'); customdrawnow
                text(0.25, 0.5, ['analysed ' num2str(indx) ' of ' num2str(length(p.colList)) ' colonies'],'Fontsize', 10, 'parent', hs.Progress2);customdrawnow
            end
            
            indx=indx+1;
            %             refresh(0);
            
            %clear all variables
            
            clear center; clear Zone; clear rgbcol; clear rgbcolG; clear m; clear X0; clear Y0; clear Y; clear X; clear z; clear theta;
            clear rho; clear rmin; clear rmax; clear tmin; clear tmax; clear rhoi; clear thetai; clear Zinterp; clear F;
            
        end%for colony loop end
        warning('on',errid);
    end %create slice of kymograph
    function Zinterp = getRadiusIntenstity(p, rgbcolG, whichCol, rres)
        Zinterp = [];
        M=double(rgbcolG);   %convert to double for calculation
        if all(M(:) == 0)  % Check if all elements in M are 0
            M(:) = 1 / (2^16);  % Replace all elements with 1 / (2^16)
        end
        
        X0=size(M,1)/2; Y0=size(M,2)/2;%center point of square image
        [Y,X,z]=find(M);%assigne the color value to z
        
        if isempty(z)%something went wrong, assing zero radius to that colony and frame
            return
        end
        
        X=X-X0; Y=Y-Y0;
        theta = atan2(Y,X);%transform into radial coordinates
        rho = sqrt(X.^2+Y.^2);
        
        %here: check if the colony we look at has some other
        %colonies overlapping with it. if yes, enter loop
        if ~isempty(p.overlapTL{whichCol})
            %set up the temporal storage of the two points in radial
            %coordinates
            p1=nan(length(p.overlapTL{whichCol}),1);
            p2=nan(length(p.overlapTL{whichCol}),1);
            %bordercheck: it's not clear which of the two points of the
            %overlap detection is the start and which the end of the
            %range of theta to exclude. Normally, from the smaller to
            %the bigger theta value works. but not if the overlapping
            %colony is to the left of the focal colony. then, between
            %the bigger theta to +pi and from -pi to smaller theta
            %needs to be excluded. bordercheck turns to 1 if that more
            %complicated approach needs execution
            borderCheck=false(length(p.overlapTL{whichCol}),1);
            ind=1;
            for olap=p.overlapTL{whichCol} %this is the long and complex test if the colony is one of these special cases
                if ((p.overlapCoordSmall{whichCol}(olap,1)-X0 < 0 && p.overlapCoordSmall{whichCol}(olap,2)-Y0 > 0)  &&...
                        (p.overlapCoordSmall{whichCol}(olap,3)-X0 <0 && p.overlapCoordSmall{whichCol}(olap,4)-Y0 <0)) || ...
                        ((p.overlapCoordSmall{whichCol}(olap,3)-X0 < 0 && p.overlapCoordSmall{whichCol}(olap,4)-Y0 > 0)  &&...
                        (p.overlapCoordSmall{whichCol}(olap,1)-X0 <0 && p.overlapCoordSmall{whichCol}(olap,2)-Y0 <0))
                    borderCheck(ind)=1;
                end
                %transform the kartesian coordinates of the two points
                %to radial
                p1(ind)=atan2(p.overlapCoordSmall{whichCol}(olap,2)-Y0, p.overlapCoordSmall{whichCol}(olap,1)-X0);
                p2(ind)=atan2(p.overlapCoordSmall{whichCol}(olap,4)-Y0, p.overlapCoordSmall{whichCol}(olap,3)-X0);
                ind=ind+1;
            end
        end
        
        % Determine the minimum and the maximum x and y values:
        rmin = min(rho); tmin = min(theta);
        rmax = max(rho); tmax = max(theta);
        
        F = scatteredInterpolant(rho,theta,z,'nearest'); %interpolation
        if isempty(F)
            return
        end

        %Evaluate the interpolant at the locations (rhoi, thetai).
        %The corresponding value at these locations is Zinterp:
        try
            if ~isempty(p.overlapTL{whichCol}) %if there is an overlap
                try
                    if length(p.overlapTL{whichCol})==1 %increase the resolution of the theta-grid according to number of overlapping cols
                        ttres=round(p.radThetaResolution*1.2);
                    elseif length(p.overlapTL{whichCol})==2
                        ttres=round(p.radThetaResolution*1.3);
                    else
                        ttres=round(p.radThetaResolution*1.4);
                    end
                catch
                    ttres=130;
                end
                
                %create the grid for the interpolated values
                theta4Zinterp=linspace(tmin,tmax,ttres);
                [rhoi,thetai] = meshgrid(linspace(rmin,rmax,rres),theta4Zinterp);
                Zinterp = F(rhoi,thetai);%interpolated values
                if isempty(Zinterp)
                    Kymo.(kymoname){whichCol}(p.i,:)=0;
                    p.KymoTrack(whichCol,p.i)=1;
                end
                Zbck=Zinterp;%for restoring. of more than 95% of theta is overlap, do not use the exclusion zinterp
                for ind=1:length(p1)
                    if ~borderCheck(ind) %normal exclusion. from the smaller theta to the bigger theta
                        toRm=theta4Zinterp>min([p1(ind), p2(ind)]) & theta4Zinterp<max([p1(ind), p2(ind)]);
                    else %the more complicated one, see above
                        toRm=(theta4Zinterp>max([p1(ind), p2(ind)]) & theta4Zinterp<pi) |...
                            (theta4Zinterp<min([p1(ind), p2(ind)]) & theta4Zinterp>(-pi));
                    end
                    Zinterp(toRm,:)=NaN; %replace these with nan
                    clear toRm;
                end
                if sum(isnan(Zinterp(:,1)))>0.9*size(Zinterp,1) %if more than 95% removed, do not use that
                    Zinterp=Zbck;
                end
                %                 figure; plot(mean(Zinterp),'b'); hold on; plot(mean(Zbck),'r'); title(num2str(whichCol));
                clear Zbck;
                clear theta4Zinterp;
            else
                [rhoi,thetai] = meshgrid(linspace(rmin,rmax,rres),linspace(tmin,tmax,p.radThetaResolution));
                Zinterp = F(rhoi,thetai);%interpolated values
            end
        catch
            Zinterp=[];
        end
    end
    function initializeedges(~,~)
        xs=1:size(Kymo.Kymo,1);
        p.kymoScalePillbox(xs,1)=p.kymoScalePillboxdef; %this times dim1*dim2 of kymo is used for pillbox filter
        p.kymoWienerFilterSize(xs,1:2)=p.kymoWienerFilterSizedef; %size of the wiener2 filter kernel
        p.kymoMaxIntensityCutoff(xs,1)=p.kymoMaxIntensityCutoffdef; %every intensity above p.kymoMaxIntensityCutoff is set to 1
        p.kymoCannyLowThresh(xs,1)=p.kymoCannyLowThreshdef; %lower canny edge detection threshold
        p.kymoCannyHighThresh(xs,2)=p.kymoCannyHighThreshdef; %upper canny edge detection threshold
        p.kymoNoiseFilterSize(xs,1)=p.kymoNoiseFilterSizedef; %this times dim2 (time) of kymo is used to define the size (in area pixel) of noise objects
        p.kymoVerticalLineRemoval(xs,1)=p.kymoVerticalLineRemovaldef; %this times dim2 is threshold for vertical line removal
        p.kymoHorizontalLineRemoval(xs,1)=p.kymoHorizontalLineRemovaldef;  %this times dim1 is threshold for horizontal line removal
        p.kymoCloseFilterLineLen(xs,1)=p.kymoCloseFilterLineLendef; %this times dim2 (time) of kymo is the size of line to use for closing
        p.kymoCloseFilterLineAngle(xs,1)=p.kymoCloseFilterLineAngledef; %the angle to be used for line closing
        p.kymoCloseFilterDiskSize(xs,1)=p.kymoCloseFilterDiskSizedef; %this times dim2 (time) of kymo is used for disk closing
        p.kymoMaskScaling(xs,1)=p.kymoMaskScalingdef; %scale the binarization threshold for mask creation
        p.kymoIterations(xs,1) = p.kymoIterationsdef; %number of iterations of active contouring
        p.kymoInvertContour(xs,1)=p.kymoInvertContourdef; %invert contour if 1
        p.kymoInvertKymo(xs,1)=p.kymoInvertKymodef; %invert kymograph if 1
        p.kymoDisablePrefilter(xs,1)=p.kymoDisablePrefilterdef; %disable all image prefiltering
    end %initialize parameter values for edge method
    function CalcRadKymo1(whichCol)
        if p.channelprocessing == 1
            kymoname = 'Kymo'; % Construct field name dynamically
            radname = 'RadMean';
        else
            kymoname = sprintf('KymoCh%d', p.channelprocessing); % Construct field name dynamically
            radname = sprintf('RadMeanCh%d', p.channelprocessing); % Construct field name dynamically
        end
        
        bin=cell(1,length(p.colList));%the binary kymograph
        if ~isfield(p,'BinThresh')
            p.BinThresh=nan(size(p.(radname),1),1);%the threshold for binarization
        end
        if ~isfield(p, 'AutoThresh')
            p.AutoThresh=0;
        end
        
        [grayImage,adjgrayImage,wienergrayImage,filtim,shrinkrange] = kymopreprocessing(Kymo.(kymoname){whichCol}, whichCol);
        
        %set to values too high so we subtract here a fixed value.
        if ~p.AutoThresh && isnan(p.BinThresh(whichCol))
            p.BinThresh(whichCol)=graythresh(shrinkrange)-p.radKymoBias;
        end
        bin{whichCol} = imbinarize(shrinkrange,p.BinThresh(whichCol));%binarize
        bin{whichCol} = bwselect(bin{whichCol}, [size(grayImage,2)-1, size(grayImage,2)-3], [size(grayImage,1)-1, size(grayImage,1)-3]);
        
        bin2rad(bin{whichCol}, whichCol, radname)
        
        if p.showplot
            if (isfield(hs, 'figkymo') && ishandle(hs.figkymo)) || ...
                    (isfield(k, 'fig1') && ishandle(k.fig1))
                showkymocalc1(whichCol)
            else
                hs.UserMess.String='Display closed, please wait for calculations to finish...';customdrawnow
            end
        end
        
        function showkymocalc1(whichCol)
            try
                fontSize=10;
                try
                    if (isfield(k, 'fig1') && ishandle(k.fig1))
                        k.steps=figure;
                        %                 [k.fig, ~] = tight_subplot(6,3,[.05 .01],[.1 .1],[.01 .01]);
                    end
                catch
                    
                end
                
                [ha, ~] = tight_subplot(3,2,[.05 .01],[.1 .1],[.01 .01]);
                
                pos=1;
                
                % for image size scaling
                rows = 90; newCols = rows*2;
                
                axes(ha(pos));
                imshow(imresize(adjgrayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') imadjust'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(wienergrayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') wiener2'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(filtim, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') pillbox filter'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(shrinkrange, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                axis on;
                title([num2str(pos),') shrink intensity range'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(bin{whichCol}, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') keep object left bottom'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                grayImage=imrotate(mat2gray(Kymo.(kymoname){whichCol}), 90);
                imshow(imresize(grayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                hold on;
                title([num2str(pos),') Kymo ' num2str(whichCol), ', radius'], 'FontSize', fontSize, 'Interpreter', 'None');
                [origrow, cols] = size(grayImage);
                originalIndices = linspace(1, cols, cols);
                newIndices = linspace(1, cols, newCols);
                RadMeanElongated = interp1(originalIndices, p.(radname)(whichCol,:), newIndices, 'linear');
                RadMeanElongated = interp1([0, origrow], [0, rows], RadMeanElongated, 'linear');
                plot(1:length(RadMeanElongated), round(rows)-RadMeanElongated*sqrt(2), 'r', 'LineWidth',1.5);%plot the radius
                
                set(gcf, 'units','normalized','outerposition',[0. 0. 0.95 0.95])%make it fullscreen (imshow resets that all the time...)
                if length(p.colList)>1 && ~(isfield(k, 'fig1') && ishandle(k.fig1))
                    pause()
                    clf(gcf)
                    set(gcf, 'units','normalized','outerposition',[0. 0. 1 1])%make it fullscreen (imshow resets that all the time...)x
                end
            catch
                hs.UserMess.String='Display closed, please wait for calculations to finish...';customdrawnow
            end
        end
        
    end %calculate the actual kymograph and radius, Global method
    function CalcRadKymo2(whichCol)
        if p.channelprocessing == 1
            kymoname = 'Kymo'; % Construct field name dynamically
            kymomodename = 'kymomode';
            radname = 'RadMean';
        else
            kymoname = sprintf('KymoCh%d', p.channelprocessing); % Construct field name dynamically
            kymomodename = sprintf('kymomodeCh%d', p.channelprocessing); % Construct field name dynamically
            radname = sprintf('RadMeanCh%d', p.channelprocessing); % Construct field name dynamically
        end
        if p.(kymomodename)(whichCol) == 1
            p.(kymomodename)(whichCol)=2;
        end
        
        [grayImage,adjgrayImage,wienergrayImage,filtim,shrinkrange] = kymopreprocessing(Kymo.(kymoname){whichCol}, whichCol);
        
        if p.(kymomodename)(whichCol) == 2
            % find edges with canny algorithm:
            if p.kymoCannyLowThresh(whichCol)>p.kymoCannyHighThresh(whichCol)
                p.kymoCannyHighThresh(whichCol)=p.kymoCannyLowThresh(whichCol)*1.1;
            end
            canynedge = edge(shrinkrange,'canny',[p.kymoCannyLowThresh(whichCol), p.kymoCannyHighThresh(whichCol)]);
            % remove small objects:
            sizectf=round(size(grayImage,2)*p.kymoNoiseFilterSize(whichCol));
            if sizectf<=1
                sizectf=2;
            end
            noisered=bwareaopen(canynedge, sizectf);
            % manually find straigt vertical lines:
            rmvert=noisered;
            whitesum=zeros(size(grayImage,2),1); %sums up white pixels per each vertical line
            for i=1:size(grayImage,2)
                whitesum(i)=sum(rmvert(:,i));%sum up
                if sum(rmvert(:,i))>p.kymoHorizontalLineRemoval(whichCol)*size(grayImage,1)
                    rmvert(:,i)=0;
                end
            end
            for i=1:size(grayImage,2)
                if i>3 && i<size(grayImage,2)-3
                    if sum(whitesum(i-2:i+2))>p.kymoHorizontalLineRemoval(whichCol)*size(grayImage,1)*4
                        rmvert(:,i-2:i+2)=0;
                    end
                end
            end
            % same for horizontal lines, different threshold:
            rmhoriz=rmvert;
            whitesum=zeros(size(grayImage,1),1);
            for i=1:size(grayImage,1)
                whitesum(i)=sum(rmhoriz(i,:));
                if sum(rmhoriz(i,:))>p.kymoVerticalLineRemoval(whichCol)*size(grayImage,2)
                    rmhoriz(i,:)=0;
                end
            end
            for i=1:size(grayImage,1)
                if i>3 && i<size(grayImage,1)-3
                    if sum(whitesum(i-2:i+2))>p.kymoVerticalLineRemoval(whichCol)*size(grayImage,2)*4
                        rmhoriz(i-2:i+2,:)=0;
                    end
                end
            end
            % morph closing with a short line
            closedimg=rmhoriz;
            closedimg(size(grayImage,1),:)=1; %set rad=1 to white
            closedimg(1:end,size(grayImage,2))=0; %set time=end to black
            clsize=size(grayImage,2)*p.kymoCloseFilterLineLen(whichCol);
            if clsize<=1
                clsize=2;
            end
            se2 = strel('line', clsize, p.kymoCloseFilterLineAngle(whichCol));
            closedimg = imclose(closedimg,se2);
            % morph closing with disk
            closedimg2=closedimg;
            closedimg2(size(grayImage,1),:)=1; %set rad=1 to white
            closedimg2(1:end,size(grayImage,2))=0; %set time=end to black
            closesize= p.kymoCloseFilterDiskSize(whichCol);
            if closesize<=1
                closesize=2;
            end
            se = strel('disk', round(closesize));
            closedimg2 = imclose(closedimg2,se);
            closedimg2(size(grayImage,1),:)=1;
            closedimg2(1:end,size(grayImage,2))=1;
        end
        
        % create convhull mask
        % mask = bwconvhull(closedimg2, 'objects');
        grthr=graythresh(shrinkrange)*p.kymoMaskScaling(whichCol);
        if grthr<=0
            grthr=0.00001;
        elseif grthr>=1
            grthr=0.9999;
        end
        mask=imbinarize(shrinkrange,grthr);
        % use active contouring to get auto estimated edges
        actcont = activecontour(im2uint8(shrinkrange), mask, p.kymoIterations(whichCol));
        if p.kymoInvertContour(whichCol)
            actcont=~actcont;
        end
        
        if p.(kymomodename)(whichCol) == 2
            % combine with the image before
            actcontcomb=actcont+closedimg2;
            actcontcomb(actcontcomb==2)=1; %set to 1 if addition led to values of 2
            actcontcomb=logical(actcontcomb); %reduce image to logical again
            % morph closing with disk
            se = strel('disk', round(closesize));
            closedimg3 = imclose(actcontcomb,se);
            closedimg3(size(grayImage,1),:)=1;
            closedimg3(1:end,size(grayImage,2))=1;
            % fill holes
            fillBW=imfill(closedimg3, 'holes');
            % morph opening
            se = strel('disk', p.kymoCloseFilterDiskSize(whichCol));
            openBW = imopen(fillBW,se);
        else
            openBW = actcont;
        end
        % keep biggest object
        bigBW = bwselect(openBW, [size(grayImage,2)-1, size(grayImage,2)-3], [size(grayImage,1)-1, size(grayImage,1)-3]);
        
        % and finally the radius calculations:
        bin2rad(bigBW, whichCol, radname)
        
        if p.showplot
            if (isfield(hs, 'figkymo') && ishandle(hs.figkymo)) || ...
                    (isfield(k, 'fig1') && ishandle(k.fig1))
                showkymocalc2(whichCol)
            else
                hs.UserMess.String='Display closed, please wait for calculations to finish...';customdrawnow
            end
        end
        
        function showkymocalc2(whichCol)
            try
                fontSize=10;
                try
                    if (isfield(k, 'fig1') && ishandle(k.fig1))
                        k.steps=figure;
                        %                 [k.fig, ~] = tight_subplot(6,3,[.05 .01],[.1 .1],[.01 .01]);
                    end
                catch
                    
                end
                if p.(kymomodename)(whichCol) == 2
                    [ha, ~] = tight_subplot(6,3,[.05 .01],[.1 .1],[.01 .01]);
                else
                    [ha, ~] = tight_subplot(4,2,[.05 .01],[.1 .1],[.01 .01]);
                end
                
                pos=1;
                
                % for image size scaling
                rows = 90; newCols = rows*2;
                
                axes(ha(pos));
                imshow(imresize(adjgrayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') imadjust'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(wienergrayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') wiener2'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(filtim, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') pillbox filter'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(shrinkrange, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                axis on;
                title([num2str(pos),') shrink intensity range'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                if p.(kymomodename)(whichCol) == 2
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(canynedge, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') edge, canny'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(noisered, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') remove noise'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(rmvert, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    axis on;
                    title([num2str(pos),') remove vertical lines'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(rmhoriz, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') remove horizontal lines'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(closedimg, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') morph closing, line'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(closedimg2, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') morph closing, disk'], 'FontSize', fontSize, 'Interpreter', 'None');
                end
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(mask, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                title([num2str(pos),') mask for activecontour'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(actcont, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                title([num2str(pos),') activecontour'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                if p.(kymomodename)(whichCol) == 2
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(actcontcomb, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    title([num2str(pos),') activecontour+morph close'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(closedimg3, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') morph closing, disk'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(fillBW, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    axis on;
                    title([num2str(pos),') imfill, holes'], 'FontSize', fontSize, 'Interpreter', 'None');
                    
                    pos=pos+1;
                    axes(ha(pos));
                    imshow(imresize(openBW, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                    ax = gca;
                    ax.Toolbar.Visible = 'off';
                    axis on;
                    title([num2str(pos),') morph open (small disk)'], 'FontSize', fontSize, 'Interpreter', 'None');
                end
                pos=pos+1;
                axes(ha(pos));
                imshow(imresize(bigBW, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                title([num2str(pos),') keep object left bottom'], 'FontSize', fontSize, 'Interpreter', 'None');
                
                pos=pos+1;
                axes(ha(pos));
                grayImage=imrotate(mat2gray(Kymo.(kymoname){whichCol}), 90);
                imshow(imresize(grayImage, [rows, round(newCols)]), 'InitialMagnification', 'fit');
                ax = gca;
                ax.Toolbar.Visible = 'off';
                axis on;
                hold on;
                title([num2str(pos),') Kymo ' num2str(whichCol), ', radius'], 'FontSize', fontSize, 'Interpreter', 'None');
                [origrow, cols] = size(grayImage);
                originalIndices = linspace(1, cols, cols);
                newIndices = linspace(1, cols, newCols);
                RadMeanElongated = interp1(originalIndices, p.(radname)(whichCol,:), newIndices, 'linear');
                RadMeanElongated = interp1([0, origrow], [0, rows], RadMeanElongated, 'linear');
                plot(1:length(RadMeanElongated), round(rows)-RadMeanElongated*sqrt(2), 'r', 'LineWidth',1.5);%plot the radius
                
                set(gcf, 'units','normalized','outerposition',[0. 0. 0.95 0.95])%make it fullscreen (imshow resets that all the time...)
                if length(p.colList)>1 && ~(isfield(k, 'fig1') && ishandle(k.fig1))
                    pause()
                    clf(gcf)
                    set(gcf, 'units','normalized','outerposition',[0. 0. 1 1])%make it fullscreen (imshow resets that all the time...)x
                end
            catch
                hs.UserMess.String='Display closed, please wait for calculations to finish...';customdrawnow
            end
        end
    end %calculate the actual kymograph and radius, Edge method
    function [grayImage,adjgrayImage,wienergrayImage,filtim,shrinkrange]=kymopreprocessing(imgin, whichCol)
        % get kymograph:
        if p.kymoInvertKymo(whichCol)
            grayImage=imrotate(mat2gray(imcomplement(imgin)), 90);
        else
            grayImage=imrotate(mat2gray(imgin), 90);
        end
        % enhance contrast:
        if ~p.kymoDisablePrefilter(whichCol)
            adjgrayImage = imadjust(grayImage);
            % apply wiener filter (smoothing):
            if p.kymoWienerFilterSize(whichCol,:)>0
                wienergrayImage = wiener2(adjgrayImage,p.kymoWienerFilterSize(whichCol,:));
            else
                wienergrayImage = adjgrayImage;
            end
            % apply pillbox filter (more smoothing):
            fsize= round(size(grayImage,1)*size(grayImage,2)*p.kymoScalePillbox(whichCol));
            if fsize<=1
                fsize=2;
            end
            filt = fspecial('disk', fsize);
            filtim = mat2gray(imfilter(wienergrayImage, filt, 'replicate'));
            % cut max intensity:
            shrinkrange = mat2gray(filtim, [0 p.kymoMaxIntensityCutoff(whichCol)]);
        else
            adjgrayImage = grayImage;
            wienergrayImage = grayImage;
            filtim = grayImage;
            shrinkrange = grayImage;
        end
    end
    function bin2rad(bin, whichCol, radname)
        bin=flip(bin,1);
        ZeroCount=0;%count how many times a radius of zero is calculated
        % if more than p.radzeroRadCutoff (=6) times,set the radius of all
        % frames before to zero
        p.(radname)(whichCol,:) = nan;
        firstCol = nan(length(p.(radname)(whichCol,:)),1);
        firstBack = nan(length(p.(radname)(whichCol,:)),1);
        fcnancnt = 0; bgnancnt = 0;
        for t=length(p.l):-1:1%go over all images, start at the last
            try
                try
                    firstCol(t)=find(bin(:,t)==1,1);%find the first entry that is a colony
                catch
                    firstCol(t)=1;%if it was not possible, insert 1 (becomes 0 afterwards)
                end
                % if t<length(p.l)-4
                %     if firstCol(t)>mean(firstCol(t+1+fcnancnt:t+3+fcnancnt), 'omitnan')+3
                %         firstCol(t)=nan;
                %         fcnancnt = fcnancnt +1;
                %         continue
                %     else
                %         fcnancnt = 0;
                %     end
                % end
                %starting from the first entry of a col, find first entry of background
                firstBack(t)=find(bin(firstCol(t):end,t)==0,1);
                if t<length(p.l)-4
                    if firstBack(t)>(mean(firstBack(t+1:t+3), 'omitnan')+size(bin,1)*0.075)
                        if mean(firstBack(t+1+bgnancnt:t+3+bgnancnt), 'omitnan')==1
                            firstBack(t)=1;
                            bgnancnt = 0;
                        else
                            firstBack(t)=nan;
                            bgnancnt = bgnancnt +1;
                            continue
                        end
                    else
                        bgnancnt = 0;
                    end
                end
                %store the rad which is the firstBackground. Apply the /sqrt(2) because of radial coordinates
                p.(radname)(whichCol,t)=(firstBack(t)-1)/sqrt(2);
            catch
                p.(radname)(whichCol,t)=nan; %if it was not possible, store a nan
            end
            
            %if the rad was set to zero, count that
            if  p.(radname)(whichCol,t)==0
                ZeroCount=ZeroCount+1;
            end
            
            %and if we are halfway through the timelapse and the zerocount
            %is big, set all rad of previous (speaking in real time) frames to zero
            if t<floor(size(bin,2)/2) && ZeroCount>p.radzeroRadCutoff
                p.(radname)(whichCol,1:t)=0;
                break
            end
        end
    end
    function AutoKymoCheck_Callback(~,~)
        disableGUI(1);%disable the GUI
        p.colList=1:size(p.RadMean,1);
        %reinitialize kymograph list
        chngList(2,0,false(size(p.RadMean,1),1))
        L=readList(2,0);
        failed=L;
        redo=0;
        hs.UserMess.String='Please wait...';customdrawnow
        for rep=1:2
            for whichCol=p.colList
                A=p.RadMean(whichCol,:);
                %        find quick changes
                [~,S1] = ischange(A, 'Threshold',10);
                Y1=diff(S1,1);
                if sum(isnan(A))>0.1*length(p.l)
                    L(whichCol)=1;
                end
                %         there are too many quick changes:
                if sum(abs(Y1)>4)>1
                    L(whichCol)=1;
                end
                %         find local maxima
                TF = islocalmax(A);
                %        there are too many maxima (indicating going up and down):
                if sum(TF)>5
                    L(whichCol)=1;
                end
                %        calculate dif from t to t+1:
                Y = diff(A);
                %        there are too many instances where rad goes down:
                if sum(Y<0)>5
                    L(whichCol)=1;
                end
                %        there  is a big jump:
                if sum(Y>10)>=1
                    L(whichCol)=1;
                end
                %         radius median is smaller than 3pixels
                if median(A, 'omitnan')<3
                    L(whichCol)=1;
                end
                
                %        too many nans:
                if sum(isnan(A))>0.7*length(A)
                    L(whichCol)=1;
                end
            end
            
            if rep==1
                quest=questdlg([num2str(sum(L)), ' kymographs detected. Recalculate these with Edge detection mode?'],...
                    'Failed kmyographs', ...
                    'Yes','No','Yes');
                switch quest
                    case 'Yes'
                        L=readList(2,0);
                        for whichCol=p.colList(L)
                            try
                                CalcRadKymo2(whichCol)
                            catch
                                L(whichCol)=1;
                                failed(whichCol)=1;
                            end
                            redo=1;
                        end
                    case 'No'
                    case ''
                end
            end
            if ~redo
                break
            end
        end
        
        chngList(2,0,L); %pushing the chnages to the list
        if ~p.disableSave
            saveall(p.dirS);
        end
        hs.UserMess.String=['List -2: ', num2str(sum(L)), ' out of ' num2str(length(L)), ' colonies need correction'];customdrawnow
        disableGUI(0);%disable the GUI
        if sum(failed)>0
            msgbox(['Something is wrong with the kymographs of colonies ', num2str(p.colList(failed)),'. Please re-run time-lapse analysis for these'],'Corrupt kymographs')
        end
    end %find failed kymographs
    function CorrectThresh_Callback(~,~)
        % profile on;
        
        if ~isstruct(k)
            k=struct();
        end
        if p.nChannel>1
            % Define the prompts for each number
            prompt = {'Which colony do you want to check? If you want to check all, insert 0. -2 for failed kymograph list:', 'Enter channel to work on:'};
            
            % Define the title of the dialog box
            dlgtitle = 'Kymograph correction';
            
            % Define the number of lines for the input fields and default answers
            dims = [1 35; 1 35];
            defaultans = {'0','1'}; % Default answers
        else
            % Define the prompts for each number
            prompt = {'Which colony do you want to check? If you want to check all, insert 0. -2 for failed kymograph list:'};
            
            % Define the title of the dialog box
            dlgtitle = 'Kymograph correction';
            
            % Define the number of lines for the input fields and default answers
            dims = [1 35];
            defaultans = {'0'}; % Default answers
            p.channelprocessing = 1;
        end
        
        % Display the input dialog box
        answer = inputdlg(prompt, dlgtitle, dims, defaultans);
        
        % Check if the user clicked OK or Cancel
        if isempty(answer); hs.UserMess.String='Canceled';customdrawnow; return; end
        
        colList1=round(str2num(answer{1,1})); %#ok<ST2NM>
        OK=setpColList(colList1); %this function sets variable p.ColList
        if OK==0; hs.UserMess.String='Colony number not valid';customdrawnow; return; end %there was an error in the list
        
        if p.nChannel>1
            ans2 = str2double(answer{2});
            if isnumeric(ans2) && mod(ans2, 1) == 0 && ans2 >= 0 && ans2 <= p.nChannel
                p.channelprocessing = ans2;
            else
                hs.UserMess.String='Channel number not valid';customdrawnow; return;
            end
        end
        
        if p.channelprocessing == 1
            kymoname = 'Kymo'; % Construct field name dynamically
            radname = 'RadMean';
            kymomodename = 'kymomode';
        else
            kymoname = sprintf('KymoCh%d', p.channelprocessing); % Construct field name dynamically
            kymomodename = sprintf('kymomodeCh%d', p.channelprocessing); % Construct field name dynamically
            radname = sprintf('RadMeanCh%d', p.channelprocessing); % Construct field name dynamically
        end
        
        if ~isfield(p,radname)
            hs.UserMess.String='Channel not yet processed';customdrawnow; return;
        end
        
        if isempty(p.(radname))
            hs.UserMess.String='Channel not yet processed';customdrawnow; return;
        end
        
        
        
        if ~isfield(p, kymomodename)
            p.(kymomodename)=[];
        end
        Kymolength=length(Kymo.Kymo);
        if isempty(p.(kymomodename))
            p.(kymomodename)=ones(Kymolength,1);
        elseif Kymolength  ~= length(p.(kymomodename))
            p.(kymomodename)=ones(Kymolength,1);
        end
        if ~isfield(p,'BinThresh')
            p.BinThresh=nan(size(p.(radname),1),1);%the threshold for binarization
        end
        if isempty(p.BinThresh) || length(p.BinThresh)~=Kymolength
            p.BinThresh=nan(Kymolength,1);
        end
        if isempty(p.kymoInvertKymo)
            p.kymoInvertKymo = zeros(Kymolength,1);
        end
        if isempty(p.kymoDisablePrefilter)
            p.kymoDisablePrefilter = zeros(Kymolength,1);
        end
        initializeedges;
        p.showplot=0;
        RadMeanBCK=p.(radname);
        
        if strcmp(p.tappMode, 'um')
            p.tappThreshPx=round(p.tappThreshUm/mean(p.umConversion, 'omitnan'));
        else
            p.tappThreshUm=round(p.tappThreshPx*mean(p.umConversion, 'omitnan'));
        end
        
        k.steps=figure;close(k.steps);
        k.fig1=figure('Name','Kymograph correction',...
            'Numbertitle','off',...
            'WindowState', 'maximized',...
            'Color',[0.9 0.9 .9],...
            'Toolbar','none',...
            'MenuBar', 'none');
        
        
        k.gray=[220, 224, 221]/255;
        k.main=uix.HBoxFlex('Parent', k.fig1,'Padding',0, 'Spacing', 10); % whole box, separed into two units: 1) TopLayer and 2) BottomLayer
        
        k.LeftLayer=uix.VBox('Parent',k.main);
        k.RightLayer=uix.VBox('Parent',k.main);
        k.main.Widths=[-5, -1];
        
        k.texts=uix.HBox('Parent',k.LeftLayer);
        k.colstring0=uicontrol('Style', 'text','Parent',k.texts, 'String', 'Colony: ','FontSize',15, 'HorizontalAlignment','Left', 'Background', 'white');
        k.colstring=uicontrol('Style', 'text','Parent',k.texts, 'String', 'x','FontSize',15, 'HorizontalAlignment','Left', 'Background', 'white');
        k.changes0=uicontrol('Style', 'text','Parent',k.texts, 'String', 'Changes: ','FontSize',15, 'HorizontalAlignment','Left', 'Background', 'white');
        k.changes=uicontrol('Style', 'text','Parent',k.texts, 'String', 'y','FontSize',15, 'HorizontalAlignment','Left', 'Background', 'white');
        k.texts.Widths=[-1 -2 -1 -5];
        k.kymo=uipanel('Parent',k.LeftLayer, 'Background', 'white');
        k.leftbuttons=uix.HBox('Parent',k.LeftLayer);
        k.LeftLayer.Heights=[-0.5 -12, -0.75];
        
        k.fig=axes('Parent', k.kymo, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
        
        k.back=uicontrol('Parent',k.leftbuttons, 'String', 'Back','Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @colback);
        k.ok=uicontrol('Parent',k.leftbuttons, 'String', 'Ok', 'Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @colok);
        k.exclude=uicontrol('Parent',k.leftbuttons, 'String', 'Exclude', 'Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @colexclude);
        k.kymomode=uibuttongroup('Parent',k.leftbuttons,'Title','Processing method','FontSize',10, 'Background', 'white', 'SelectionChangedFcn',@globalswitch);
        k.globalsw=uicontrol(k.kymomode,'Style','radiobutton','String','Global','FontSize',10,'Units','normalized','Position',[.05 .2 .3 .7], 'Background', 'white');
        k.edgesw=uicontrol(k.kymomode,'Style','radiobutton','String','Edge','FontSize',10, 'Units','normalized','Position',[.375 .2 .3 .7], 'Background', 'white');
        k.contsw=uicontrol(k.kymomode,'Style','radiobutton','String','Contour','FontSize',10, 'Units','normalized','Position',[.65 .2 .3 .7], 'Background', 'white');
        k.addlist=uicontrol('Parent',k.leftbuttons, 'String', 'Add to list', 'Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @coladdlist);
        k.showstep=uicontrol('Parent',k.leftbuttons, 'String', 'Show steps','Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @showstep_callback);
        k.abort=uicontrol('Parent',k.leftbuttons, 'String', 'Abort', 'Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @abortcor);
        k.save=uicontrol('Parent',k.leftbuttons, 'String', 'Save&Close', 'Style','pushbutton','FontSize',15, 'Background', 'white', 'Callback', @savecor);
        k.leftbuttons.Widths=[-1 -1 -1 225 -1 -1 -1 -1];
        
        k.rightop=uix.VBox('Parent',k.RightLayer, 'Background', 'white');
        k.righbottom=uix.VBox('Parent',k.RightLayer,'Background', k.gray);
        k.voidtit=uix.Empty('Parent', k.righbottom,'Background', k.gray);
        k.title=uicontrol('Style', 'text','Parent',k.righbottom, 'String', 'Finetuning:','FontSize',20,'Background', k.gray);
        
        k.rbl1=uix.HBox('Parent',k.righbottom);
        k.rbl=uix.VBox('Parent',k.rbl1, 'Background', k.gray);
        k.voidbot=uix.Empty('Parent', k.rbl1, 'Background', k.gray);
        k.rbr=uix.VBox('Parent',k.rbl1, 'Background', k.gray);
        k.rbl1.Widths=[-1 -0.1 -1];
        
        %         main sliders + checkbox
        k.title=uicontrol('Style', 'text','Parent',k.rightop, 'String', 'Main modifications:','FontSize',20, 'Background', 'white');
        k.disablefiltswitch=uicontrol('Parent',k.rightop, 'Style', 'checkbox', 'String', 'disable filtering','Callback', @disablefiltswitch,'FontSize',15, 'Value', 0, 'Background', 'white');
        k.inverttoggles=uix.HBox('Parent',k.rightop);
        k.invertstring=uicontrol('Style', 'text','Parent',k.inverttoggles, 'String', 'Invert:','FontSize',15, 'Background', 'white');
        k.kymoswitch=uicontrol('Parent',k.inverttoggles, 'Style', 'checkbox', 'String', 'kymograph','Callback', @kymoswitch,'FontSize',15, 'Value', 0, 'Background', 'white');
        k.contswitch=uicontrol('Parent',k.inverttoggles, 'Style', 'checkbox', 'String', 'contour','Callback', @contswitch,'FontSize',15, 'Value', 0, 'Background', 'white');
        k.inverttoggles.Widths=[-0.95 -1.5 -1];
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rightop, 'String', 'Contour, nr iterations:','FontSize',15, 'Background', 'white');
        k.iter=uicontrol('Parent',k.rightop, 'Style', 'slider','Callback', @iter_slider,'FontSize',15, 'min', 2, 'max', 500, 'Value', 70, 'Background', 'white');
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rightop, 'String', 'Canny high thresh:','FontSize',15, 'Background', 'white');
        k.canhi=uicontrol('Parent',k.rightop, 'Style', 'slider','Callback', @canhi_slider,'FontSize',15, 'min', 0.01, 'max', 0.99, 'Value', 0.11, 'Background', 'white');
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rightop, 'String', 'Disk size:','FontSize',15, 'Background', 'white');
        k.disksize=uicontrol('Parent',k.rightop, 'Style', 'slider','Callback', @disksize_slider,'FontSize',15, 'min', 1, 'max', 15, 'Value', 3, 'Background', 'white');
        
        
        k.void2=uix.Empty('Parent', k.rightop);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rightop, 'String', 'Global threshold:','FontSize',15, 'Background', 'white');
        k.globalsldr=uicontrol('Parent',k.rightop, 'Style', 'slider','Callback', @global_slider,'FontSize',15, 'min', 0.00001, 'max', 0.9999, 'Value', 0.1, 'Background', 'white');
        
        
        %       Finetuning sliders
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbl, 'String', 'Pillbox filter:','FontSize',15,'Background', k.gray);
        k.pill=uicontrol('Parent',k.rbl, 'Style', 'slider','Callback', @pillbox_slider,'FontSize',15, 'min', 1/500000, 'max', 1/1000, 'Value', 1/500000,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbl, 'String', 'Max Intensity:','FontSize',15,'Background', k.gray);
        k.int=uicontrol('Parent',k.rbl, 'Style', 'slider','Callback', @maxint_slider,'FontSize',15, 'min', 0.1, 'max', 1, 'Value', 1,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbl, 'String', 'Rem vert lines:','FontSize',15,'Background', k.gray);
        k.strtime=uicontrol('Parent',k.rbl, 'Style', 'slider','Callback', @strtime_slider,'FontSize',15, 'min', 0.01, 'max', 0.9, 'Value', 0.5,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbl, 'String', 'Noise reduction:','FontSize',15,'Background', k.gray);
        k.noise=uicontrol('Parent',k.rbl, 'Style', 'slider','Callback', @noise_slider,'FontSize',15, 'min', 0.005, 'max', 0.2, 'Value', 0.05,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbl, 'String', 'Line length:','FontSize',15,'Background', k.gray);
        k.linerad=uicontrol('Parent',k.rbl, 'Style', 'slider','Callback', @linerad_slider,'FontSize',15, 'min', 1/100, 'max', 1/10, 'Value', 1/30,'Background', k.gray);
        
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbr, 'String', 'Wiener2 filter:','FontSize',15,'Background', k.gray);
        k.wien=uicontrol('Parent',k.rbr, 'Style', 'slider','Callback', @wiener_slider,'FontSize',15, 'min', 0, 'max', 15, 'Value', 0,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbr, 'String', 'Canny lo thresh:','FontSize',15,'Background', k.gray);
        k.canlow=uicontrol('Parent',k.rbr, 'Style', 'slider','Callback', @canlow_slider,'FontSize',15, 'min', 0, 'max', 0.7, 'Value', 0.05,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbr, 'String', 'Rem horiz lines:','FontSize',15,'Background', k.gray);
        k.strrad=uicontrol('Parent',k.rbr, 'Style', 'slider','Callback', @strrad_slider,'FontSize',15, 'min', 0.01, 'max', 0.9, 'Value', 0.3,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbr, 'String', 'Mask scaling:','FontSize',15,'Background', k.gray);
        k.mask=uicontrol('Parent',k.rbr, 'Style', 'slider','Callback', @mask_slider,'FontSize',15, 'min', 0.05, 'max', 2, 'Value', 1.7,'Background', k.gray);
        k.sldrstr=uicontrol('Style', 'text','Parent',k.rbr, 'String', 'Line, angle:','FontSize',15,'Background', k.gray);
        k.lineangle=uicontrol('Parent',k.rbr, 'Style', 'slider','Callback', @lineangle_slider,'FontSize',15, 'min', 0, 'max', 90, 'Value', 10,'Background', k.gray);
        
        k.rightop.Heights=[35 35 35 -1 35 -1 35 -1 35 20 35 -1];
        k.righbottom.Heights=[-0.1 35 -1];
        k.RightLayer.Heights=[-1 -1];
        k.rbl.Heights=[45 -1 45 -1 45 -1 45 -1 45 -1];
        k.rbr.Heights=k.rbl.Heights;
        
        k.ix=1;
        k.newrad = [];
        try
            [resizedImg, originalIndices, newIndices, rows, newRows, newCols, RadMeanElongatedOrig] = initcolview;
            while k.ix <= length(p.colList)
                whichCol = p.colList(k.ix);
                uiwait(k.fig1)
            end
            hs.UserMess.String='Correction finished'; customdrawnow
        catch
            try close(k.fig1); catch; end
            saveall(p.dirS);
            return
        end
        % profile off;
        % profile viewer
        try close(k.fig1); catch; end
        refresh(0);
        
        function [resizedImg, originalIndices, newIndices, rows, newRows, newCols, RadMeanElongatedOrig] = initcolview;
            whichCol=p.colList(k.ix);
            while isempty(Kymo.(kymoname){whichCol})
                waitfor(errordlg(['No data found for colony Nr. ',num2str(whichCol)]));
                k.ix=k.ix+1;
                whichCol=p.colList(k.ix);
            end
            if p.(kymomodename)(whichCol)==1
                set(k.globalsw, 'Value', 1)
                set(k.edgesw, 'Value', 0)
                set(k.contsw, 'Value', 0)
            elseif p.(kymomodename)(whichCol)==2
                set(k.globalsw, 'Value', 0)
                set(k.edgesw, 'Value', 1)
                set(k.contsw, 'Value', 0)
            elseif p.(kymomodename)(whichCol)==3
                set(k.globalsw, 'Value', 0)
                set(k.edgesw, 'Value', 0)
                set(k.contsw, 'Value', 1)
            end
            
            set(k.iter,'Value', p.kymoIterations(whichCol));
            set(k.canhi,'Value', p.kymoCannyHighThresh(whichCol));
            set(k.disksize,'Value', p.kymoCloseFilterDiskSize(whichCol));
            set(k.contswitch,'Value', p.kymoInvertContour(whichCol));
            set(k.kymoswitch,'Value', p.kymoInvertKymo(whichCol));
            set(k.disablefiltswitch,'Value', p.kymoDisablePrefilter(whichCol));
            if ~isnan(p.BinThresh(whichCol))
                set(k.globalsldr,'Value', p.BinThresh(whichCol));
            else
                set(k.globalsldr,'Value', 0.1);
            end
            
            set(k.pill,'Value', p.kymoScalePillbox(whichCol));
            set(k.int,'Value', p.kymoMaxIntensityCutoff(whichCol));
            set(k.strtime,'Value', p.kymoVerticalLineRemoval(whichCol));
            set(k.noise,'Value', p.kymoNoiseFilterSize(whichCol));
            set(k.linerad,'Value', p.kymoCloseFilterLineLen(whichCol));
            set(k.wien,'Value', p.kymoWienerFilterSize(whichCol));
            set(k.canlow,'Value', p.kymoCannyLowThresh(whichCol));
            set(k.strrad,'Value', p.kymoHorizontalLineRemoval(whichCol));
            set(k.mask,'Value', p.kymoMaskScaling(whichCol,1));
            set(k.lineangle,'Value', p.kymoCloseFilterLineAngle(whichCol,1));
            
            set(k.colstring, 'String', num2str(whichCol));
            set(k.changes, 'String', '');
            
            
            % img loading
            if p.kymoInvertKymo(whichCol)
                img = mat2gray(imrotate(imcomplement(Kymo.(kymoname){whichCol}), 90));
            else
                img = mat2gray(imrotate((Kymo.(kymoname){whichCol}), 90));
            end
            [rows, cols, ~] = size(img);
            
            % for image size scaling
            newRows = 540; newCols = newRows*2;
            scaledthresh = p.tappThreshPx*(newRows/rows);
            
            % Resize the image
            resizedImg = imresize(img, [newRows, newCols]);
            
            
            % Generate a vector of the original indices
            originalIndices = linspace(1, cols, cols);
            % Generate a new set of indices for the desired 'newCols' entries
            newIndices = linspace(1, cols, newCols);
            % Interpolate the original vector to the new resolution
            RadMeanElongatedOrig = interp1(originalIndices, p.(radname)(whichCol,:), newIndices, 'linear');
            RadMeanElongatedOrig = interp1([0, rows], [0, newRows], RadMeanElongatedOrig, 'linear');            % ax = gca;
            % ax.Toolbar.Visible = 'off';
            
            % display it
            if k.ix == 1
                cla(k.fig); axis off;
                k.fig=axes('Parent', k.kymo, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
                k.hImage = imshow(resizedImg, 'InitialMagnification', 'fit');
                hold on;
                plot(1:newCols, size(resizedImg,1)-repmat(scaledthresh*sqrt(2), newCols ,1), 'Color','b','Linewidth', 0.5);%plot the threshold
                k.newrad = plot(1:length(RadMeanElongatedOrig), size(resizedImg,1)-RadMeanElongatedOrig*sqrt(2), 'r', 'LineWidth',1.5);%plot the radius
                k.orrad = plot(1:length(RadMeanElongatedOrig), size(resizedImg,1)-RadMeanElongatedOrig*sqrt(2), 'g', 'LineWidth',1.5);%plot the radius
                hold off
            else
                set(k.hImage, 'CData', resizedImg);
                set(k.newrad,'XData',1:length(RadMeanElongatedOrig),'YData',size(resizedImg,1)-RadMeanElongatedOrig*sqrt(2));
                set(k.orrad,'XData',1:length(RadMeanElongatedOrig),'YData',size(resizedImg,1)-RadMeanElongatedOrig*sqrt(2));
            end
            
            
            
            
            if ~ishandle(k.steps)
                if p.kymomode(whichCol)==1
                    uicontrol(k.globalsldr)
                elseif p.kymomode(whichCol)==2
                    uicontrol(k.canhi)
                elseif p.kymomode(whichCol)==3
                    uicontrol(k.iter)
                end
            end
            
            if ~isnan(activeList) || -activeList <= size(p.UserLists.l,2)
                L=readList(-activeList, p.i);
                if L(whichCol)==0
                    k.addlist.String='Add to list';
                else
                    k.addlist.String='Remove from list';
                end
            else
                k.addlist.String='No active list';
            end
            k.update = 0;
            drawnow
        end
        function colback(~,~)
            if k.ix==1
                return
            end
            k.ix = k.ix-1;
            uiresume(k.fig1);
            [resizedImg, originalIndices, newIndices, rows, newRows, newCols, RadMeanElongatedOrig] = initcolview;
        end
        function colok(~,~)
            k.ix = k.ix+1;
            if k.ix > length(p.colList)
                close(k.fig1);
                hs.UserMess.String='Please wait...'; customdrawnow
                saveall(p.dirS);
                hs.UserMess.String='Correction saved'; customdrawnow
                return
            end
            uiresume(k.fig1);
            [resizedImg, originalIndices, newIndices, rows, newRows, newCols, RadMeanElongatedOrig] = initcolview;
        end
        function colexclude(~,~)
            k.ix = k.ix+1;
            p.(radname)(whichCol,:)=nan;
            uiresume(k.fig1);
            [resizedImg, originalIndices, newIndices, rows, newRows, newCols, RadMeanElongatedOrig] = initcolview;
        end
        function coladdlist(~,~)
            if ~isnan(activeList) && activeList<-Fvar.numNonUserList
                L=readList(-activeList, p.i);
                L(whichCol)=~L(whichCol);
                chngList(-activeList, p.i, L);
                if L(whichCol)
                    set(k.changes, 'String', 'Colony added to list');
                else
                    set(k.changes, 'String', 'Colony removed from list');
                end
                k.update = 1;
            else
                set(k.changes, 'String', 'No active list');
            end
            uiresume(k.fig1);
        end
        function abortcor(~,~)
            p.(radname)=RadMeanBCK;
            close(k.fig1);
            hs.UserMess.String='Correction aborted'; customdrawnow
            return
        end
        function savecor(~,~)
            close(k.fig1);
            hs.UserMess.String='Please wait...'; customdrawnow
            saveall(p.dirS);
            hs.UserMess.String='Correction saved'; customdrawnow
            return
        end
        function globalswitch(~,~)
            if k.globalsw.Value
                p.(kymomodename)(whichCol)=1;
                set(k.changes, 'String', 'Switchted to global thresholding mode');
            end
            if k.edgesw.Value
                p.(kymomodename)(whichCol)=2;
                set(k.changes, 'String', 'Switchted to edge detection mode');
            end
            if k.contsw.Value
                p.(kymomodename)(whichCol)=3;
                set(k.changes, 'String', 'Switchted to contour mode');
            end
            uiresume(k.fig1);
            drawradkymocor
            if ~isempty(p.BinThresh(whichCol)) && ~isnan(p.BinThresh(whichCol))
                set(k.globalsldr,'Value', p.BinThresh(whichCol));
            end
        end
        function showstep_callback(~,~)
            p.showplot=1;
            if p.(kymomodename)(whichCol)==1
                CalcRadKymo1(whichCol);
            else
                CalcRadKymo2(whichCol);
            end
            p.showplot=0;
        end
        
        function iter_slider(~,~)
            if p.(kymomodename)(whichCol)==1
                return
            end
            p.kymoIterations(whichCol)=round(get(k.iter,'Value'));
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Contour iterations changed to ', num2str(p.kymoIterations(whichCol))]);
        end
        function canhi_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            p.kymoCannyHighThresh(whichCol)=get(k.canhi,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Canny high threshold changed to ', num2str(p.kymoCannyHighThresh(whichCol))]);
        end
        function disksize_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            p.kymoCloseFilterDiskSize(whichCol)=round(get(k.disksize,'Value'));
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Disk size changed to ', num2str(p.kymoCloseFilterDiskSize(whichCol))]);
        end
        function disablefiltswitch(~,~)
            p.kymoDisablePrefilter(whichCol)=get(k.disablefiltswitch,'Value');
            set(k.changes, 'String', 'Please wait...');
            uiresume(k.fig1);
            drawradkymocor
            if p.kymoDisablePrefilter(whichCol)
                set(k.changes, 'String', 'Disabled image filtering');
            else
                set(k.changes, 'String', 'Enabled image filtering');
            end
        end
        function contswitch(~,~)
            if p.(kymomodename)(whichCol)==1
                return
            end
            p.kymoInvertContour(whichCol)=get(k.contswitch,'Value');
            set(k.changes, 'String', 'Please wait...');
            uiresume(k.fig1);
            drawradkymocor
            if p.kymoInvertContour(whichCol)
                set(k.changes, 'String', 'Enabled contour inversion');
            else
                set(k.changes, 'String', 'Disabled  contour inversion');
            end
        end
        function kymoswitch(~,~)
            p.kymoInvertKymo(whichCol)=get(k.kymoswitch,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            
            [resizedImg, originalIndices, newIndices, newCols, RadMeanElongatedOrig] = initcolview;
            if p.kymoInvertKymo(whichCol)
                set(k.changes, 'String', 'Enabled kymograph inversion');
            else
                set(k.changes, 'String', 'Disabled  kymograph inversion');
            end
        end
        function global_slider(~,~)
            if p.(kymomodename)(whichCol)~=1
                return
            end
            p.BinThresh(whichCol)=get(k.globalsldr,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Global threshold changed to ', num2str(p.BinThresh(whichCol))]);
        end
        
        function pillbox_slider(~,~)
            p.kymoScalePillbox(whichCol)=get(k.pill,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Pillbox filter scaling changed to ', num2str(p.kymoScalePillbox(whichCol))]);
        end
        function wiener_slider(~,~)
            p.kymoWienerFilterSize(whichCol)=round(get(k.wien,'Value'));
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Wiener2 filter size changed to ', num2str(p.kymoWienerFilterSize(whichCol))]);
        end
        function maxint_slider(~,~)
            p.kymoMaxIntensityCutoff(whichCol)=get(k.int,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Max intensity changed to ', num2str(p.kymoMaxIntensityCutoff(whichCol))]);
        end
        function canlow_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            p.kymoCannyLowThresh(whichCol)=get(k.canlow,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Canny low threshold changed to ', num2str(p.kymoCannyLowThresh(whichCol))]);
        end
        function strtime_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            uiresume(k.fig1);
            p.kymoVerticalLineRemoval(whichCol)=get(k.strtime,'Value');
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Vertical line removal threshold changed to ', num2str(p.kymoVerticalLineRemoval(whichCol))]);
        end
        function strrad_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            uiresume(k.fig1);
            p.kymoHorizontalLineRemoval(whichCol)=get(k.strrad,'Value');
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Horizontal line removal threshold changed to ', num2str(p.kymoHorizontalLineRemoval(whichCol))]);
        end
        function noise_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            uiresume(k.fig1);
            p.kymoNoiseFilterSize(whichCol)=get(k.noise,'Value');
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Noise removal threshold changed to ', num2str(p.kymoNoiseFilterSize(whichCol))]);
        end
        function mask_slider(~,~)
            if p.(kymomodename)(whichCol)==1
                return
            end
            p.kymoMaskScaling(whichCol)=get(k.mask,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Mask scaling changed to ', num2str(p.kymoMaskScaling(whichCol))]);
            k.fig=axes('Parent', k.kymo, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
        end
        function linerad_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            p.kymoCloseFilterLineLen(whichCol)=get(k.linerad,'Value');
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Line closing scaleing changed to ', num2str(p.kymoCloseFilterLineLen(whichCol))]);
        end
        function lineangle_slider(~,~)
            if p.(kymomodename)(whichCol)~=2
                return
            end
            p.kymoCloseFilterLineAngle(whichCol)=round(get(k.lineangle,'Value'));
            uiresume(k.fig1);
            set(k.changes, 'String', 'Please wait...');
            drawradkymocor
            set(k.changes, 'String', ['Line closing angle changed to ', num2str(p.kymoCloseFilterLineAngle(whichCol))]);
        end
        
        function drawradkymocor(~,~)
            if p.(kymomodename)(whichCol)==1
                CalcRadKymo1(whichCol);
            elseif p.(kymomodename)(whichCol)==2 || p.(kymomodename)(whichCol)==3
                CalcRadKymo2(whichCol);
            end
            % cla(k.fig); axis off;
            % k.fig=axes('Parent', k.kymo, 'Color', [0.8 0.9 0.8], 'Visible', 'off', 'Xcolor', 'none','Ycolor', 'none','Position', [0 0 1 1]);
            % imshow(resizedImg, 'InitialMagnification', 'fit');
            % hold on;
            % axis on
            % ax = gca;
            % ax.Toolbar.Visible = 'off';
            % Generate a vector of the original indices
            % originalIndices = linspace(1, cols, cols);
            % % Generate a new set of indices for the desired 'newCols' entries
            % newIndices = linspace(1, cols, newCols);
            % Interpolate the original vector to the new resolution
            % RadMeanElongated = interp1(originalIndices, p.(radname)(whichCol,:), newIndices, 'linear');
            
            RadMeanElongated = interp1(originalIndices, p.(radname)(whichCol,:), newIndices, 'linear');
            RadMeanElongated = interp1([0, rows], [0, newRows], RadMeanElongated, 'linear');
            % plot(1:newCols, size(resizedImg,1)-repmat(p.tappThreshPx, newCols ,1), 'Color','b','Linewidth', 0.5);%plot the threshold
            % plot(1:length(RadMeanElongatedOrig), size(resizedImg,1)-RadMeanElongatedOrig*sqrt(2), 'g', 'LineWidth',1.5);%plot the radius
            % plot(1:length(RadMeanElongated), size(resizedImg,1)-RadMeanElongated*sqrt(2), 'r', 'LineWidth',1.5);%plot the radius
            set(k.newrad, 'XData', 1:length(RadMeanElongated), 'YData', size(resizedImg,1)-RadMeanElongated*sqrt(2));
            % hold off
        end
        
    end %manual kymograph correction
    function TappCalc_Callback(~,~)
        f=gcf;
        TappCalc;
        set(0, 'currentfigure', f);
        if ~p.disableSave
            saveall(p.dirS);
        end
        refresh(1);
        ProgressUpdate
        figure(hs.tappf1)
        hs.tappf1=[];
    end %appearance time determination button
    function TappCalc(~,~)
        if ~isstruct(b)
            b=struct();
        end
        if ~isfield(b, 'runningBatch')
            b.runningBatch=0;
        end
        if ~b.runningBatch
            if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
            if strcmp(p.operatingMode, 'single')
                errordlg('The loaded images seems to be from a single image set. You can only estimate growth rate from timelapses'); return;
            end
            if isempty(p.RadMean); errordlg('Please run timelapse analysis first'); return; end %timelapse done?
            if isempty(p.umConversion) || sum(isnan(p.umConversion))>0
                hs.UserMess.String='The reference for pixel to um conversion is missing!';customdrawnow
                return
            end
        end
        %calculate Rad in um
        RadUmCalc;
        disableGUI(1);%disable the GUI
        hs.UserMess.String='Variables are set up, please wait...'; customdrawnow
        if ~isfield(p, 'tappThreshPx')
            p.tappThreshPx=10; %detection threshold in pxl
        end
        if ~isfield(p, 'tappLengthLinFitFrame')
            p.tappLengthLinFitFrame=50; %number of frames in which we fit the linear regression
        end
        
        if ~isfield(p, 'tappThreshUm')
            p.tappThreshUm=200; %detection threshold in pxl
        end
        
        if strcmp(p.tappMode, 'um')
            p.tappThreshPx=round(p.tappThreshUm/mean(p.umConversion, 'omitnan'));
        else
            p.tappThreshUm=round(p.tappThreshPx*mean(p.umConversion, 'omitnan'));
        end
        
        for chi = 1:p.nChannel
            if chi == 1
                p.TappFr=nan(size(p.RadMeanUm,1),1); %contains the frame at which col are above p.tappThreshUm
            else
                fname = sprintf('TappFrCh%d', p.channelprocessing);
                p.(fname)=nan(size(p.RadMeanUm,1),1); %contains the frame at which col are above p.tappThreshUm
                fname = sprintf('TappErrorsCh%d', p.channelprocessing);
                p.(fname)=[];
                fname = sprintf('TappCh%d', p.channelprocessing);
                p.(fname)=[];
                fname = sprintf('GRCh%d', p.channelprocessing);
                p.(fname)=[];
                fname = sprintf('R0Ch%d', p.channelprocessing);
                p.(fname)=[];
            end
        end
        
        timeVect2=(0:size(p.RadMeanUm,2)-1)*p.deltaTmin/60; % a complete timevector for plotting
        
        
        
        % Calculate the width and height for the figure
        figWidth = Fvar.screen(3) / 3;  % One-third of the screen width
        figHeight = Fvar.screen(4) / 2;  % Half of the screen height
        
        % Calculate the position for the figure
        % The x position is at two-thirds of the screen width (since it's top right)
        % The y position is at half the screen height (since it's top right)
        figX = Fvar.screen(3) - figWidth;
        figY = Fvar.screen(4) - figHeight;
        
        % Create the figure with the calculated dimensions and position
        hs.tappf1 = figure('Position', [1, figY-80, figWidth, figHeight]);
        [ha, ~] = tight_subplot(1,p.nChannel,[.05 .05],[.1 .1],[.1 .1]);
        
        for chi = 1:p.nChannel
            axes(ha(chi));
            hold on
            p.channelprocessing = chi;
            if chi == 1
                nm_TappFr = 'TappFr';
                nm_TappErrors = 'TappErrors';
                nm_Tapp = 'Tapp';
                nm_GR = 'GR';
                nm_R0 = 'R0';
                if strcmp(p.tappMode, 'um')
                    nm_rad = 'RadMeanUm';
                else
                    nm_rad = 'RadMean';
                end
                
            else
                nm_TappFr = sprintf('TappFrCh%d', p.channelprocessing);
                nm_TappErrors = sprintf('TappErrorsCh%d', p.channelprocessing);
                nm_Tapp = sprintf('TappCh%d', p.channelprocessing);
                nm_GR = sprintf('GRCh%d', p.channelprocessing);
                nm_R0 = sprintf('R0Ch%d', p.channelprocessing);
                if strcmp(p.tappMode, 'um')
                    nm_rad = sprintf('RadMeanUmCh%d', p.channelprocessing);
                else
                    nm_rad = sprintf('RadMeanCh%d', p.channelprocessing);
                end
            end
            if ~isfield(p, nm_rad)
                continue
            end
            if isempty(p.(nm_rad))
                continue
            end
            
            %find if col is bigger than p.tappThreshUm, if it is bigger than that for
            %p.tappStayOverThresh times, take that frame as the start
            if strcmp(p.tappMode, 'um')
                Check1=p.(nm_rad)>=p.tappThreshUm;%for each RadMean entry: =1 if bigger than tappThreshUm
            else
                Check1=p.(nm_rad)>=p.tappThreshPx;%for each RadMean entry: =1 if bigger than tappThreshUm
            end
            
            TappFrameEnd=nan(size(p.RadMeanUm,1),1); %contains the endtime in frame for the lin fit
            LinFitTime=nan(size(p.RadMeanUm,1),2); %contains the start and end time for the lin fit in h
            
            Tapp=nan(size(p.RadMeanUm,1),1); %contains the time where p.tappThreshUm=R0+GR*Tapp
            GR=nan(size(p.RadMeanUm,1),1); %contains all the GR
            R0=nan(size(p.RadMeanUm,1),1); %contains the R0 from the equation R(t)=R0+GR*t
            p.(nm_TappErrors)=[];
            
            
            for i=1:size(p.RadMeanUm,1)
                
                try
                    %     Loop to find the frame on which the R is bigger than the detection
                    %     threshold of p.tappThreshPx=10px and remains above that for the next p.tappStayOverThresh=10 frames
                    for j=1:size(p.RadMeanUm,2)
                        try
                            %check if the R is above the Threshold and if it remains
                            %above it for enough frames
                            if Check1(i,j)==1 && sum(Check1(i,j:j+p.tappStayOverThresh))==p.tappStayOverThresh+1
                                p.(nm_TappFr)(i)=j; %store the frame
                                break
                            end
                        catch %because if the if condition never happens, the loop can exceed the length of p.RadMeanUm (indexing error)
                            p.(nm_TappFr)(i)=nan;
                            p.(nm_TappErrors)=[p.(nm_TappErrors), i]; % keep track of which colonies created an error
                            break
                        end
                    end
                    
                    TappFrameEnd(i)=p.(nm_TappFr)(i)+p.tappLengthLinFitFrame; %the end of the fitting frame
                    if TappFrameEnd(i)>length(p.l) %if that was outside of the range of the TL, choose the last frame
                        TappFrameEnd(i)=length(p.l);
                    end
                    
                    %if the end is bigger than the start, if the start or the end are
                    %nan, create an errorlog for that colony
                    if p.(nm_TappFr)(i)>=length(p.l) || isnan(p.(nm_TappFr)(i)) || isnan(TappFrameEnd(i))
                        TappFrameEnd(i)=nan;
                        p.(nm_TappErrors)=[p.(nm_TappErrors), i]; % keep track of which colonies created an error
                    end
                    
                    %plot the Radius, thick if it failed
                    if ismember(i, p.(nm_TappErrors))
                        plot(timeVect2,p.(nm_rad)(i,:), 'Linewidth', 2.5);
                        continue
                    else
                        pl=plot(timeVect2,p.(nm_rad)(i,:));
                    end
                    cl{i}=get(pl,'Color');% store color Value
                    
                    %store the timeframe for the start/end in h
                    LinFitTime(i,2)=TappFrameEnd(i)*p.deltaTmin/60;
                    LinFitTime(i,1)=p.(nm_TappFr)(i)*p.deltaTmin/60;
                    
                    %create time vectors for the fit and plotting
                    pxVect=(p.(nm_TappFr)(i):TappFrameEnd(i)-1);
                    timeVect=(pxVect-1)*p.deltaTmin/60;
                    
                    %fit the data!
                    P = polyfit(timeVect,p.(nm_rad)(i,pxVect),1);
                    
                    %store the GR and R0
                    GR(i)=P(1);
                    R0(i)=P(2);
                    
                    %caculate the exact time from the fit
                    Tapp(i)=(p.tappThreshUm-R0(i))/GR(i);
                    
                    if Tapp(i)>max(timeVect) || GR(i)<0
                        GR(i)=NaN;
                        R0(i)=NaN;
                        Tapp(i)=NaN;
                        p.(nm_TappErrors)=[p.(nm_TappErrors), i];
                        plot(timeVect2,p.(nm_rad)(i,:), 'Linewidth', 2.5);
                        continue
                    end
                    
                    % Calculate the y-values based on the linear equation
                    yValues = GR(i) * timeVect + R0(i);
                    
                    
                    %plot the linear fit
                    plot(timeVect, yValues, 'Linewidth', 2, 'Color', cl{i});  % Plot the line with a line width of 2
                    % plot([LinFitTime(i,1),LinFitTime(i,2)], [p.(nm_rad)(i,p.(nm_TappFr)(i)), p.(nm_rad)(i,TappFrameEnd(i))], 'Linewidth', 2, 'Color', cl{i})
                    scatter(Tapp(i), p.tappThreshUm, 'MarkerEdgeColor',cl{i}, 'MarkerFaceColor',cl{i})
                catch
                    p.(nm_TappErrors)=[p.(nm_TappErrors), i]; % keep track of which colonies created an error
                end
            end
            
            
            %define plot limits
            xlim([0 size(p.(nm_rad),2)*p.deltaTmin/60]);
            set(gca, 'XTickLabelMode', 'auto'); % Reset x-tick labels to automatic
            xticks('auto')
            ylim([-50 max(max(p.(nm_rad)))+50]);
            set(gca, 'YTickLabelMode', 'auto'); % Reset x-tick labels to automatic
            yticks('auto')
            xlabel('Time [h]');
            ylabel('Radius [\mum]');
            title(['Channel ', num2str(chi)]);
            
            %add the threshold line
            line([0 size(p.(nm_rad),2)*p.deltaTmin/60;],[p.tappThreshUm,p.tappThreshUm], 'Color', 'k', 'Linewidth', 2.5)
            
            
            %store the variables
            p.(nm_Tapp)=Tapp;
            p.(nm_GR)=GR;
            p.(nm_R0)=R0;
            
            hold off
            
        end
        if ~b.runningBatch
            msg = [];
            for chi = 1:p.nChannel
                p.channelprocessing = chi;
                if chi == 1
                    nm_TappErrors = 'TappErrors';
                else
                    nm_TappErrors = sprintf('TappErrorsCh%d', p.channelprocessing);
                end
                
                if ~isempty(p.(nm_TappErrors))
                    msg = [msg, 'Channel ', num2str(chi), ': Appearance time calculation for colonies: ', num2str(p.(nm_TappErrors)),' failed.']
                end
            end
            if ~isempty(msg)
                msgbox(msg)
            end
        end
        
        % final display for which colonies the Tdap calculation failed
        hs.UserMess.String='Appearance time calculation finished!'; customdrawnow
        
        disableGUI(0);%disable the GUI
    end %Tapp calculation
    function Intensity_TL_Callback(~,~)
        
        %         for the moment, plate AOI is required
        if isempty(p.roiPlateRad)
            errordlg('Please delimit Area of interest (Plate detection) before using this function');
            return
        end
        %         3 ways to scale intensity: internal min-max from first and last
        %         images; manual providing min max values or no scaling
        q = questdlg('Scale intensity with internal min-max, manual min-max or no scaling?','','Internal', 'Manual', 'None', 'Internal');
        switch q
            case 'Internal'
                scl=1;
                mn=0;
            case 'None'
                scl=0;
                mn=0;
            case 'Manual'
                scl=1;
                mn=1;
            case ''
                return
        end
        q = questdlg('S aureus or S pneumoniae?','','aureus', 'pneumoniae', 'Cancel', 'aureus');
        switch q
            case 'aureus'
                if isempty(p.colonyCenRad{length(p.l),2})
                    errordlg('Please add 1 cicle');return
                end
                aureus=1;
                %         calculate structuring element for tophat filtering of image based
                %         on the biggest circle on the image
                se = strel('disk',ceil(max(p.colonyCenRad{length(p.l),2})*1.15));
            case 'pneumoniae'
                aureus=0;
            case 'Cancel'
                return
            case ''
                return
        end
        disableGUI(1)
        
        hs.UserMess.String='Please wait...';customdrawnow
        
        
        
        %         read last image, transform to grayscale, tophat filtering
        frend = imread([p.dir, '/',p.l(length(p.l)).name]);
        fr1s = customcol2gray(frend);
        
        if aureus
            fr1s=imtophat(fr1s, se);
        else
            %             fr1s=imcomplement(fr1s);
            frbeg = imread([p.dir, '/',p.l(1).name]);
            frbeg = customcol2gray(frbeg);
            frbeg = imgaussfilt(frbeg, 10);
            fr1s = fr1s - frbeg;
        end
        
        
        
        %         Get pixel index values for the AOI filtering
        imageSizeY = size(fr1s,1);
        imageSizeX = size(fr1s,2);
        [columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
        radius=p.roiPlateRad(1)+10;
        
        centerY = p.roiPlateCenter(1,2);
        centerX = p.roiPlateCenter(1,1);
        circlePixels = (rowsInImage - centerY).^2 ...
            + (columnsInImage - centerX).^2 <= radius.^2;
        
        % define internal min/max as 0.1% and 99.9% quantiles
        mat2grayRef=[NaN, NaN];
        mat2grayRef(1) = quantile(fr1s(circlePixels), 0.001);
        mat2grayRef(2) = quantile(fr1s(circlePixels), 0.999);
        
        %         if manual scaling: ask user for the min/max. Defaults as the
        %         internal min/max
        if mn
            dlg_title = 'Min-max scaling'; num_lines = 1;
            prompt = {'Minimal intensity', 'Maximal intensity'};
            
            defaultans = {num2str(mat2grayRef(1)), num2str(mat2grayRef(2))};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            if isempty(answer);hs.UserMess.String='';customdrawnow; return; end
            mat2grayRef(1)=str2double(answer{1});
            mat2grayRef(2)=str2double(answer{2});
        end
        
        
        % read in 1st image, do transformations
        fr1 = imread([p.dir, '/',p.l(1).name]); %to substract
        fr1s=customcol2gray(fr1);
        if aureus
            fr1s=imtophat(fr1s, se);
        else
            %             fr1s=imcomplement(fr1s);
            fr1s = fr1s - frbeg;
        end
        
        
        
        %         if internal scaling: edit min/max from last image if
        %         smaller/bigger on 1st image
        if scl && ~mn
            if quantile(fr1s(circlePixels), 0.001)<mat2grayRef(1)
                mat2grayRef(1) = quantile(fr1s(circlePixels), 0.001);
            end
            if quantile(fr1s(circlePixels), 0.999)>mat2grayRef(2)
                mat2grayRef(2) = quantile(fr1s(circlePixels), 0.999);
            end
        end
        
        % subset to AOI only
        fr1s = fr1s(circlePixels);
        
        % scaling
        fr1s=mat2gray(fr1s, mat2grayRef);
        %         and divide sum of pixel intensity by nr pixel inside AOI
        fr1s=sum(fr1s)/sum(circlePixels(:));
        
        %         initialize loop over all frames
        p.dif=NaN(length(p.l),1);
        TimeIdx=1;
        tic %timing
        for i=1:length(p.l)
            hs.UserMessFrame.String=['frame ',num2str(i), ' of ', num2str(length(p.l))];
            
            %             read frame, transform to grayscale, tophat filtering
            fr = imread([p.dir, '/',p.l(i).name]);
            fr = customcol2gray(fr);
            if aureus
                fr=imtophat(fr, se);
            else
                fr = fr - frbeg;
                %                 fr=imcomplement(fr);
            end
            
            
            %             if scaling, scale intensity
            if scl
                fr = mat2gray(fr, mat2grayRef);
            end
            %             subset for AOI only
            fr = fr(circlePixels);
            %             final value
            dif = (sum(fr)/sum(circlePixels(:))-fr1s);
            p.dif(i) = dif;
            
            
            
            % telling user how long remains
            a=floor(100*((TimeIdx)/(length(p.l))));
            textMsg=([num2str(floor(a)),'% done, est. ' sec2timestr((100*toc/a-toc)), ' remaining']);
            hs.UserMess.String=textMsg; customdrawnow
            fill([0 0 a/100 a/100],[0,1,1,0],[0.5 0.7 0.8],'Parent',hs.Progress1), set(hs.Progress1,'Xlim',[0 1],'Ylim',[0 1], 'Xcolor','none','Ycolor','none'); customdrawnow
            
            TimeIdx=TimeIdx+1;
            
        end
        %         save .csv file
        writematrix([p.dif,((1:p.deltaTmin:length(p.l)*p.deltaTmin)/60)'],...
            [p.dirS,filesep,p.dirS(p.del(end)+1:end), '.csv'],'Delimiter',...
            Fvar.csvdelimiterssymbol{p.csvdelimiter});
        
        refresh(0);
        saveall(p.dirS);
        disableGUI(0)
        hs.UserMess.String='Intensity vector saved.';customdrawnow
        figure; plot(p.dif);  title('Increase of pixel intensity');
        xlabel('Time (frame)'); ylabel('Average intensity increase per pixel');
        
    end %intensity TL
    function Colony_Intensity_TL_Callback(~,~)

        % EXTRACT_AND_PLOT_CHANNEL_DATA (CHANNEL-NAMED FIELDS)
        % This script extracts quantitative kymograph data from p and Kymo structs for each colony,
        % computes statistics for each imaging channel, saves results to CSV, and visualizes them.
        % It is modular and will handle any number of imaging channels (p.nChannel).
        % Assumes p, Kymo are loaded; saveDir and p.dirS are set.
        
        %ask user for dir
        saveDir=p.dirS;
        saveDir=uigetdir(saveDir,'select the directory to save data and plots');
        if saveDir==0; return; end %canceled
        try     
            hs.UserMess.String=['Running intensity analysis with delta time: ',num2str(p.deltaTmin),...
                'min and spatial calibration: ', num2str(p.umConversion(1)), ', please wait ...'];
            customdrawnow
            
            % --- Initialization and Table Setup ---
            % Build dynamic variable names for all channels and statistics
            baseStats = {'range', 'iqr', 'std', 'mean', 'cv', 'maxintensity', 'meanInclBackground', 'slope'};
            allVarNames = {'folder','colony','time'};
            for ci = 1:p.nChannel
                suffix = sprintf('_ch%d',ci);
                allVarNames = [allVarNames, strcat(baseStats, suffix)];
            end
            
            % Preallocate empty table with appropriate columns
            tab1 = cell2table(cell(0,numel(allVarNames)), 'VariableNames', allVarNames);
            
            % Get folder name from directory
            [~, folder, ~] = fileparts(p.dirS);
            
            % --- Data Extraction and Table Population ---
            colList = 1:size(p.RadMean,1); % Each colony
            for whichCol = colList
                % Loop over all imaging channels
                for ti = 1:size(p.RadMean,2) % time index
                    newRow = cell(1, numel(allVarNames));
                    newRow{1} = folder;    % folder name
                    newRow{2} = whichCol;   % Colony index
                    newRow{3} = (ti-1)*p.deltaTmin; % Time (min)
                    for ci = 1:p.nChannel
                        % Channel-specific image and radial data
                        if ci == 1
                            kymoField = 'Kymo';
                            radField = 'RadMean';
                            img = imcomplement(imrotate(Kymo.(kymoField){whichCol}, 90));
                            rad = p.(radField)(whichCol,:);
                        else
                            kymoField = sprintf('KymoCh%d', ci);
                            radField = sprintf('RadMeanCh%d', ci);
                            img = imrotate(Kymo.(kymoField){whichCol}, 90);
                            rad = p.(radField)(whichCol,:);
                        end
                        % Extract radial band and full profile
                        try
                            selrads = flip((size(img,1)-floor(rad(ti)*sqrt(2))):size(img,1));
                            totch = img(:,ti);
                            curint = img(selrads,ti);
                            imgfilt = imgaussfilt(img,5);
                            formax = imgfilt(selrads,ti);
                        catch
                            continue
                        end
                        if sum(isnan(selrads))>1
                            continue
                        end
                        if rad(ti) < 25
                            curint = nan; imgfilt = nan; formax = nan;
                        end
                        suffix = sprintf('_ch%d',ci);
            
                        % Compute and assign statistics
                        for vi = 1:numel(baseStats)
                            colIdx = find(strcmp(tab1.Properties.VariableNames, [baseStats{vi}, suffix]));
                            switch baseStats{vi}
                                case 'range'
                                    newRow{colIdx} = range(curint);
                                case 'iqr'
                                    newRow{colIdx} = iqr(curint);
                                case 'std'
                                    newRow{colIdx} = std(curint);
                                case 'mean'
                                    newRow{colIdx} = mean(curint);
                                case 'cv'
                                    newRow{colIdx} = std(curint)/mean(curint);
                                case 'maxintensity'
                                    [maxVal, ~] = max(formax);
                                    maxIndices = find(formax == maxVal);
                                    newRow{colIdx} = (mean(maxIndices)/sqrt(2)*p.umConversion(1)) / (length(formax)/sqrt(2)*p.umConversion(1));
                                case 'meanInclBackground'
                                    newRow{colIdx} = mean(totch);
                                case 'slope'
                                    if rad(ti) >= 25
                                        y = curint(1:round(0.95*length(curint)));
                                        x = (1:length(y))/sqrt(2)*p.umConversion(1);
                                        P = polyfit(x, y, 1);
                                        newRow{colIdx} = P(1);
                                    else
                                        newRow{colIdx} = nan;
                                    end
                            end
                        end
                    end
                    % Fill empty entries with nan or 'NA' as appropriate
                    for j = 1:length(newRow)
                        if isempty(newRow{j})
                            if isnumeric(tab1{:,j}), newRow{j} = nan;
                            elseif iscell(tab1{:,j}), newRow{j} = {"NA"};
                            else, newRow{j} = "NA";
                            end
                        end
                    end
                    % Append row to table
                    tab1 = [tab1; cell2table(newRow, 'VariableNames', tab1.Properties.VariableNames)];
                end
            end
            
            % --- Save Data to CSV ---
            csvName = fullfile(saveDir, [folder, '_TL_colony_intensity.csv']);
            writetable(tab1, csvName);
            
            % --- Plotting for All Channels ---
            varNames = tab1.Properties.VariableNames;
            uniqueColonies = unique(tab1.colony);
            nRows = 3; % Number of subplot rows (adjust as needed)
            
            for ci = 1:p.nChannel
                suffix = sprintf('_ch%d',ci);
                vars = varNames(endsWith(varNames, suffix));
                nPlots = numel(vars);
                nCols = ceil(nPlots / nRows);
                figure('Name', ['Variables for channel ', num2str(ci)]);
                ha = tight_subplot(nRows, nCols, [0.15, 0.05], 0.1, 0.05);
                for i = 1:nPlots
                    axes(ha(i));
                    inithold = 1;
                    for colony = uniqueColonies'
                        idx = tab1.colony == colony;
                        plotData = tab1(idx, {'time', vars{i}});
                        plot(plotData.time/60, plotData.(vars{i}), '-', ...
                            'DisplayName', sprintf('Colony %d', colony));
                        if inithold
                            hold on;
                            inithold = 0;
                        end
                    end
                    title(vars{i}, 'Interpreter', 'none');
                    xlabel('Time [h]');
                    xlim([0, max(plotData.time/60)+0.25]);
                    hold off;
                end
                % Export figure
                f = gcf;
                fName = fullfile(saveDir, [folder, sprintf('_TL_colony_intensity_ch%d.tif',ci)]);
                exportgraphics(f, fName, 'resolution', 300)
            end
    
            hs.UserMess.String=['Intensity analysis finished. Data saved to: ', saveDir]; customdrawnow
        catch
            hs.UserMess.String=['Something went wrong. Ensure radii tracking for all channels and colonies is finished & close .csv files']; customdrawnow
        end
    end
%% Visualize tab:
    function SizeDist_Callback(~,~)
        %plot radius distribution for timepoint. For single sets, use the time that
        %the user had specified after the first loading and ask user from which
        %timepoint for timelapses
        if strcmp(p.operatingMode, 'single')
            if isempty(p.colonyCenRad); errodlg('Please detect colonies'); return; end
            ftoplot= UserChoiceFrames('plot');
            if isempty(ftoplot)% the user canceled ,abort
                hs.UserMess.String='';customdrawnow
                return;
            end
            ftoplot=sort(unique(ftoplot));
            x=preparingx(ftoplot);
            if isempty(x)
                if size(ftoplot)==1
                    errordlg('There are no colonies on this frame')
                else
                    errordlg('There are no colonies on these frames')
                end
                return;
            end
            [x1,x2,x3]=adjustingunits(x, ftoplot);
            if p.plotUnit~=1
                val=CheckVariableOnFrames(p.umConversion,'spatial calibration factor', ftoplot);
                if val~=0; return;end
            end
            figure;
            if p.plotUnit==1
                histplot(x1,ftoplot);xlabel('colony radius [pixels]');
            elseif p.plotUnit==2
                histplot(x2,ftoplot);xlabel('colony radius [\mum]');
            elseif p.plotUnit==3
                histplot(x3,ftoplot); xlabel('log (colony radius [\mum])');
            elseif p.plotUnit==4
                subplot(1,3,1); xlabel('colony radius [pixels]'); hold on;
                histplot(x1,ftoplot);
                subplot(1,3,2); xlabel('colony radius [\mum]');  hold on;
                histplot(x2,ftoplot);
                subplot(1,3,3); xlabel('log (colony radius [\mum])');  hold on;
                histplot(x3,ftoplot); hold off;
            end
            
        elseif strcmp(p.operatingMode,'TL')
            if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
            
            %userinput: which timepoint
            timedef=0;
            while ~timedef
                prompt = {'From which timepoint in hours do you want to plot the size distribution?'};
                dlg_title = 'size distribution timepoint';
                num_lines = 1;
                defaultans = {'24'};
                answer=inputdlg(prompt,dlg_title,num_lines,defaultans);
                if isempty(answer);return;end
                ttoplot=str2double(cell2mat(answer));%time to plot
                ftoplot=round(ttoplot*60/p.deltaTmin);%frame to plot
                %check if input is in range of timelapse
                if ftoplot>size(p.l,1) || ftoplot<1 || isnan(ftoplot) || length(ftoplot)>1 || isempty(ftoplot)
                    waitfor(errordlg(['timepoint is outside picture range. Max possible timepoint:',num2str(size(p.l,1)*p.deltaTmin/60),'h. Try again']));
                else
                    timedef=1;
                end
                %convert into microns
            end
            RadUmCalc;
            
            %plot
            figure; hold on;
            
            toplot=p.RadMeanUm(:,ftoplot);
            histbar=linspace(floor(min(toplot)*0.95), ceil(max(toplot)*1.05), p.histbins);
            
            [a,b]=hist(toplot,histbar); %calculate hist
            plot(b,(a*100)/length(toplot),'k','LineWidth',1.5);
            title(['Colony size distribution at ',num2str(round(ttoplot,2)),'h']);
            ylabel('Percentage');xlabel('colony radius [\mum]');
            hold off;
        end
    end %radius distribution
    function x=preparingx(ftoplot)
        x=[];
        if ftoplot==0 %all frames
            for ii2=1:length(p.l)
                temp=p.colonyCenRad{ii2,2};
                x=vertcat(x,temp);
                clear temp
            end
        else %a selection of frames
            for ii2=ftoplot
                temp=p.colonyCenRad{ii2,2};
                x=vertcat(x,temp);
                clear temp
            end
        end
    end %get radius data
    function [x1,x2,x3]=adjustingunits(x, ftoplot)
        if ftoplot==0
            for ii2=1:length(p.l)
                x1=x;
                x2=x*p.umConversion(ii2);
                x3=log(x*p.umConversion(ii2));
            end
        else
            for ii2=ftoplot
                x1=x;
                x2=x*p.umConversion(ii2);
                x3=log(x*p.umConversion(ii2));
            end
        end
    end %get correct units
    function histplot(x,ftoplot)
        histbar=linspace(floor(min(x)*0.95), ceil(max(x)*1.05), p.histbins);
        [a,ba]=hist(x,histbar);
        plot(ba,(a*100)/length(x),'k','LineWidth',1.5);
        if ~isempty(p.thistimepoint)
            title(['colony size distribution at ',num2str(p.thistimepoint),'h']);
        else
            title('Colony size distribution');
        end
        if ftoplot~=0
            legend(['frame Nr. ',num2str(ftoplot)], 'Location','southeast');
        end
        ylabel('Percentage');
    end %do histogram plot
    function plotTL_Callback(~,~)
        % CalcRadKymo
        disableGUI(1)
        
        if strcmp(p.operatingMode, 'TL')
            hs.tappf1 = figure();
            if p.plotUnit==4
                [ha, ~] = tight_subplot(p.nChannel,3,[.1 .1],[.1 .1],[.1 .1]);
                cntr =0;
            else
                [ha, ~] = tight_subplot(1,p.nChannel,[.05 .05],[.1 .1],[.1 .1]);
            end
            
            for chi = 1:p.nChannel
                p.channelprocessing = chi;
                if p.plotUnit~=4
                    axes(ha(chi));
                end
                
                hold on
                if p.plotUnit==1
                    rawRad_Callback;
                elseif p.plotUnit==2
                    smoothRad_Callback;
                elseif p.plotUnit==3
                    logRad_Callback;
                elseif p.plotUnit==4
                    
                    for i = 1:3
                        cntr = cntr+1;
                        axes(ha(cntr));
                        if i ==1
                            rawRad_Callback;
                        elseif i==2
                            smoothRad_Callback;
                        else
                            logRad_Callback;
                        end
                    end
                end
                hold off
            end
            
        else
            multiEPplot_Callback;
        end
        
        disableGUI(0)
    end %Radius vs time
    function rawRad_Callback(~,~)
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
        
        % Radius versus time data is contained in RadMean (colonies x time).
        
        % Quick and dirty plot raw data:
        %  set(0,'defaultfigureposition',[0 0 2000 1000])
        %  figure;
        %  subplot(2,3,1)
        if p.channelprocessing == 1
            nm_rad = 'RadMean';
        else
            nm_rad = sprintf('RadMeanCh%d', p.channelprocessing);
        end
        
        plot(p.(nm_rad)');
        xlabel('time (frames)'); ylabel('radius [pixels]');
        title(['Channel ', num2str(p.channelprocessing), newline, p.rawTitle]);
        xlim([0 size(p.RadMean,2)+5]);
    end %px vs frame
    function smoothRad_Callback(~,~)
        %smoothed um vs time(h). I took a smoothing functions from the web called
        %nanfastsmooth that can deal with nan values in the dataset. the inbuilt
        %smoothing functions gives errors or strange results when trying to smooth
        %data with nans
        if sum(size(p.l))==0; errordlg('please load an image series'); return; end %image loaded?
        if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
        
        
        RadUmCalc;
        timeVect=(0:size(p.RadMeanUm,2)-1)*p.deltaTmin/60; % we will need a time vector
        
        if p.channelprocessing == 1
            nm_rad = 'RadMeanUm';
        else
            nm_rad = sprintf('RadMeanUmCh%d', p.channelprocessing);
        end
        % one can smooth the data and plot :
        if p.smoothFrames>1
            smoothedRad=nan(size(p.RadMeanUm));
            for b1=1:size(p.RadMeanUm,1)
                smoothedRad(b1,:)=nanfastsmooth(p.(nm_rad)(b1,:),p.smoothFrames,1,0.5);
            end
        else
            smoothedRad=p.(nm_rad);
        end
        % smoothedRad=smoothdata(p.RadMeanUm,2, p.smoothFrames, 'omitnan');
        
        %actual plotting
        % fig=figure; hold on; %#ok<NASGU>
        %for b1=1:size(p.RadMeanUm,1)
        x=plot(timeVect,smoothedRad); %#ok<NASGU>
        %end
        xlim([0 max(timeVect+0.5)]);
        
        %set(gca,'fontsize',20);
        xlabel('time (h)');
        title(['Channel ', num2str(p.channelprocessing), newline, p.smoothTitle]);
        if p.smoothFrames>1
            ylabel('Radius [smoothed, \mum]');
        else
            ylabel('Radius [\mum]');
        end
        axis tight;  % Adjust the axis limits based on the data
        xticks('auto');  % Ensure automatic generation of x-tick labels
        yticks('auto');  % Ensure automatic generation of y-tick labels
        xticklabels('auto');  % Ensure automatic generation of x-tick labels
        yticklabels('auto'); % Ensure automatic generation of x-tick labels
        clear x; clear smoothedRad;
        
    end %um vs h, potential to smooth
    function logRad_Callback(~,~)
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
        
        timeVect=(0:size(p.RadMeanUm,2)-1)*p.deltaTmin/60; % we will need a time vector
        
        RadUmCalc;
        if p.channelprocessing == 1
            nm_rad = 'RadMeanUm';
        else
            nm_rad = sprintf('RadMeanUmCh%d', p.channelprocessing);
        end
        
        if p.smoothFrames>1
            smoothedRad1=nan(size(p.RadMeanUm));
            for b1=1:size(p.RadMeanUm,1)
                smoothedRad1(b1,:)=log10(nanfastsmooth(p.(nm_rad)(b1,:),p.smoothFrames,1,0.5));
                %                 smoothedRad1(b1,:)=smooth(log10(p.RadMeanUm(b1,:)),p.smoothFrames);
                
            end
        else
            smoothedRad1=log10(p.(nm_rad));
        end
        smoothedRad1(~isfinite(smoothedRad1))=0;
        
        % figure; hold on;
        for b1=1:size(p.RadMeanUm,1)
            x=plot(timeVect,smoothedRad1); %#ok<NASGU>
        end
        ylim([min(log10(p.RadMeanUm(:)))-0.2 max(log10(p.RadMeanUm(:)))+0.2]);
        xlim([0 max(timeVect+0.5)]);
        clear x;
        %clear smoothedRad
        clear smoothedRad1;
        title(['Channel ', num2str(p.channelprocessing), newline, p.logTitle]);
        xlabel('time (h)');
        if p.smoothFrames>1
            ylabel('log10 of radius [smoothed, \mum]');
        else
            ylabel('log10 of radius [\mum]');
        end
    end %log(um) vs h, potential to smooth
    function allRad_Callback(~,~)
        %Check load
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
        
        %timevector
        timeVect=(0:size(p.RadMeanUm,2)-1)*p.deltaTmin/60; % we will need a time vector
        
        RadUmCalc;
        
        if p.channelprocessing == 1
            nm_rad = 'RadMeanUm';
        else
            nm_rad = sprintf('RadMeanUmCh%d', p.channelprocessing);
        end
        
        %raw
        plot(p.RadMean');
        xlabel('time (frames)'); ylabel('radius [pixels]'); title(p.rawTitle);
        xlim([0 size(p.RadMean,2)+5]);
        
        
        %smoothed
        subplot(1,3,2);
        if p.smoothFrames>1
            smoothedRad1=nan(size(p.RadMeanUm));
            for b1=1:size(p.RadMeanUm,1)
                smoothedRad1(b1,:)=nanfastsmooth(p.RadMeanUm(b1,:),p.smoothFrames,1,0.5);
            end
        else
            smoothedRad1=p.RadMeanUm;
        end
        
        
        hold on;
        for b1=1:size(p.RadMeanUm,1)
            x=plot(timeVect,smoothedRad1); %#ok<NASGU>
        end
        xlim([0 max(timeVect+0.5)]);
        xlabel('time (h)'); title(p.smoothTitle);
        if p.smoothFrames>1
            ylabel('Radius [smoothed, \mum]');
        else
            ylabel('Radius [\mum]');
        end
        clear x;
        %clear smoothedRad;
        clear smoothedRad1;
        hold off;
        %set(gca,'fontsize',20);
        
        
        %log smoothed
        subplot(1,3,3);
        if p.smoothFrames>1
            smoothedRad1=nan(size(p.RadMeanUm));
            for b1=1:size(p.RadMeanUm,1)
                smoothedRad1(b1,:)=log10(nanfastsmooth(p.RadMeanUm(b1,:),p.smoothFrames,1,0.5));
                %                 smoothedRad1(b1,:)=smooth(log10(p.RadMeanUm(b1,:)),p.smoothFrames);
                
            end
        else
            smoothedRad1=log10(p.RadMeanUm);
        end
        smoothedRad1(~isfinite(smoothedRad1))=0;
        hold on;
        for bbb=1:size(p.RadMeanUm,1)
            x=plot(timeVect, smoothedRad1); %#ok<NASGU>
        end
        ylim([min(log10(p.RadMeanUm(:)))-0.2 max(log10(p.RadMeanUm(:)))+0.2]);
        xlim([0 max(timeVect+0.5)]);
        xlabel('time (h)'); title(p.logTitle);
        if p.smoothFrames>1
            ylabel('log10 of radius [smoothed, \mum]');
        else
            ylabel('log10 of radius [\mum]');
        end
        clear x; clear smoothedRad;
        hold off;
        
    end %all 3 options in 1 figure
    function SmoothY = nanfastsmooth(Y,w,type,tol)
        % nanfastsmooth(Y,w,type,tol) smooths vector Y with moving
        % average of width w ignoring NaNs in data..
        %
        % Y is input signal.
        % w is the window width.
        %
        % The argument "type" determines the smooth type:
        %   If type=1, rectangular (sliding-average or boxcar)
        %   If type=2, triangular (2 passes of sliding-average)
        %   If type=3, pseudo-Gaussian (3 passes of sliding-average)
        %
        % The argument "tol" controls the amount of tolerance to NaNs allowed
        % between 0 and 1. A value of zero means that if the window has any NaNs
        % in it then the output is set as NaN. A value of 1 allows any number of
        % NaNs in the window and will still give an answer for the smoothed signal.
        % A value of 0.5 means that there must be at least half
        % real values in the window for the output to be valid.
        %
        % The start and end of the file are treated as if there are NaNs beyond the
        % dataset. As such the behaviour depends on the value of 'tol' as above.
        % With 'tol' set at 0.5 the smoothed signal will start and end at the same
        % time as the orgional signal. However it's accuracy will be reduced and
        % the moving average will become more and more one-sided as the beginning
        % and end is approached.
        %
        % fastsmooth(Y,w,type) smooths with tol = 0.5.
        % fastsmooth(Y,w) smooths with type = 1 and tol = 0.5
        %
        % Version 1.0, 26th August 2015. G.M.Pittam
        %   - First Version
        % Version 1.1, 5th October 2015. G.M.Pittam
        %   - Updated to correctly smooth both even and uneven window length.
        %   - Issue identified by Erik Benkler 5th September 2015.
        % Modified from fastsmooth by T. C. O'Haver, May, 2008.
        
        if nargin == 2, tol = 0.5; type = 1; end
        if nargin == 3, tol = 0.5; end
        switch type
            case 1
                SmoothY = sa(Y,w,tol);
            case 2
                SmoothY = sa(sa(Y,w,tol),w,tol);
            case 3
                SmoothY = sa(sa(sa(Y,w,tol),w,tol),w,tol);
        end
        
        
        
        
        
        function SmoothY = sa(Y,smoothwidth,tol)
            if smoothwidth == 1
                SmoothY = Y;
                return
            end
            
            % Bound Tolerance
            if tol<0, tol=0; end
            if tol>1, tol=1; end
            
            w = round(smoothwidth);
            halfw = floor(w/2);
            L = length(Y);
            
            % Make empty arrays to store data
            n = size(Y);
            s = zeros(n);
            np = zeros(n);
            
            if mod(w,2)
                % Initialise Sums and counts
                SumPoints = sum(Y(1:halfw+1));
                NumPoints = sum(~isnan(Y(1:halfw+1)));
                
                % Loop through producing sum and count
                s(1) = SumPoints;
                np(1) = NumPoints;
                for ki=2:L
                    if ki > halfw+1 && ~isnan(Y(ki-halfw-1))
                        SumPoints = SumPoints-Y(ki-halfw-1);
                        NumPoints = NumPoints-1;
                    end
                    if ki <= L-halfw && ~isnan(Y(ki+halfw))
                        SumPoints = SumPoints+Y(ki+halfw);
                        NumPoints = NumPoints+1;
                    end
                    s(ki) = SumPoints;
                    np(ki) = NumPoints;
                end
            else
                % Initialise Sums and counts
                SumPoints = sum(Y(1:halfw))+0.5*Y(halfw+1);
                NumPoints = sum(~isnan(Y(1:halfw)))+0.5;
                
                % Loop through producing sum and count
                s(1) = SumPoints;
                np(1) = NumPoints;
                for ki=2:L
                    if ki > halfw+1 && ~isnan(Y(ki-halfw-1))
                        SumPoints = SumPoints - 0.5*Y(ki-halfw-1);
                        NumPoints = NumPoints - 0.5;
                    end
                    if ki > halfw && ~isnan(Y(ki-halfw))
                        SumPoints = SumPoints - 0.5*Y(ki-halfw);
                        NumPoints = NumPoints - 0.5;
                    end
                    if ki <= L-halfw && ~isnan(Y(ki+halfw))
                        SumPoints = SumPoints + 0.5*Y(ki+halfw);
                        NumPoints = NumPoints + 0.5;
                    end
                    if ki <= L-halfw+1 && ~isnan(Y(ki+halfw-1))
                        SumPoints = SumPoints + 0.5*Y(ki+halfw-1);
                        NumPoints = NumPoints + 0.5;
                    end
                    s(ki) = SumPoints;
                    np(ki) = NumPoints;
                end
            end
            
            % Remove the amount of interpolated datapoints desired
            np(np<max((w*(1-tol)),1)) = NaN;
            
            % Calculate Smoothed Signal
            SmoothY=s./np;
        end
        
        function y = sum(x)
            y = sum(x(~isnan(x)));
        end
    end %smoothing function that can deal with nans
    function multiEPplot_Callback(~,~)
        flist= UserChoiceFrames('plot');
        if isempty(flist)% the user canceled ,abort
            hs.UserMess.String='';customdrawnow
            return;
        end
        if length(flist)>1
            col=colormap();
            col=col(round(linspace(1, size(col,1), length(p.l))), :);
            Legend=cell(length(p.l),1);
            h=nan(length(p.l),1);
        end
        
        
        
        epf=figure; hold on
        ymax=0;
        keepfr=true(length(flist),1);
        %         radall=[];
        for fr=flist
            if isempty(p.(['counts',num2str(1)]){fr,2})
                if length(flist)==1
                    try close(epf); catch; end
                    hs.UserMess.String='No sequence data for this frame loaded';customdrawnow
                    return
                else
                    
                    keepfr(fr)=false;
                    hs.UserMess.String='Sequence data for at least one frame is missing';customdrawnow
                    continue
                end
            end
            rad=nan(length(p.(['counts',num2str(1)]){fr,2}), length(p.multiEPdirs));
            for i=1:length(p.multiEPdirs)
                rad(:,i)=p.(['counts',num2str(i)]){fr,2};
                if p.plotUnit==2 || p.plotUnit==3
                    rad(:,i)=rad(:,i)*p.(['umConversion',num2str(i)])(fr);
                end
                if p.plotUnit==3
                    rad(:,i)=log10(rad(:,i)+1);
                end
            end
            if length(flist)~=1
                hi=plot(rad', 'Color',col(fr,:));
                h(fr) = hi(1);
                clear hi
                Legend{fr}=strcat('Frame ', num2str(fr));
            else
                plot(rad');
            end
            
            %             rad=[repmat(fr,size(rad,1),1), rad];
            %             radall=[radall; rad];
            ymax=max(ymax, max(max(rad)));
        end
        
        
        
        if length(flist)~=1
            Legend=Legend(keepfr);
            h=h(keepfr);
            legend(h,Legend, 'Location','SouthEast');
        end
        
        xlabel('timepoints');
        if p.plotUnit==1
            ylabel('radius [pixels]');
        elseif p.plotUnit==2
            ylabel('radius [\mum]');
        elseif p.plotUnit==3
            ylabel('log10 radius+1 [\mum]');
        end
        title('multi-TP');
        xlim([0.8 size(rad,2)+0.2]);
        ylim([-2 ymax*1.05]);
        xticks(1:length(p.multiEPdirs));
        xticklabels(1:length(p.multiEPdirs));
        
    end %radius at multiple timepoints
    function TappDist_Callback(~,~)
        %plot radius distribution for timepoint. For single sets, use the time that
        %the user had specified after the first loading and ask user from which
        %timepoint for timelapses
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        %val=CheckVariableOnFrames(p.umConversion,'spatial calibration factor', ftoplot);
        %if val~=0; return;end
        if strcmp(p.operatingMode, 'TL')
            if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
            if isempty(p.Tapp)==1; errordlg('Please determine appearance time first'); return; end %timelapse done?
            if isempty(p.TappCalibrated)
                toplot=p.Tapp;
            else
                toplot=p.TappCalibrated;
            end
        else
            if isempty(p.estTapp)==1; errordlg('Please estimate appearance time first first'); return; end %timelapse done?
            toplot=-2;
            frame=-2;
            for i=1:length(p.l)
                temp=p.estTapp(~isnan(p.estTapp(:,i)),i);
                toplot(end+1:end+length(temp))=temp;
                frame(end+1:end+length(temp))=i;
            end
            toplot=toplot(2:end);
            frame=frame(2:end);
        end
        
        figure; hold on;
        
        
        
        histbar=linspace(floor(min(toplot)*0.95), ceil(max(toplot)*1.05), p.histbins);
        
        [a,b]=hist(toplot,histbar);%calculate hist
        plot(b,(a*100)/length(toplot),'k','LineWidth',1.5);
        title('Appearance time distribution');
        if isempty(p.TappCalibrated)
            xlabel('Raw appearance time [h]');
        else
            xlabel('Calibrated appearance time [h]');
        end
        ylabel('Percentage');
        hold off;
    end %Tapp distribution plot
    function GRdist_Callback(~,~)
        %plot radius distribution for timepoint. For single sets, use the time that
        %the user had specified after the first loading and ask user from which
        %timepoint for timelapses
        if sum(size(p.l))==0; errordlg('please load a image series'); return; end %image loaded?
        %val=CheckVariableOnFrames(p.umConversion,'spatial calibration factor', ftoplot);
        %if val~=0; return;end
        if strcmp(p.operatingMode, 'TL')
            if isempty(p.RadMean)==1; errordlg('Please run timelapse analysis first'); return; end %timelapse done?
            if isempty(p.Tapp)==1; errordlg('Please estimate appearance time first'); return; end %because then GR is also filled
        else
            flist= UserChoiceFrames('plot');
            if isempty(flist)% the user canceled ,abort
                hs.UserMess.String='';customdrawnow
                return;
            end
            if length(flist)>1
                col=colormap();
                col=col(round(linspace(1, size(col,1), length(p.l))), :);
                Legend=cell(length(p.l),1);
                h=nan(length(p.l),1);
            end
        end
        %userinput: which timepoint
        
        epf=figure; hold on;
        
        if strcmp(p.operatingMode, 'TL')
            toplot=p.GR;
            histbar=linspace(floor(min(toplot)*0.95), ceil(max(toplot)*1.05), p.histbins);
            [a,b]=hist(toplot,histbar);%calculate hist
            plot(b,(a*100)/length(toplot),'k','LineWidth',1.5);
            title('Growth rate distribution');
            xlabel('Growth rate [\mum/h]');
            
            ylabel('Percentage');
            hold off;
        else
            ymax=0;
            for fr=flist
                if isempty(p.(['counts',num2str(1)]){fr,2})
                    if length(flist)==1
                        try close(epf); catch; end
                        hs.UserMess.String='No sequence data for this frame loaded';customdrawnow
                        return
                    else
                        %                         keepfr(fr)=false;
                        hs.UserMess.String='Sequence data for at least one frame is missing';customdrawnow
                        continue
                    end
                end
                GR=p.GR(p.GR(:,2)==fr, 3:end);
                if length(flist)~=1
                    hi=plot(GR', 'Color',col(fr,:));
                    h(fr) = hi(1);
                    clear hi
                    Legend{fr}=strcat('Frame ', num2str(fr));
                else
                    plot(GR');
                end
                ymax=max(ymax, max(max(GR)));
            end
            
            
            if length(flist)~=1
                %                 Legend=Legend(keepfr);
                %                 h=h(keepfr);
                legend(h,Legend, 'Location','SouthEast');
            end
            
            xlabel('time interval');
            ylabel('Growth rate [\mum/h]');
            title('Growth rate');
            xlim([0.8 size(GR,2)+0.2]);
            ylim([0 ymax*1.05]);
            xticks(1:length(p.multiEPdirs)-1);
            %             xticklabels(1:length(p.multiEPdirs));
        end
        
        
    end %GR distribution plot

%% functions of general use
    function val=CheckVariableOnFrames(variable,varname,onframes)
        val=~isempty(isnan(variable(onframes))); %0 if none of the frames has a nan for the variable of interest -->OK
        if val % some frames have a nan for the variable of interest
            val=sum(isnan(variable(onframes)));%number of problemmatic frames
            which=find(isnan(variable(onframes)))';%problematic frames
            if val==length(variable(onframes))
                waitfor(errordlg(['The ', varname,'is missing on all frames. Please specify it before proceeding.']));
            elseif val==1
                waitfor(errordlg(['The ', varname, 'is missing on frame ',num2str(onframes(which)),...
                    '. Please specify it before proceeding.']));
            elseif val>1 && val<10
                waitfor(errordlg(['The ', varname, 'is missing on the frames: ',num2str(onframes(which(1:end-1))),...
                    ' and ', num2str(onframes(which(end))),'. Please specify it on these frames before proceeding.']));
            elseif val>10
                waitfor(errordlg(['The ', varname, 'is missing on many frames. Please specify it before proceeding.']));
            end
        end
    end  %check if given variable is defined for given frame
    function timestr = sec2timestr(sec)
        % Convert a time measurement from seconds into a human readable string.
        % Convert seconds to other units
        w = floor(sec/604800); % Weeks
        sec = sec - w*604800;
        d = floor(sec/86400); % Days
        sec = sec - d*86400;
        h = floor(sec/3600); % Hours
        sec = sec - h*3600;
        m = floor(sec/60); % Minutes
        sec = sec - m*60;
        s = floor(sec); % Seconds
        
        % Create time string
        if w > 0
            if w > 9
                timestr = sprintf('%d week', w);
            else
                timestr = sprintf('%d week, %d day', w, d);
            end
        elseif d > 0
            if d > 9
                timestr = sprintf('%d day', d);
            else
                timestr = sprintf('%d day, %d hr', d, h);
            end
        elseif h > 0
            if h > 9
                timestr = sprintf('%d hr', h);
            else
                timestr = sprintf('%d hr, %d min', h, m);
            end
        elseif m > 0
            if m > 9
                timestr = sprintf('%d min', m);
            else
                timestr = sprintf('%d min, %d sec', m, s);
            end
        else
            timestr = sprintf('%d sec', s);
        end
    end %get time from seconds
    function frameList=UserChoiceFrames(action)
        if length(p.l)>1
            prompt = {['Which frame do you want to ',action,'? For all frames, insert 0.',...
                'To specify some frames, insert these separated by space or in the following syntax: start:end (going over frame Nr. "start" until Nr. "end"']};
            dlg_title = 'Which frame?'; num_lines = 1;
            defaultans = {num2str(p.i)};
            
            done=0;
            while ~done
                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
                if isempty(answer)
                    frameList =[];
                else %user cancelled
                    frameList=str2num(answer{1,1}); %#ok<ST2NM>
                end
                done=checkFrList(frameList); frameList=p.frlist;
                if ~done
                    waitfor(errordlg('The frame input was incorrect. Please try again.'))
                end
            end
        else
            frameList=1;
        end
        
    end %user choice frame
    function Zone=ZoneDef(center,whichCol,img,fr)
        %Defining a zone to extract images
        Zone=round(p.colonyCenRad{fr,2}(whichCol)*p.radCropAreaScaleFactor); %the analyzed zone is Zonesize fold bigger than the last radii
        %checks if the small image is possible to extract or if the borders are
        %outside image range. If yes, reduce Zone to rad of counts file
        
        if center(1)-Zone<1 || center(1)+Zone>=size(img,1) || center(2)-Zone<1 || center(2)+Zone>=size(img,2)
            Zone=floor(p.colonyCenRad{fr,2}(whichCol));
            shrinked = 0;
            while ~shrinked
                if center(1)-Zone<1
                    Zone = min([Zone, center(1)-1]);
                end
                if center(2)-Zone<1
                    Zone = min([Zone, center(2)-1]);
                end
                if center(1)+Zone>=size(img,1)
                    Zone = min([Zone, size(img,1)-center(1)-1]);
                end
                if center(2)+Zone>=size(img,2)
                    Zone = min([Zone, size(img,2)-center(2)-1]);
                end
                if center(1)-Zone<1 || center(1)+Zone>=size(img,1) || center(2)-Zone<1 || center(2)+Zone>=size(img,2)
                    shrinked = 0;
                else
                    shrinked = 1;
                end
            end
        end
        
    end %define zone size
    function poly=CreatePolyCircle(C,R)
        %this function creates a polygon from a circle
        N=360; %number of vertices around circle
        xc(1:N)=R*cos(2*pi*(1:N)/N)+C(1); %equation of x
        yc(1:N)=R*sin(2*pi*(1:N)/N)+C(2); %y
        xc(N+1)=xc(1); yc(N+1)=yc(1); %close the circle
        poly=[xc;yc]'; %polygonal coordinates of the external boundary (the plate)
        
    end %create circle from 3 points
    function Dt=calculateDT(imgpath1, imgpath2)
        a=imfinfo(imgpath1);
        bq=imfinfo(imgpath2);
        diff=datetime(bq.FileModDate)-datetime(a.FileModDate);
        
        Dt=minutes(diff);
    end %get time interval from image metaata
    function in=click_Colony()
        if ~Fvar.clickcall
            %get position
            if strcmp(p.imgFormat, 'rgb') && ~p.showGrayscale && ~Fvar.imgenhanced && ~Fvar.imgenhanced2
                [X1, Y1] = ginput(1);
            else
                [X1, Y1] =  ginputCustom(1);
            end
            if X1<1 || Y1<1 || X1>size(Fvar.rgb,2) || Y1>size(Fvar.rgb,1)
                hs.UserMess.String=''; customdrawnow
                return
            end
        else
            seedPt = get(hs.fig, 'CurrentPoint'); % Get init mouse position
            X1=seedPt(1,1);
            Y1=seedPt(1,2);
        end
        %calculate distance to click
        dist=zeros(1,length(p.centers(:,1)));
        for i=1:length(p.centers(:,1))
            dist(i) = norm([p.centers(i,1) - X1 p.centers(i,2) - Y1]);
        end
        dist=dist';
        zoom=((hs.fig.YLim(2)-hs.fig.YLim(1)) / size(Fvar.rgb,2)) +...
            ((hs.fig.XLim(2)-hs.fig.XLim(1))  / size(Fvar.rgb,1));
        zoom=zoom/2;
        ctfdist=30*zoom;
        
        in=(p.radii>dist | dist<ctfdist); %clicked inside
    end %get colony clicked on
    function [pathname] = uigetdir2(start_path, dialog_title)
        % Pick multiple directories and/or files
        
        import javax.swing.JFileChooser;
        
        %if nargin == 0 || start_path == '' || start_path == 0 % Allow a null argument.
        %   start_path = pwd;
        %end
        
        jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);
        
        jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        if nargin > 1
            jchooser.setDialogTitle(dialog_title);
        end
        
        jchooser.setMultiSelectionEnabled(true);
        
        status = jchooser.showOpenDialog([]);
        
        if status == JFileChooser.APPROVE_OPTION
            jFile = jchooser.getSelectedFiles();
            pathname{size(jFile, 1)}=[];
            for i=1:size(jFile, 1)
                pathname{i} = char(jFile(i).getAbsolutePath);
            end
            
        elseif status == JFileChooser.CANCEL_OPTION
            pathname = [];
        else
            error('Error occured while picking file.');
        end
    end %pick multiple dirs
    function RadUmCalc(~,~)
        if p.progress.TLrun~=1 || strcmp(p.operatingMode,'single')
            return
        end
        if isempty(p.umConversion) || sum(isnan(p.umConversion))>0
            hs.UserMess.String='The spatial calibration factor is missing!';customdrawnow
            return
        end
        
        for chi = 1:p.nChannel
            if chi == 1
                fname1 = 'RadMean';
                fname2 = 'RadMeanUm';
            else
                fname1 = sprintf('RadMeanCh%d', chi); % Construct field name dynamically
                fname2 = sprintf('RadMeanUmCh%d', chi); % Construct field name dynamically
            end
            try
                p.(fname2)=p.(fname1)*p.umConversion(1);
            catch
            end
        end
        
        
    end %calculate um radius
    function ProgressInitialize(~,~)
        %initialize all the progress variables.
        p.progress.open=0; %folder opened?
        p.progress.found=0; %colonies detected?
        p.progress.AA=0; %AA defined?
        p.progress.umRef=0; %ref to calculate um from pxl?
        p.progress.compLoaded=0; %is a comparison loaded?
        p.progress.calibrationLoaded=0; %is a calibration loaded?
        p.progress.calibrated=0; %calibration applied?
        p.progress.corrected=0; %correction applied?
        p.progress.RlinDone=0; %is an Rlin specified?
        p.progress.TlagDone=0; %is a lagtime here?
        
        %the following only makes sense for TL
        p.progress.TLrun=0;
        
        % and this only for single sets
        p.progress.GRadded=0;
        
    end%initialze the progress variables
    function ProgressUpdate(~,~)
        if ~isempty(p.l); p.progress.open=1; end
        check=0;
        if p.progress.found==0 && ~isempty(p.colonyCenRad)
            for i3=1:length(p.l)
                baa=(p.colonyCenRad{i3,:});
                if ~isempty(baa)
                    check=1; break
                end
            end
        end
        if p.progress.found==0 && check
            p.progress.found=1;
        end
        
        if ~isnan(p.umConversion); p.progress.umRef=1; end
        if isempty(p.compFileName); p.progress.compLoaded=0; else; p.progress.compLoaded=1; end
        if ~isempty(p.Rlin); p.progress.RlinDone=1; end
        
        if ~isempty(p.RadMean); p.progress.TLrun=1; else; p.progress.TLrun=0; end
        
        UpdateButtonState
        
    end %update the progress variables
    function UpdateButtonState(~,~)
        %different part of the following code are executed based on the
        %section input.
        % 1 is for things available from the first opening of a set
        % 2 for things if there is at least 1 colony detected
        % 3 enables ploting after a TL analysis is done
        % 4
        if p.progress.open
            set(hs.Classify, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            set(hs.SaveAsButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            set(hs.SaveAsCSV2, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            
            if length(p.l)>1
                set(hs.SetFrameSlider, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
                set(hs.SetFrameSlider, 'min', 1, 'max', length(p.l), 'Value', p.i);
                set(hs.SetFrameSlider, 'SliderStep', [1/(length(p.l)-1), 1/(length(p.l)-1)*10]);
            else
                set(hs.SetFrameSlider, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            end
            set(hs.Options, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
            set(hs.aoiplate, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.aoipolygon, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.aoiwhole, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.FindColonies, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.AddCol, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.UndoButton, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.umRef, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.EnhanceImage, 'Enable', 'on'); set(hs.EnhanceImage2, 'Enable', 'on');
            set(hs.overlay, 'Enable', 'on');
            set(hs.modColonyClick, 'Enable', 'on');
            set(hs.AddNonGrowingButton, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            
            
            if strcmp(p.operatingMode, 'single')
                hs.TimeLapseTab.Parent=[];
            elseif strcmp(p.operatingMode, 'TL')
                hs.SITab.Parent=[];
                set(hs.IntensityFull, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            end
        end
        
        
        if p.progress.found
            set(hs.DefineRange, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.HLButton, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.HLDelButton, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.AddList, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.ShowList, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.RmvCol, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.CleanZone, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.CleanOutZone, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.LocalCorrection1, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            if strcmp(p.operatingMode,'TL')
                set(hs.FindTimeCol, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.AutoCenter, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.ManualCenter, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.closecenterbutton, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.registration,'Enable', 'on', 'Value', p.REGstatus);
            else
                set(hs.SizeDist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.multiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.TappEst,'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.LoadRef2,'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.IntensityRadius,'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                
                if isfield(p, 'counts1')
                    set(hs.showmultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    set(hs.plot, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    set(hs.GRmultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    if ~isempty(p.GR)
                        set(hs.GRdist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    end
                else
                    if p.overlayIMGstatus
                        set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                    else
                        set(hs.registermultiEP, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                    end
                end
            end
        else
            set(hs.LocalCorrection1, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.HLDelButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.AddList, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.ShowList, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.HLButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.DefineRange, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.SizeDist, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.RmvCol, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.CleanZone, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.CleanOutZone, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            if strcmp(p.operatingMode,'TL')
                set(hs.FindTimeCol, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.AutoCenter, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.ManualCenter, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.closecenterbutton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
                set(hs.registration,'Enable', 'off');
            else
            end
        end
        
        if ~strcmp(p.operatingMode, 'TL') & ~isempty(p.estTapp) %#ok<AND2>
            set(hs.TappDist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
        end
        
        if p.progress.TLrun
            set(hs.plot, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.CorrectThresh, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.findwrongkymo, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.LoadRef1, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.TappCalc, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.SizeDist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            set(hs.IntensityColony, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            if ~isempty(p.Tapp)
                set(hs.TappDist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
                set(hs.GRdist, 'BackgroundColor', hs.btnCol.green1, 'Enable', 'on');
            end
        end
        
        
        
        if length(p.l)==1
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'off');
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'off');
        elseif p.i==1
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif p.i==length(p.l)
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif strcmp(hs.LeftButton.Enable,'inactive')
            set(hs.LeftButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        elseif strcmp(hs.RightButton.Enable,'inactive')
            set(hs.RightButton, 'BackgroundColor', hs.btnCol.green2, 'Enable', 'on');
        end
        
        
        if Fvar.imTBmiss
            set(hs.aoiplate, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.aoipolygon, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.aoiwhole, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.FindColonies, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.AddCol, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.HLButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.AddList, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.ShowList, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.UndoButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.umRef, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.AddNonGrowingButton, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.overlay, 'Enable', 'on');
            set(hs.RmvCol, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.CleanZone, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.CleanOutZone, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.FindTimeCol, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
            set(hs.CorrectThresh, 'BackgroundColor', hs.btnCol.gray, 'Enable', 'inactive');
        end
    end %update the color of the buttons according to the progress variables
    function OK=checkFrList(FrList)
        %this function checks that frames chosen by user are within range
        OK=0;
        if FrList==0
            p.frlist=1:length(p.l);
            OK=1;
        elseif sum(FrList<0) || sum(FrList>length(p.l)) || sum(isnan(FrList))
            p.frlist=[];
            waitfor(errordlg('The frame input was incorrect.'))
        else
            p.frlist=FrList;
            OK=1;
        end
    end %check if frame list input was correct
    function OK=setpColList(colList1)
        OK=0;
        
        if strcmp(p.operatingMode,'TL')
            %error if not in range of colonies
            if sum(colList1>length(p.colonyCenRad{p.focalframe}))> 1 || (sum(colList1<0)>=1 && length(colList1)>1)
                errordlg('A colony Nr is out of range'); return
            end
        end
        %set the list of colonies that should be analyzed
        if colList1==0
            if strcmp(p.operatingMode,'TL')
                p.colList=1:length(p.colonyCenRad{p.focalframe,2}); %over all colonies
            else
                p.colList=1:length(p.colonyCenRad{p.i,2}); %over all colonies
            end
        elseif colList1<0 %asking for user list
            if -colList1 <= numel(fieldnames(p.UserLists.l))% the user asks for a list that exists
                p.colList=find(readList(-colList1,p.i))';
                if isempty(p.colList)
                    errordlg('The list is non existant or empty'); return
                end
            end
        else %this is a list of valid colonies
            p.colList=colList1;
        end
        p.colList=sort(unique(p.colList)); %sorting the list and removing duplicates
        OK=1;
    end %set list of colonies
    function [OK,Colonies]=setpColList2(colList1,Frames)
        % this function is used to generate a list similar to setpColList2,
        % but has one specific output on EP mode
        
        if strcmp(p.operatingMode,'TL')
            OK=setpColList(colList1);
            if ~OK % in case the list doesn't work, exporting all colonies
                OK=setpColList(0);
            end
        else % in EP mode, Colonies contains the biggest posible ensemble assuming
            biggest=0;
            for i=Frames %over all frames
                if numel(p.colonyCenRad{i,2})>biggest
                    biggest=numel(p.colonyCenRad{i,2});
                    biggesti=i;
                end
                %[biggest,ind]=max(biggest,numel(p.colonyCenRad{i,2}));
            end
            oldpi=p.i;
            p.i=biggesti; %setting p.i to use setpColList
            OK=setpColList(colList1);
            p.i=oldpi;
            if ~OK % in case the list doesn't work, exporting all colonies
                OK=setpColList(0);
            end
        end
        Colonies=p.colList;
        
    end %set list of colonies
    function GetColAndTime(prompt, defCol, defStartF)
        %let the user specify which colonies and which frames he wants to
        %analyze as a subset
        correct=0;%turns to 1 if every input was correct
        p.abortParent=1;
        p.UserColNb=defCol;
        startT=defStartF; stepT=1; endT=length(p.l);
        while ~correct
            dlg_title = 'Timelapse for subset'; num_lines = 1;
            defaultans = {num2str(p.UserColNb),num2str(startT),num2str(stepT),num2str(endT)};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer); return; end %user cancelled
            colList1=round(str2num(answer{1})); %#ok<ST2NM> %user input
            OK=setpColList(colList1); %this function sets variable p.ColList
            if OK==0; return; end %there was an error in the list
            
            if length(answer)==4
                %get the values for the frames
                startT=str2double(answer{2}); stepT=str2double(answer{3}); endT=str2double(answer{4});
                if sum(startT<1) || sum(isnan(startT)) || isempty(startT) || length(startT)>1 || mod(startT,1)
                    waitfor(errordlg('The input for the starting frame was in a wrong format. Try again.'));startT=1; continue
                end
                if sum(stepT<1) || sum(isnan(stepT)) || isempty(stepT) || length(stepT)>1 || mod(stepT,1) || (sum(stepT>length(p.l)/10) && length(p.l)>10)
                    waitfor(errordlg('The input for the stepsize was in a wrong format. Also, do not use stepsize bigger than 1/10th of the length of the timelapse. Try again.'));
                    stepT=1; continue
                end
                if sum(endT>length(p.l)) || sum(endT<1) || sum(endT<startT) || sum(isnan(endT)) || isempty(endT) || length(endT)>1 || mod(endT,1)
                    waitfor(errordlg('The input for the ending frame was in a wrong format. Try again.')); endT=length(p.l); continue
                end
                
                timeList2=endT:-stepT:startT;
                timeList2=fliplr(timeList2);
                %then, check if the difference between the frames is always 1, we
                %want the user not to skip a frame
                %following are some tests to check if the input was correct
                if length(timeList2)>length(p.l) || timeList2(1)<1 || timeList2(end)>length(p.l) || isempty(timeList2)
                    waitfor(errordlg('The input for the frames was in a wrong format. Try again.'));
                    startT=1; stepT=1; endT= length(p.l); continue;
                end
                %finally set correct to 1
                correct=1;
                
                
            elseif length(answer)==2
                startT=str2double(answer{2});
                if sum(startT<1) || sum(isnan(startT)) || isempty(startT) || length(startT)>1 || mod(startT,1)
                    waitfor(errordlg('The input for the frame was in a wrong format. Try again.'));startT=1; continue
                else
                    correct=1;
                end
                timeList2=startT;
            end
        end
        p.timeList=fliplr(timeList2);%all frames list
        p.abortParent=0;
    end %set list of colonies and time
    function customdrawnow(~,~)
        drawnow
        try
            if ~verLessThan('Matlab','9.12')
                if isprop(hs.fig, 'Toolbar')
                    hs.fig.Toolbar.Visible = 'off';
                end
                if isprop(hs.Progress1, 'Toolbar')
                    hs.Progress1.Toolbar.Visible = 'off';
                end
                if isprop(hs.Progress2, 'Toolbar')
                    hs.Progress2.Toolbar.Visible = 'off';
                end
            end
        catch
        end
    end

%% functions from external sources
    function imgzoompan(hfig, varargin)
        % imgzoompan provides instant mouse zoom and pan
        %
        % function imgzoompan(hfig, varargin)
        %
        %% Purpose
        % This function provides instant mouse zoom (mouse wheel) and pan (mouse drag) capabilities
        % to figures, designed for displaying 2D images that require lots of drag & zoom. For more
        % details see README file.
        %
        %
        %% Inputs (optional param/value pairs)
        % The following relate to zoom config
        % * 'Magnify' General magnitication factor. 1.0 or greater (default: 1.1). A value of 2.0
        %             solves the zoom & pan deformations caused by MATLAB's embedded image resize method.
        % * 'XMagnify'        Magnification factor of X axis (default: 1.0).
        % * 'YMagnify'        Magnification factor of Y axis (default: 1.0).
        % * 'ChangeMagnify'.  Relative increase of the magnification factor. 1.0 or greater (default: 1.1).
        % * 'IncreaseChange'  Relative increase in the ChangeMagnify factor. 1.0 or greater (default: 1.1).
        % * 'MinValue' Sets the minimum value for Magnify, ChangeMagnify and IncreaseChange (default: 1.1).
        % * 'MaxZoomScrollCount' Maximum number of scroll zoom-in steps; might need adjustements depending
        %                        on your image dimensions & Magnify value (default: 30).
        % The following relate to pan configuration:
        % 'ImgWidth' Original image pixel width. A value of 0 disables the functionality that prevents the
        %            user from dragging and zooming outside of the image (default: 0).
        % 'ImgHeight' Original image pixel height (default: 0).
        %
        %
        %% Outputs
        %  none
        %
        %
        %% ACKNOWLEDGEMENTS:
        %
        % *) Hugo Eyherabide (Hugo.Eyherabide@cs.helsinki.fi) as this project uses his code
        %    (FileExchange: zoom_wheel) as reference for zooming functionality.
        % *) E. Meade Spratley for his mouse panning example (FileExchange: MousePanningExample).
        % *) Alex Burden for his technical and emotional support.
        %
        % Send code updates, bug reports and comments to: Dany Cabrera (dcabrera@uvic.ca)
        % Please visit https://github.com/danyalejandro/imgzoompan (or check the README.md text file) for
        % full instructions and examples on how to use this plugin.
        %
        %% Copyright (c) 2018, Dany Alejandro Cabrera Vargas, University of Victoria, Canada,
        % published under BSD license (http://www.opensource.org/licenses/bsd-license.php).
        
        
        %  Run in current figure unless otherwise requested
        if isempty(findobj('type','figure'))
            fprintf('%s -- finds no open figure windows. Quitting.\n', mfilename)
            return
        end
        
        if nargin==0 || isempty(hfig) || ~isa(hfig,'matlab.ui.Figure')
            hfig = gcf;
        end
        
        % Parse configuration options
        pan1 = inputParser;
        % Zoom configuration options
        pan1.addOptional('Magnify', 1.1, @isnumeric);
        pan1.addOptional('XMagnify', 1.0, @isnumeric);
        pan1.addOptional('YMagnify', 1.0, @isnumeric);
        pan1.addOptional('ChangeMagnify', 1.1, @isnumeric);
        pan1.addOptional('IncreaseChange', 1.1, @isnumeric);
        pan1.addOptional('MinValue', 1.1, @isnumeric);
        pan1.addOptional('MaxZoomScrollCount', 30, @isnumeric);
        
        % Pan configuration options
        pan1.addOptional('ImgWidth', 0, @isnumeric);
        pan1.addOptional('ImgHeight', 0, @isnumeric);
        
        % Mouse options and callbacks
        pan1.addOptional('PanMouseButton', 2, @isnumeric);
        pan1.addOptional('ResetMouseButton', 3, @isnumeric);
        pan1.addOptional('ButtonDownFcn',  @(~,~) 0);
        pan1.addOptional('ButtonUpFcn', @(~,~) 0) ;
        
        % Parse & Sanitize options
        parse(pan1, varargin{:});
        opt = pan1.Results;
        
        if opt.Magnify<opt.MinValue
            opt.Magnify=opt.MinValue;
        end
        if opt.ChangeMagnify<opt.MinValue
            opt.ChangeMagnify=opt.MinValue;
        end
        if opt.IncreaseChange<opt.MinValue
            opt.IncreaseChange=opt.MinValue;
        end
        
        
        
        % Set up callback functions
        set(hfig, 'WindowScrollWheelFcn', @zoom_fcn);
        set(hfig, 'WindowButtonDownFcn', @down_fcn);
        set(hfig, 'WindowButtonUpFcn', @up_fcn);
        
        zoomScrollCount = 0;
        %     orig.h=[];
        %     orig.XLim=[];
        %     orig.YLim=[];
        
        
        
        % -------------------------------
        % Nested callback functions, etc, follow
        
        
        % Applies zoom
        function zoom_fcn(~, cbdata)
            scrollChange = cbdata.VerticalScrollCount; % -1: zoomIn, 1: zoomOut
            
            if ((zoomScrollCount - scrollChange) <= opt.MaxZoomScrollCount)
                axish = gca;
                
                %             if (isempty(orig.h) || axish ~= orig.h)
                %                 orig.h = axish;
                %                 orig.XLim = axish.XLim;
                %                 orig.YLim = axish.YLim;
                %             end
                
                % calculate the new XLim and YLim
                cpaxes = mean(axish.CurrentPoint, 'omitnan');
                newXLim = (axish.XLim - cpaxes(1)) * (opt.Magnify * opt.XMagnify)^scrollChange + cpaxes(1);
                newYLim = (axish.YLim - cpaxes(2)) * (opt.Magnify * opt.YMagnify)^scrollChange + cpaxes(2);
                
                newXLim = floor(newXLim);
                newYLim = floor(newYLim);
                % only check for image border location if user provided ImgWidth
                if (opt.ImgWidth > 0)
                    if (newXLim(1) >= 0 && newXLim(2) <= opt.ImgWidth && newYLim(1) >= 0 && newYLim(2) <= opt.ImgHeight)
                        axish.XLim = newXLim;
                        axish.YLim = newYLim;
                        zoomScrollCount = zoomScrollCount - scrollChange;
                    else
                        axish.XLim = orig.XLim;
                        axish.YLim = orig.YLim;
                        zoomScrollCount = 0;
                    end
                else
                    axish.XLim = newXLim;
                    axish.YLim = newYLim;
                    zoomScrollCount = zoomScrollCount - scrollChange;
                end
                %fprintf('XLim: [%.3f, %.3f], YLim: [%.3f, %.3f]\n', axish.XLim(1), axish.XLim(2), axish.YLim(1), axish.YLim(2));
            end
        end %zoom_fcn
        
        %% Mouse Button Callbacks
        function down_fcn(hObj, evt)
            opt.ButtonDownFcn(hObj, evt); % First, run callback from options
            
            clickType = evt.Source.SelectionType;
            
            % Panning action
            panBt = opt.PanMouseButton;
            if (panBt > 0)
                if (panBt == 1 && strcmp(clickType, 'normal')) || ...
                        (panBt == 2 && strcmp(clickType, 'alt')) || ...
                        (panBt == 3 && strcmp(clickType, 'extend'))
                    
                    guiArea = hittest(hObj);
                    parentAxes = ancestor(guiArea,'axes');
                    
                    % if the mouse is over the desired axis, trigger the pan fcn
                    if ~isempty(parentAxes)
                        startPan(parentAxes)
                    else
                        setptr(evt.Source,'forbidden')
                    end
                end
            end
            
            
            if Fvar.clickdisable==0
                if (strcmp(clickType, 'normal'))
                    Fvar.clickcall=1;
                    Addcol_callback;
                    Fvar.clickcall=0;
                end
                
                if strcmp(clickType, 'extend')
                    Fvar.clickcall=1;
                    RemoveCol2_Callback;
                    Fvar.clickcall=0;
                end
            end
        end %down_fcn
        
        % Main mouseButtonUp callback
        function up_fcn(hObj, evt)
            opt.ButtonUpFcn(hObj, evt); % First, run callback from options
            
            % Reset action
            clickType = evt.Source.SelectionType;
            resBt = opt.ResetMouseButton;
            if (resBt > 0 && ~isempty(orig.XLim))
                if (resBt == 1 && strcmp(clickType, 'normal')) || ...
                        (resBt == 2 && strcmp(clickType, 'alt')) || ...
                        (resBt == 3 && strcmp(clickType, 'extend'))
                    
                    guiArea = hittest(hObj);
                    parentAxes = ancestor(guiArea,'axes');
                    parentAxes.XLim=orig.XLim;
                    parentAxes.YLim=orig.YLim;
                end
            end
            
            
            
            stopPan
        end %up_fcn
        
        
        %% AXIS PANNING FUNCTIONS
        
        % Call this Fcn in your 'WindowButtonDownFcn'
        % Take in desired Axis to pan
        % Get seed points & assign the Panning Fcn to top level Fig
        function startPan(hAx)
            hFig = ancestor(hAx, 'Figure', 'toplevel');   % Parent Fig
            
            seedPt = get(hAx, 'CurrentPoint'); % Get init mouse position
            seedPt = seedPt(1, :); % Keep only 1st point
            
            % Temporarily stop 'auto resizing'
            hAx.XLimMode = 'manual';
            hAx.YLimMode = 'manual';
            
            set(hFig,'WindowButtonMotionFcn',{@panningFcn,hAx,seedPt});
            setptr(hFig, 'hand'); % Assign 'Panning' cursor
        end %startPan
        
        
        % Call this Fcn in your 'WindowButtonUpFcn'
        function stopPan
            set(gcbf,'WindowButtonMotionFcn',[]);
            setptr(gcbf,'arrow');
        end %stopPan
        
        
        % Controls the real-time panning on the desired axis
        function panningFcn(~,~,hAx,seedPt)
            % Get current mouse position
            currPt = get(hAx,'CurrentPoint');
            
            % Current Limits [absolute vals]
            XLim = hAx.XLim;
            YLim = hAx.YLim;
            
            % Original (seed) and Current mouse positions [relative (%) to axes]
            x_seed = (seedPt(1)-XLim(1))/(XLim(2)-XLim(1));
            y_seed = (seedPt(2)-YLim(1))/(YLim(2)-YLim(1));
            
            x_curr = (currPt(1,1)-XLim(1))/(XLim(2)-XLim(1));
            y_curr = (currPt(1,2)-YLim(1))/(YLim(2)-YLim(1));
            
            % Change in mouse position [delta relative (%) to axes]
            deltaX = x_curr-x_seed;
            deltaY = y_curr-y_seed;
            
            % Calculate new axis limits based on mouse position change
            newXLims(1) = -deltaX*diff(XLim)+XLim(1);
            newXLims(2) = newXLims(1)+diff(XLim);
            
            newYLims(1) = -deltaY*diff(YLim)+YLim(1);
            newYLims(2) = newYLims(1)+diff(YLim);
            
            % MATLAB lack of anti-aliasing deforms the image if XLims & YLims are not integers
            newXLims = round(newXLims);
            newYLims = round(newYLims);
            
            % Update Axes limits
            if (newXLims(1) > 0.0 && newXLims(2) < opt.ImgWidth)
                set(hAx,'Xlim',newXLims);
            end
            if (newYLims(1) > 0.0 && newYLims(2) < opt.ImgHeight)
                set(hAx,'Ylim',newYLims);
            end
        end %panningFcn
        
    end %imgzoompan
    function [R,xcyc] = fit_circle_through_3_points(ABC)
        % FIT_CIRCLE_THROUGH_3_POINTS
        % Mathematical background is provided in http://www.regentsprep.org/regents/math/geometry/gcg6/RCir.htm
        %
        % Input:
        %
        %   ABC is a [3 x 2n] array. Each two columns represent a set of three points which lie on
        %       a circle. Example: [-1 2;2 5;1 1] represents the set of points (-1,2), (2,5) and (1,1) in Cartesian
        %       (x,y) coordinates.
        %
        % Outputs:
        %
        %   R     is a [1 x n] array of circle radii corresponding to each set of three points.
        %   xcyc  is an [2 x n] array of of the centers of the circles, where each column is [xc_i;yc_i] where i
        %         corresponds to the {A,B,C} set of points in the block [3 x 2i-1:2i] of ABC
        %
        % Author: Danylo Malyuta.
        % Version: v1.0 (June 2016)
        % ----------------------------------------------------------------------------------------------------------
        % Each set of points {A,B,C} lies on a circle. Question: what is the circles radius and center?
        % A: point with coordinates (x1,y1)
        % B: point with coordinates (x2,y2)
        % C: point with coordinates (x3,y3)
        % ============= Find the slopes of the chord A<-->B (mr) and of the chord B<-->C (mt)
        %   mt = (y3-y2)/(x3-x2)
        %   mr = (y2-y1)/(x2-x1)
        % /// Begin by generalizing xi and yi to arrays of individual xi and yi for each {A,B,C} set of points provided in ABC array
        x1 = ABC(1,1:2:end);
        x2 = ABC(2,1:2:end);
        x3 = ABC(3,1:2:end);
        y1 = ABC(1,2:2:end);
        y2 = ABC(2,2:2:end);
        y3 = ABC(3,2:2:end);
        % /// Now carry out operations as usual, using array operations
        mr = (y2-y1)./(x2-x1);
        mt = (y3-y2)./(x3-x2);
        % A couple of failure modes exist:
        %   (1) First chord is vertical       ==> mr==Inf
        %   (2) Second chord is vertical      ==> mt==Inf
        %   (3) Points are collinear          ==> mt==mr (NB: NaN==NaN here)
        %   (4) Two or more points coincident ==> mr==NaN || mt==NaN
        % Resolve these failure modes case-by-case.
        idf1 = isinf(mr); % Where failure mode (1) occurs
        idf2 = isinf(mt); % Where failure mode (2) occurs
        idf34 = isequaln(mr,mt) | isnan(mr) | isnan(mt); % Where failure modes (3) and (4) occur
        % ============= Compute xc, the circle center x-coordinate
        xcyc = (mr.*mt.*(y3-y1)+mr.*(x2+x3)-mt.*(x1+x2))./(2*(mr-mt));
        xcyc(idf1) = (mt(idf1).*(y3(idf1)-y1(idf1))+(x2(idf1)+x3(idf1)))/2; % Failure mode (1) ==> use limit case of mr==Inf
        xcyc(idf2) = ((x1(idf2)+x2(idf2))-mr(idf2).*(y3(idf2)-y1(idf2)))/2; % Failure mode (2) ==> use limit case of mt==Inf
        xcyc(idf34) = NaN; % Failure mode (3) or (4) ==> cannot determine center point, return NaN
        % ============= Compute yc, the circle center y-coordinate
        xcyc(2,:) = -1./mr.*(xcyc-(x1+x2)/2)+(y1+y2)/2;
        idmr0 = mr==0;
        xcyc(2,idmr0) = -1./mt(idmr0).*(xcyc(idmr0)-(x2(idmr0)+x3(idmr0))/2)+(y2(idmr0)+y3(idmr0))/2;
        xcyc(2,idf34) = NaN; % Failure mode (3) or (4) ==> cannot determine center point, return NaN
        % ============= Compute the circle radius
        R = sqrt((xcyc(1,:)-x1).^2+(xcyc(2,:)-y1).^2);
        R(idf34) = Inf; % Failure mode (3) or (4) ==> assume circle radius infinite for this case
    end% for AOI delimit
    function [V,C,XY]=VoronoiLimit(varargin)
        % --------------------------------------------------------------
        % [V,C,XY]=VoronoiLimit(x,y,additional_variables)
        % Provides the Voronoi decomposition of a set of (x,y) data, but with all
        % vertices limited to the boundary created by the data itself.
        % V contains all vertices and C contains all vertices for each individual
        % point. That is: V(C{ij},:) will give you the vertices of the ij'th data
        % point. The order of polygon vertices are given in a counter-clockwise
        % manner. XY contains updated xy coordinates as limited by any input boundaries.
        %
        % Addition variables:
        % 'bs_ext':  Describe an arbitrary external boundary by giving an xy matrix of size (n,1) where n are number of vertices.
        % 'bs_int':  Describe any number of arbitrary internal boundaries by giving a cell structure of M xy matrices of size
        %            (Ni,1) where M are number of internal boundaries and Ni are number of vertices in the respective boundaries.
        %            When defining a single boundary the algorithm automatically converts the given matrix into a cell structure.
        %            (See examples below).
        % 'figure':  output figure ('on'/'off'. Default='on').
        %
        % EXAMPLES
        % Example 0: Run with no input to see graphical example.
        %
        % Example 1: External and one internal boundary
        %            bs_int=[.2 .8 .8 .2;.6 .6 .2 .2]';
        %            bs_ext=[-.8 .5 1.80 -.8;-.05 1.7 -.05 -.05]';
        %            [X,Y] = meshgrid(-.5:.1:1.5, 0.1:.1:1.4);
        %            X=X(:);Y=Y(:);
        %            [V,C,XY]=VoronoiLimit(X,Y,'bs_ext',bs_ext,'bs_int',bs_int);
        %
        % Example 2: No external boundary and two internal boundaries
        %            bs_int=cell(2,1);
        %            bs_int{1}=[.2 .8 .8 .2;.6 .6 .2 .2]';
        %            bs_int{2}=[.2 .5 .7 .2;1 1 .7 .7]';
        %            [X,Y] = meshgrid(-.5:.1:1.5, 0.1:.1:1.4);
        %            X=X(:);Y=Y(:);
        %            [V,C,XY]=VoronoiLimit(X,Y,'bs_int',bs_int);
        %
        % Example 3: As above but without figure output
        %            [V,C,XY]=VoronoiLimit(X,Y,'bs_int',bs_int,'figure','off');
        %
        % Requires the Polybool function of the mapping toolbox to run!.
        % I recommend the tool 'export_fig' for exporting figures. It can be found here:
        % http://www.mathworks.com/matlabcentral/fileexchange/23629-export-fig
        %
        % Made by: Jakob Sievers (PhD, Arctic Geophysics)
        % Contact: Jakob.Sievers@gmail.com
        % --------------------------------------------------------------
        warning('off','map:polygon:noExternalContours');
        version=[3 0 2 1];
        
        %% SETUP
        
        % USERTYPE
        [~,hostname]=system('hostname');
        user=0;
        if strcmp(hostname(1:end-1),'DESKTOP-PC4MSAH') || strcmp(hostname(1:end-1),'Sievers')
            user=1;
        end
        
        
        % DETERMINE IF A MORE RECENT VERSION OF OOT IS AVAILABLE ON THE MATHWORKS FILEEXCHANGE
        try
            onlinedata = webread('http://se.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit');
            try_ver=1;
        catch %me
            try_ver=0;
        end
        if try_ver==1
            try % using hardcoded version (faster)
                ixVersion=strfind(onlinedata,'version ');
                onlinedata=onlinedata(ixVersion+8:ixVersion+80);
                ixsspan=strfind(onlinedata,'</span>');
                onlinedata=onlinedata(1:ixsspan(1)-1);
                ixsp=strfind(onlinedata,'(');
                onlinedata=onlinedata(1:ixsp-2);
                ixp=strfind(onlinedata,'.');
                version_online=sum([str2double(onlinedata(1:ixp(1)-1))*1e3 str2double(onlinedata(ixp(1)+1:ixp(2)-1))*1e2  str2double(onlinedata(ixp(2)+1:ixp(3)-1))*1e1 str2double(onlinedata(ixp(3)+1:end))], 'omitnan');
                version=sum([version(1)*1e3 version(2)*1e2 version(3)*1e1 version(4)], 'omitnan');
                if version_online>version
                    warndlg(['NOTE: A more recent version (ver. ',num2str(version_online(1,1)),'.',num2str(version_online(1,2)),'.',num2str(version_online(1,3)),'.',num2str(version_online(1,4)),') of VoronoiLimit is now available on the mathworks fileexchange. Currently running version ',num2str(version(1,1)),'.',num2str(version(1,2)),'.',num2str(version(1,3)),'.',num2str(version(1,4))])
                    pause(2)
                end
            catch %me
                if user==1
                    warndlg('CRASH #1: HARDCODED version of VoronoiLimit_ver script! Update hardcoded/online script!')
                    pause(2)
                end
                try %download/unzip most recent script to determine online version (updated in case Mathworks has changed its website and hardcoded version crashes)
                    outfilename = websave([pwd,filesep,'Current_version_VoronoiLimit_DONOTDELETE.m'],'https://www.dropbox.com/s/daqya2vv3hh9x9d/Current_version_VoronoiLimit_DONOTDELETE.m?dl=1');
                    Current_version_VoronoiLimit_DONOTDELETE(version);
                    delete(outfilename)
                catch %me2
                    if user==1
                        warndlg('CRASH #2: ONLINE version of VoronoiLimit_ver script! Update hardcoded/online script!')
                        pause(2)
                    end
                end
            end
        end
        
        
        %% ALGORITHM BEGINNING
        try
            if nargin==0
                val=600;
                x=rand(val,1);
                y=rand(val,1);
                XY=unique([x,y],'rows');
                x=XY(:,1);
                y=XY(:,2);
                
                %EXTERNAL BOUNDARIES
                ButtonName = questdlg('Choose external boundary example:','','Irregular pentagon', 'Triangle', 'Irregular pentagon');
                switch ButtonName
                    case 'Irregular pentagon'
                        bs_ext=[min(x)-std(x)/2 min(x)-std(x)/2 0.65 max(x)+std(x)/2 max(x)+std(x)/2 min(x)-std(x)/2;min(y)-std(y)/2 max(y)+std(y)/2 max(y)+std(y)/2 .65 min(y)-std(y)/2 min(y)-std(y)/2]';
                    case 'Triangle'
                        bs_ext=[-.8 .5 1.80 -.8;-.05 1.7 -.05 -.05]';
                end
                
                %INTERNAL OBJECTS
                bs_int=cell(3,1);
                rat=1.5;
                % rectangle
                bs_int{1}=[min(x)+(std(x)*rat) min(x)+(std(x)*rat) max(x)-std(x) max(x)-std(x) min(x)+(std(x)*rat);min(y)+std(y) max(y)-std(y) max(y)-std(y) min(y)+std(y) min(y)+std(y)]';
                t = linspace(0,2*pi)';
                % circle 1
                xc=.25;
                yc=.7;
                rad=.10;
                bs_int{2}=[(cos(t)*rad)+xc (sin(t)*rad)+yc];
                % circle 2
                xc=.4;
                yc=.3;
                rad=.16;
                bs_int{3}=[(cos(t)*rad)+xc (sin(t)*rad)+yc];
                fig='on';
            else
                x=varargin{1}(:);
                y=varargin{2}(:);
                XY=unique([x,y],'rows');
                x=XY(:,1);
                y=XY(:,2);
                for ii=3:2:nargin
                    if strcmp(varargin{ii},'bs_ext')
                        bs_ext=varargin{ii+1};
                    elseif strcmp(varargin{ii},'bs_int')
                        bs_int=varargin{ii+1};
                        if ~iscell(bs_int)
                            bs_int_cell=cell(1);
                            bs_int_cell{1}=bs_int;
                            bs_int=bs_int_cell;
                        end
                    elseif strcmp(varargin{ii},'figure')
                        fig=varargin{ii+1};
                    end
                end
                if exist('fig','var')==0
                    fig='on';
                end
            end
            
            
            x=x(:);
            y=y(:);
            rx=[min(x) max(x)];
            ry=[min(y) max(y)];
            
            bnd=[rx ry]; %data bounds
            crs=double([bnd(1) bnd(4);bnd(2) bnd(4);bnd(2) bnd(3);bnd(1) bnd(3);bnd(1) bnd(4)]); %data boundary corners
            
            if exist('bs_ext','var')
                crs=bs_ext;
            end
            crslim=[min(crs(:,1)) max(crs(:,1)) min(crs(:,2)) max(crs(:,2))];
            crslim_pol=[crslim(1) crslim(3)
                crslim(1) crslim(4)
                crslim(2) crslim(4)
                crslim(2) crslim(3)
                crslim(1) crslim(3)];
            if ~any(size(x)==1) || ~any(size(y)==1) || numel(x)==1 || numel(y)==1
                disp('Input vectors should be single rows or columns')
                return
            end
            
            
            dt=delaunayTriangulation(x(:),y(:));
            [V,C]=voronoiDiagram(dt);   % This structure gives vertices for each individual point but is missing all "infinite" vertices
            [vx,vy]=voronoi(x,y);       % This structure includes the "infinite" vertices but provides everything as a completele list of vertices rather than individually for each point.
            % Hence we need to add the missing vertices from vx and vy to the V and C structure.
            vxyl=[vx(:) vy(:)];
            
            
            
            % combine identical V-entries
            epsx=eps(max(abs(crs(:))))*10;
            ctr=0;
            Vun=V;
            while ctr<size(Vun,1)-1
                ctr=ctr+1;
                ix=find(abs(Vun(ctr+1:end,1)-Vun(ctr,1))<epsx & abs(Vun(ctr+1:end,2)-Vun(ctr,2))<epsx);
                if ~isempty(ix)
                    Vun(ix+ctr,:)=[];
                end
            end
            for ih=1:length(C)
                for ii=1:length(C{ih})
                    if ~isinf(V(C{ih}(ii),1))
                        C{ih}(ii)=find(abs(V(C{ih}(ii),1)-Vun(:,1))<epsx & abs(V(C{ih}(ii),2)-Vun(:,2))<epsx);
                    end
                end
            end
            V=Vun;
            
            
            %values provided by voronoiDiagram may be an infinitesimal fraction off
            %relative to those provided by "voronoi". Hence we need to make sure all
            %values in V are similar to those located in vxyl.
            vals=unique(vxyl(:));
            for ik=1:length(vals)
                df=abs(V(:)-vals(ik));
                if any(df<=epsx)
                    V(df<=epsx)=vals(ik);
                end
            end
            lV0=length(V);
            
            
            %Find missing points that should be added to existing V/C structure
            %     xix=ones(size(vx));
            xix=ones(size(vx));
            for ii=1:length(vxyl)
                %         ch=1;
                fix=find(abs(V(:,1)-vxyl(ii,1))<epsx);
                if ~isempty(fix)
                    if any(abs(V(fix,2)-vxyl(ii,2))<epsx)
                        xix(ii)=0;
                        %                 plot(vxyl(ii,1),vxyl(ii,2),'or','markersize',15)
                        %             else
                        %                 ch=0;
                    end
                else
                    %             ch=0;
                end
                %         if ch==0
                %             plot(vxyl(ii,1),vxyl(ii,2),'og','markersize',12)
                %         end
            end
            mix=find(xix==1)./2; %index of missing values
            lmix=length(mix);
            mvx=vx(2,mix); %missing vx
            mvy=vy(2,mix); %missing vy
            mv=[mvx',mvy'];
            cpx=vx(1,mix); %connector point x (connects between outer missing points and inner existing points in V/C)
            cpy=vy(1,mix); %connector point y (connects between outer missing points and inner existing points in V/C)
            
            ctr=0;
            mv2=[];
            cpVixt=cell(lmix,1); %connector points, index in V structure
            for ii=1:lmix
                if any(abs(V(:,1)-cpx(ii))<epsx & abs(V(:,2)-cpy(ii))<epsx)
                    cpVixt{ii}=find(abs(V(:,1)-cpx(ii))<epsx & abs(V(:,2)-cpy(ii))<epsx);
                    lval=length(cpVixt{ii});
                    if lval==1
                        ctr=ctr+1;
                        mv2(ctr,:)=mv(ii,:);
                    elseif lval>1
                        ctr=ctr+1;
                        mv2(ctr:ctr+lval-1,:)=[ones(lval,1).*mv(ii,1) ones(lval,1).*mv(ii,2)];
                        ctr=ctr+lval-1;
                    end
                end
            end
            cpVixt=cell2mat(cpVixt);
            
            V=[V;mv2]; %add points to V structure
            
            
            %remove spurious double-entries in C/V structure
            epsx=eps(max(abs(crs(:))))*10;
            for ih=1:length(C)
                VC=V(C{ih},:);
                TMAT=true(size(VC,1));
                for ii=1:size(VC,1)
                    for ij=1:size(VC,1)
                        TMAT(ii,ij)=all(abs(VC(ii,:)-VC(ij,:))<=epsx);
                    end
                end
                TMAT=TMAT-eye(size(TMAT));
                if any(TMAT(:)==1)
                    if all(abs(V(C{ih}(1),:)-V(C{ih}(end),:))<=epsx)
                        C{ih}(end)=[];
                    end
                    ctr=0;
                    while ctr<length(C{ih})-1
                        ctr=ctr+1;
                        if all(abs(V(C{ih}(ctr),:)-V(C{ih}(ctr+1),:))<=epsx)
                            C{ih}(ctr+1)=[];
                        end
                    end
                end
            end
            
            
            %Addition-routine: addition of missing points (mvx,mvy) to individual vertice-polygons (C)
            totalbounds=[min([min(V(~isinf(V(:,1)),1)),min(x),min(crs(:,1)),min(mv2(:,1))]) max([max(V(~isinf(V(:,1)),1)),max(x),max(crs(:,1)),max(mv2(:,1))]) min([min(V(~isinf(V(:,1)),2)),min(y),min(crs(:,2)),min(mv2(:,2))]) max([max(V(~isinf(V(:,1)),2)),max(y),max(crs(:,2)),max(mv2(:,2))])];
            tbdx=diff(totalbounds(1:2));
            tbdy=diff(totalbounds(3:4));
            expandX=.2;
            extremebounds=[totalbounds(1)-(tbdx*expandX) totalbounds(2)+(tbdx*expandX) totalbounds(3)-(tbdy*expandX) totalbounds(4)+(tbdy*expandX)];
            exb_vertices=[extremebounds(1) extremebounds(4)
                extremebounds(2) extremebounds(4)
                extremebounds(2) extremebounds(3)
                extremebounds(1) extremebounds(3)];
            for ij=1:length(C)
                if any(C{ij}==1)
                    C{ij}(C{ij}==1)=[];
                    ixa=find(cpVixt==C{ij}(1));
                    ixb=find(cpVixt==C{ij}(end));
                    
                    if (length(ixa)>=2 || length(ixb)>=2)
                        % DO THE PROPOSED POINTS OBEY THE FOLLOWING RULES?
                        % 1: The resulting shape must contain the original centroid
                        %    (0=does not contain centroid. 1=contains centroid)
                        % 2: None of the end-sections may cross any existing section
                        %    (0=crossing. 1=no crossing)
                        polygon=[V(C{ij},1),V(C{ij},2)];
                        if any(isinf(polygon(:)))
                            polygon(isinf(sum(polygon,2), 'omitnan'),:)=[];
                        end
                        ixok=false(length(ixa),length(ixb),5);
                        for ic1=1:length(ixa)
                            for ic2=1:length(ixb)
                                for ic3=0:4
                                    poly=[[V(lV0+ixa(ic1),1);polygon(:,1);V(lV0+ixb(ic2),1)],[V(lV0+ixa(ic1),2);polygon(:,2);V(lV0+ixb(ic2),2)]];
                                    poly=unique(poly,'rows','stable');
                                    if size(poly,1)>2
                                        if ic3>0 %with external point
                                            poly=[[V(lV0+ixa(ic1),1);polygon(:,1);V(lV0+ixb(ic2),1);exb_vertices(ic3,1)],[V(lV0+ixa(ic1),2);polygon(:,2);V(lV0+ixb(ic2),2);exb_vertices(ic3,2)]];
                                            poly=unique(poly,'rows','stable');
                                        end
                                        k = convhull(poly(:,1),poly(:,2));
                                        A = polyarea(poly(:,1),poly(:,2));
                                        B = polyarea(poly(k,1),poly(k,2));
                                        if abs(A-B)<epsx %convex hull?
                                            ixok(ic1,ic2,ic3+1)=inpolygon(x(ij),y(ij),poly(:,1),poly(:,2)); %centroid in polygon?
                                        end
                                        %                                 if centroidIN(ic1,ic2,ic3+1)==true
                                        %                                     [xi,~] = polyxpoly(polygon(:,1),polygon(:,2),[V(lV0+ixa(ic1),1);V(lV0+ixb(ic2),1)],[V(lV0+ixa(ic1),2);V(lV0+ixb(ic2),2)]);
                                        %                                     sectionCROSS(ic1,ic2,ic3+1)=isempty(xi);
                                        %                                 end
                                    end
                                end
                            end
                        end
                        selection=any(ixok,3);
                        if any(selection(:)==1)
                            [selixa,selixb]=ind2sub(size(selection),find(selection==1));
                            ixa=ixa(unique(selixa));
                            ixb=ixb(unique(selixb));
                        end
                    end
                    
                    
                    % special case
                    if length(C{ij})==1 && isequal(ixa,ixb)
                        C{ij}=[lV0+ixa(1),C{ij},lV0+ixa(2)];
                    elseif length(ixa)==1 && length(ixb)==1
                        C{ij}=[lV0+ixa,C{ij},lV0+ixb];
                    elseif length(ixa)==2 && length(ixb)==1
                        C{ij}=[C{ij},lV0+ixb];
                        [~,minix]=min(sqrt((V(C{ij}(end),1)-V(lV0+ixa,1)).^2+(V(C{ij}(end),2)-V(lV0+ixa,2)).^2));
                        C{ij}=[lV0+ixa(minix),C{ij}];
                    elseif length(ixa)==1 && length(ixb)==2
                        C{ij}=[lV0+ixa,C{ij}];
                        [~,minix]=min(sqrt((V(C{ij}(1),1)-V(lV0+ixb,1)).^2+(V(C{ij}(1),2)-V(lV0+ixb,2)).^2));
                        C{ij}=[C{ij},lV0+ixb(minix)];
                    elseif length(ixa)==2 && length(ixb)==2
                        dist1=sqrt((x(ij)-V(lV0+ixa,1)).^2+(y(ij)-V(lV0+ixa,2)).^2);
                        dist2=sqrt((x(ij)-V(lV0+ixb,1)).^2+(y(ij)-V(lV0+ixb,2)).^2);
                        if diff(dist1)==0 && diff(dist2)==0
                            minix1=1;
                            minix2=2;
                        else
                            [~,minix1]=min(dist1);
                            [~,minix2]=min(dist2);
                        end
                        C{ij}=[lV0+ixa(minix1),C{ij},lV0+ixb(minix2)];
                    end
                end
            end
            
            
            % Extend outer connections which do not extend beyond the user-given boundaries
            crsx=range(crs(:,1));
            crsy=range(crs(:,2));
            scale=10;
            for ij=1:length(C)
                LC=length(C{ij});
                RC=[1 2;
                    LC LC-1];
                for ii=1:2 %open ends: left/right
                    if C{ij}(RC(ii,1))>lV0
                        inpol=inpolygon(V(C{ij}(RC(ii,1)),1),V(C{ij}(RC(ii,1)),2),crs(:,1),crs(:,2));
                        if inpol
                            if V(C{ij}(RC(ii,1)),1)==V(C{ij}(RC(ii,2)),1) %points aligned vertically (polyfit cannot be used)
                                if V(C{ij}(RC(ii,1)),2)>V(C{ij}(RC(ii,2)),2) %point DIRECTLY above. Extend upward
                                    V(C{ij}(RC(ii,1)),2)=max(crs(:,2))+crsy/scale;
                                else %point DIRECTLY below. Extend downward
                                    V(C{ij}(RC(ii,1)),2)=min(crs(:,2))-crsy/scale;
                                end
                            else %extend using polyfit
                                plf=polyfit(V(C{ij}(RC(ii,:)),1),V(C{ij}(RC(ii,:)),2),1);
                                if V(C{ij}(RC(ii,1)),1)>V(C{ij}(RC(ii,2)),1) %extend point beyond RIGHT boundary
                                    V(C{ij}(RC(ii,1)),1)=max(crs(:,1))+crsx/scale;
                                    V(C{ij}(RC(ii,1)),2)=polyval(plf,V(C{ij}(RC(ii,1)),1));
                                else %extend point beyond LEFT boundary
                                    V(C{ij}(RC(ii,1)),1)=min(crs(:,1))-crsx/scale;
                                    V(C{ij}(RC(ii,1)),2)=polyval(plf,V(C{ij}(RC(ii,1)),1));
                                end
                            end
                        end
                    end
                end
            end
            
            
            
            %   Polybool for restriction of polygons to domain.
            %   Expand vertices when necessary!
            allVixinp=inpolygon(V(:,1),V(:,2),crs(:,1),crs(:,2)); %determine which points in V that are within the data boundaries.
            totalbounds=[min([min(V(~isinf(V(:,1)),1)),min(x),min(crs(:,1)),min(mv2(:,1))]) max([max(V(~isinf(V(:,1)),1)),max(x),max(crs(:,1)),max(mv2(:,1))]) min([min(V(~isinf(V(:,1)),2)),min(y),min(crs(:,2)),min(mv2(:,2))]) max([max(V(~isinf(V(:,1)),2)),max(y),max(crs(:,2)),max(mv2(:,2))])];
            tbdx=diff(totalbounds(1:2));
            tbdy=diff(totalbounds(3:4));
            expandX=1;
            extremebounds=[totalbounds(1)-(tbdx*expandX) totalbounds(2)+(tbdx*expandX) totalbounds(3)-(tbdy*expandX) totalbounds(4)+(tbdy*expandX)];
            
            
            Nint=4;
            exb_vertices_x=[linspace(extremebounds(1),extremebounds(2),Nint)';linspace(extremebounds(1),extremebounds(2),Nint)';ones(Nint,1)*extremebounds(1);ones(Nint,1)*extremebounds(2)];
            exb_vertices_y=[ones(Nint,1)*extremebounds(3);ones(Nint,1)*extremebounds(4);linspace(extremebounds(3),extremebounds(4),Nint)';linspace(extremebounds(3),extremebounds(4),Nint)'];
            exb_vertices=[exb_vertices_x exb_vertices_y];
            
            %     exb_vertices=[extremebounds(1) extremebounds(4)
            %         extremebounds(2) extremebounds(4)
            %         extremebounds(2) extremebounds(3)
            %         extremebounds(1) extremebounds(3)];
            
            
            % STEP 1: categorize and apply polybool on all polygons who contain vertices outside the boundaries, but does not cross the boundaries between the first and last point
            poly_ok=zeros(size(C)); %   0=ok
            %   1=vertices outside boundaries but no crossing of boundary lines (resolve now)
            %   2=vertices outside boundaries AND crossing of boundary lines (resolve later)
            for ij=1:length(C)
                if sum(allVixinp(C{ij}), 'omitnan')~=length(C{ij})
                    poly_ok(ij)=1;
                    % Q: when drawing a line between the open ends of the polygon, does it intersect with the extreme (rectangle) data boundaries?
                    % If so, connect the open ends to the extreme boundaries so that this is no longer the case.
                    % The goal here is to expand the outer voronoi cells to include all of the domain of the given boundaries
                    
                    intersect=false(4,1);
                    for ii=1:4
                        [xip,~]=polyxpoly(crslim_pol(ii:ii+1,1),crslim_pol(ii:ii+1,2),V([C{ij}(1) C{ij}(end)],1),V([C{ij}(1) C{ij}(end)],2)); %intersections between lines
                        if ~isempty(xip)
                            intersect(ii)=true;
                        end
                    end
                    if any(intersect) %possibly expand outer points
                        poly_ok(ij)=2;
                    end
                    
                    if poly_ok(ij)==1
                        poly_ok(ij)=0;
                        [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),V(C{ij},1),V(C{ij},2));  %#ok<*PLBL>
                        %             [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),V(C1{ij},1),V(C1{ij},2));
                        ix=nan(1,length(xb));
                        for il=1:length(xb)
                            if any(V(:,1)==xb(il)) && any(V(:,2)==yb(il))
                                ix1=find(V(:,1)==xb(il));
                                ix2=find(V(:,2)==yb(il));
                                for ib=1:length(ix1)
                                    if any(ix1(ib)==ix2)
                                        ix(il)=ix1(ib);
                                    end
                                end
                                if isnan(ix(il))
                                    lv=length(V);
                                    V(lv+1,1)=xb(il);
                                    V(lv+1,2)=yb(il);
                                    allVixinp(lv+1)=1;
                                    ix(il)=lv+1;
                                end
                            else
                                lv=length(V);
                                V(lv+1,1)=xb(il);
                                V(lv+1,2)=yb(il);
                                allVixinp(lv+1)=1;
                                ix(il)=lv+1;
                            end
                        end
                        C{ij}=ix;
                    end
                end
            end
            
            
            % STEP 2: if any polygons remain evaluate whether by expanding them, they encroach on the territory of a neighboring polygon which has been accepted
            if any(poly_ok==2)
                ixpo=cell(2,1);
                for im=1:2  % im=1: run only the first three criteria to accept as many polygons based on this as possible.
                    % im=2: run the remaining polygons with the final fourth criteria only
                    ixpo{im}=find(poly_ok==2);
                    if im==1
                        diagnostics=zeros(size(exb_vertices,1)*size(exb_vertices,1)*5,length(ixpo{im}));
                    elseif im==2
                        diagnostics2=zeros(size(exb_vertices,1)*size(exb_vertices,1)*5,length(ixpo{im}));
                        for in=1:length(ixpo{im})
                            diagnostics2(:,in)=diagnostics(:,ixpo{1}==ixpo{im}(in));
                        end
                        diagnostics=diagnostics2;
                    end
                    
                    if im==2
                        ixpo_new=ixpo{im};
                    end
                    for ik=1:length(ixpo{im})
                        if im==2
                            % Determine neighboring polygons of all relevant polygons.
                            % Iteratively sort and run these according to the highest ratio of neighboring polygons which have already been accepted.
                            neighbors=cell(size(ixpo_new));
                            neighbors_ok_ratio=nan(length(ixpo_new),3);
                            for ij=1:length(ixpo_new)
                                for ii=1:length(C{ixpo_new(ij)})
                                    for il=1:length(C)
                                        if any(C{il}==C{ixpo_new(ij)}(ii)) && il~=ixpo_new(ij)
                                            neighbors{ij}=[neighbors{ij};il];
                                        end
                                    end
                                    
                                end
                                neighbors{ij}=unique(neighbors{ij});
                                neighbors_ok_ratio(ij,:)=[sum(poly_ok(neighbors{ij})==0, 'omitnan')/numel(neighbors{ij}) ixpo_new(ij) ij];
                            end
                            if length(ixpo_new)>1
                                neighbors_ok_ratio=flipud(sortrows(neighbors_ok_ratio));
                                neighbors1=cell(size(neighbors));
                                for ij=1:length(ixpo_new)
                                    neighbors1{ij}=neighbors{neighbors_ok_ratio(ij,3)};
                                end
                                neighbors=neighbors1;
                                ixpo_new=neighbors_ok_ratio(:,2);
                            else
                                neighbors(neighbors_ok_ratio(:,2)~=ixpo_new)=[];
                            end
                        end
                        
                        if im==1
                            ij=ixpo{im}(ik);
                        elseif im==2
                            ij=ixpo_new(1);
                        end
                        
                        % Q: when drawing a line between the open ends of the polygon, does it intersect with the extreme (rectangle) data boundaries?
                        % If so, connect the open ends to the extreme boundaries so that this is no longer the case.
                        % The goal here is to expand the outer voronoi cells to include all of the domain of the given boundaries
                        % all combinations of connections between open ends and boundary limits are investigated to find the right one
                        poly0=[V(C{ij},1),V(C{ij},2)];
                        
                        polylog=cell(size(exb_vertices,1)*size(exb_vertices,1)*5,1);
                        ctr=0;
                        for iv1=1:size(exb_vertices,1)     % extreme boundary vertices
                            for iv2=1:size(exb_vertices,1) % extreme boundary vertices
                                for iv3=0:4 % Optional (iv3=0) additional points (iv3=1:4)
                                    ctr=ctr+1;
                                    run=1;
                                    if im==2 && (diagnostics(ctr,ik)==0 || isnan(diagnostics(ctr,ik)))
                                        run=0;
                                    end
                                    %check all possible variations of connections between open ends and extreme boundary limits for the following traits:
                                    % 1) Area of convexhull of points equals area of raw points (i.e. "clean" shape)
                                    % 2) Does not contain any of the other centroids
                                    % 3) A line drawn between the open points does not intersect with the boundaries (as above)
                                    % 4) Does not encroach on the territory of any accepted (poly_ok==0) polygon
                                    
                                    % Define polygon
                                    if run==1
                                        if iv3==0
                                            poly=[exb_vertices(iv1,:);poly0;exb_vertices(iv2,:)];
                                        else
                                            poly=[exb_vertices(iv1,:);poly0;exb_vertices(iv2,:);exb_vertices(iv3,:)];
                                        end
                                        poly=unique(poly,'rows','stable');
                                        polylog{ctr}=poly;
                                    end
                                    
                                    
                                    % if ctr>1 -> check that unique case hasn't been run before
                                    if ctr>1 && run==1
                                        polytest=nan(ctr-1,1);
                                        for ipt=1:length(polytest)
                                            polytest(ipt)=isequal(poly,polylog{ipt});
                                        end
                                        if any(polytest) %do not run again
                                            run=0;
                                            diagnostics(ctr,ik)=nan;
                                        end
                                    end
                                    
                                    
                                    if run==1
                                        % TEST 1: Area of convex hull
                                        if im==1
                                            k = convhull(poly(:,1),poly(:,2));
                                            A = polyarea(poly(:,1),poly(:,2));
                                            B = polyarea(poly(k,1),poly(k,2));
                                            if abs(A-B)<epsx
                                                diagnostics(ctr,ik)=1;
                                            end
                                            
                                            
                                            % TEST 2: contains no other centroids
                                            if diagnostics(ctr,ik)==1
                                                xy=[x y];
                                                xy(ij,:)=[];
                                                IN1=inpolygon(xy(:,1),xy(:,2),poly(:,1),poly(:,2));
                                                IN2=inpolygon(x(ij),y(ij),poly(:,1),poly(:,2));
                                                if all(~IN1) && IN2==1
                                                    diagnostics(ctr,ik)=1;
                                                else
                                                    diagnostics(ctr,ik)=0;
                                                end
                                            end
                                            
                                            % TEST 3: line between open points does not intersect with boundaries (as above)
                                            if diagnostics(ctr,ik)==1
                                                
                                                %define "links"
                                                lp0=length(poly0);
                                                for il=1:length(poly)-lp0+1
                                                    if isequal(poly(il:il+lp0-1,:),poly0)
                                                        poly0ix=il;
                                                    end
                                                end
                                                links=cell(2,1);
                                                if poly0ix>1
                                                    links{1}=poly(1:poly0ix,:);
                                                end
                                                if poly0ix+lp0-1<length(poly)
                                                    links{2}=poly(poly0ix+lp0-1:end,:);
                                                end
                                                
                                                
                                                intersect2=false(4,1);
                                                ilix_intersect=false(4,2);
                                                for ii=1:4
                                                    %%% "links"
                                                    for il=1:2
                                                        if ~isempty(links{il})
                                                            %                                                     ilix_intersect(ii,il)=false(size(links{il},1)-1,1);
                                                            for ilix=1:size(links{il},1)-1
                                                                [xip,~]=polyxpoly(crslim_pol(ii:ii+1,1),crslim_pol(ii:ii+1,2),links{il}(ilix:ilix+1,1),links{il}(ilix:ilix+1,2)); %intersections between lines
                                                                if ~isempty(xip)
                                                                    ilix_intersect(ii,il)=true;
                                                                end
                                                            end
                                                        end
                                                        
                                                    end
                                                    
                                                    %%% outer points
                                                    [xip,~]=polyxpoly(crslim_pol(ii:ii+1,1),crslim_pol(ii:ii+1,2),poly([1 end],1),poly([1 end],2)); %intersections between lines
                                                    if ~isempty(xip)
                                                        intersect2(ii)=true;
                                                    end
                                                end
                                                if any(intersect2) || any(ilix_intersect(:))
                                                    diagnostics(ctr,ik)=0;
                                                end
                                            end
                                        end
                                        
                                        if im==2
                                            % TEST 4: Does not encroach on the territory of any accepted (poly_ok==0) polygon
                                            nb=neighbors{1};
                                            %                                     nb=nb(poly_ok(nb)==0);
                                            if ~isempty(nb)
                                                overlap=false(size(nb));
                                                for in=1:length(nb)
                                                    [xb,~] = polybool('intersection',V(C{nb(in)},1),V(C{nb(in)},2),poly(:,1),poly(:,2));
                                                    if ~isempty(xb)
                                                        overlap(in)=1;
                                                    end
                                                end
                                                if sum(overlap, 'omitnan')~=0
                                                    diagnostics(ctr,ik)=0;
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        ixok=find(diagnostics(:,ik)==1);
                        %                 if im==2 && ~isempty(ixok)
                        if ~isempty(ixok)
                            polyfinal=polylog{ixok(1)};
                            
                            %add any new points to C/V structure
                            Ct=nan(1,size(polyfinal,1));
                            for ia=1:size(polyfinal,1)
                                vpf=nan(size(V,1),1);
                                for iv=1:size(V,1)
                                    vpf(iv)=isequal(V(iv,:),polyfinal(ia,:));
                                end
                                if all(vpf==0) %add point
                                    V=[V;polyfinal(ia,:)];
                                    Ct(ia)=size(V,1);
                                else
                                    Ct(ia)=find(vpf==1,1,'first');
                                end
                            end
                            C{ij}=Ct;
                            ixok=[];
                        end
                        if (im==1 && isempty(ixok)) || im==2
                            [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),V(C{ij},1),V(C{ij},2));
                            ix=nan(1,length(xb));
                            for il=1:length(xb)
                                if any(V(:,1)==xb(il)) && any(V(:,2)==yb(il))
                                    ix1=find(V(:,1)==xb(il));
                                    ix2=find(V(:,2)==yb(il));
                                    for ib=1:length(ix1)
                                        if any(ix1(ib)==ix2)
                                            ix(il)=ix1(ib);
                                        end
                                    end
                                    if isnan(ix(il))
                                        lv=length(V);
                                        V(lv+1,1)=xb(il);
                                        V(lv+1,2)=yb(il);
                                        allVixinp(lv+1)=1;
                                        ix(il)=lv+1;
                                    end
                                else
                                    lv=length(V);
                                    V(lv+1,1)=xb(il);
                                    V(lv+1,2)=yb(il);
                                    allVixinp(lv+1)=1;
                                    ix(il)=lv+1;
                                end
                            end
                            C{ij}=ix;
                            poly_ok(ij)=0;
                        end
                        if im==2
                            ixpo_new(ixpo_new==ij)=[];
                        end
                    end
                end
            end
            isemp=false(size(C));
            for ij=1:length(C)
                if isempty(C{ij})
                    isemp(ij)=true;
                end
            end
            if any(isemp)
                C(isemp)=[];
                XY(isemp,:)=[];
            end
            
            
            %adjust polygons to the presence of internal boundaries
            if exist('bs_int','var')
                isemp=false(length(C),length(bs_int));
                for ii=1:length(bs_int)
                    V2=nan(length(V)*10,2);
                    C2=cell(length(C),1);
                    ctr=1;
                    for ij=1:length(C)
                        [pbx,pby]=polybool('subtraction',V(C{ij},1),V(C{ij},2),bs_int{ii}(:,1),bs_int{ii}(:,2));
                        if ~isempty(pbx)
                            C2{ij}=(ctr:ctr+length(pbx)-1)';
                            C2{ij}=[C2{ij} ones(size(C2{ij}))*ij];
                            V2(ctr:ctr+length(pbx)-1,:)=[pbx pby];
                            ctr=ctr+length(pbx);
                        end
                    end
                    V=V2(1:ctr-1,:);
                    C=C2;
                    for ij=1:length(C)
                        if isempty(C{ij})
                            isemp(ij,ii)=true;
                        else
                            C{ij}=(C{ij}(:,1))';
                        end
                    end
                end
                if any(any(isemp'))
                    C(sum(isemp,2, 'omitnan')~=0)=[];
                    XY(sum(isemp,2, 'omitnan')~=0,:)=[];
                end
            end
            
            
            %remove spurious double-entries in C/V structure
            epsx=eps(max(abs(V(unique(cell2mat(C'))))));
            for ih=1:length(C)
                VC=V(C{ih},:);
                TMAT=true(size(VC,1));
                for ii=1:size(VC,1)
                    for ij=1:size(VC,1)
                        TMAT(ii,ij)=all(abs(VC(ii,:)-VC(ij,:))<=epsx);
                    end
                end
                TMAT=TMAT-eye(size(TMAT));
                if any(TMAT(:)==1)
                    if all(abs(V(C{ih}(1),:)-V(C{ih}(end),:))<=epsx)
                        C{ih}(end)=[];
                    end
                    ctr=0;
                    while ctr<length(C{ih})-1
                        ctr=ctr+1;
                        if all(abs(V(C{ih}(ctr),:)-V(C{ih}(ctr+1),:))<=epsx)
                            C{ih}(ctr+1)=[];
                        end
                    end
                end
                C{ih}=C{ih}';
            end
            
            
            TMAT=cell(length(V)-1,1);
            Vt=V;
            idx1=(1:length(V))';
            idx2=(1:length(V))';
            for ii=1:length(V)-1
                Vt=[Vt(2:end,:);Vt(1,:)];
                idx2=[idx2(2:end);idx2(1)];
                TMATt=find(all(abs(V-Vt)<=epsx,2));
                TMAT{ii}=[idx1(TMATt) idx2(TMATt)];
            end
            TMATf=unique(sort(cell2mat(TMAT),2),'rows');
            if ~isempty(TMATf)
                for ii=1:size(TMATf,1)
                    for ij=1:length(C)
                        C{ij}(C{ij}==TMATf(ii,2))=TMATf(ii,1);
                    end
                end
            end
            
            
            
            %remove V-entries which are now unused by C
            index_rem=true(size(V,1),1);
            Ctot=unique(cell2mat(C));
            index_rem(Ctot)=false;
            index_rem=find(index_rem);
            while ~isempty(index_rem)
                for ij=1:length(C)
                    ixf=find(C{ij}>index_rem(1));
                    if ~isempty(ixf)
                        C{ij}(ixf)=C{ij}(ixf)-1;
                    end
                end
                V(index_rem(1),:)=[];
                index_rem=true(size(V,1),1);
                Ctot=unique(cell2mat(C));
                index_rem(Ctot)=false;
                index_rem=find(index_rem);
            end
            
            %Check and repair cells that have been split into closed sub-cells by input boundaries
            Csplit=cell(length(C),1);
            XYsplit=cell(length(C),1);
            splitlog=false(length(C),1);
            for ij=1:length(C)
                [xClosed, yClosed] = closePolygonParts(V(C{ij},1),V(C{ij},2));
                if any(isnan(xClosed))
                    splitlog(ij)=true;
                    ix=find(~isnan(xClosed));
                    diffix=diff(ix)>1;
                    NUMcell=sum(isnan(xClosed))+1;
                    Csplit{ij}=cell(NUMcell,1);
                    XYsplit{ij}=nan(NUMcell,2);
                    C_temp=C{ij};
                    ix_begin=1;
                    for ik=1:NUMcell
                        cs_diffix=cumsum(diffix);
                        if ik>1
                            ix_begin=2;
                        end
                        ix_end=find(cs_diffix>0,1,'first');
                        if isempty(ix_end)
                            ix_end=length(xClosed);
                        end
                        Csplit{ij}{ik}=C_temp(ix_begin:ix_end);
                        inpol=inpolygon(XY(ij,1),XY(ij,2),xClosed(ix_begin:ix_end),yClosed(ix_begin:ix_end));
                        if inpol==0
                            XYsplit{ij}(ik,:)=[mean(xClosed(ix_begin:ix_end), 'omitnan') mean(yClosed(ix_begin:ix_end), 'omitnan')];
                        else
                            XYsplit{ij}(ik,:)=XY(ij,:);
                        end
                        if ik<NUMcell
                            C_temp(ix_begin:ix_end)=[];
                            diffix(ix_begin:ix_end)=[];
                            xClosed(ix_begin:ix_end)=[];
                            yClosed(ix_begin:ix_end)=[];
                        end
                    end
                end
            end
            if any(splitlog)
                ix_splitlog=find(splitlog);
                ix_splitlog0=ix_splitlog;
                for ij=1:length(ix_splitlog)
                    if ix_splitlog(ij)==1
                        C=[Csplit{ix_splitlog(ij)};C(2:end)];
                        XY=[XYsplit{ix_splitlog(ij)};XY(2:end,:)];
                    elseif ix_splitlog(ij)==length(C)
                        C=[C(1:end-1);Csplit{ix_splitlog(ij)}];
                        XY=[XY(1:end-1,:);XYsplit{ix_splitlog(ij)}];
                    else
                        C=[C(1:ix_splitlog(ij)-1);Csplit{ix_splitlog0(ij)};C(ix_splitlog(ij)+1:end)];
                        XY=[XY(1:ix_splitlog(ij)-1,:);XYsplit{ix_splitlog0(ij)};XY(ix_splitlog(ij)+1:end,:)];
                        if ij<length(ix_splitlog)
                            ix_splitlog(ij+1:end)=ix_splitlog(ij+1:end)+(length(Csplit{ix_splitlog0(ij)})-1);
                        end
                    end
                end
            end
            
            %ensure that all polygon vertex groups are given in counter-clockwise order
            for ih=1:length(C)
                if ispolycw(V(C{ih},1),V(C{ih},2))
                    C{ih}=flipud(C{ih});
                end
            end
            
            
            %% create and output figure
            if exist('fig','var')
                if strcmp(fig,'on')
                    
                    %close polygons for the purpose of plotting
                    C2=C;
                    for ih=1:length(C2)
                        if C2{ih}(1)~=C2{ih}(end)
                            C2{ih}=[C2{ih};C2{ih}(1)];
                        end
                    end
                    
                    figure
                    set(gcf,'position',get(0,'screensize'),'color','w')
                    set(gca,'box','on')
                    hold on
                    plot(x,y,'.k')
                    %             if any(splitlog)
                    %                 for ij=1:length(ix_splitlog0)
                    %                     plot(XYsplit{ix_splitlog0(ij)}(:,1),XYsplit{ix_splitlog0(ij)}(:,2),'*r')
                    %                     plot(XYsplit{ix_splitlog0(ij)}(:,1),XYsplit{ix_splitlog0(ij)}(:,2),'or','markersize',8)
                    %                 end
                    %             end
                    voronoi(x,y)
                    for id=1:length(C2)
                        plot(V(C2{id},1),V(C2{id},2),'-r')
                    end
                    grid on
                    axis tight
                    axis square
                    if nargin==0
                        axis equal
                    end
                    ax=axis;
                    dx=(ax(2)-ax(1))/10;
                    dy=(ax(4)-ax(3))/10;
                    axis([ax(1)-dx ax(2)+dx ax(3)-dy ax(4)+dy])
                    title({'Original Voronoi Decomposition ({\color{blue}blue})';'New limited Voronoi Decomposition ({\color{red}red})'},'fontsize',16,'fontweight','bold')
                    if exist('bs_int','var')
                        for ii=1:length(bs_int)
                            text(mean(unique(bs_int{ii}(:,1)), 'omitnan'),mean(unique(bs_int{ii}(:,2)), 'omitnan'),num2str(ii),'fontsize',30,'fontweight','bold','horizontalalignment','center')
                        end
                    end
                end
            end
            %         export_fig([pwd,'\VoronoiLimit_example.jpg'],'-r300');
            
        catch %me
            disp('stop')
        end
        
    end %this function calculates the bounded voronoi tesselation
    function [out1,out2,out3] = ginputCustom(arg1)
        %GINPUT Graphical input from mouse.
        %   [X,Y] = GINPUT(N) gets N points from the current axes and returns
        %   the X- and Y-coordinates in length N vectors X and Y.  The cursor
        %   can be positioned using a mouse.  Data points are entered by pressing
        %   a mouse button or any key on the keyboard except carriage return,
        %   which terminates the input before N points are entered.
        %
        %   [X,Y] = GINPUT gathers an unlimited number of points until the
        %   return key is pressed.
        %
        %   [X,Y,BUTTON] = GINPUT(N) returns a third result, BUTTON, that
        %   contains a vector of integers specifying which mouse button was
        %   used (1,2,3 from left) or ASCII numbers if a key on the keyboard
        %   was used.
        %
        %   Examples:
        %       [x,y] = ginput;
        %
        %       [x,y] = ginput(5);
        %
        %       [x, y, button] = ginput(1);
        %
        %   See also GTEXT, WAITFORBUTTONPRESS.
        
        %   Copyright 1984-2015 The MathWorks, Inc.
        
        out1 = []; out2 = []; out3 = []; y = [];
        
        if ~matlab.ui.internal.isFigureShowEnabled
            error(message('MATLAB:hg:NoDisplayNoFigureSupport', 'ginput'))
        end
        
        % Check Inputs
        if nargin == 0
            how_many = -1;
            b1 = [];
        else
            how_many = arg1;
            b1 = [];
            if  ~isPositiveScalarIntegerNumber(how_many)
                error(message('MATLAB:ginput:NeedPositiveInt'))
            end
            if how_many == 0
                % If input argument is equal to zero points,
                % give a warning and return empty for the outputs.
                warning (message('MATLAB:ginput:InputArgumentZero'));
            end
        end
        
        % Get figure
        fig = gcf;
        customdrawnow;
        figure(gcf);
        
        % Make sure the figure has an axes
        gca(fig);
        
        % Setup the figure to disable interactive modes and activate pointers.
        initialState = setupFcn(fig);
        
        % onCleanup object to restore everything to original state in event of
        % completion, closing of figure errors or ctrl+c.
        c = onCleanup(@() restoreFcn(initialState));
        
        customdrawnow
        char = 0;
        
        while how_many ~= 0
            waserr = 0;
            try
                keydown = wfbp;
            catch %#ok<CTCH>
                waserr = 1;
            end
            if(waserr == 1)
                if(ishghandle(fig))
                    cleanup(c);
                    error(message('MATLAB:ginput:Interrupted'));
                else
                    cleanup(c);
                    error(message('MATLAB:ginput:FigureDeletionPause'));
                end
            end
            % g467403 - ginput failed to discern clicks/keypresses on the figure it was
            % registered to operate on and any other open figures whose handle
            % visibility were set to off
            figchildren = allchild(0);
            if ~isempty(figchildren)
                ptr_fig = figchildren(1);
            else
                error(message('MATLAB:ginput:FigureUnavailable'));
            end
            %         old code -> ptr_fig = get(0,'CurrentFigure'); Fails when the
            %         clicked figure has handlevisibility set to callback
            if(ptr_fig == fig)
                if keydown
                    char = get(fig, 'CurrentCharacter');
                    button = abs(get(fig, 'CurrentCharacter'));
                else
                    button = get(fig, 'SelectionType');
                    if strcmp(button,'open')
                        button = 1;
                    elseif strcmp(button,'normal')
                        button = 1;
                    elseif strcmp(button,'extend')
                        button = 2;
                    elseif strcmp(button,'alt')
                        button = 3;
                    else
                        error(message('MATLAB:ginput:InvalidSelection'))
                    end
                end
                
                if(char == 13) % & how_many ~= 0)
                    % if the return key was pressed, char will == 13,
                    % and that's our signal to break out of here whether
                    % or not we have collected all the requested data
                    % points.
                    % If this was an early breakout, don't include
                    % the <Return> key info in the return arrays.
                    % We will no longer count it if it's the last input.
                    break;
                end
                
                axes_handle = gca;
                if ~isa(axes_handle,'matlab.graphics.axis.Axes')
                    % If gca is not an axes, warn but keep listening for clicks.
                    % (There may still be other subplots with valid axes)
                    warning(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'ginput', axes_handle.Type));
                    continue
                end
                
                customdrawnow;
                pt = get(axes_handle, 'CurrentPoint');
                how_many = how_many - 1;
                
                
                
                out1 = [out1;pt(1,1)];
                y = [y;pt(1,2)];
                b1 = [b1;button];
            end
        end
        
        % Cleanup and Restore
        cleanup(c);
        
        if nargout > 1
            out2 = y;
            if nargout > 2
                out3 = b1;
            end
        else
            out1 = [out1 y];
        end
        
    end %use green crosshair
    function valid = isPositiveScalarIntegerNumber(how_many)
        valid = ~ischar(how_many) && ...            % is numeric
            isscalar(how_many) && ...           % is scalar
            (fix(how_many) == how_many) && ...  % is integer in value
            how_many >= 0;                      % is positive
    end %check for positive scalar
    function key = wfbp
        %WFBP   Replacement for WAITFORBUTTONPRESS that has no side effects.
        
        fig = gcf;
        current_char = []; %#ok<NASGU>
        
        % Now wait for that buttonpress, and check for error conditions
        waserr = 0;
        try
            h=findall(fig,'Type','uimenu','Accelerator','C');   % Disabling ^C for edit menu so the only ^C is for
            set(h,'Accelerator','');                            % interrupting the function.
            keydown = waitforbuttonpress;
            current_char = double(get(fig,'CurrentCharacter')); % Capturing the character.
            if~isempty(current_char) && (keydown == 1)          % If the character was generated by the
                if(current_char == 3)                           % current keypress AND is ^C, set 'waserr'to 1
                    waserr = 1;                                 % so that it errors out.
                end
            end
            
            set(h,'Accelerator','C');                           % Set back the accelerator for edit menu.
        catch %#ok<CTCH>
            waserr = 1;
        end
        customdrawnow;
        if(waserr == 1)
            set(h,'Accelerator','C');                          % Set back the accelerator if it errored out.
            error(message('MATLAB:ginput:Interrupted'));
        end
        
        if nargout>0, key = keydown; end
    end %wait for button press replacement
    function initialState = setupFcn(fig)
        
        % Store Figure Handle.
        initialState.figureHandle = fig;
        
        % Suspend figure functions
        initialState.uisuspendState = uisuspend(fig);
        
        % Disable Plottools Buttons
        initialState.toolbar = findobj(allchild(fig),'flat','Type','uitoolbar');
        if ~isempty(initialState.toolbar)
            initialState.ptButtons = [uigettool(initialState.toolbar,'Plottools.PlottoolsOff'), ...
                uigettool(initialState.toolbar,'Plottools.PlottoolsOn')];
            initialState.ptState = get (initialState.ptButtons,'Enable');
            set (initialState.ptButtons,'Enable','off');
        end
        
        %Setup empty pointer
        cdata = NaN(16,16);
        hotspot = [8,8];
        set(gcf,'Pointer','custom','PointerShapeCData',cdata,'PointerShapeHotSpot',hotspot)
        
        % Create uicontrols to simulate fullcrosshair pointer.
        initialState.CrossHair = createCrossHair(fig);
        
        % Adding this to enable automatic updating of currentpoint on the figure
        % This function is also used to update the display of the fullcrosshair
        % pointer and make them track the currentpoint.
        set(fig,'WindowButtonMotionFcn',@(o,e) dummy()); % Add dummy so that the CurrentPoint is constantly updated
        initialState.MouseListener = addlistener(fig,'WindowMouseMotion', @(o,e) updateCrossHair(o,initialState.CrossHair));
        
        % Get the initial Figure Units
        initialState.fig_units = get(fig,'Units');
    end % ginputCustom
    function restoreFcn(initialState)
        if ishghandle(initialState.figureHandle)
            delete(initialState.CrossHair);
            
            % Figure Units
            set(initialState.figureHandle,'Units',initialState.fig_units);
            
            set(initialState.figureHandle,'WindowButtonMotionFcn','');
            delete(initialState.MouseListener);
            
            % Plottools Icons
            if ~isempty(initialState.toolbar) && ~isempty(initialState.ptButtons)
                set (initialState.ptButtons(1),'Enable',initialState.ptState{1});
                set (initialState.ptButtons(2),'Enable',initialState.ptState{2});
            end
            
            % UISUSPEND
            uirestore(initialState.uisuspendState);
        end
    end % ginputCustom
    function updateCrossHair(fig, crossHair)
        % update cross hair for figure.
        gap = 3; % 3 pixel view port between the crosshairs
        cp = hgconvertunits(fig, [fig.CurrentPoint 0 0], fig.Units, 'pixels', fig);
        cp = cp(1:2);
        figPos = hgconvertunits(fig, fig.Position, fig.Units, 'pixels', fig.Parent);
        figWidth = figPos(3);
        figHeight = figPos(4);
        
        % Early return if point is outside the figure
        if cp(1) < gap || cp(2) < gap || cp(1)>figWidth-gap || cp(2)>figHeight-gap
            return
        end
        
        set(crossHair, 'Visible', 'on');
        thickness = 1; % 1 Pixel thin lines.
        set(crossHair(1), 'Position', [0 cp(2) cp(1)-gap thickness]);
        set(crossHair(2), 'Position', [cp(1)+gap cp(2) figWidth-cp(1)-gap thickness]);
        set(crossHair(3), 'Position', [cp(1) 0 thickness cp(2)-gap]);
        set(crossHair(4), 'Position', [cp(1) cp(2)+gap thickness figHeight-cp(2)-gap]);
    end % ginputCustom
    function crossHair = createCrossHair(fig)
        % Create thin uicontrols with black backgrounds to simulate fullcrosshair pointer.
        % 1: horizontal left, 2: horizontal right, 3: vertical bottom, 4: vertical top
        %*************** CHANGED [0,0,0] TO [[1,1,1] to make cross hairs white. ******************
        for ki = 1:4
            crossHair(ki) = uicontrol(fig, 'Style', 'text', 'Visible', 'off', 'Units', 'pixels', 'BackgroundColor', [0 1 0], 'HandleVisibility', 'off', 'HitTest', 'off');
        end
    end % ginputCustom
    function cleanup(c)
        if isvalid(c)
            delete(c);
        end
    end %ginputCustom
    function dummy(~,~)
    end %ginputCustom
    function [output, Greg] = dftregistration(buf1ft,buf2ft,usfac)
        % function [output Greg] = dftregistration(buf1ft,buf2ft,usfac);
        % Efficient subpixel image registration by crosscorrelation. This code
        % gives the same precision as the FFT upsampled cross correlation in a
        % small fraction of the computation time and with reduced memory
        % requirements. It obtains an initial estimate of the crosscorrelation peak
        % by an FFT and then refines the shift estimation by upsampling the DFT
        % only in a small neighborhood of that estimate by means of a
        % matrix-multiply DFT. With this procedure all the image points are used to
        % compute the upsampled crosscorrelation.
        % Manuel Guizar - Dec 13, 2007
        %
        % Rewrote all code not authored by either Manuel Guizar or Jim Fienup
        % Manuel Guizar - May 13, 2016
        %
        % Citation for this algorithm:
        % Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup,
        % "Efficient subpixel image registration algorithms," Opt. Lett. 33,
        % 156-158 (2008).
        %
        % Inputs
        % buf1ft    Fourier transform of reference image,
        %           DC in (1,1)   [DO NOT FFTSHIFT]
        % buf2ft    Fourier transform of image to register,
        %           DC in (1,1) [DO NOT FFTSHIFT]
        % usfac     Upsampling factor (integer). Images will be registered to
        %           within 1/usfac of a pixel. For example usfac = 20 means the
        %           images will be registered within 1/20 of a pixel. (default = 1)
        %
        % Outputs
        % output =  [error,diffphase,net_row_shift,net_col_shift]
        % error     Translation invariant normalized RMS error between f and g
        % diffphase     Global phase difference between the two images (should be
        %               zero if images are non-negative).
        % net_row_shift net_col_shift   Pixel shifts between images
        % Greg      (Optional) Fourier transform of registered version of buf2ft,
        %           the global phase difference is compensated for.
        %
        %
        % Copyright (c) 2016, Manuel Guizar Sicairos, James R. Fienup, University of Rochester
        % All rights reserved.
        %
        % Redistribution and use in source and binary forms, with or without
        % modification, are permitted provided that the following conditions are
        % met:
        %
        %     * Redistributions of source code must retain the above copyright
        %       notice, this list of conditions and the following disclaimer.
        %     * Redistributions in binary form must reproduce the above copyright
        %       notice, this list of conditions and the following disclaimer in
        %       the documentation and/or other materials provided with the distribution
        %     * Neither the name of the University of Rochester nor the names
        %       of its contributors may be used to endorse or promote products derived
        %       from this software without specific prior written permission.
        %
        % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        % AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        % IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
        % ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
        % LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
        % CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
        % SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
        % INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
        % CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
        % ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
        % POSSIBILITY OF SUCH DAMAGE.
        
        if ~exist('usfac','var')
            usfac = 1;
        end
        
        [nr,nc]=size(buf2ft);
        Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
        Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
        
        if usfac == 0
            % Simple computation of error and phase difference without registration
            CCmax = sum(buf1ft(:).*conj(buf2ft(:)), 'omitnan');
            row_shift = 0;
            col_shift = 0;
        elseif usfac == 1
            % Single pixel registration
            CC = ifft2(buf1ft.*conj(buf2ft));
            CCabs = abs(CC);
            [row_shift, col_shift] = find(CCabs == max(CCabs(:)));
            CCmax = CC(row_shift,col_shift)*nr*nc;
            % Now change shifts so that they represent relative shifts and not indices
            row_shift = Nr(row_shift);
            col_shift = Nc(col_shift);
        elseif usfac > 1
            % Start with usfac == 2
            CC = ifft2(FTpad(buf1ft.*conj(buf2ft),[2*nr,2*nc]));
            CCabs = abs(CC);
            [row_shift, col_shift] = find(CCabs == max(CCabs(:)),1,'first');
            CCmax = CC(row_shift,col_shift)*nr*nc;
            % Now change shifts so that they represent relative shifts and not indices
            Nr2 = ifftshift(-fix(nr):ceil(nr)-1);
            Nc2 = ifftshift(-fix(nc):ceil(nc)-1);
            row_shift = Nr2(row_shift)/2;
            col_shift = Nc2(col_shift)/2;
            % If upsampling > 2, then refine estimate with matrix multiply DFT
            if usfac > 2
                %%% DFT computation %%%
                % Initial shift estimate in upsampled grid
                row_shift = round(row_shift*usfac)/usfac;
                col_shift = round(col_shift*usfac)/usfac;
                dftshift = fix(ceil(usfac*1.5)/2); %% Center of output array at dftshift+1
                % Matrix multiply DFT around the current shift estimate
                CC = conj(dftups(buf2ft.*conj(buf1ft),ceil(usfac*1.5),ceil(usfac*1.5),usfac,...
                    dftshift-row_shift*usfac,dftshift-col_shift*usfac));
                % Locate maximum and map back to original pixel grid
                CCabs = abs(CC);
                [rloc, cloc] = find(CCabs == max(CCabs(:)),1,'first');
                CCmax = CC(rloc,cloc);
                rloc = rloc - dftshift - 1;
                cloc = cloc - dftshift - 1;
                row_shift = row_shift + rloc/usfac;
                col_shift = col_shift + cloc/usfac;
            end
            
            % If its only one row or column the shift along that dimension has no
            % effect. Set to zero.
            if nr == 1
                row_shift = 0;
            end
            if nc == 1
                col_shift = 0;
            end
            
        end
        
        rg00 = sum(abs(buf1ft(:)).^2, 'omitnan');
        rf00 = sum(abs(buf2ft(:)).^2, 'omitnan');
        error = 1.0 - abs(CCmax).^2/(rg00*rf00);
        error = sqrt(abs(error));
        diffphase = angle(CCmax);
        
        output=[error,diffphase,row_shift,col_shift];
        
        % Compute registered version of buf2ft
        if (nargout > 1)&&(usfac > 0)
            [Nc,Nr] = meshgrid(Nc,Nr);
            Greg = buf2ft.*exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
            Greg = Greg*exp(1i*diffphase);
        elseif (nargout > 1)&&(usfac == 0)
            Greg = buf2ft*exp(1i*diffphase);
        end
        return
    end %For image registration
    function out=dftups(in,nor,noc,usfac,roff,coff)
        % function out=dftups(in,nor,noc,usfac,roff,coff);
        % Upsampled DFT by matrix multiplies, can compute an upsampled DFT in just
        % a small region.
        % usfac         Upsampling factor (default usfac = 1)
        % [nor,noc]     Number of pixels in the output upsampled DFT, in
        %               units of upsampled pixels (default = size(in))
        % roff, coff    Row and column offsets, allow to shift the output array to
        %               a region of interest on the DFT (default = 0)
        % Recieves DC in upper left corner, image center must be in (1,1)
        % Manuel Guizar - Dec 13, 2007
        % Modified from dftus, by J.R. Fienup 7/31/06
        
        % This code is intended to provide the same result as if the following
        % operations were performed
        %   - Embed the array "in" in an array that is usfac times larger in each
        %     dimension. ifftshift to bring the center of the image to (1,1).
        %   - Take the FFT of the larger array
        %   - Extract an [nor, noc] region of the result. Starting with the
        %     [roff+1 coff+1] element.
        
        % It achieves this result by computing the DFT in the output array without
        % the need to zeropad. Much faster and memory efficient than the
        % zero-padded FFT approach if [nor noc] are much smaller than [nr*usfac nc*usfac]
        
        [nr,nc]=size(in);
        % Set defaults
        if exist('roff', 'var')~=1, roff=0;  end
        if exist('coff', 'var')~=1, coff=0;  end
        if exist('usfac','var')~=1, usfac=1; end
        if exist('noc',  'var')~=1, noc=nc;  end
        if exist('nor',  'var')~=1, nor=nr;  end
        % Compute kernels and obtain DFT by matrix products
        kernc=exp((-1i*2*pi/(nc*usfac))*( ifftshift(0:nc-1).' - floor(nc/2) )*( (0:noc-1) - coff ));
        kernr=exp((-1i*2*pi/(nr*usfac))*( (0:nor-1).' - roff )*( ifftshift(0:nr-1) - floor(nr/2)  ));
        out=kernr*in*kernc;
        return
    end %For image registration
    function [ imFTout ] = FTpad(imFT,outsize)
        % imFTout = FTpad(imFT,outsize)
        % Pads or crops the Fourier transform to the desired ouput size. Taking
        % care that the zero frequency is put in the correct place for the output
        % for subsequent FT or IFT. Can be used for Fourier transform based
        % interpolation, i.e. dirichlet kernel interpolation.
        %
        %   Inputs
        % imFT      - Input complex array with DC in [1,1]
        % outsize   - Output size of array [ny nx]
        %
        %   Outputs
        % imout   - Output complex image with DC in [1,1]
        % Manuel Guizar - 2014.06.02
        
        if ~ismatrix(imFT)
            error('Maximum number of array dimensions is 2')
        end
        Nout = outsize;
        Nin = size(imFT);
        imFT = fftshift(imFT);
        center = floor(size(imFT)/2)+1;
        
        imFTout = zeros(outsize);
        centerout = floor(size(imFTout)/2)+1;
        
        % imout(centerout(1)+[1:Nin(1)]-center(1),centerout(2)+[1:Nin(2)]-center(2)) ...
        %     = imFT;
        cenout_cen = centerout - center;
        imFTout(max(cenout_cen(1)+1,1):min(cenout_cen(1)+Nin(1),Nout(1)),max(cenout_cen(2)+1,1):min(cenout_cen(2)+Nin(2),Nout(2))) ...
            = imFT(max(-cenout_cen(1)+1,1):min(-cenout_cen(1)+Nout(1),Nin(1)),max(-cenout_cen(2)+1,1):min(-cenout_cen(2)+Nout(2),Nin(2)));
        
        imFTout = ifftshift(imFTout)*Nout(1)*Nout(2)/(Nin(1)*Nin(2));
        return
        
    end %For image registration
    function [ha, pos] = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
        
        % tight_subplot creates "subplot" axes with adjustable gaps and margins
        %
        % [ha, pos] = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
        %
        %   in:  Nh      number of axes in hight (vertical direction)
        %        Nw      number of axes in width (horizontaldirection)
        %        gap     gaps between the axes in normalized units (0...1)
        %                   or [gap_h gap_w] for different gaps in height and width
        %        marg_h  margins in height in normalized units (0...1)
        %                   or [lower upper] for different lower and upper margins
        %        marg_w  margins in width in normalized units (0...1)
        %                   or [left right] for different left and right margins
        %
        %  out:  ha     array of handles of the axes objects
        %                   starting from upper left corner, going row-wise as in
        %                   subplot
        %        pos    positions of the axes objects
        %
        %  Example: ha = tight_subplot(3,2,[.01 .03],[.1 .01],[.01 .01])
        %           for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
        %           set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')
        
        % Pekka Kumpulainen 21.5.2012   @tut.fi
        % Tampere University of Technology / Automation Science and Engineering
        
        
        if nargin<3; gap = .02; end
        if nargin<4 || isempty(marg_h); marg_h = .05; end
        if nargin<5; marg_w = .05; end
        
        if numel(gap)==1
            gap = [gap gap];
        end
        if numel(marg_w)==1
            marg_w = [marg_w marg_w];
        end
        if numel(marg_h)==1
            marg_h = [marg_h marg_h];
        end
        
        axh = (1-sum(marg_h, 'omitnan')-(Nh-1)*gap(1))/Nh;
        axw = (1-sum(marg_w, 'omitnan')-(Nw-1)*gap(2))/Nw;
        
        py = 1-marg_h(2)-axh;
        
        % ha = zeros(Nh*Nw,1);
        ii = 0;
        for ih = 1:Nh
            px = marg_w(1);
            
            for ix = 1:Nw
                ii = ii+1;
                ha(ii) = axes('Units','normalized', ...
                    'Position',[px py axw axh], ...
                    'XTickLabel','', ...
                    'YTickLabel','');
                px = px+axw+gap(2);
            end
            py = py-axh-gap(1);
        end
        if nargout > 1
            pos = get(ha,'Position');
        end
        ha = ha(:);
    end %For image registration

end
