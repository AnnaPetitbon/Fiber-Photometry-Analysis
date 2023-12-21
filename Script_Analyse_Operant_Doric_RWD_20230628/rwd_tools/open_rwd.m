function data = open_rwd(filepath,params)

Fluorescence_path = filepath;
recording_config = params.recording_config;

config = load_rwd_config(Fluorescence_path);

sep = strfind(filepath,filesep);
dataRoot = filepath(1:sep(end)-1);
Fluorescence_unaligned_path = [dataRoot filesep 'Fluorescence-unaligned.csv'];

raw_data = dlmread(Fluorescence_unaligned_path,',',1,0);

idx_physio = find(raw_data(:,2)==470);
data_tmp.t_physio = raw_data(idx_physio,1);
data_tmp.physio = raw_data(idx_physio,3);

idx_iso = find(raw_data(:,2)==410);
data_tmp.t_iso = raw_data(idx_iso,1);
data_tmp.iso = raw_data(idx_iso,3);


%interpolate iso data, to synchronise them with physio data
xq = data_tmp.t_physio;
x = data_tmp.t_iso;
v = data_tmp.iso;

vq = interp1(x,v,xq);
data_tmp.iso2 = vq;

clear raw_data

% figure()
% hold on
% plot(data.t_physio, data.physio,'b*')
% plot(data.t_iso, data.iso,'r*')
% plot(data.t_physio, data.iso2,'b*')


%% UPDATE STRUCTURE BEFORE RETURNING IT
data.time = data_tmp.t_physio/1000.0;
data.iso = data_tmp.iso2;
data.physio = data_tmp.physio;

Events_path = [dataRoot filesep 'Events.csv'];
data.TTLs = extract_TTL_inputs(Events_path, params);


n=size(recording_config,2);

data.sfreq = 1/mean(diff(data.time))


for i=1:n
    
    r=recording_config{i};
    
    try
        
        if strcmp(r{3},'extract_as_TTL') || strcmp(r{3},'extract_as_ComplexTTL')
            varname = r{2};
            if iscell(varname), varname=varname{1};end
            
            cmd = sprintf('on_ts =  data.TTLs.%s.on_ts;', r{1});eval(cmd);
            cmd = sprintf('off_ts =  data.TTLs.%s.off_ts;', r{1});eval(cmd);
%             on_idx = floor(on_ts*data.sfreq);
%             off_idx = floor(off_ts*data.sfreq);
            
            if strcmp(r{3},'extract_as_TTL')
%                 cmd = sprintf('data.%s.%s.on_idx=on_idx;',r{4},r{2});eval(cmd);
%                 cmd = sprintf('data.%s.%s.off_idx=off_idx;',r{4},r{2});eval(cmd);
                cmd = sprintf('data.%s.%s.on_ts=on_ts;',r{4},r{2});eval(cmd);
                cmd = sprintf('data.%s.%s.off_ts=off_ts;',r{4},r{2});eval(cmd);
            else
%                 cmd = sprintf('data.%s.on_idx=on_idx;',r{2});eval(cmd);
%                 cmd = sprintf('data.%s.off_idx=off_idx;',r{2});eval(cmd);
                cmd = sprintf('data.%s.on_ts=on_ts;',r{2});eval(cmd);
                cmd = sprintf('data.%s.off_ts=off_ts;',r{2});eval(cmd);
            end
        end
    end
end











end

function config = load_rwd_config(filepath)
fp = fopen(filepath,'r'); % Open the csv file in read mode 'r'
tmp = fgetl(fp);
tmp = strrep(tmp,';', ',');
config = jsondecode(tmp);
fclose(fp);
end

function Events = importfile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  EVENTS = IMPORTFILE(FILENAME) reads data from text file FILENAME for
%  the default selection.  Returns the data as a table.
%
%  EVENTS = IMPORTFILE(FILE, DATALINES) reads data for the specified row
%  interval(s) of text file FILENAME. Specify DATALINES as a positive
%  scalar integer or a N-by-2 array of positive scalar integers for
%  dis-contiguous row intervals.
%
%  Example:
%  Events = importfile("E:\NAS_SD\SuiviClient\Triffilieff\2023\Data\RWD_Anna\Exp1\M67342\M67342_20220720_sess01_rec1_Pavlovien_M_DELTA\Events.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 14-Feb-2023 16:38:05

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "Name", "State"];
opts.VariableTypes = ["double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Name", "TrimNonNumeric", true);
opts = setvaropts(opts, "Name", "ThousandsSeparator", ",");

% Import the data
Events = readtable(filename, opts);

end


function TTLs = extract_TTL_inputs(filename, params)
raw_TTL_inputs = importfile(filename);
for i=1:4
    rows = (raw_TTL_inputs.Name==i & raw_TTL_inputs.State==0);
    cmd = sprintf('TTLs.Input%d.on_ts=raw_TTL_inputs.TimeStamp(rows)/1000.0;',i);eval(cmd);
    rows = (raw_TTL_inputs.Name==i & raw_TTL_inputs.State==1);
    cmd = sprintf('TTLs.Input%d.off_ts=raw_TTL_inputs.TimeStamp(rows)/1000.0;',i);eval(cmd);
end
end









