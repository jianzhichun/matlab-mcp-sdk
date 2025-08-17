function SimpleServer()
    %SimpleServer 简单的MCP服务器示例
    %   演示基本的MCP服务器功能
    
    fprintf('🚀 启动简单MCP服务器...\n');
    
    % 创建MCP服务器
    server = MCPServer('simple-server');
    
    % 添加简单计算工具
    server.addTool('add', @addNumbers, ...
        'description', '计算两个数的和', ...
        'inputSchema', struct(...
            'a', struct('type', 'number', 'description', '第一个数'), ...
            'b', struct('type', 'number', 'description', '第二个数') ...
        ));
    
    % 添加字符串处理工具
    server.addTool('reverse', @reverseString, ...
        'description', '反转字符串', ...
        'inputSchema', struct(...
            'text', struct('type', 'string', 'description', '要反转的字符串') ...
        ));
    
    % 添加数组处理工具
    server.addTool('sort_array', @sortArray, ...
        'description', '对数组进行排序', ...
        'inputSchema', struct(...
            'array', struct('type', 'array', 'description', '要排序的数组'), ...
            'ascending', struct('type', 'boolean', 'default', true, 'description', '是否升序') ...
        ));
    
    % 添加数学计算工具
    server.addTool('calculate', @calculate, ...
        'description', '执行数学计算', ...
        'inputSchema', struct(...
            'operation', struct('type', 'string', 'enum', {{'add', 'subtract', 'multiply', 'divide', 'power'}}, ...
                'description', '运算类型'), ...
            'a', struct('type', 'number', 'description', '第一个操作数'), ...
            'b', struct('type', 'number', 'description', '第二个操作数') ...
        ));
    
    % 启动服务器
    server.start();
    
    fprintf('✅ 简单MCP服务器已启动\n');
    fprintf('📊 可用工具:\n');
    fprintf('  - add (加法)\n');
    fprintf('  - reverse (字符串反转)\n');
    fprintf('  - sort_array (数组排序)\n');
    fprintf('  - calculate (数学计算)\n');
    fprintf('\n🌐 服务器地址: http://localhost:8080\n');
    fprintf('按 Ctrl+C 停止服务器\n');
    
    % 保持服务器运行
    try
        while true
            pause(1);
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:interrupt')
            fprintf('\n🛑 正在停止服务器...\n');
            server.stop();
            fprintf('✅ 服务器已停止\n');
        else
            rethrow(ME);
        end
    end
end

function result = addNumbers(args)
    %addNumbers 计算两个数的和
    
    a = args.a;
    b = args.b;
    
    result = a + b;
end

function result = reverseString(args)
    %reverseString 反转字符串
    
    text = args.text;
    result = fliplr(text);
end

function result = sortArray(args)
    %sortArray 对数组进行排序
    
    array = args.array;
    ascending = args.ascending;
    
    if ascending
        result = sort(array);
    else
        result = sort(array, 'descend');
    end
end

function result = calculate(args)
    %calculate 执行数学计算
    
    operation = args.operation;
    a = args.a;
    b = args.b;
    
    switch operation
        case 'add'
            result = a + b;
        case 'subtract'
            result = a - b;
        case 'multiply'
            result = a * b;
        case 'divide'
            if b == 0
                error('除数不能为零');
            end
            result = a / b;
        case 'power'
            result = a ^ b;
        otherwise
            error('未知的运算类型: %s', operation);
    end
end
