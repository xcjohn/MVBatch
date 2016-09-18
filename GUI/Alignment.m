function varargout = Alignment(varargin)
% ALIGNMENT M-file for Alignment.fig
%      ALIGNMENT, by itself, creates a new ALIGNMENT or raises the existing
%      singleton*.
%
%      H = ALIGNMENT returns the handle to a new ALIGNMENT or the handle to
%      the existing singleton*.
%
%      ALIGNMENT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALIGNMENT.M with the given input arguments.
%
%      ALIGNMENT('Property','Value',...) creates a new ALIGNMENT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before build3way_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Alignment_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Alignment

% Last Modified by GUIDE v2.5 22-Sep-2014 17:53:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Alignment_OpeningFcn, ...
                   'gui_OutputFcn',  @Alignment_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Alignment is made visible.
function Alignment_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Alignment (see VARARGIN)

% Choose default command line output for Alignment
handles.output = hObject;

if length(varargin)<1, error('Error in the number of arguments.'); end;

handles.ParentsWindow=varargin{1};
handles.ParentFigure = guidata(handles.ParentsWindow);
handles.data.x = handles.ParentFigure.x;

handles.data.type=0;
if iscell(handles.data.x),
    sb=size(handles.data.x);
    sd = size(handles.data.x{1}.data);
    if sb(2)>1 && sb(1)==1 && sd(1)>1
        handles.data.type=1;
    elseif sb(2)>1 && sb(1)==1 && sd(1)==1
        for i=1:sb(2)
             handles.data.synchronization{handles.Stage2Syn}.nor_batches{i} = handles.data.x{i}.data{1}(:,3:end);
        end
        handles.data.stages = numel(unique(handles.data.x{1}.data{1}(:,2)));
        handles.data.type=2;
    end
end

switch handles.data.type,
    case 1,
        enable_EQ('on',handles);
    case 2,
        % Clean the fields and disable the panels corresponding to the
        % other methods (DTW, RGTW), including SCT panel
        enable_DTW('off',handles)
        enable_RGTW('off',handles)
        enable_SCT('off',handles)
        % Disable the equalization panel
        enable_EQ('off',handles);
        % Enable the fields of the form corresponding to the IV
        enable_IV('on',handles);    
        set(handles.popupmenu_alg,'Value',1);
        set(handles.lbUnsyn,'String','');
        for st=1:length(handles.data.stages)
            content = get(handles.lbUnsyn,'String');
            set(handles.lbUnsyn,'String',strvcat(content,num2str(handles.data.stages(st))));
        end
        set(handles.radiobuttonPlotResults,'Enable','on');
        set(handles.text_syn_method,'Enable','on');
        set(handles.popupmenu_alg,'Enable','on');
        set(handles.uib_equalize,'Enable','off');
        set(handles.uib_synchronize,'Enable','on');
        % Create arrays of structures for synchronization based on stage by stage
        %handles.data.synchronization{1}= struct;
        % Create array of flags to determine the stages that have been
        % already synchronized (by default 0 since no stage option is set)
        handles.flagStagesSyn(1) = 0;
        handles.SynStage = false;
        % If there is only a stage, disable the option stages
        if numel(handles.data.stages)==1, set(handles.radiobuttonStages,'Enable','off'); end
        % initialize parameters for IV-based synchronization
        handles.data.synchronization{handles.Stage2Syn}.var = 1;
        handles.data.synchronization{handles.Stage2Syn}.method = 'linear';
        handles.data.synchronization{handles.Stage2Syn}.steps = 100;
        
    otherwise,
        error('Incorrect input data structure.'); 
end

% Set IV the synchronization by default for the first stage
handles.data.synchronization{1}.methodsyn = 'iv';
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Alignment wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Alignment_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  STRUCTURE
%% 
%%  1.- GUI PANEL for DATA INTERPOLATION
%%  2.- SELECTION OF THE APPROACH FOR BATCH SYNCHRONIZATION
%%  3.- GUI PANEL for IV
%%  4.- GUI PANEL for Common parameters of SCT-based methods
%%  5.- GUI PANEL for DTW
%%  6.- GUI PANEL for RGTW
%%  7.- FUNCTIONS TO EQUALIZE AND SYNCHRONIZE BATCH DATA
%%  8.- FUNCTIONS TO CONTROL THE WHOLE GUI
%%  9.- FUNCTION TO MOVE ON THE NEXT MODELING STEP
%%  10.- GUI PANEL for Multi-synchro
%%  11.- MISCELLANEOUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                   1.- GUI PANEL for DATA INTERPOLATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function edit_units_Callback(hObject, eventdata, handles)
% hObject    handle to edit_units (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_units as text
%        str2double(get(hObject,'String')) returns contents of edit_units as a double

handles.data.equalization.units = str2num(get(hObject,'String'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_units_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_units (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

edit_units_Callback(hObject, eventdata, handles)
% --- Executes on selection change in popupmenu_interp.
function popupmenu_interp_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_interp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_interp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_interp

contents = get(hObject,'String');
txt=contents{get(hObject,'Value')};
 
switch txt,
    case ' Nearest Neighbor',
        method = 'nearest';
    case ' Linear',
        method = 'linear';
    case ' Spline',
        method = 'spline';
    case ' Cubic',
        method = 'cubic';
    case ' V5cubic',
        method = 'v5cubic';
end
        
handles.data.equalization.method_interp = method;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_interp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_interp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',2);
popupmenu_interp_Callback(hObject, eventdata, handles)


% --- Executes on selection change in popupmenu_inter.
function popupmenu_inter_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_inter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu_inter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_inter
     
handles.data.equalization.inter = get(hObject,'Value')-1;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_inter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_inter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',2);

popupmenu_inter_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                         2.- SELECTION OF THE APPROACH FOR BATCH SYNCHRONIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in popupmenu_alg.
function popupmenu_alg_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_alg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu_alg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_alg

contents = get(hObject,'String');
txt=contents{get(hObject,'Value')};

set(handles.text_syn_method,'Enable','on');
nVariables = size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2);

switch txt
    case ' Indicator Variable'
        %handles.data.synchronization{handles.Stage2Syn} = struct;
        handles.data.synchronization{handles.Stage2Syn}.methodsyn = 'iv';
        % Disabling the objects from the SCT panel
        enable_SCT('off',handles)
        % Disabling the objects from the DTW panel
        enable_DTW('off',handles);
        % Enabling the objects from the IV panel
        enable_IV('on',handles);
        % Disabling the objects from the RGTW panel
        enable_RGTW('off',handles);   
        % Disabling the objects from the RGTW panel
        enable_MultiSynchro('off',handles);
       
        set(handles.uib_RGTW,'Enable','off');
        set(handles.uite_DTW_Reference,'Enable','off');    
        set(handles.edit_var,'String',1);
        handles.data.synchronization{handles.Stage2Syn}.var = 1;
        set(handles.edit_steps,'String',100);
        handles.data.synchronization{handles.Stage2Syn}.steps = 100;
        set(handles.popupmenu_method,'Value',2);
        handles.data.synchronization{handles.Stage2Syn}.method = 'linear';
        set(handles.radiobutton_cut,'Value',1);
        set(handles.uite_DTW_Weights,'Enable','off');
        
    case ' Dynamic Time Warping'
        %handles.data.synchronization{handles.Stage2Syn} = struct;
        handles.data.synchronization{handles.Stage2Syn}.methodsyn = 'dtw';
        % Enabling the bjects of the SCT panel
        enable_SCT('on',handles)
        % Enabling the objects from the DTW panel
        enable_DTW('on',handles);
        % Disabling the objects from the RGTW panel
        enable_RGTW('off',handles);   
        % Disabling the objects from the IV panel
        enable_IV('off',handles);
        % Disabling the objects from the Multinchro panel
        enable_MultiSynchro('off',handles);
        % Setting parameters to apply off-line DTW synchronization
        handles.data.synchronization{handles.Stage2Syn}.method = 'kass';
        set(handles.uite_DTW_Weights,'String',' ');
        set(handles.uipu_DTW_Weights,'Value',1);
        set(handles.uipu_DTW_Reference,'Value',1);
        set(handles.uite_DTW_Reference,'Enable','off');
        handles.data.synchronization{handles.Stage2Syn}.Bref = -1;
        set(handles.uite_DTW_Reference,'String',' ');
         cprint(handles.uite_DTW_Window,[],[],-1);
        %set(handles.uite_DTW_Window,'String',' ');
        set(handles.editConstraintVariables,'String',num2str(zeros(1,nVariables)));
        handles.data.synchronization{handles.Stage2Syn}.W = ones(nVariables);
        handles.data.synchronization{handles.Stage2Syn}.Wconstr = zeros(nVariables,1);
    case ' Multi-synchro'
        % Disabling the objects from the SCT panel
        enable_SCT('on',handles)
        % Disabling the objects from the DTW panel
        enable_DTW('off',handles);
        % Disabling the objects from the IV panel
        enable_IV('off',handles);
        % Disabling the objects from the RGTW panel
        enable_RGTW('off',handles);   
        % Enabling the objects from the Multisynchro panel
        enable_MultiSynchro('on',handles);
        % Initialize parameters of the GUI
        
        % Parameters of the automatic asynchronism recognition
        set(handles.editFraction,'String',num2str(Inf));
        set(handles.editPsiv,'String',num2str(3));
        set(handles.editPsih,'String',num2str(3));
        set(handles.editPcs,'String',num2str(6));

        handlesGUI = guidata(hObject);editPcs_Callback(handlesGUI.editPcs, eventdata, handlesGUI);
        handlesGUI = guidata(hObject);editFraction_Callback(handlesGUI.editFraction, eventdata, handlesGUI);
        handlesGUI = guidata(hObject);editPsiv_Callback(handlesGUI.editPsiv, eventdata, handlesGUI);
        handlesGUI = guidata(hObject);editPsih_Callback(handlesGUI.editPsih, eventdata, handlesGUI);
        handlesGUI = guidata(hObject);
        
        % Parameters of the manual asynchornism recognition
        set(handles.editTypeAsynchronisms,'String','1'); handles.TypeAsyn = 1;
        set(handles.editBatches,'String',strcat('1:',num2str(length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)))); handles.AsynBatches =  1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches);
        handles.selectedAsyn = 1;
        
        eventdata.EventName = 'SelectionChanged';
        eventdata.NewValue = handles.radiobuttonAutomatic;
        uipanelMultiSynchrpParameters_SelectionChangeFcn(handles.radiobuttonAutomatic, eventdata, handles)
        
        % Enable common GUI objects for the different synchronization
        % methods
        set(handles.listboxAsynchronisms,'String','');
        set(handles.uite_DTW_Weights,'String',' ');
        set(handles.uipu_DTW_Weights,'Value',1);
        set(handles.uipu_DTW_Reference,'Value',1);
        set(handles.uite_DTW_Reference,'Enable','off');
        set(handles.uite_DTW_Reference,'String',' ');
         cprint(handles.uite_DTW_Window,[],[],-1);
%         set(handles.uite_DTW_Window,'String',' ');
        set(handles.editConstraintVariables,'String',num2str(zeros(1,nVariables)));
        
        % Setting parameters to apply Multi-synchro
        handles.data.synchronization{handles.Stage2Syn}.methodsyn = 'multisynchro';
        handles.data.synchronization{handles.Stage2Syn}.method = 'nomethod';
        handles.data.synchronization{handles.Stage2Syn}.Bref = -1; 
        handles.data.synchronization{handles.Stage2Syn}.W = ones(nVariables,1);
        handles.data.synchronization{handles.Stage2Syn}.Wconstr = zeros(nVariables,1);
        handles.data.synchronization{handles.data.stages}.param = handlesGUI.data.synchronization{handles.data.stages}.param;
end

set(handles.pushbuttonCalibration,'Enable','off');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_alg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_alg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

guidata(hObject,handles);

% --- Executes on button press in radiobuttonPlotResults.
function radiobuttonPlotResults_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonPlotResults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in radiobuttonStages.
function returnv = radiobuttonStages_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonStages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonStages

value = get(hObject,'Value');
returnv = false;

if ~isempty(find(handles.flagStagesSyn==1))
    % Construct a questdlg with three options
    choice = questdlg('Synchronization has been performed in some or all stages. If you continue, previous synchronizations will be removed. Do you want to continue?', ...
        'Yes', ...
        'No');
    % Handle response
    switch choice
        case 'Yes'
            if ~value
                handles.data.synchronization{1}= struct;
                handles.flagStagesSyn = 0;
            else
                for i=1:numel(handles.data.stages)
                    handles.data.synchronization{i}= struct;
                end
                 handles.flagStagesSyn = zeros(numel(handles.data.stages),1);
            end
            handles.handles.Stage2Syn = 1;
        case 'No'
            returnv = true;
            return;
        otherwise
            returnv = true;
            return;                
    end 
else
    if ~value
        handles.data.synchronization{1}= struct;
        handles.flagStagesSyn = 0;
    else
        for i=1:numel(handles.data.stages)
            handles.data.synchronization{i}= struct;
        end
         handles.flagStagesSyn = zeros(numel(handles.data.stages),1);
    end
    handles.handles.Stage2Syn = 1;
        
end    

if value 
    set(handles.lbUnsyn,'Enable','on');
    set(handles.lbSyn,'Enable','on');
    set(handles.lbSyn,'String','');
    set(handles.lbUnsyn,'String','');
    for st=1:length(handles.data.stages)
        content = get(handles.lbUnsyn,'String');
        set(handles.lbUnsyn,'String',strvcat(content,num2str(handles.data.stages(st))));
    end
    handles.SynStage = 1;
    handles.Stage2Syn = 1;
    
else
    set(handles.lbUnsyn,'Enable','off');
    set(handles.lbSyn,'Enable','off'); 
    handles.SynStage = 0;
end

popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles)
% Retrieve data from the handles updated by the previous call
handles=guidata(handles.output);

guidata(hObject,handles);

% --- Executes on selection change in lbUnsyn.
function lbUnsyn_Callback(hObject, eventdata, handles)
% hObject    handle to lbUnsyn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbUnsyn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbUnsyn

contents = cellstr(get(hObject,'String'));
handles.Stage2Syn = str2num(contents{get(hObject,'Value')});
popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function lbUnsyn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbUnsyn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.Stage2Syn = 1;
guidata(hObject,handles);

% --- Executes on selection change in lbSyn.
function lbSyn_Callback(hObject, eventdata, handles)
% hObject    handle to lbSyn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbSyn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbSyn

contents = cellstr(get(hObject,'String'));
handles.StageSyn = contents{get(hObject,'Value')};

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function lbSyn_CreateFcn(hObject, ~, handles)
% hObject    handle to lbSyn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.StageSyn = 0;
guidata(hObject,handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                   3.- GUI PANEL for IV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popupmenu_method.
function popupmenu_method_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu_method contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_method

contents = get(hObject,'String');
txt=contents{get(hObject,'Value')};
 
switch txt,
    case ' Nearest Neighbor',
        method = 'nearest';
    case ' Linear',
        method = 'linear';
    case ' Spline',
        method = 'spline';
    case ' Cubic',
        method = 'cubic';
    case ' V5cubic',
        method = 'v5cubic';
end
        
handles.data.synchronization{handles.Stage2Syn}.method = method;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_method_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',2);

% --- Executes on button press in radiobutton_cut.
function radiobutton_cut_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_cut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function edit_steps_Callback(hObject, eventdata, handles)
% hObject    handle to edit_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_steps as text
%        str2double(get(hObject,'String')) returns contents of edit_steps as a double

handles.data.synchronization{handles.Stage2Syn}.steps = str2num(get(hObject,'String'));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_steps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_steps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_var_Callback(hObject, eventdata, handles)
% hObject    handle to edit_var (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_var as text
%        str2double(get(hObject,'String')) returns contents of edit_var as a double

handles.data.synchronization{handles.Stage2Syn}.var = str2num(get(hObject,'String'));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_var_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_var (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                  4.- GUI PANEL for Common parameters of SCT-based methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function editConstraintVariables_Callback(hObject, eventdata, handles)
% hObject    handle to editConstraintVariables (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editConstraintVariables as text
%        str2double(get(hObject,'String')) returns contents of editConstraintVariables as a double

nVariables = size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2);

Wconstr = str2num(get(hObject,'string'))';
if size(Wconstr,1) ~= nVariables
        formats = [];
        for i=1:nVariables
            formats = [formats '%d '];
        end
    set(handles.editConstraintVariables,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.Wconstr));      
    errordlg('The number of constraints differs from the number of variables. Please, introduce as many constraints as process variables.','File Error'); return;
end
if numel(find(Wconstr==0)) + numel(find(Wconstr==1)) ~= nVariables,
    formats = [];
    for i=1:nVariables
        formats = [formats '%d '];
    end
    set(handles.editConstraintVariables,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.Wconstr)); 
    errordlg('The constraints must be binary numbers. One values stand for variables contrained, i.e. variables that are not taken into account in the batch synchronization, ','File Error'); 
    return;
end

if sum(Wconstr)==0, errordlg('To proceed with the synchronization of the batch trajectories, one process variable is at least required to be weighted.','File Error'); return;  end

if strcmp(handles.data.synchronization{handles.Stage2Syn}.method,'nomethod')
    if sum(Wconstr-handles.data.synchronization{handles.Stage2Syn}.Wconstr) ~= 0
        % Construct a questdlg with three options
        choice = questdlg('Are you sure of introducing new constraints', ...
            'Yes', ...
            'No');
        % Handle response
        switch choice
            case 'Yes'
                 handles.data.synchronization{handles.Stage2Syn}.Wconstr = Wconstr; 
            case 'No'
                formats = [];
                for i=1:nVariables
                     formats = [formats '%d '];
                end
                set(handles.editConstraintVariables,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.Wconstr));
                return;
            otherwise
                formats = [];
                for i=1:nVariables
                     formats = [formats '%d '];
                end
                set(handles.editConstraintVariables,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.Wconstr));
                return;                
        end
        NonconstrainedVars = find(Wconstr==0);
        handles.data.synchronization{handles.Stage2Syn}.W = zeros(nVariables,1);
        handles.data.synchronization{handles.Stage2Syn}.W(NonconstrainedVars) = nVariables/numel(NonconstrainedVars); 
        formats = [];
        for i=1:nVariables
            formats = [formats '%0.3f '];
        end
        set(handles.uite_DTW_Weights,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.W));
    end
end

handles.data.synchronization{handles.Stage2Syn}.Wconstr = Wconstr;
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editConstraintVariables_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editConstraintVariables (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function uite_DTW_Reference_Callback(hObject, eventdata, handles)
% hObject    handle to uite_DTW_Reference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of uite_DTW_Reference as text
%        str2double(get(hObject,'String')) returns contents of uite_DTW_Reference as a double

ref = str2num(get(hObject,'String'));

if ref< 0 || ref > size(handles.data.synchronization{handles.Stage2Syn}.nor_batches,2)
    errordlg('The reference introduced is not correct. This reference batch does not exist. The first batch will be selected as reference in case no another criterium of selection is chosen.','File Error');  
    handles.data.synchronization{handles.Stage2Syn}.Bref = 1; 
    set(hObject,'String',num2str(handles.data.synchronization{handles.Stage2Syn}.Bref));
else
    handles.data.synchronization{handles.Stage2Syn}.Bref = ref;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function uite_DTW_Reference_CreateFcn(hObject, ~, handles)
% hObject    handle to uite_DTW_Reference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in uipu_DTW_Reference.
function uipu_DTW_Reference_Callback(hObject, eventdata, handles)
% hObject    handle to uipu_DTW_Reference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns uipu_DTW_Reference contents as cell array
%        contents{get(hObject,'Value')} returns selected item from uipu_DTW_Reference
contents = get(hObject,'String');
txt=contents{get(hObject,'Value')};

set(handles.uite_DTW_Reference,'String',' ');
set(handles.uite_DTW_Reference,'Enable','off');
 
switch txt,
    case 'Median',
        handles.data.synchronization{handles.Stage2Syn}.Bref = refBatch(handles.data.synchronization{handles.Stage2Syn}.nor_batches,'median');        
    case 'Average'
        handles.data.synchronization{handles.Stage2Syn}.Bref = refBatch(handles.data.synchronization{handles.Stage2Syn}.nor_batches,'average');        
    case 'Select'
        set(handles.uite_DTW_Reference,'Enable','on'); 
       handles.data.synchronization{handles.Stage2Syn}.Bref = 1;
        set(handles.uite_DTW_Reference,'String',num2str(1));
end
        
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function uipu_DTW_Reference_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipu_DTW_Reference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                     5.- GUI PANEL for DTW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in uipu_DTW_Weights.
function uipu_DTW_Weights_Callback(hObject, eventdata, handles)
% hObject    handle to uipu_DTW_Weights (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns uipu_DTW_Weights contents as cell array
%        contents{get(hObject,'Value')} returns selected item from uipu_DTW_Weights
contents = get(hObject,'String');
txt=contents{get(hObject,'Value')};

set(handles.uite_DTW_Weights,'Enable','off');
set(handles.uite_DTW_Weights,'String',' ');

handles.data.synchronization{handles.Stage2Syn}.cv = 0;
enable_RGTW('off',handles);
set(handles.uib_RGTW,'Enable','off');
    
switch txt,
    case 'Kassidas',
        method = 'kass';
    case 'Ramaker'
        method = 'ram';       
    case 'Geo. average'
        method = 'geo';        
    case 'Select'
        method = 'nomethod';
        set(handles.uite_DTW_Weights,'Enable','on');
        nVariables = size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2);
        % Check if there are variables constrained for batch
        % synchronization. If so, estimate the weights properly.
        NonconstrainedVars = find(handles.data.synchronization{handles.Stage2Syn}.Wconstr==0);
        formats = [];
        for i=1:nVariables
            formats = [formats '%0.3f '];
        end
        if ~isempty(NonconstrainedVars)          
            handles.data.synchronization{handles.Stage2Syn}.W = zeros(nVariables,1);
            handles.data.synchronization{handles.Stage2Syn}.W(NonconstrainedVars) = nVariables/numel(NonconstrainedVars);
            set(handles.uite_DTW_Weights,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.W));
        else
            set(handles.uite_DTW_Weights,'String',sprintf(formats,num2str(ones(1,nVariables).*1.0)));
        end
    otherwise
        handles.data.synchronization{handles.Stage2Syn}.W = ones(nVariables,1);
end

handles.data.synchronization{handles.Stage2Syn}.method = method;        
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function uipu_DTW_Weights_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipu_DTW_Weights (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function uite_DTW_Weights_Callback(hObject, eventdata, handles)
% hObject    handle to uite_DTW_Weights (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of uite_DTW_Weights as text
%        str2double(get(hObject,'String')) returns contents of uite_DTW_Weights as a double

W = str2num(get(hObject,'string'))';
nVariables = size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2);

if size(W,1) ~= nVariables || sum(W)-nVariables > .01 || sum(W)-nVariables < -0.01
    errordlg('The number of weights or the values of weights are incorrect. Please, introduce the synchronization weights again.','File Error');
    formats = [];
    for i=1:nVariables
        formats = [formats '%0.3f '];
    end
    set(handles.uite_DTW_Weights,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.W));
    return;
end

constrainedVars = find(handles.data.synchronization{handles.Stage2Syn}.Wconstr==1);
if ~isempty(constrainedVars)
    if sum(W(constrainedVars)) ~= 0
        errordlg('One or more process variables are constrained, however certain weight has given to them. Please, introduce the synchronization weights again.','File Error'); 
        formats = [];
        for i=1:nVariables
            formats = [formats '%0.3f '];
        end
        set(handles.uite_DTW_Weights,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.W));
        return;
    end
end

if ~isequal(find(W==0),find(handles.data.synchronization{handles.Stage2Syn}.Wconstr==1))
    errordlg('One or more process variables are not constrained but have a weight equal to zero. Please, introduce the synchronization weights again.','File Error'); 
    formats = [];
    for i=1:nVariables
        formats = [formats '%0.3f '];
    end
    set(handles.uite_DTW_Weights,'String',sprintf(formats,handles.data.synchronization{handles.Stage2Syn}.W));
    return;
end

handles.data.synchronization{handles.Stage2Syn}.W = W; 
    
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function uite_DTW_Weights_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uite_DTW_Weights (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                     6- GUI PANEL for RGTW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function uite_DTW_Window_Callback(hObject, eventdata, handles)
% hObject    handle to uite_DTW_Window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function uite_DTW_Window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uite_DTW_Window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function uite_RGTW_Window_Callback(hObject, eventdata, handles)
% hObject    handle to uite_RGTW_Window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of uite_RGTW_Window as text
%        str2double(get(hObject,'String')) returns contents of uite_RGTW_Window as a double

cvwvalue = str2num(get(hObject,'String'));

if handles.data.synchronization{handles.Stage2Syn}.cv ==1
  handles.data.synchronization{handles.Stage2Syn}.cvwvalue = cvwvalue;
  handles.data.synchronization{handles.Stage2Syn}.band = estimationBD(handles.data.synchronization{handles.Stage2Syn}.rgtwWARPS{cvwvalue}, size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref},1), handles.data.synchronization{handles.Stage2Syn}.maxi);
  
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function uip_DTW_Par_Syn_Selection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uip_DTW_Par_Syn_Selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

guidata(hObject,handles);

% --- Executes when selected object is changed in uip_DTW_Par_Syn_Selection.
function uip_DTW_Par_Syn_Selection_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uip_DTW_Par_Syn_Selection 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag')   % Get Tag of selected object
    case 'uirb_DTW_Par_Syn_cv'
         handles.data.synchronization{handles.Stage2Syn}.cv = 1;
         set(handles.text_maximum,'Enable','on');
         set(handles.text_zeta,'Enable','on');
         set(handles.popmenu_zeta_cv,'Enable','on');
         set(handles.popmenu_zeta_cv,'Value',1);
         set(handles.uib_validate,'Enable','on');
         set(handles.text_rgtw,'Enable','off');
         set(handles.text_dtw_ww,'Enable','off');
         set(handles.popupmenu_zeta,'Enable','off');
         set(handles.uib_RGTW,'Enable','off');
         
    case 'uirb_DTW_Par_Syn_off'
        handles.data.synchronization{handles.Stage2Syn}.cv = 0;
         set(handles.text_maximum,'Enable','off');
         set(handles.text_zeta,'Enable','off');
         set(handles.popmenu_zeta_cv,'Value',1);
         set(handles.popmenu_zeta_cv,'Enable','off');
         set(handles.uib_validate,'Enable','off');
         set(handles.text_rgtw,'Enable','on');
         set(handles.text_dtw_ww,'Enable','on');
         set(handles.popupmenu_zeta,'Enable','on');
         contents = [];
        for i=1:15
            contents=strvcat(contents,num2str(i)); 
        end
        set(handles.popupmenu_zeta,'String',' '); 
        set(handles.popupmenu_zeta,'String',contents); 
         set(handles.uib_RGTW,'Enable','on');
    otherwise
        errordlg('An error has been occurred. Please, send a sms to the software administrator','Error Dialog','modal');
end
    set(handles.popmenu_zeta_cv,'String',num2cell([1:15]'));
    % Update handles structure
    guidata(hObject,handles);

    % --- Executes on selection change in popupmenu_zeta.
function popupmenu_zeta_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_zeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function popupmenu_zeta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_zeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popmenu_zeta_cv.
function popmenu_zeta_cv_Callback(hObject, eventdata, handles)
% hObject    handle to popmenu_zeta_cv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function popmenu_zeta_cv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popmenu_zeta_cv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in uib_validate.
function uib_validate_Callback(hObject, eventdata, handles)
% hObject    handle to uib_validate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
contents = get(handles.popmenu_zeta_cv,'String');
handles.data.synchronization{handles.Stage2Syn}.zetacv=str2num(contents{get(handles.popmenu_zeta_cv,'Value')});

[handles.data.synchronization{handles.Stage2Syn}.rgtwWARPS, handles.data.synchronization{handles.Stage2Syn}.rgtw_r] = cvBands(handles.data.synchronization{handles.Stage2Syn}.nor_batches,diag(handles.data.synchronization{handles.Stage2Syn}.W),handles.data.synchronization{handles.Stage2Syn}.band,...
    handles.data.synchronization{handles.Stage2Syn}.Bref,handles.data.synchronization{handles.Stage2Syn}.warpingOri',handles.data.synchronization{handles.Stage2Syn}.zetacv,handles,hObject);

% Analysis of Variance on the Fisher Z-transformed correlation coefficients
if handles.data.synchronization{handles.Stage2Syn}.zetacv > 1
    [~,~,st] = anova1(atan(handles.data.synchronization{handles.Stage2Syn}.rgtw_r'));
    figure;
    multcompare(st,'display','on'); 
end

contents = [];
for i=1:handles.data.synchronization{handles.Stage2Syn}.zetacv
    contents=strvcat(contents,num2str(i)); 
end
set(handles.popupmenu_zeta,'String',' '); 
set(handles.popupmenu_zeta,'String',contents);


set(handles.text_rgtw,'Enable','on');
set(handles.text_dtw_ww,'Enable','on');
set(handles.popupmenu_zeta,'Enable','on');
set(handles.popupmenu_zeta,'Value',1);
set(handles.uib_RGTW,'Enable','on');
  
guidata(hObject,handles);

save trash.mat

% --- Executes on button press in uib_RGTW.
function uib_RGTW_Callback(hObject, eventdata, handles)
% hObject    handle to uib_RGTW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Setting the window width to be used in on-line synchronization using the
% RGTW algorithm

 contents = get(handles.popupmenu_zeta,'String');
 handles.data.synchronization{handles.Stage2Syn}.zeta=str2num(contents(get(handles.popupmenu_zeta,'Value'),:));
 
 if get(handles.radiobuttonPlotResults,'Value')
    figure;
    if handles.data.synchronization{handles.Stage2Syn}.cv == 1  
        handles.data.synchronization{handles.Stage2Syn}.band = estimationBD(handles.data.synchronization{handles.Stage2Syn}.rgtwWARPS{handles.data.synchronization{handles.Stage2Syn}.zeta}, size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref},1), handles.data.synchronization{handles.Stage2Syn}.maxi);
        plot(handles.data.synchronization{handles.Stage2Syn}.rgtwWARPS{handles.data.synchronization{handles.Stage2Syn}.zeta},'k-'); hold on;
    else
        plot(handles.data.synchronization{handles.Stage2Syn}.warp,'k-'); hold on;       
        handles.data.synchronization{handles.Stage2Syn}.band = handles.data.synchronization{handles.Stage2Syn}.band_aux;
    end
    if get(handles.radiobuttonPlotResults,'Value')
        plot(handles.data.synchronization{handles.Stage2Syn}.band,'r-','LineWidth',1.5)
        axis tight
    end
    xlabel('Reference batch sampling point','FontSize',12,'FontWeight','bold');
    ylabel('Test batch sampling point','FontSize',12,'FontWeight','bold');
 end  
 
 % Estimation of the synchronized data to be used in the subsequent
 % multivariate analysis using the selected warping window width zeta.
 
 Bref = scale_(handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref},handles.data.synchronization{handles.Stage2Syn}.rng);
 sr = size(Bref);
 
 handles.data.synchronization{handles.Stage2Syn}.alg_batches  = zeros(size(handles.data.synchronization{handles.Stage2Syn}.alg_batches));
 warp = zeros(sr(1),length(handles.data.synchronization{handles.Stage2Syn}.nor_batches));
 
for l=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
    [Sn,warp(:,l)] = onSyn(handles.data.synchronization{handles.Stage2Syn}.nor_batches{l},Bref, handles.data.synchronization{handles.Stage2Syn}.band,diag(handles.data.synchronization{handles.Stage2Syn}.W), handles.data.synchronization{handles.Stage2Syn}.zeta, handles.data.synchronization{handles.Stage2Syn}.rng);
    st = size(Sn);
%    xrec = reconstructX([warp(1:st(1),l) Sn],t,p,pcs,M,Sstd);
%    handles.data.synchronization{handles.Stage2Syn}.warp(:,l) = [warp(1:st(1),l); xrec(st(1)+1:end,1)];
%    handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,l) = [handles.data.synchronization{handles.Stage2Syn}.warp(:,l) [Sn(1:st(1),:); xrec(st(1)+1:end,2:end)]];
    handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,l) = [handles.data.synchronization{handles.Stage2Syn}.warp(:,l) [Sn; repmat(Sn(st(1),:), sr(1)-st(1),1)]];
end

 %handles.data.synchronization{handles.Stage2Syn}.warp = warp;

if get(handles.radiobuttonPlotResults,'Value')
    plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches);
end
  
% Once RGTW-synchronization has been performed, we set to 1 the
% corresponding stage at the Stages vector to know that it has been
% already synchronized.
handles.flagStagesSyn(handles.Stage2Syn) = 1;

if handles.SynStage
    % Remove the stage from the pending one to be synchronized and add it
    % to the list of the stages already synchronized.
    set(handles.lbUnsyn,'String','');
    set(handles.lbUnsyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==0))));

    set(handles.lbSyn,'String','');
    set(handles.lbSyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==1))));

    if isempty(find(handles.flagStagesSyn==0))
        set(handles.pushbuttonCalibration,'Enable','on');
        guidata(hObject, handles);
    else
        handles.Stage2Syn = handles.data.stages(find(handles.flagStagesSyn==0,1,'first'));
        %handles.StageSyn = handles.data.stages(find(handles.flagStagesSyn==1,1,'first'));
        % Disabling the objects from the RGTW panel
        enable_RGTW('off',handles)
        % Set parameters for next stage
        popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
        % Retrieve data from the handles updated by the previous call
        handles=guidata(handles.output);
    end
end

if isempty(find(handles.flagStagesSyn==0))
    set(handles.pushbuttonCalibration,'Enable','on');
    guidata(hObject, handles);
else
    handles.Stage2Syn = handles.data.stages(find(handles.flagStagesSyn==0,1,'first'));
    % Set parameters for next stage
    set(handles.popupmenu_alg,'Value',2);
    popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
    % Retrieve data from the handles updated by the previous call
    handles=guidata(handles.output);
end
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                             7.- FUNCTIONS TO EQUALIZE AND SYNCHRONIZE BATCH DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in uib_equalize.
function uib_equalize_Callback(hObject, eventdata, handles)
% hObject    handle to uib_equalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.data.synchronization{handles.Stage2Syn}.nor_batches = arrange2D(handles.data.x,handles.data.equalization.inter,handles.data.equalization.units,handles.data.equalization.method_interp);
for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches),
    handles.data.synchronization{handles.Stage2Syn}.nor_batches{i} =  handles.data.synchronization{handles.Stage2Syn}.nor_batches{i}(:,3:end);
end

% Enabling some objects of the user interface
set(handles.text_syn_method,'Enable','on');
set(handles.popupmenu_alg,'Enable','on');
set(handles.popupmenu_alg,'Value',1);
set(handles.uib_synchronize,'Enable','on');
% Setting the variable of the synchronization method to 'iv' (IV)
handles.data.synchronization{1}.methodsyn = 'iv';

% Disabling the objects from the SCT panel
enable_SCT('off',handles)
% Disabling the objects from the DTW panel
enable_DTW('off',handles);
% Enabling the objects from the IV panel
enable_IV('on',handles);
% Disabling the objects from the RGTW panel
enable_RGTW('off',handles)
% Enabling the objects from the RGTW panel
enable_MultiSynchro('off',handles);
handles.data.synchronization{handles.Stage2Syn}.cv = 0;
set(handles.uib_RGTW,'Enable','off');
% Removing the information shown in the information window
 cprint(handles.uite_DTW_Window,[],[],-1);
% set(handles.uite_DTW_Window,'String',' ');

% Setting the parameters for IV synchronization
set(handles.edit_var,'String',1);
handles.data.synchronization{1}.var = 1;
set(handles.edit_steps,'String',100);
handles.data.synchronization{1}.steps = 100;
set(handles.popupmenu_method,'Value',2);
handles.data.synchronization{1}.method = 'linear';
set(handles.radiobutton_cut,'Value',1);

guidata(hObject,handles);

% --- Executes on button press in uib_synchronize.
function uib_synchronize_Callback(hObject, eventdata, handles)
% hObject    handle to uib_synchronize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(find(handles.flagStagesSyn==0)) && handles.SynStage
   returnv = radiobuttonStages_Callback(handles.radiobuttonStages, eventdata, handles);
   % Retrieve data from the handles updated by the previous call
    handles=guidata(handles.output);
    guidata(hObject,handles);
    if returnv, return; end
end
    
if ~isfield(handles.data.synchronization{handles.Stage2Syn},'nor_batches')
    handles.data.synchronization{handles.Stage2Syn}.nor_batches = handles.data.x;
end

% if handles.SynStage
%     handles.data.synchronization{handles.Stage2Syn}.nor_batches = SplitStage(handles.data.synchronization{handles.Stage2Syn}.nor_batches,handles.Stage2Syn);
% else
%     handles.data.synchronization{handles.Stage2Syn}.nor_batches = SplitStage(handles.data.synchronization{handles.Stage2Syn}.nor_batches);
% end
    Stage2Syn = handles.Stage2Syn;



if strcmp(handles.data.synchronization{handles.Stage2Syn}.methodsyn,'dtw')
   
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    %%                                                                         DTW
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Store the reference batch that is going to be used for synchronization
    if handles.data.synchronization{handles.Stage2Syn}.Bref == -1, handles.data.synchronization{handles.Stage2Syn}.Bref = refBatch(handles.data.synchronization{handles.Stage2Syn}.nor_batches,'median');end
    handles.data.synchronization{handles.Stage2Syn}.Xref = handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref};

    % Disabling the panel corresponding to the RGTW panel. Firstly, off-line synchronization based on DTW must be performed.
    handles.data.synchronization{handles.Stage2Syn}.cv = 0;
    handles.data.synchronization{handles.Stage2Syn}.alg_batches = [];

    % GUI actions
    enable_RGTW('off',handles);
    set(handles.uib_RGTW,'Enable','off');
      
    switch handles.data.synchronization{handles.Stage2Syn}.method
        case 'kass'
            
            cprint(handles.uite_DTW_Window,'Synchronizing...Be patient, please.',[],0);
                        
%             set(handles.uite_DTW_Window,'String','');
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing...Be patient, please.', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);
            
            % Synchronize the batch trajectories using the procedure proposed by Kassidas et al.
            [handles.data.synchronization{handles.Stage2Syn}.W, alg_batches, handles.data.synchronization{handles.Stage2Syn}.warp, handles.data.synchronization{handles.Stage2Syn}.rng, handles.data.synchronization{handles.Stage2Syn}.warpingOri,flag] = DTW_Kassidas(handles.data.synchronization{handles.Stage2Syn}.nor_batches,handles.data.synchronization{handles.Stage2Syn}.Xref,handles.data.synchronization{handles.Stage2Syn}.Wconstr);
            if flag, return;end
            
            handles.data.synchronization{handles.Stage2Syn}.alg_batches = zeros(size(alg_batches,1),size(alg_batches,2)+1,size(alg_batches,3));
            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                     handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,i)= [handles.data.synchronization{handles.Stage2Syn}.warp(:,i) squeeze(alg_batches(:,:,i))];
            end
            
            cprint(handles.uite_DTW_Window,'Synchronization finished');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronization finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);
        case 'ram'
            
            cprint(handles.uite_DTW_Window,'Synchronizing...Be patient, please.',[],0);
%             set(handles.uite_DTW_Window,'String','');
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing...Be patient, please.', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);
            
            % Synchronize the batch trajectories using the procedure proposed by Ramaker et al.
            [handles.data.synchronization{handles.Stage2Syn}.W, alg_batches, handles.data.synchronization{handles.Stage2Syn}.warp, handles.data.synchronization{handles.Stage2Syn}.rng,handles.data.synchronization{handles.Stage2Syn}.warpingOri] = DTW_Ramaker(handles.data.synchronization{handles.Stage2Syn}.nor_batches, handles.data.synchronization{handles.Stage2Syn}.Xref,handles.data.synchronization{handles.Stage2Syn}.Wconstr);            
            
            handles.data.synchronization{handles.Stage2Syn}.alg_batches = zeros(size(alg_batches,1),size(alg_batches,2)+1,size(alg_batches,3));
            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                     handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,i)= [handles.data.synchronization{handles.Stage2Syn}.warp(:,i) squeeze(alg_batches(:,:,i))];
            end
            cprint(handles.uite_DTW_Window,'Synchronization finished');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronization finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);
        case 'geo'
            cprint(handles.uite_DTW_Window,'It takes some time. Please, be patient.',[],0);
            cprint(handles.uite_DTW_Window,'Synchronizing... (Kassidas approach)');
%             set(handles.uite_DTW_Window,'String','');
%             set(handles.uite_DTW_Window,'String',strvcat('It takes some time. Please, be patient.', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing... (Kassidas approach)', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);
            
             % Synchronize the batch trajectories using the classical DTW with the weights estimated as the geometric mean of Kassidas et al. and Ramaker et al.'s approach
            Wkass = DTW_Kassidas(handles.data.synchronization{handles.Stage2Syn}.nor_batches, handles.data.synchronization{handles.Stage2Syn}.Xref);
            
            cprint(handles.uite_DTW_Window,'Synchronization (Kassidas approach) finished');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronization (Kassidas approach) finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);

            cprint(handles.uite_DTW_Window,'Synchronizing... (Ramaker approach)');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing... (Ramaker approach)', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);

            Wram  = DTW_Ramaker(handles.data.synchronization{handles.Stage2Syn}.nor_batches, handles.data.synchronization{handles.Stage2Syn}.Xref);

            cprint(handles.uite_DTW_Window,'Synchronization (Ramaker approach) finished');
%             set(handles.uite_DTW_Window,'String',strvcat( 'Synchronization (Ramaker approach) finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));
%             pause(0.01);

            % Estimating the geometric average between Kassidas et al. and Ramaker et al.'s weights
            handles.data.synchronization{handles.Stage2Syn}.W = sqrt(Wram.*Wkass)/sum(sqrt(Wram.*Wkass))*size(Wkass,1);

            % Scaling all batches at mean range, including the reference batch
            [X,handles.data.synchronization{handles.Stage2Syn}.rng]= scale_(handles.data.synchronization{handles.Stage2Syn}.nor_batches);

            % Synchronizing the batch trajectories using DTW and the weight matrix W
            cprint(handles.uite_DTW_Window,'Synchronizing... (classical DTW)');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing... (classical DTW)', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), '')); pause(0.01);
            warp = zeros(size(X{handles.data.synchronization{handles.Stage2Syn}.Bref},1),length(handles.data.synchronization{handles.Stage2Syn}.nor_batches));
            warpingOri = cell(length(handles.data.synchronization{handles.Stage2Syn}.nor_batches),1);
            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                [alg_batches{i}, warp(:,i), warpingOri{i}]= DTW(X{i},X{handles.data.synchronization{handles.Stage2Syn}.Bref},diag(handles.data.synchronization{handles.Stage2Syn}.W),0, handles.data.synchronization{handles.Stage2Syn}.Wconstr);
            end
            handles.data.synchronization{handles.Stage2Syn}.warp = warp;
            handles.data.synchronization{handles.Stage2Syn}.warpingOri = warpingOri;
            
            cprint(handles.uite_DTW_Window,'Synchronization finished');
            
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronization finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));  pause(0.01);

            % Unscaling the batch trajectories
            handles.data.synchronization{handles.Stage2Syn}.alg_batches = zeros(size(alg_batches{1},1),size(alg_batches{1},2)+1,size(alg_batches{1},3));
            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,1,i)= handles.data.synchronization{handles.Stage2Syn}.warp(:,i);
                for j=1:size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2)
                     handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,j+1,i)=alg_batches{i}(:,j).*handles.data.synchronization{handles.Stage2Syn}.rng(j);
                end
            end
            %handles.data.dtw.cv = 1;
            
        case 'nomethod'
            uite_DTW_Weights_Callback(handles.uite_DTW_Weights, eventdata, handles);
            if size(handles.data.synchronization{handles.Stage2Syn}.W,1) ~= size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2) || sum(handles.data.synchronization{handles.Stage2Syn}.W)-size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2) > .001 || sum(handles.data.synchronization{handles.Stage2Syn}.W)-size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2) < -0.001, return; end
            
             % Scaling all batches at mean range, including the reference batch
            [X handles.data.synchronization{handles.Stage2Syn}.rng]= scale_(handles.data.synchronization{handles.Stage2Syn}.nor_batches);

            cprint(handles.uite_DTW_Window,'Synchronizing... (classical DTW)',[],0);
            
%             set(handles.uite_DTW_Window,'String','');
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronizing... (classical DTW)', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), '')); pause(0.01);

            warp = zeros(size(X{handles.data.synchronization{handles.Stage2Syn}.Bref},1),length(handles.data.synchronization{handles.Stage2Syn}.nor_batches));
            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                [Syn{i}, warp(:,i),handles.data.synchronization{handles.Stage2Syn}.warpingOri{i}] = DTW(X{i},X{handles.data.synchronization{handles.Stage2Syn}.Bref},diag(handles.data.synchronization{handles.Stage2Syn}.W),0,handles.data.synchronization{handles.Stage2Syn}.Wconstr);
            end
            handles.data.synchronization{handles.Stage2Syn}.warp= warp;

            handles.data.synchronization{handles.Stage2Syn}.alg_batches = zeros(size(Syn{1},1),size(Syn{1},2)+1,length(handles.data.synchronization{handles.Stage2Syn}.nor_batches));

            for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
                 for j=1:size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{1},2)
                    alg_batches{i}(:,j)=Syn{i}(:,j).*handles.data.synchronization{handles.Stage2Syn}.rng(j);
                end
                handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,i) = [handles.data.synchronization{handles.Stage2Syn}.warp(:,i) alg_batches{i}];
            end
            
            cprint(handles.uite_DTW_Window,'Synchronization finished');
%             set(handles.uite_DTW_Window,'String',strvcat('Synchronization finished', get(handles.uite_DTW_Window,'String')));
%             set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), ''));  pause(0.01);      
    end

    handles.data.synchronization{handles.Stage2Syn}.maxi = 0; 
    s = size(handles.data.synchronization{handles.Stage2Syn}.alg_batches);
    for i=1:s(3)
         handles.data.synchronization{handles.Stage2Syn}.maxi = max(handles.data.synchronization{handles.Stage2Syn}.maxi,size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{i},1));
    end

    % Estimating the synchronization band
    handles.data.synchronization{handles.Stage2Syn}.band = estimationBD(handles.data.synchronization{handles.Stage2Syn}.warp);
    handles.data.synchronization{handles.Stage2Syn}.band_aux = handles.data.synchronization{handles.Stage2Syn}.band;
    
    % Construct a questdlg with three options
    choice = questdlg('In case you want to design a monitoring system for real-time application, a resynchronization using the RGT algorithm is recommended. Do you want to proceed with the RGTW-based synchronization?', ...
        'Synchronization', ...
        'Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            enable_RGTW('on',handles);
            set(handles.uib_RGTW,'Enable','on');
            handles.data.synchronization{handles.Stage2Syn}.cv = 0;
            handles.data.synchronization{handles.Stage2Syn}.zetacv = Inf;
        case 'No'
        % Once the DTW-synchronization has been performed, we set to 1 the
        % corresponding stage at the Stages vector to know that it has been
        % already synchronized.
        handles.flagStagesSyn(handles.Stage2Syn) = 1;
        if handles.SynStage
            % Remove the stage from the pending one to be synchronized and add it
            % to the list of the stages already synchronized.
            set(handles.lbUnsyn,'String','');
            set(handles.lbUnsyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==0))));

            set(handles.lbSyn,'String','');
            set(handles.lbSyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==1))));

            if isempty(find(handles.flagStagesSyn==0))
                set(handles.pushbuttonCalibration,'Enable','on');
                guidata(hObject, handles);
            else
                handles.Stage2Syn = handles.data.stages(find(handles.flagStagesSyn==0,1,'first'));
                % Set parameters for next stage
                set(handles.popupmenu_alg,'Value',2);
                popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
                % Retrieve data from the handles updated by the previous call
                handles=guidata(handles.output);
            end
        end 
         if get(handles.radiobuttonPlotResults,'Value')
                figure;
                if handles.data.synchronization{handles.Stage2Syn}.cv == 1  
                    handles.data.synchronization{handles.Stage2Syn}.band = estimationBD(handles.data.synchronization{handles.Stage2Syn}.warp, size(handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref},1), handles.data.synchronization{handles.Stage2Syn}.maxi);
                    plot(handles.data.synchronization{handles.Stage2Syn}.rgtwWARPS{handles.data.synchronization{handles.Stage2Syn}.zeta},'k-'); hold on;
                else
                    plot(handles.data.synchronization{handles.Stage2Syn}.warp,'k-'); hold on;       
                    handles.data.synchronization{handles.Stage2Syn}.band = handles.data.synchronization{handles.Stage2Syn}.band_aux;
                end
                plot(handles.data.synchronization{handles.Stage2Syn}.band,'r-','LineWidth',1.5)
                axis tight
                xlabel('Reference batch sampling point','FontSize',14);
                ylabel('Test batch sampling point','FontSize',14);
                plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches);
         end  
        set(handles.pushbuttonCalibration,'Enable','on');
    end 
    
    elseif strcmp(handles.data.synchronization{handles.Stage2Syn}.methodsyn,'multisynchro')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                                                                MULTI-SYNCHRO
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if handles.data.synchronization{handles.Stage2Syn}.Bref == -1, handles.data.synchronization{handles.Stage2Syn}.Bref = refBatch(handles.data.synchronization{handles.Stage2Syn}.nor_batches,'median');end
    % Store the reference batch that is going to be used for synchronization
    handles.data.synchronization{handles.Stage2Syn}.Xref = handles.data.synchronization{handles.Stage2Syn}.nor_batches{handles.data.synchronization{handles.Stage2Syn}.Bref};
    
    cprint(handles.uite_DTW_Window,'Synchronizing... (Multi-synchro)',[],0);
    cprint(handles.uite_DTW_Window,'Synchronizing... Phase I: asynchronisms detection');
    % Execute the high-level routine of Multisynchro    
    if get(handles.radiobuttonManual,'Value'),
        asynDetection.batchcI_II.I = [];
        asynDetection.batchcIII.I = [];
        asynDetection.batchcIV.I = [];
        asynDetection.batchcIII_IV.I = [];
        
        for i=1:size(handles.TypeAsyn,2)
            switch handles.TypeAsyn(i)
                case 1
                 asynDetection.batchcI_II.I = handles.AsynBatches{1,i}';
                case 2
                asynDetection.batchcIII.I = handles.AsynBatches{1,i}';
                case 3
                asynDetection.batchcIV.I = handles.AsynBatches{1,i}';
                case 4
                asynDetection.batchcIII_IV.I = handles.AsynBatches{1,i}';
            end
        end
        [handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection] = high_multisynchro(handles.data.synchronization{handles.Stage2Syn}.nor_batches,handles.data.synchronization{handles.Stage2Syn}.Xref,handles.data.synchronization{handles.Stage2Syn}.W,handles.data.synchronization{handles.Stage2Syn}.Wconstr,handles.data.synchronization{handles.Stage2Syn}.param.k,handles.data.synchronization{handles.Stage2Syn}.param.psih,handles.data.synchronization{handles.Stage2Syn}.param.psiv,0,asynDetection);
    else
        [handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection] = high_multisynchro(handles.data.synchronization{handles.Stage2Syn}.nor_batches,handles.data.synchronization{handles.Stage2Syn}.Xref,handles.data.synchronization{handles.Stage2Syn}.W,handles.data.synchronization{handles.Stage2Syn}.Wconstr,handles.data.synchronization{handles.Stage2Syn}.param.k,handles.data.synchronization{handles.Stage2Syn}.param.psih,handles.data.synchronization{handles.Stage2Syn}.param.psiv);
    end
    
    cprint(handles.uite_DTW_Window,'Synchronizing... Phase II: specific synchronization');
    [alg_batches,handles.data.synchronization{handles.Stage2Syn}.warp,handles.data.synchronization{handles.Stage2Syn}.specSynchronization] = low_multisychro(handles.data.synchronization{handles.Stage2Syn}.nor_batches,handles.data.synchronization{handles.Stage2Syn}.Xref,handles.data.synchronization{handles.Stage2Syn}.asynDetection,handles.data.synchronization{handles.Stage2Syn}.Wconstr,handles.data.synchronization{handles.Stage2Syn}.param.pcsMon,[],handles.uite_DTW_Window);   
   
    handles.data.synchronization{handles.Stage2Syn}.alg_batches = zeros(size(alg_batches,1),size(alg_batches,2)+1,size(alg_batches,3));
    for i=1:length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)
             handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,i)= [handles.data.synchronization{handles.Stage2Syn}.warp(:,i) squeeze(alg_batches(:,:,i))];
    end
    
    
    set(handles.listboxAsynchronisms,'String','');
             
    if ~isempty(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcI_II.I),
        cprint(handles.uite_DTW_Window,['Batches with class I or II asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcI_II.I')]);
        content = get(handles.listboxAsynchronisms,'String');
        set(handles.listboxAsynchronisms,'String',strvcat(content,'Asyn. I-II'));
        handles.data.synchronization{handles.Stage2Syn}.asynchronisms(1)=1;
    end
    if ~isempty(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII.I),
        cprint(handles.uite_DTW_Window,['Batches with class III asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII.I')]); 
        content = get(handles.listboxAsynchronisms,'String');
        set(handles.listboxAsynchronisms,'String',strvcat(content,'Asyn. III'));
        handles.data.synchronization{handles.Stage2Syn}.asynchronisms(2)=1;
    end
    if ~isempty(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIV.I),
        cprint(handles.uite_DTW_Window,['Batches with class IV asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIV.I')]); 
        content = get(handles.listboxAsynchronisms,'String');
        set(handles.listboxAsynchronisms,'String',strvcat(content,'Asyn. IV'));
        handles.data.synchronization{handles.Stage2Syn}.asynchronisms(3)=1;
    end
    if ~isempty(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII_IV.I),
        cprint(handles.uite_DTW_Window,['Batches with class III or IV asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII_IV.I')]);
        content = get(handles.listboxAsynchronisms,'String');
        set(handles.listboxAsynchronisms,'String',strvcat(content,'Asyn. III-IV'));
        handles.data.synchronization{handles.Stage2Syn}.asynchronisms(4)=1;
    end
    
      
   % set(handles.uite_DTW_Window,'String',strvcat(get(handles.uite_DTW_Window,'String'), '')); pause(0.01);
    set(handles.listboxAsynchronisms,'Value',1);
    
    % Enable the buttons for depicting outcomes
    set(handles.pushbuttonInfo,'Enable','on');
    set(handles.pushbuttonWI,'Enable','on');
    set(handles.pushbuttonPlotBatches,'Enable','on');

    % Remove the stage from the pending one to be synchronized and add it
    % to the list of the stages already synchronized.
    if handles.SynStage
        % Once IV-synchronization has been performed, we set to 1 the
        % corresponding stage at the Stages vector to know that it has been
        % already synchronized.
        handles.flagStagesSyn(handles.Stage2Syn) = 1;
    
        set(handles.lbUnsyn,'String','');
        set(handles.lbUnsyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==0))));

        set(handles.lbSyn,'String','');
        set(handles.lbSyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==1))));
    else
        handles.flagStagesSyn(1) = 1;
    end
        
    if isempty(find(handles.flagStagesSyn==0))
        set(handles.pushbuttonCalibration,'Enable','on');
    else
        handles.Stage2Syn = handles.data.stages(find(handles.flagStagesSyn==0,1,'first'));
        %handles.StageSyn = handles.data.stages(find(handles.flagStagesSyn==1,1,'first'));
        % Initialize next stage
        set(handles.popupmenu_alg,'Value',1);
        popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
        % Retrieve data from the handles updated by the previous call
        handles=guidata(handles.output);
    end

    if get(handles.radiobuttonPlotResults,'Value')
        plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches);
        figure; plot(handles.data.synchronization{handles.Stage2Syn}.warp,'k-');
        xlabel('Reference batch sampling point','FontSize',14);
        ylabel('Test batch sampling point','FontSize',14);
        axis tight;
    end

    

elseif strcmp(handles.data.synchronization{handles.Stage2Syn}.methodsyn,'iv')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                                                                         IV
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Cut to common start and end points
    nor_batches2 = handles.data.synchronization{handles.Stage2Syn}.nor_batches;
    if get(handles.radiobutton_cut,'Value'),
        handles.data.synchronization{handles.Stage2Syn}.cut = true;
        handles.data.synchronization{handles.Stage2Syn}.max_ep = -Inf;
        for i=1:length(nor_batches2),
            handles.data.synchronization{handles.Stage2Syn}.max_ep = max(handles.data.synchronization{handles.Stage2Syn}.max_ep,min(nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var)));
        end

        handles.data.synchronization{handles.Stage2Syn}.min_ep = Inf;
        for i=1:length(nor_batches2),
            handles.data.synchronization{handles.Stage2Syn}.min_ep = min(handles.data.synchronization{handles.Stage2Syn}.min_ep,max(nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var)));
        end

        for i=1:length(nor_batches2),
            indm = find(handles.data.synchronization{handles.Stage2Syn}.max_ep>=nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var),1);
            indM = find(handles.data.synchronization{handles.Stage2Syn}.min_ep<=nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var),1);
            nor_batches2{i} =  nor_batches2{i}(min(indm,indM):max(indm,indM),:);
        end
    else
        handles.data.synchronization{handles.Stage2Syn}.cut = false;
    end
    handles.data.synchronization{handles.Stage2Syn}.alg_batches = [];
    batch_ind = 1;
    
    for i=1:length(nor_batches2),
        if length(find(isnan(nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var)))) <= 0.25*length(nor_batches2{i}(:,handles.data.synchronization{handles.Stage2Syn}.var)) % Aling every batch where the iv was measured
            handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,batch_ind) = align_IV(nor_batches2{i},handles.data.synchronization{handles.Stage2Syn}.var,handles.data.synchronization{handles.Stage2Syn}.steps,handles.data.synchronization{handles.Stage2Syn}.method);
            batch_ind = batch_ind + 1;
        else
            errordlg('Too much missing data in the indicator variable.','Error Dialog','modal');
        end
    end
      
    % Remove the stage from the pending one to be synchronized and add it
    % to the list of the stages already synchronized.
    if handles.SynStage
        % Once IV-synchronization has been performed, we set to 1 the
        % corresponding stage at the Stages vector to know that it has been
        % already synchronized.
        handles.flagStagesSyn(handles.Stage2Syn) = 1;
    
        set(handles.lbUnsyn,'String','');
        set(handles.lbUnsyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==0))));

        set(handles.lbSyn,'String','');
        set(handles.lbSyn,'String',num2str(handles.data.stages(find(handles.flagStagesSyn==1))));
    else
        handles.flagStagesSyn(1) = 1;
    end
        
    if isempty(find(handles.flagStagesSyn==0))
        set(handles.pushbuttonCalibration,'Enable','on');
    else
        handles.Stage2Syn = handles.data.stages(find(handles.flagStagesSyn==0,1,'first'));
        % Initialize next stage
        set(handles.popupmenu_alg,'Value',1);
        popupmenu_alg_Callback(handles.popupmenu_alg, eventdata, handles);
        % Retrieve data from the handles updated by the previous call
        handles=guidata(handles.output);
    end

    if get(handles.radiobuttonPlotResults,'Value')
        plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches);
    end
    
end

guidata(hObject,handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                   8.- FUNCTIONS TO CONTROL THE WHOLE GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
function SaveMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SaveMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function SaveMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SaveMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file, pathname] = uiputfile('*.mat','Save to File');
if ~isequal(file, 0)
    dataAlig=handles.data;
    eval(['save ' fullfile(pathname, file) ' dataAlig']);
end
 
% --------------------------------------------------------------------
function SaveWMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to SaveWMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

assignin('base','dataAlig',handles.data);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                             9.- FUNCTION TO MOVE ON THE NEXT MODELLING STEP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in pushbuttonCalibration.
function pushbuttonCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Merge all the synchronized data sets.

K = 0;
for i=1:length(handles.data.synchronization)
    K = K + size(handles.data.synchronization{i}.alg_batches,1);
end
handles.data.alg_batches = zeros(K,size(handles.data.synchronization{i}.alg_batches,2),size(handles.data.synchronization{i}.alg_batches,3));

k = 0;
stg = [];
for i=1:length(handles.data.synchronization)
    ki = size(handles.data.synchronization{i}.alg_batches,1);
    k = k + ki;
    handles.data.alg_batches(k-ki+1:k,:,:) = handles.data.synchronization{i}.alg_batches;
    stg = [stg ones(1,ki).*i];
    if strcmp(handles.data.synchronization{i}.methodsyn,'multisynchro')  
        % Store parameters of the specific synchronization performed by Multisynchro
        handles.data.synchronization{handles.Stage2Syn}.rng = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.rng;
        handles.data.synchronization{handles.Stage2Syn}.t = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.t;
        handles.data.synchronization{handles.Stage2Syn}.p = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.p;
        handles.data.synchronization{handles.Stage2Syn}.Xi = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.Xi;
        handles.data.synchronization{handles.Stage2Syn}.Omega = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.Omega;
        handles.data.synchronization{handles.Stage2Syn}.band = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.band;
        handles.data.synchronization{handles.Stage2Syn}.pcs = handles.data.synchronization{handles.Stage2Syn}.specSynchronization.pcs;
        handles.data.synchronization{i}.W = handles.data.synchronization{i}.specSynchronization.W;
        handles.data.synchronization{i}.Wconstr = handles.data.synchronization{i}.specSynchronization.Wconstr;
    end
end

plot3D(handles.data.alg_batches,stg);

handles.ParentFigure.s_alignment = handles.data;
guidata(handles.ParentsWindow,handles.ParentFigure)
delete(handles.figure1);

axes(handles.ParentFigure.main_window)
image(handles.ParentFigure.images{4});
axis off;
axis image;
set(handles.ParentFigure.pbCalibration,'Enable','on');
handles.ParentFigure.track(3) = 1;
handles.ParentFigure.track(4:end) = 0;

% Update handles structure
guidata(handles.ParentsWindow, handles.ParentFigure);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                   10.- GUI PANEL for Multi-synchro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in listboxAsynchronisms.
function listboxAsynchronisms_Callback(hObject, eventdata, handles)
% hObject    handle to listboxAsynchronisms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxAsynchronisms contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxAsynchronisms

handles.selectedAsyn = get(hObject,'Value');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function listboxAsynchronisms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxAsynchronisms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.selectedAsyn = 1;
guidata(hObject,handles);

% --- Executes on button press in pushbuttonWI.
function pushbuttonWI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonWI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


asyn = find(handles.data.synchronization{handles.Stage2Syn}.asynchronisms==1);

switch asyn(handles.selectedAsyn)
    case 1
         plotWI(handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcI_II.I,'ASYN. I-II');
    case 2
        plotWI(handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII.I,'ASYN. III');
    case 3
        plotWI(handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIV.I,'ASYN. IV');
    case 4
        plotWI(handles.data.synchronization{handles.Stage2Syn}.warpAsynDetection,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII_IV.I,'ASYN. III-IV');
end
        
guidata(hObject,handles);

function editPsih_Callback(hObject, eventdata, handles)

psih = str2double(get(hObject,'String'));
handles.data.synchronization{handles.Stage2Syn}.param.psih = psih;
if psih > 10, 
    psih = 3; set(hObject,'String',num2str(psih)); 
    handles.data.synchronization{handles.Stage2Syn}.param.psih = psih; 
    errordlg('A value greater than 10 units is not recommendable. The default value is set.'); 
end

if psih < 1 
    psih = 3; set(hObject,'String',num2str(psih)); 
    handles.data.synchronization{handles.Stage2Syn}.param.psih = psih; 
    errordlg('A value lower than 0 units is incorrect. The default value is set.'); 
end
    
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function editPsih_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPsih (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editPsiv_Callback(hObject, eventdata, handles)
% hObject    handle to editPsiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPsiv as text
%        str2double(get(hObject,'String')) returns contents of editPsiv as a double

psiv = str2double(get(hObject,'String'));
handles.data.synchronization{handles.Stage2Syn}.param.psiv = psiv;
if  psiv > 10, 
    psiv = 3; set(hObject,'String',num2str(psiv)); 
    handles.data.synchronization{handles.Stage2Syn}.param.psiv = psiv; 
    errordlg('A value greater than 10 units is not recommendable. The default value is set.');
end

if psiv < 1 
    psiv = 3; set(hObject,'String',num2str(psiv)); 
    handles.data.synchronization{handles.Stage2Syn}.param.psiv = psiv; 
    errordlg('A value lower than 0 units is incorrect. The default value is set.'); 
end
    
    
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function editPsiv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPsiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editFraction_Callback(hObject, eventdata, handles)
% hObject    handle to editFraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFraction as text
%        str2double(get(hObject,'String')) returns contents of editFraction as a double


k = str2double(get(hObject,'String'));
handles.data.synchronization{handles.Stage2Syn}.param.k = k;
if k ~= Inf && (k <= 0 || k > 1), 
    k = 0.4; set(hObject,'String',num2str(k)); 
    handles.data.synchronization{handles.Stage2Syn}.param.k = k; 
    errordlg('The fraction value must be ranged in the interval ]0,1]. The default value is set.'); 
end

guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function editFraction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFraction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editPcs_Callback(hObject, eventdata, handles)
% hObject    handle to editPcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPcs as text
%        str2double(get(hObject,'String')) returns contents of editPcs as a double

pcs = str2double(get(hObject,'String'));
handles.data.synchronization{handles.Stage2Syn}.param.pcsMon = pcs;
if pcs < 0 || pcs > 50, 
    pcs = 50; set(hObject,'String',num2str(pcs)); 
    handles.data.synchronization{handles.Stage2Syn}.param.pcsMon = pcs; 
    errordlg('The number of PCs for monitoring purpose is bounded to 50 PCs'); 
end

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function editPcs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbuttonPlotBatches.
function pushbuttonPlotBatches_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPlotBatches (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

asyn = find(handles.data.synchronization{handles.Stage2Syn}.asynchronisms==1);

switch asyn(handles.selectedAsyn)
    case 1
         plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches,[],handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcI_II.I));
    case 2
        plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches,[],handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII.I));
    case 3
        plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches,[],handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIV.I));
    case 4
        plot3D(handles.data.synchronization{handles.Stage2Syn}.alg_batches,[],handles.data.synchronization{handles.Stage2Syn}.alg_batches(:,:,handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII_IV.I));
end
        
% --- Executes on button press in pushbuttonInfo.
function pushbuttonInfo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

asyn = find(handles.data.synchronization{handles.Stage2Syn}.asynchronisms==1);

switch asyn(handles.selectedAsyn)
    case 1
         cprint(handles.uite_DTW_Window,['Batches with class I or II asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcI_II.I')],[],0);
    case 2
        cprint(handles.uite_DTW_Window,['Batches with class III asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII.I')],[],0); 
    case 3
        cprint(handles.uite_DTW_Window,['Batches with class IV asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIV.I')],[],0); 
    case 4
        cprint(handles.uite_DTW_Window,['Batches with class III or IV asynchronism: ' num2str(handles.data.synchronization{handles.Stage2Syn}.asynDetection.batchcIII_IV.I')],[],0);
end
        
% --- Executes when selected object is changed in uipanelParametersMultiSynchro.
function uipanelParametersMultiSynchro_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanelParametersMultiSynchro 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


switch get(eventdata.NewValue,'Tag')   % Get Tag of selected object
     case 'radiobuttonAutomaticRecogniction'
        set(handles.editFraction,'Enable','on');
        handles.data.synchronization{handles.Stage2Syn}.param.k = str2double(get(handles.editFraction,'String'));
        set(handles.editPsiv,'Enable','off');
        set(handles.editPsih,'Enable','off');  
     case 'radiobuttonManualRecogniction'
        set(handles.editFraction,'Enable','off');
        set(handles.editPsiv,'Enable','on');
        set(handles.editPsih,'Enable','on');       
        handles.data.synchronization{handles.Stage2Syn}.param.k = Inf;
end

guidata(hObject,handles);

% --- Executes when selected object is changed in uipanelMultiSynchrpParameters.
function uipanelMultiSynchrpParameters_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanelMultiSynchrpParameters 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


switch get(eventdata.NewValue,'Tag')   % Get Tag of selected object
     case 'radiobuttonAutomatic'
        set(handles.radiobuttonAutomaticRecogniction,'Enable','on');
        set(handles.radiobuttonManualRecogniction,'Enable','on');
        set(handles.editTypeAsynchronisms,'Enable','off');
        set(handles.editBatches,'Enable','off');
        eventdata.EventName = 'SelectionChanged';
        eventdata.NewValue = handles.radiobuttonManualRecogniction;
        set(handles.radiobuttonManualRecogniction,'Value',1);
        uipanelParametersMultiSynchro_SelectionChangeFcn(handles.uipanelMultiSynchrpParameters, eventdata, handles);
     case 'radiobuttonManual'
        set(handles.radiobuttonAutomaticRecogniction,'Enable','off');
        set(handles.radiobuttonManualRecogniction,'Enable','off');
        set(handles.editFraction,'Enable','off');
        set(handles.editPsiv,'Enable','off');
        set(handles.editPsih,'Enable','off');
        set(handles.editTypeAsynchronisms,'Enable','on');
        set(handles.editBatches,'Enable','on');
end

function editBatches_Callback(hObject, eventdata, handles)
% hObject    handle to editBatches (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editBatches as text
%        str2double(get(hObject,'String')) returns contents of editBatches as a double

eval(strcat(strcat('AsynBatches={',str2mat(get(hObject,'String'))),'}'));
if size(AsynBatches,2) ~= size(handles.TypeAsyn,2), errordlg('The number of sets of batches does not coincide with the number of asynchronisms.'); set(handles.editBatches,'String',strcat('1:',num2str(length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)))); AsynBatches = 1:num2str(length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)); end

for i=1:size(AsynBatches,2)
   if ~isempty(union(find(AsynBatches{1,i} > length(handles.data.synchronization{handles.Stage2Syn}.nor_batches)),find(AsynBatches{1,i} < 1))), errordlg(strcat(strcat('The set of batches #',num2str(i)),' contains incorrect batch IDs')); return; end 
end
handles.AsynBatches = AsynBatches;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function editBatches_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBatches (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTypeAsynchronisms_Callback(hObject, eventdata, handles)
% hObject    handle to editTypeAsynchronisms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTypeAsynchronisms as text
%        str2double(get(hObject,'String')) returns contents of editTypeAsynchronisms as a double

eval(strcat(strcat('TypeAsyn=[',str2mat(get(hObject,'String')),']')));
if size(TypeAsyn,2) > 4, errordlg('As maximum there are four types of aynchronisms: (1) batches with equal duration but key process event not overlapping at the same time point in all batches (class I asynchronism) and/or batches with different duration and process pace caused by external factors (class II asynchronism), (2) batches with different duration due to incompletion of some batches and key process events overlapping (class III asynchronism); and (3) batches with different duration due to delay in the start but batch trajectories showing the same evolution pace after (class IV asynchronism), and 4) the combination of 2) and 3).'); set(handles.editTypeAsynchronisms,num2str(1)); return; end
if ~isempty(find(TypeAsyn<=1)) && ~isempty(find(TypeAsyn>4)), errordlg('There are only four classes of asynchronisms: (1) batches with equal duration but key process event not overlapping at the same time point in all batches (class I asynchronism) and/or batches with different duration and process pace caused by external factors (class II asynchronism), (2) batches with different duration due to incompletion of some batches and key process events overlapping (class III asynchronism); and (3) batches with different duration due to delay in the start but batch trajectories showing the same evolution pace after (class IV asynchronism), and 4) the combination of 2) and 3).'); set(handles.editTypeAsynchronisms,num2str(1)); return; end

handles.TypeAsyn = TypeAsyn;
guidata(hObject,handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                11.- MISCELLANEOUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [StageData] = SplitStage(x,stage)

if nargin < 2, stage = -1; end

StageData = cell(1,length(x)); 

    if stage ~= -1,
        for i=1:length(x)
            iniv = find(x{i}(:,1)==stage,1,'first');
            endv = find(x{i}(:,1)==stage,1,'last'); 
            StageData{i} = x{i}(iniv:endv,2:end);
        end
    else
        for i=1:length(x)
            StageData{i} = x{i}(:,2:end);
        end
    end

function enable_EQ(value,handles)

set(handles.text_inter,'Enable',value);
set(handles.popupmenu_inter,'Enable',value);
set(handles.text_units,'Enable',value);
set(handles.edit_units,'Enable',value);
set(handles.text_interp,'Enable',value);
set(handles.popupmenu_interp,'Enable',value);
        
function enable_IV(value,handles)

% Objects from the IV panel
set(handles.edit_var,'Enable',value);
set(handles.edit_steps,'Enable',value);
set(handles.popupmenu_method,'Enable',value);
set(handles.radiobutton_cut,'Enable',value);

set(handles.text_iv_var,'Enable',value);
set(handles.text_iv_steps,'Enable',value);
set(handles.text_iv_interp,'Enable',value);

function enable_SCT(value,handles)

% Objects from the DTW panel
set(handles.uipu_DTW_Reference,'Enable',value);
set(handles.uite_DTW_Window,'Enable',value);
set(handles.editConstraintVariables,'String','');
set(handles.editConstraintVariables,'Enable',value);
set(handles.uite_DTW_Reference,'String','');
set(handles.uite_DTW_Reference,'Enable',value);
set(handles.textConstraintVariables,'Enable',value);

function enable_DTW(value,handles)

% Objects from the DTW panel
set(handles.uipu_DTW_Weights,'Enable',value);
set(handles.uite_DTW_Weights,'Enable','off');

function enable_RGTW(value,handles)

set(handles.uirb_DTW_Par_Syn_off,'Enable',value);
set(handles.uirb_DTW_Par_Syn_cv,'Enable',value);
set(handles.text_rgtw,'Enable',value);
set(handles.text_dtw_ww,'Enable',value);
set(handles.uirb_DTW_Par_Syn_off,'Value',1);

if strcmp(value, 'off')
    set(handles.text_maximum,'Enable',value);
    set(handles.text_zeta,'Enable',value);
    set(handles.popmenu_zeta_cv,'Enable',value);
    set(handles.uib_validate,'Enable',value);
end

contents = [];
for i=1:15
    contents=strvcat(contents,num2str(i));  %#ok<FPARK>
end
set(handles.popupmenu_zeta,'String',' '); 
set(handles.popupmenu_zeta,'String',contents); 
set(handles.popupmenu_zeta,'Value',1);
set(handles.popupmenu_zeta,'Enable',value);

function enable_MultiSynchro(value,handles)

% Objects from the DTW panel
set(handles.listboxAsynchronisms,'Enable',value);
set(handles.editFraction,'Enable',value);
set(handles.editPsiv,'Enable',value);
set(handles.editPsih,'Enable',value);
set(handles.editPcs,'Enable',value);
set(handles.radiobuttonAutomaticRecogniction,'Enable',value);
set(handles.radiobuttonManualRecogniction,'Enable',value);
set(handles.radiobuttonAutomatic,'Enable',value);
set(handles.radiobuttonManual,'Enable',value);

if strcmp('off',value)
    set(handles.pushbuttonInfo,'Enable',value);
    set(handles.pushbuttonWI,'Enable',value);
    set(handles.pushbuttonPlotBatches,'Enable',value);    
    set(handles.editTypeAsynchronisms,'Enable',value);
end


function plotWI(warp,batches,label)
figure;
plot(warp,'Color','k'); hold on;
h1 = plot(warp(:,1),'Color','k');
plot(warp(:,batches),'r-','LineWidth',1.5);
h2 = plot(warp(:,batches(1)),'r-','LineWidth',1.2);
ylabel('Test batch time sampling point','FontSize',14);
xlabel('Reference batch time sampling point','FontSize',14);
legend([h1 h2],'all',label);
title('Warping information','FontSize',12,'FontWeight','b');
axis tight


% --- Executes during object creation, after setting all properties.
function editTypeAsynchronisms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTypeAsynchronisms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
