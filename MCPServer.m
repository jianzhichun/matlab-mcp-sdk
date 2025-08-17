classdef MCPServer < handle
    %MCPServer MATLAB MCP服务器实现
    %   用于创建和管理MCP（模型上下文协议）服务器
    
    properties (Access = private)
        name            % 服务器名称
        tools           % 工具字典
        server          % HTTP服务器对象
        port            % 端口号
        host            % 主机地址
        logLevel        % 日志级别
        timeout         % 超时时间
        isRunning       % 运行状态
        requestId       % 请求ID计数器
    end
    
    properties (Constant)
        VERSION = '1.0.0'
        PROTOCOL_VERSION = '2024-11-05'
    end
    
    methods
        function obj = MCPServer(name, options)
            %MCPServer 构造函数
            %   server = MCPServer(name, options)
            %   
            %   参数:
            %       name (string): 服务器名称
            %       options (struct, 可选): 配置选项
            
            if nargin < 1
                error('MCPServer:InvalidInput', '必须提供服务器名称');
            end
            
            obj.name = name;
            obj.tools = containers.Map();
            obj.requestId = 0;
            obj.isRunning = false;
            
            % 设置默认选项
            if nargin < 2
                options = struct();
            end
            
            obj.port = getfield(options, 'port', 8080);
            obj.host = getfield(options, 'host', 'localhost');
            obj.logLevel = getfield(options, 'logLevel', 'INFO');
            obj.timeout = getfield(options, 'timeout', 30);
            
            obj.log('INFO', sprintf('MCP服务器 "%s" 已创建', name));
        end
        
        function addTool(obj, name, handler, varargin)
            %addTool 添加工具到服务器
            %   server.addTool(name, handler, 'description', desc, 'inputSchema', schema)
            %
            %   参数:
            %       name (string): 工具名称
            %       handler (function_handle): 处理函数
            %       varargin: 可选参数对
            
            if nargin < 3
                error('MCPServer:InvalidInput', '必须提供工具名称和处理函数');
            end
            
            % 解析可选参数
            p = inputParser;
            addParameter(p, 'description', '');
            addParameter(p, 'inputSchema', struct());
            addParameter(p, 'timeout', obj.timeout);
            addParameter(p, 'async', false);
            parse(p, varargin{:});
            
            % 创建工具对象
            tool = struct();
            tool.name = name;
            tool.handler = handler;
            tool.description = p.Results.description;
            tool.inputSchema = p.Results.inputSchema;
            tool.timeout = p.Results.timeout;
            tool.async = p.Results.async;
            
            % 验证处理函数
            if ~isa(handler, 'function_handle')
                error('MCPServer:InvalidInput', '处理函数必须是函数句柄');
            end
            
            % 添加到工具字典
            obj.tools(name) = tool;
            
            obj.log('INFO', sprintf('工具 "%s" 已添加', name));
        end
        
        function start(obj)
            %start 启动MCP服务器
            
            if obj.isRunning
                warning('MCPServer:AlreadyRunning', '服务器已在运行');
                return;
            end
            
            try
                % 创建HTTP服务器
                obj.server = matlab.net.http.Server();
                obj.server.Port = obj.port;
                
                % 设置请求处理器
                obj.server.RequestReceivedFcn = @(src, event) obj.handleRequest(src, event);
                
                % 启动服务器
                obj.server.start();
                obj.isRunning = true;
                
                obj.log('INFO', sprintf('MCP服务器已启动在 http://%s:%d', obj.host, obj.port));
                obj.log('INFO', sprintf('可用工具: %s', strjoin(obj.tools.keys, ', ')));
                
            catch ME
                obj.log('ERROR', sprintf('启动服务器失败: %s', ME.message));
                rethrow(ME);
            end
        end
        
        function stop(obj)
            %stop 停止MCP服务器
            
            if ~obj.isRunning
                warning('MCPServer:NotRunning', '服务器未在运行');
                return;
            end
            
            try
                obj.server.stop();
                obj.isRunning = false;
                obj.log('INFO', 'MCP服务器已停止');
            catch ME
                obj.log('ERROR', sprintf('停止服务器失败: %s', ME.message));
                rethrow(ME);
            end
        end
        
        function tools = getTools(obj)
            %getTools 获取所有工具列表
            
            tools = obj.tools.keys;
        end
        
        function delete(obj)
            %delete 析构函数
            
            if obj.isRunning
                obj.stop();
            end
        end
    end
    
    methods (Access = private)
        function handleRequest(obj, ~, event)
            %handleRequest 处理HTTP请求
            
            try
                request = event.Request;
                response = event.Response;
                
                obj.log('DEBUG', sprintf('收到请求: %s %s', request.Method, request.RequestLine));
                
                % 解析请求
                if strcmp(request.Method, 'POST')
                    obj.handlePostRequest(request, response);
                else
                    obj.handleGetRequest(request, response);
                end
                
            catch ME
                obj.log('ERROR', sprintf('处理请求失败: %s', ME.message));
                obj.sendErrorResponse(response, 'InternalError', ME.message);
            end
        end
        
        function handlePostRequest(obj, request, response)
            %handlePostRequest 处理POST请求
            
            try
                % 解析JSON请求体
                body = char(request.Body.Data);
                data = jsondecode(body);
                
                % 根据请求类型处理
                switch data.method
                    case 'tools/list'
                        obj.handleListTools(request, response);
                    case 'tools/call'
                        obj.handleCallTool(request, response, data);
                    case 'initialize'
                        obj.handleInitialize(request, response, data);
                    otherwise
                        obj.sendErrorResponse(response, 'MethodNotFound', sprintf('未知方法: %s', data.method));
                end
                
            catch ME
                obj.log('ERROR', sprintf('处理POST请求失败: %s', ME.message));
                obj.sendErrorResponse(response, 'ParseError', ME.message);
            end
        end
        
        function handleGetRequest(obj, request, response)
            %handleGetRequest 处理GET请求
            
            % 返回服务器信息
            info = struct();
            info.name = obj.name;
            info.version = obj.VERSION;
            info.protocol = obj.PROTOCOL_VERSION;
            info.tools = obj.tools.keys;
            
            response.Body = matlab.net.http.MessageBody(jsonencode(info));
            response.StatusCode = matlab.net.http.StatusCode.OK;
            response.HeaderFields = [response.HeaderFields, ...
                matlab.net.http.HeaderField('Content-Type', 'application/json')];
        end
        
        function handleInitialize(obj, request, response, data)
            %handleInitialize 处理初始化请求
            
            obj.requestId = obj.requestId + 1;
            
            % 构建响应
            result = struct();
            result.jsonrpc = '2.0';
            result.id = obj.requestId;
            result.result = struct();
            result.result.protocolVersion = obj.PROTOCOL_VERSION;
            result.result.capabilities = struct();
            result.result.serverInfo = struct();
            result.result.serverInfo.name = obj.name;
            result.result.serverInfo.version = obj.VERSION;
            
            response.Body = matlab.net.http.MessageBody(jsonencode(result));
            response.StatusCode = matlab.net.http.StatusCode.OK;
            response.HeaderFields = [response.HeaderFields, ...
                matlab.net.http.HeaderField('Content-Type', 'application/json')];
        end
        
        function handleListTools(obj, request, response)
            %handleListTools 处理工具列表请求
            
            obj.requestId = obj.requestId + 1;
            
            % 构建工具列表
            tools = {};
            toolNames = obj.tools.keys;
            
            for i = 1:length(toolNames)
                name = toolNames{i};
                tool = obj.tools(name);
                
                toolInfo = struct();
                toolInfo.name = tool.name;
                toolInfo.description = tool.description;
                toolInfo.inputSchema = tool.inputSchema;
                
                tools{end+1} = toolInfo;
            end
            
            % 构建响应
            result = struct();
            result.jsonrpc = '2.0';
            result.id = obj.requestId;
            result.result = struct();
            result.result.tools = tools;
            
            response.Body = matlab.net.http.MessageBody(jsonencode(result));
            response.StatusCode = matlab.net.http.StatusCode.OK;
            response.HeaderFields = [response.HeaderFields, ...
                matlab.net.http.HeaderField('Content-Type', 'application/json')];
        end
        
        function handleCallTool(obj, request, response, data)
            %handleCallTool 处理工具调用请求
            
            obj.requestId = obj.requestId + 1;
            
            try
                % 获取工具
                if ~isfield(data.params, 'name') || ~obj.tools.isKey(data.params.name)
                    obj.sendErrorResponse(response, 'ToolNotFound', sprintf('工具未找到: %s', data.params.name));
                    return;
                end
                
                tool = obj.tools(data.params.name);
                args = data.params.arguments;
                
                % 验证参数
                obj.validateArguments(args, tool.inputSchema);
                
                % 执行工具
                obj.log('INFO', sprintf('执行工具: %s', tool.name));
                
                if tool.async
                    % 异步执行
                    result = obj.executeToolAsync(tool, args);
                else
                    % 同步执行
                    result = obj.executeToolSync(tool, args);
                end
                
                % 构建响应
                response_data = struct();
                response_data.jsonrpc = '2.0';
                response_data.id = obj.requestId;
                response_data.result = struct();
                response_data.result.content = {{struct('type', 'text', 'text', jsonencode(result))}};
                
                response.Body = matlab.net.http.MessageBody(jsonencode(response_data));
                response.StatusCode = matlab.net.http.StatusCode.OK;
                response.HeaderFields = [response.HeaderFields, ...
                    matlab.net.http.HeaderField('Content-Type', 'application/json')];
                
            catch ME
                obj.log('ERROR', sprintf('执行工具失败: %s', ME.message));
                obj.sendErrorResponse(response, 'ToolError', ME.message);
            end
        end
        
        function result = executeToolSync(obj, tool, args)
            %executeToolSync 同步执行工具
            
            % 设置超时
            if tool.timeout > 0
                % 注意：MATLAB的timeout功能有限，这里只是示例
                result = tool.handler(args);
            else
                result = tool.handler(args);
            end
        end
        
        function result = executeToolAsync(obj, tool, args)
            %executeToolAsync 异步执行工具
            
            % 创建后台任务
            future = parfeval(@tool.handler, 1, args);
            
            % 等待结果（这里简化处理）
            result = fetchOutputs(future);
        end
        
        function validateArguments(obj, args, schema)
            %validateArguments 验证参数
            
            if isempty(schema)
                return;
            end
            
            fields = fieldnames(schema);
            for i = 1:length(fields)
                field = fields{i};
                fieldSchema = schema.(field);
                
                % 检查必需字段
                if isfield(fieldSchema, 'required') && fieldSchema.required
                    if ~isfield(args, field)
                        error('MCP:InvalidInput', sprintf('缺少必需参数: %s', field));
                    end
                end
                
                % 检查字段类型
                if isfield(args, field)
                    obj.validateFieldType(args.(field), fieldSchema, field);
                end
            end
        end
        
        function validateFieldType(obj, value, schema, fieldName)
            %validateFieldType 验证字段类型
            
            if ~isfield(schema, 'type')
                return;
            end
            
            switch schema.type
                case 'string'
                    if ~ischar(value) && ~isstring(value)
                        error('MCP:InvalidInput', sprintf('参数 %s 必须是字符串', fieldName));
                    end
                case 'number'
                    if ~isnumeric(value) || ~isscalar(value)
                        error('MCP:InvalidInput', sprintf('参数 %s 必须是数字', fieldName));
                    end
                case 'integer'
                    if ~isnumeric(value) || ~isscalar(value) || mod(value, 1) ~= 0
                        error('MCP:InvalidInput', sprintf('参数 %s 必须是整数', fieldName));
                    end
                case 'boolean'
                    if ~islogical(value) && ~(isnumeric(value) && isscalar(value) && (value == 0 || value == 1))
                        error('MCP:InvalidInput', sprintf('参数 %s 必须是布尔值', fieldName));
                    end
                case 'array'
                    if ~isvector(value)
                        error('MCP:InvalidInput', sprintf('参数 %s 必须是数组', fieldName));
                    end
            end
            
            % 检查枚举值
            if isfield(schema, 'enum')
                if ~any(strcmp(value, schema.enum))
                    error('MCP:InvalidInput', sprintf('参数 %s 的值必须是: %s', fieldName, strjoin(schema.enum, ', ')));
                end
            end
        end
        
        function sendErrorResponse(obj, response, code, message)
            %sendErrorResponse 发送错误响应
            
            obj.requestId = obj.requestId + 1;
            
            error_data = struct();
            error_data.jsonrpc = '2.0';
            error_data.id = obj.requestId;
            error_data.error = struct();
            error_data.error.code = code;
            error_data.error.message = message;
            
            response.Body = matlab.net.http.MessageBody(jsonencode(error_data));
            response.StatusCode = matlab.net.http.StatusCode.BadRequest;
            response.HeaderFields = [response.HeaderFields, ...
                matlab.net.http.HeaderField('Content-Type', 'application/json')];
        end
        
        function log(obj, level, message)
            %log 记录日志
            
            if obj.shouldLog(level)
                timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                fprintf('[%s] %s: %s\n', timestamp, level, message);
            end
        end
        
        function should = shouldLog(obj, level)
            %shouldLog 判断是否应该记录日志
            
            levels = {'DEBUG', 'INFO', 'WARN', 'ERROR'};
            currentLevel = find(strcmp(levels, obj.logLevel));
            requestedLevel = find(strcmp(levels, level));
            
            should = requestedLevel >= currentLevel;
        end
    end
    
    methods (Static)
        function setLogLevel(level)
            %setLogLevel 设置全局日志级别
            
            global MCP_LOG_LEVEL;
            MCP_LOG_LEVEL = level;
        end
        
        function log(level, message)
            %log 静态日志方法
            
            global MCP_LOG_LEVEL;
            if isempty(MCP_LOG_LEVEL)
                MCP_LOG_LEVEL = 'INFO';
            end
            
            levels = {'DEBUG', 'INFO', 'WARN', 'ERROR'};
            currentLevel = find(strcmp(levels, MCP_LOG_LEVEL));
            requestedLevel = find(strcmp(levels, level));
            
            if requestedLevel >= currentLevel
                timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                fprintf('[%s] %s: %s\n', timestamp, level, message);
            end
        end
    end
end

function value = getfield(struct_obj, field, default)
    %getfield 安全获取结构体字段值
    
    if isfield(struct_obj, field)
        value = struct_obj.(field);
    else
        value = default;
    end
end
