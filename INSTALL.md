# MATLAB MCP SDK 安装和部署指南

## 📦 安装步骤

### 1. 环境要求

**MATLAB版本要求：**
- MATLAB R2016b 或更高版本
- 支持HTTP服务器功能
- 支持JSON处理
- 支持面向对象编程

**系统要求：**
- Windows 10/11, macOS 10.14+, 或 Linux
- 网络访问权限
- 至少 4GB RAM

### 2. 下载和安装

```bash
# 1. 克隆或下载SDK
git clone <repository-url>
cd matlab-mcp-sdk

# 2. 在MATLAB中添加路径
addpath('matlab-mcp-sdk');
savepath;  % 保存路径设置
```

### 3. 验证安装

```matlab
% 测试SDK是否正常工作
try
    server = MCPServer('test-server');
    fprintf('✅ SDK安装成功！\n');
catch ME
    fprintf('❌ SDK安装失败: %s\n', ME.message);
end
```

## 🚀 快速测试

### 运行简单示例
```matlab
% 启动简单服务器
SimpleServer
```

### 测试服务器
1. 在浏览器中访问：`http://localhost:8080`
2. 应该看到服务器信息页面

## 🔧 配置MCP客户端

### Cursor配置

1. 打开Cursor设置
2. 找到MCP配置部分
3. 添加以下配置：

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

1. 打开Claude Desktop设置
2. 找到MCP配置部分
3. 添加以下配置：

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

## 🎯 CVI仿真服务器部署

### 1. 准备CVI项目
```matlab
% 确保CVI项目路径正确
addpath('..');  % 添加CVI项目路径

% 验证CVI函数可用
which main
```

### 2. 启动CVI服务器
```matlab
% 启动CVI仿真服务器
CVIServer
```

### 3. 配置CVI服务器
```json
{
  "mcpServers": {
    "cvi-simulation": {
      "command": "matlab",
      "args": ["-batch", "CVIServer"],
      "cwd": "/path/to/matlab-mcp-sdk"
    }
  }
}
```

## 🔍 调试和故障排除

### 常见问题

#### 1. 端口被占用
```matlab
% 更改端口号
options = struct();
options.port = 8081;
server = MCPServer('my-server', options);
```

#### 2. 路径问题
```matlab
% 检查路径设置
path
which MCPServer

% 重新添加路径
addpath('matlab-mcp-sdk');
```

#### 3. 权限问题
- 确保MATLAB有网络访问权限
- 检查防火墙设置
- 在Windows上以管理员身份运行

#### 4. 内存不足
```matlab
% 增加MATLAB内存限制
memory
```

### 调试模式

```matlab
% 启用详细日志
MCPServer.setLogLevel('DEBUG');

% 启动调试服务器
server = MCPServer('debug-server');
server.start();
```

## 📊 性能优化

### 1. 服务器配置
```matlab
options = struct();
options.timeout = 60;        % 增加超时时间
options.logLevel = 'WARN';   % 减少日志输出
server = MCPServer('optimized-server', options);
```

### 2. 工具优化
```matlab
% 使用异步执行
server.addTool('heavy_computation', @heavyFunction, ...
    'async', true, ...
    'timeout', 300);
```

### 3. 内存管理
```matlab
% 定期清理内存
clear variables;
pack;
```

## 🔒 安全配置

### 1. 访问控制
```matlab
% 限制访问IP
options.host = '127.0.0.1';  % 只允许本地访问
server = MCPServer('secure-server', options);
```

### 2. 输入验证
```matlab
% 在工具中验证输入
function result = secureTool(args)
    % 验证输入
    if ~isfield(args, 'input') || isempty(args.input)
        error('MCP:InvalidInput', '输入不能为空');
    end
    
    % 执行逻辑
    result = process(args.input);
end
```

## 📦 部署选项

### 1. 开发环境
```matlab
% 直接运行
SimpleServer
```

### 2. 生产环境
```matlab
% 使用MATLAB Compiler编译为独立可执行文件
mcc -m SimpleServer.m
```

### 3. 服务部署
```bash
# Linux系统服务
sudo systemctl enable matlab-mcp-server
sudo systemctl start matlab-mcp-server
```

## 📈 监控和日志

### 1. 日志配置
```matlab
% 设置日志级别
MCPServer.setLogLevel('INFO');

% 记录自定义日志
MCPServer.log('INFO', '服务器启动');
MCPServer.log('ERROR', '发生错误');
```

### 2. 性能监控
```matlab
% 监控工具执行时间
tic;
result = toolHandler(args);
execution_time = toc;
MCPServer.log('INFO', sprintf('工具执行时间: %.2f秒', execution_time));
```

## 🔄 更新和维护

### 1. 更新SDK
```bash
# 拉取最新代码
git pull origin main

# 重新添加路径
addpath('matlab-mcp-sdk');
```

### 2. 备份配置
```matlab
% 保存当前配置
save('mcp_config.mat', 'server_config');
```

### 3. 版本管理
```matlab
% 检查SDK版本
fprintf('SDK版本: %s\n', MCPServer.VERSION);
```

## 📞 技术支持

### 获取帮助
- 查看文档：`README.md`
- 运行示例：`SimpleServer` 或 `CVIServer`
- 检查日志：设置日志级别为 `DEBUG`

### 报告问题
- 提供MATLAB版本信息
- 包含错误日志
- 描述复现步骤

### 联系方式
- GitHub Issues
- 邮箱：your.email@example.com
