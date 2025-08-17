# MATLAB MCP Server SDK

这是一个用纯MATLAB语言实现的MCP（模型上下文协议）服务器SDK，专门为MATLAB项目设计。

## 项目概述

本SDK允许您将任何MATLAB函数包装成MCP工具，使AI助手能够直接调用MATLAB代码。

## 核心特性

- ✅ **纯MATLAB实现** - 无需Python或其他语言
- ✅ **简单易用** - 几行代码即可创建MCP工具
- ✅ **类型安全** - 支持参数验证和类型检查
- ✅ **异步支持** - 支持长时间运行的计算
- ✅ **错误处理** - 完善的错误处理和日志记录
- ✅ **JSON通信** - 基于JSON的标准化通信协议

## 快速开始

### 1. 基本使用

```matlab
% 创建MCP服务器
server = MCPServer('my-server');

% 添加工具
server.addTool('calculate_sum', @(a, b) a + b, ...
    'description', '计算两个数的和', ...
    'inputSchema', struct('a', 'number', 'b', 'number'));

% 启动服务器
server.start();
```

### 2. 高级示例

```matlab
% 创建CVI仿真服务器
cviServer = MCPServer('cvi-simulation');

% 添加CVI仿真工具
cviServer.addTool('run_cvi_simulation', @runCVISimulation, ...
    'description', '运行CVI仿真计算', ...
    'inputSchema', struct(...
        'k_mesh', struct('type', 'integer', 'default', 0), ...
        'T_process', struct('type', 'number', 'default', 1273), ...
        'ptot', struct('type', 'number', 'default', 5000) ...
    ));

% 添加结果获取工具
cviServer.addTool('get_results', @getSimulationResults, ...
    'description', '获取仿真结果', ...
    'inputSchema', struct(...
        'result_type', struct('type', 'string', 'enum', {{'porosity', 'density'}}) ...
    ));

% 启动服务器
cviServer.start();
```

## API参考

### MCPServer类

#### 构造函数
```matlab
server = MCPServer(name, options)
```

参数：
- `name` (string): 服务器名称
- `options` (struct, 可选): 配置选项

#### 方法

##### addTool(name, handler, varargin)
添加工具到服务器

```matlab
server.addTool('tool_name', @handler_function, ...
    'description', '工具描述', ...
    'inputSchema', schema_struct);
```

##### start()
启动MCP服务器

```matlab
server.start();
```

##### stop()
停止MCP服务器

```matlab
server.stop();
```

##### getTools()
获取所有工具列表

```matlab
tools = server.getTools();
```

### 工具处理函数

工具处理函数应该接受一个参数结构体，并返回结果：

```matlab
function result = myToolHandler(args)
    % args 是包含输入参数的结构体
    a = args.a;
    b = args.b;
    
    % 执行计算
    result = a + b;
    
    % 返回结果（可以是任何MATLAB数据类型）
end
```

## 配置选项

### 服务器选项

```matlab
options = struct();
options.port = 8080;           % HTTP端口（可选）
options.host = 'localhost';     % 主机地址
options.logLevel = 'INFO';      % 日志级别
options.timeout = 30;           % 超时时间（秒）

server = MCPServer('my-server', options);
```

### 工具选项

```matlab
server.addTool('my_tool', @handler, ...
    'description', '工具描述', ...
    'inputSchema', schema, ...
    'timeout', 60, ...          % 工具超时时间
    'async', true);             % 是否异步执行
```

## 输入模式定义

### 基本类型

```matlab
schema = struct();
schema.name = struct('type', 'string', 'required', true);
schema.age = struct('type', 'integer', 'default', 18);
schema.height = struct('type', 'number', 'minimum', 0);
schema.active = struct('type', 'boolean', 'default', true);
```

### 复杂类型

```matlab
schema = struct();
schema.array = struct('type', 'array', 'items', 'number');
schema.object = struct('type', 'object', 'properties', struct(...
    'x', struct('type', 'number'), ...
    'y', struct('type', 'number') ...
));
schema.choice = struct('type', 'string', 'enum', {{'option1', 'option2'}});
```

## 错误处理

### 抛出错误

```matlab
function result = myTool(args)
    if args.value < 0
        error('MCP:InvalidInput', '值不能为负数');
    end
    result = sqrt(args.value);
end
```

### 错误类型

- `MCP:InvalidInput` - 输入参数错误
- `MCP:ToolError` - 工具执行错误
- `MCP:Timeout` - 执行超时
- `MCP:InternalError` - 内部错误

## 日志记录

```matlab
% 设置日志级别
MCPServer.setLogLevel('DEBUG');

% 在工具中记录日志
function result = myTool(args)
    MCPServer.log('INFO', '开始执行工具');
    % ... 执行逻辑
    MCPServer.log('INFO', '工具执行完成');
end
```

## 示例项目

### CVI仿真服务器

```matlab
function createCVIServer()
    % 创建CVI仿真MCP服务器
    server = MCPServer('cvi-simulation');
    
    % 添加仿真工具
    server.addTool('run_simulation', @runCVISimulation, ...
        'description', '运行CVI仿真', ...
        'inputSchema', getCVISchema());
    
    % 添加结果工具
    server.addTool('get_results', @getResults, ...
        'description', '获取仿真结果', ...
        'inputSchema', struct(...
            'type', struct('type', 'string', 'enum', {{'porosity', 'density'}}) ...
        ));
    
    % 启动服务器
    server.start();
end

function schema = getCVISchema()
    schema = struct();
    schema.k_mesh = struct('type', 'integer', 'default', 0, ...
        'description', '网格类型 (0:粗网格, 1:中等网格, 2:细网格)');
    schema.T_process = struct('type', 'number', 'default', 1273, ...
        'description', '工艺温度 (K)');
    schema.ptot = struct('type', 'number', 'default', 5000, ...
        'description', '总压力 (Pa)');
    schema.Time_porecess = struct('type', 'number', 'default', 480, ...
        'description', '制备时间 (小时)');
end
```

## 部署

### 作为独立应用

```matlab
% 创建启动脚本
function startMCPServer()
    server = MCPServer('my-app');
    % 添加工具...
    server.start();
    
    % 保持运行
    while true
        pause(1);
    end
end
```

### 作为服务

```matlab
% 创建Windows服务或Linux守护进程
% 使用MATLAB Compiler编译为独立可执行文件
```

## 故障排除

### 常见问题

1. **端口被占用**
   - 更改端口号：`options.port = 8081;`

2. **权限问题**
   - 确保有网络访问权限
   - 检查防火墙设置

3. **内存不足**
   - 增加MATLAB内存限制
   - 优化工具函数

### 调试模式

```matlab
% 启用详细日志
MCPServer.setLogLevel('DEBUG');

% 启动服务器
server = MCPServer('debug-server');
server.start();
```

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 联系方式

- GitHub Issues: [项目地址]
- 邮箱: your.email@example.com
