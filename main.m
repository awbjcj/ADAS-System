%main：输入xml与csv，作图
clc;
% %以下数据仅需要导入一次，节约时间
% db = canDatabase('MET_IFVS-500_CAN_Release_v1.20.dbc');                                          %加载数据库
% 
% %若为csv文件，需要进行如下的数据导入与处理
% varNames = {'needless','needless','Time',...
%     'needless','needless','ID',...
%     'needless','Extended','Length',...
%     'needless','d1','d2','d3','d4','d5','d6','d7','d8'} ;
% varTypes = {'char','char','char',...
%     'char','char','char',...
%     'char','char','char',...
%     'char','char','char','char','char','char','char','char','char'} ;
% delimiter = {',',' '};
% dataStartLine = 2;
% extraColRule = 'ignore';
% opts = delimitedTextImportOptions('VariableNames',varNames,...
%                                 'VariableTypes',varTypes,...
%                                 'Delimiter',delimiter,...
%                                 'DataLines', dataStartLine,...
%                                 'ExtraColumnsRule',extraColRule); 
% msgRaw=readtable('test.csv',opts); 
% msgRaw(:,1:2)=[];
% msgRaw(:,2:3)=[];
% msgRaw(:,3)=[];
% msgRaw(:,5)=[];
% 
% sz=size(msgRaw);
% msgAll=table('Size',[sz(1) 9],'VariableNames',{'Time','ID',...
%     'Extended','Name','Length','Signals','Error','Remote','Data'}...
%     ,'VariableTypes',{'double','uint32','logical','cellstr','uint8','cell'...
%     'logical','logical','cell'});
% 
% for i=1:sz(1)
% msgAll.ID(i)=hex2dec(msgRaw.ID(i));
% msgAll.Time(i)=(hex2dec(msgRaw.Time(i))-hex2dec(msgRaw.Time(1)))*0.1*0.001;
% msgAll.Length(i)=hex2dec(msgRaw.Length(i));
% msgAll.Extended(i)=(string(msgRaw.Extended(i))=='扩展帧');                                   
% msgAll.Data(i)={[uint8(hex2dec(msgRaw.d1(i))) uint8(hex2dec...
% (msgRaw.d2(i))) uint8(hex2dec(msgRaw.d3(i))) uint8(hex2dec(msgRaw.d4(i)))...
% uint8(hex2dec(msgRaw.d5(i))) uint8(hex2dec(msgRaw.d6(i))) ...
% uint8(hex2dec(msgRaw.d7(i))) uint8(hex2dec(msgRaw.d8(i)))]};
% end
% msgAll.Time=seconds(msgAll.Time);
% msgAll= canMessageTimetable(table2timetable(msgAll),db);               
% % 以上数据仅需要导入一次，节约时间




xmlDoc = xmlread('input.xml');                                             %关于如何构建xml文件：
% <?xml version="1.0" ?>
% <xxx>                                                                    起始总框架
% <plot>                                                                   起始绘制图表框架
% <plotid>1</plotid>                                                       图表序号
% <start>35</start>                                                        图表起始时间
% <end>200</end>                                                           图表结束时间
% <data>                                                                   起始数据框架 
% <msgid>0x18FF09E8</msgid>                                                信号所属的报文编号
% <ext>1</ext>                                                             报文是否为扩展帧，是为1，不是为0
% <sgn>vehicle_speed</sgn>                                                 信号名称
% <factor>1</factor>                                                       设置的系数（上下拉伸）
% <offset>0</offset>                                                       设置的偏移量（上下平移）
%                                                                          最终结果=原数据*系数+偏移量
% <msgid>0x18FF09E8</msgid>                                                可在同一张图表上绘制多组数据绘制多组数据
% <ext>1</ext>                                                             报文是否为扩展帧，是为1，不是为0
% <sgn>TTC_PED</sgn>
% <factor>0.2</factor>
% <offset>35</offset>
% </data>                                                                  结束数据框架
% </plot>                                                                  结束图表框架
% <msgid>0x18FF09E8</msgid>                                                想临时注释的数据需要放在图表框架外，总框架内
% <ext>1</ext>                                                             报文是否为扩展帧，是为1，不是为0
% <sgn>distance</sgn>
% <factor>0.1</factor>
% <offset>15</offset>
% </xxx>                                                                   结束总框架

plotidArray = xmlDoc.getElementsByTagName('plotid');
startArray = xmlDoc.getElementsByTagName('start');
endArray = xmlDoc.getElementsByTagName('end');
dataArray = xmlDoc.getElementsByTagName('data');
for i = 0 : plotidArray.getLength-1                              
    figure
    startTemp = str2double(startArray.item(i).getFirstChild.getData);
    endTemp = str2double(endArray.item(i).getFirstChild.getData);
    dataTemp = dataArray.item(i);
    msgidArray = dataTemp.getElementsByTagName('msgid');
    extArray = dataTemp.getElementsByTagName('ext');
    sgnArray = dataTemp.getElementsByTagName('sgn');
    factorArray = dataTemp.getElementsByTagName('factor');
    offsetArray = dataTemp.getElementsByTagName('offset');
    for ii=0:msgidArray.getLength-1
        msgTemp=messageInfo(db,hex2dec(char(msgidArray.item...
            (ii).getFirstChild.getData)),(char(extArray.item...
            (ii).getFirstChild.getData)=='1')).Name;                            
        sgnTemp = char(sgnArray.item(ii).getFirstChild.getData);
        factorTemp = str2double(factorArray.item(ii).getFirstChild.getData);
        offsetTemp = str2double(offsetArray.item(ii).getFirstChild.getData);
        dataVisualize(db,msgAll,msgTemp,sgnTemp,...
            startTemp,endTemp,factorTemp,offsetTemp)
        hold on
    end
    legend
    annotation('line',[.5,.5],[0,1],'Color',...
        'red','LineWidth',1,'LineStyle','--')
    annotation('line',[0,1],[.5,.5],'Color','red',...
        'LineWidth',1,'LineStyle','--')
    hold off
end 


function dataVisualize(db,msgAll,msgName,varName,lower,upper,factor,offset)
%function dataVisualize(db,varSgn,msgName,varName,lowerTime,upperTime)
%asc文件所用函数模式

varSgn= canSignalTimetable(msgAll,msgName);                                %提取总报文数据中与所需报文有关的时间信号表

%S = timerange(upperTime,lowerTime);
timeRange=timerange(seconds(lower),seconds(upper),'closed');               %设置上下限时间格式

%strcmpi(fieldnames(msg.Signals),varName)'
varSgnFilt=varSgn(timeRange,...
    strcmpi(fieldnames(canMessage(db,msgName).Signals),varName)');         %从时间信号表中根据名称提取信号

%作图
if isempty(signalInfo(db,msgName,varName).Comment)                         %尝试抓取信号的备注与单位作为图示，若无则以信号名称作为图示
   plot(varSgnFilt.Time, varSgnFilt.Variables*factor+offset,...
       'LineWidth',1.5,'DisplayName',append(strrep(varName,'_','\_'),',',...
       signalInfo(db,msgName,varName).Units,',','系数 = ',...
    num2str(factor),',','偏移 = ',num2str(offset))); 
else
    plot(varSgnFilt.Time, varSgnFilt.Variables*factor+offset,...
        'LineWidth',1.5,'DisplayName',...
        append(signalInfo(db,msgName,varName).Comment,...
        ',',signalInfo(db,msgName,varName).Units,',','系数 =',...
    num2str(factor),',','偏移 = ',num2str(offset)));
end

%添加标题与图例
if isempty(messageInfo(db,msgName).Comment)                                %尝试抓取报文的备注作为标题，若无则以报文名称作为标题
    title(strrep(msgName,'_','\_'));
else
    title(messageInfo(db,msgName).Comment);
end

%添加坐标轴
xlabel('时间')
grid on
end