# MATLAB MCP SDK 快速开始指南

## 🚀 5分钟快速上手

### 1. 环境准备
确保您的MATLAB版本支持以下功能：
- HTTP服务器 (R2016b+)
- JSON处理 (R2016b+)
- 面向对象编程

### 2. 添加路径
```matlab
% 将SDK路径添加到MATLAB路径
addpath('matlab-mcp-sdk');
```

### 3. 运行简单示例
```matlab
% 启动简单服务器
SimpleServer
```

### 4. 测试服务器
在浏览器中访问：`http://localhost:8080`

## 📋 基本使用

### 创建MCP服务器
```matlab
% 创建服务器
server = MCPServer('my-server');

% 添加工具
server.addTool('my_tool', @myHandler, ...
    'description', '我的工具', ...
    'inputSchema', struct('param', 'string'));

% 启动服务器
server.start();
```

### 工具处理函数
```matlab
function result = myHandler(args)
    % args 是包含输入参数的结构体
    param = args.param;
    
    % 执行逻辑
    result = ['处理结果: ', param];
end
```

## 🔧 高级配置

### 服务器选项
```matlab
options = struct();
options.port = 8080;           % 端口号
options.host = 'localhost';     % 主机地址
options.logLevel = 'INFO';      % 日志级别
options.timeout = 30;           % 超时时间

server = MCPServer('my-server', options);
```

### 工具选项
```matlab
server.addTool('my_tool', @handler, ...
    'description', '工具描述', ...
    'inputSchema', schema, ...
    'timeout', 60, ...          % 工具超时时间
    'async', true);             % 异步执行
```

## 📊 输入模式定义

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
schema.choice = struct('type', 'string', 'enum', {{'option1', 'option2'}});
```

## 🎯 CVI仿真示例

### 启动CVI服务器
```matlab
% 确保CVI项目路径已添加
addpath('..');  % 添加CVI项目路径

% 启动CVI仿真服务器
CVIServer
```

### 可用工具
- `run_cvi_simulation` - 运行CVI仿真
- `get_simulation_results` - 获取仿真结果
- `visualize_results` - 可视化结果
- `export_results` - 导出结果
- `compare_with_experimental` - 与实验数据比较

## 🔍 调试和日志

### 设置日志级别
```matlab
% 设置详细日志
MCPServer.setLogLevel('DEBUG');

% 在工具中记录日志
MCPServer.log('INFO', '开始执行工具');
```

### 错误处理
```matlab
function result = myTool(args)
    try
        % 执行逻辑
        result = process(args);
    catch ME
        % 记录错误
        MCPServer.log('ERROR', ME.message);
        error('MCP:ToolError', ME.message);
    end
end
```

## 🌐 客户端配置

### Cursor配置
```json
{
  "mcpServers": {
    "matlab-server": {
      "command": "matlab",
      "args": ["-batch", "SimpleServer"],
      "cwd": "/path/to/matlab-mcp-sdk"
    }
  }
}
```

### Claude Desktop配置
```json
{
  "mcpServers": {
    "matlab-server": {
      "command": "matlab",
      "args": ["-batch", "SimpleServer"],
      "cwd": "/path/to/matlab-mcp-sdk"
    }
  }
}
```

## 🐛 故障排除

### 常见问题

1. **端口被占用**
   ```matlab
   options.port = 8081;  % 更改端口
   ```

2. **路径问题**
   ```matlab
   % 确保所有必要路径已添加
   addpath('matlab-mcp-sdk');
   addpath('..');  % CVI项目路径
   ```

3. **权限问题**
   - 确保MATLAB有网络访问权限
   - 检查防火墙设置

### 调试模式
```matlab
% 启用详细日志
MCPServer.setLogLevel('DEBUG');

% 启动服务器
server = MCPServer('debug-server');
server.start();
```

## 📚 示例项目

### 简单服务器
```matlab
SimpleServer  % 基本功能演示
```

### CVI仿真服务器
```matlab
CVIServer     % CVI仿真功能
```

## 🎯 下一步

1. 运行示例服务器
2. 配置MCP客户端
3. 创建自定义工具
4. 部署到生产环境

## 📞 获取帮助

- 查看详细文档：`README.md`
- 运行示例：`SimpleServer` 或 `CVIServer`
- 检查日志：设置日志级别为 `DEBUG`
