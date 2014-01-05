function handles = MultiBinLoad(hObject,eventdata,handles,binnames)
 global SR scratchPath  %#ok<NUSED>
 % ----------------------------------------------------
 % Passed Inputs:
 % binnames
 % ----------------------------------------------------
 % % Global Inputs (from SR structure):
 % .LoadOps: structure containing filepaths for data, warps etc
 % .fnames: cell array of names of current data files in display 
 %          (used for display only).
 %------------------------------------------------------
 % Outputs (saved in SR data structure)
 % .mlist:  cell array of all molecule lists loaded for display
 % .infofile: InfoFile structure for dataset (contains stage position,
 %          needed for MosaicView reconstruction).  

% Extract some useful info for later:
    guidata(hObject, handles);
%  Set up title field in display   
SR{handles.gui_number}.fnames = binnames; % display name for the files
% Get infofile #1 for position information
k = strfind(binnames{1},'_'); 
SR{handles.gui_number}.infofile = ...
    ReadInfoFile([SR{handles.gui_number}.LoadOps.pathin,filesep,binnames{1}(1:k(end)-1),'.inf']);

% Load the binfiles 
Tchns = length(binnames);
mlist = cell(Tchns,1); 
for c=1:Tchns
    fullBinName = strcat(SR{handles.gui_number}.LoadOps.pathin,filesep,binnames{c});
    mlist{c} = ReadMasterMoleculeList(fullBinName,'verbose',...
                    SR{handles.gui_number}.DisplayOps.verbose); 
end

    
% Apply global drift correction, then return loaded mlist file.
% Then apply chromewarp.
mlist = MultiChnDriftCorrect(mlist,...
        'correctDrift',SR{handles.gui_number}.LoadOps.correctDrift,...
        'verbose',SR{handles.gui_number}.DisplayOps.verbose);

% Need a warp map.  
if isempty(SR{handles.gui_number}.LoadOps.warpfile)
[FileName,PathName] = uigetfile({'*.mat','Matlab data (*.mat)';...
'*.*','All Files (*.*)'},'Select warpfile',SR{handles.gui_number}.LoadOps.pathin);
SR{handles.gui_number}.LoadOps.warpfile = [PathName,FileName];
end

if isempty([SR{handles.gui_number}.LoadOps.chns{:}])
chns = inputdlg({'Channel Names: (name must match warpmap, order match layer order)'},...
'',1,{'750,647,561,488'});  % <--  Default channel names
SR{handles.gui_number}.LoadOps.chns = parseCSL(chns{1});
end
% Automatically dealing with old or new style chromewarp format
if ~isempty(SR{handles.gui_number}.LoadOps.warpfile)   
[warppath,warpname] = extractpath(SR{handles.gui_number}.LoadOps.warpfile); % detect old style
    if ~isempty(strfind(warpname,'tform'))
        for c=1:length(mlist)
            mlist{c} = chromewarp(SR{handles.gui_number}.LoadOps.chns(c),...
                mlist{c},warppath,'warpD',SR{handles.gui_number}.LoadOps.warpD);
        end        
    else  % Run new style
        mlist = ApplyChromeWarp(mlist,SR{handles.gui_number}.LoadOps.chns,...
            SR{handles.gui_number}.LoadOps.warpfile,...
            'warpD',SR{handles.gui_number}.LoadOps.warpD,...
            'names',SR{handles.gui_number}.fnames);    
    end
else
    disp('warning, no warp file found to align color channels');
end
% Cleanup settings from any previous data and render image:
SR{handles.gui_number}.mlist = mlist; 
ImSetup(hObject,eventdata, handles);
handles = RunClearFilter(hObject,eventdata,handles);
guidata(hObject, handles);
