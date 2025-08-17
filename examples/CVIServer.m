function CVIServer()
    %CVIServer CVI仿真MCP服务器示例
    %   演示如何使用MATLAB MCP SDK创建CVI仿真服务器
    
    fprintf('🚀 启动CVI仿真MCP服务器...\n');
    
    % 创建MCP服务器
    options = struct();
    options.port = 8080;
    options.logLevel = 'INFO';
    
    server = MCPServer('cvi-simulation', options);
    
    % 添加CVI仿真工具
    server.addTool('run_cvi_simulation', @runCVISimulation, ...
        'description', '运行CVI仿真计算', ...
        'inputSchema', getCVISchema());
    
    % 添加结果获取工具
    server.addTool('get_simulation_results', @getSimulationResults, ...
        'description', '获取仿真结果数据', ...
        'inputSchema', struct(...
            'result_type', struct('type', 'string', 'enum', {{'porosity', 'density', 'temperature', 'concentration'}}) ...
        ));
    
    % 添加可视化工具
    server.addTool('visualize_results', @visualizeResults, ...
        'description', '可视化仿真结果', ...
        'inputSchema', struct(...
            'plot_type', struct('type', 'string', 'enum', {{'contour', 'surface', 'line'}}, 'default', 'contour'), ...
            'variable', struct('type', 'string', 'default', 'por_f') ...
        ));
    
    % 添加导出工具
    server.addTool('export_results', @exportResults, ...
        'description', '导出仿真结果', ...
        'inputSchema', struct(...
            'format', struct('type', 'string', 'enum', {{'mat', 'csv', 'json'}}, 'default', 'mat'), ...
            'filename', struct('type', 'string', 'default', 'cvi_results') ...
        ));
    
    % 添加比较工具
    server.addTool('compare_with_experimental', @compareWithExperimental, ...
        'description', '与实验数据比较', ...
        'inputSchema', struct(...
            'experimental_file', struct('type', 'string'), ...
            'comparison_type', struct('type', 'string', 'enum', {{'porosity', 'density'}}, 'default', 'porosity') ...
        ));
    
    % 启动服务器
    server.start();
    
    fprintf('✅ CVI仿真MCP服务器已启动\n');
    fprintf('📊 可用工具:\n');
    fprintf('  - run_cvi_simulation\n');
    fprintf('  - get_simulation_results\n');
    fprintf('  - visualize_results\n');
    fprintf('  - export_results\n');
    fprintf('  - compare_with_experimental\n');
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

function schema = getCVISchema()
    %getCVISchema 获取CVI仿真参数模式
    
    schema = struct();
    
    % 网格参数
    schema.k_mesh = struct('type', 'integer', 'default', 0, ...
        'description', '网格类型 (0:粗网格, 1:中等网格, 2:细网格)');
    
    % 维度参数
    schema.k_dim = struct('type', 'integer', 'default', 1, ...
        'description', '维度类型 (0:一维复合材料, 1:二维复合材料)');
    
    % 纤维参数
    schema.k_fiber = struct('type', 'integer', 'default', 0, ...
        'description', '纤维类型 (0:碳纤维, 1:碳化硅纤维)');
    
    % 气体成分参数
    schema.x_MTS = struct('type', 'number', 'default', 0.0476, ...
        'description', 'MTS摩尔分数');
    schema.x_H2 = struct('type', 'number', 'default', 0.4762, ...
        'description', 'H2摩尔分数');
    schema.x_Ar = struct('type', 'number', 'default', 0.4762, ...
        'description', 'Ar摩尔分数');
    
    % 工艺参数
    schema.T_process = struct('type', 'number', 'default', 1273, ...
        'description', '工艺温度 (K)');
    schema.ptot = struct('type', 'number', 'default', 5000, ...
        'description', '总压力 (Pa)');
    schema.Flux = struct('type', 'number', 'default', 210, ...
        'description', '气体通量 (SCCM)');
    
    % 几何参数
    schema.x = struct('type', 'number', 'default', 0.3, ...
        'description', '反应器长度 (m)');
    schema.y = struct('type', 'number', 'default', 0.1, ...
        'description', '反应器直径 (m)');
    schema.hx_sub = struct('type', 'number', 'default', 0.065, ...
        'description', '基体长度 (m)');
    schema.hy_sub = struct('type', 'number', 'default', 0.01, ...
        'description', '基体厚度 (m)');
    schema.h_inlet = struct('type', 'number', 'default', 0.01, ...
        'description', '入口半径 (m)');
    schema.h_outlet = struct('type', 'number', 'default', 0.015, ...
        'description', '出口半径 (m)');
    
    % 时间参数
    schema.Time_porecess = struct('type', 'number', 'default', 480, ...
        'description', '制备时间 (小时)');
    
    % 材料参数
    schema.Vf0 = struct('type', 'number', 'default', 0.444, ...
        'description', '纤维体积分数');
    schema.rf = struct('type', 'number', 'default', 3.5e-6, ...
        'description', '纤维半径 (m)');
    schema.Hb = struct('type', 'number', 'default', 1.5e-3, ...
        'description', '纤维束厚度 (m)');
end

function result = runCVISimulation(args)
    %runCVISimulation 运行CVI仿真
    
    MCPServer.log('INFO', '开始CVI仿真计算');
    
    try
        % 提取参数
        k_mesh = args.k_mesh;
        k_dim = args.k_dim;
        k_fiber = args.k_fiber;
        x_MTS = args.x_MTS;
        x_H2 = args.x_H2;
        x_Ar = args.x_Ar;
        T_process = args.T_process;
        ptot = args.ptot;
        Flux = args.Flux;
        x = args.x;
        y = args.y;
        hx_sub = args.hx_sub;
        hy_sub = args.hy_sub;
        h_inlet = args.h_inlet;
        h_outlet = args.h_outlet;
        Time_porecess = args.Time_porecess;
        Vf0 = args.Vf0;
        rf = args.rf;
        Hb = args.Hb;
        
        % 记录参数
        MCPServer.log('INFO', sprintf('仿真参数: k_mesh=%d, T=%gK, p=%gPa, t=%gh', ...
            k_mesh, T_process, ptot, Time_porecess));
        
        % 调用MATLAB main函数
        [por_tot_ave, dens_tot_ave] = main(k_mesh, k_dim, k_fiber, x_MTS, x_H2, x_Ar, ...
            T_process, ptot, Flux, x, y, hx_sub, hy_sub, h_inlet, h_outlet, ...
            Time_porecess, Vf0, rf, Hb);
        
        % 构建结果
        result = struct();
        result.success = true;
        result.porosity = por_tot_ave;
        result.density = dens_tot_ave;
        result.message = sprintf('CVI仿真完成！平均孔隙率: %.6f, 平均密度: %.6f kg/m³', ...
            por_tot_ave, dens_tot_ave);
        
        MCPServer.log('INFO', 'CVI仿真计算完成');
        
    catch ME
        MCPServer.log('ERROR', sprintf('CVI仿真失败: %s', ME.message));
        result = struct();
        result.success = false;
        result.error = ME.message;
    end
end

function result = getSimulationResults(args)
    %getSimulationResults 获取仿真结果
    
    result_type = args.result_type;
    
    try
        switch result_type
            case 'porosity'
                % 获取孔隙率数据
                if exist('por_f', 'var') && exist('por_b', 'var')
                    result = struct();
                    result.por_f = por_f;
                    result.por_b = por_b;
                    result.por_tot_ave = por_tot_ave;
                    result.message = '孔隙率数据获取成功';
                else
                    error('仿真数据不存在，请先运行仿真');
                end
                
            case 'density'
                % 获取密度数据
                if exist('dens_tot_ave', 'var')
                    result = struct();
                    result.density = dens_tot_ave;
                    result.message = '密度数据获取成功';
                else
                    error('密度数据不存在，请先运行仿真');
                end
                
            case 'temperature'
                % 获取温度数据
                if exist('T', 'var')
                    result = struct();
                    result.temperature = T;
                    result.message = '温度场数据获取成功';
                else
                    error('温度数据不存在，请先运行仿真');
                end
                
            case 'concentration'
                % 获取浓度数据
                if exist('xx_MTS', 'var')
                    result = struct();
                    result.concentration = xx_MTS;
                    result.message = '浓度场数据获取成功';
                else
                    error('浓度数据不存在，请先运行仿真');
                end
                
            otherwise
                error('未知的结果类型: %s', result_type);
        end
        
    catch ME
        result = struct();
        result.success = false;
        result.error = ME.message;
    end
end

function result = visualizeResults(args)
    %visualizeResults 可视化仿真结果
    
    plot_type = args.plot_type;
    variable = args.variable;
    
    try
        switch plot_type
            case 'contour'
                % 生成等高线图
                display_CVI();
                result = struct();
                result.success = true;
                result.message = sprintf('已生成%s的等高线图', variable);
                
            case 'surface'
                % 生成3D表面图
                display_CVI1();
                result = struct();
                result.success = true;
                result.message = sprintf('已生成%s的3D表面图', variable);
                
            case 'line'
                % 生成线图
                Compare();
                result = struct();
                result.success = true;
                result.message = sprintf('已生成%s的线图', variable);
                
            otherwise
                error('未知的图表类型: %s', plot_type);
        end
        
    catch ME
        result = struct();
        result.success = false;
        result.error = ME.message;
    end
end

function result = exportResults(args)
    %exportResults 导出仿真结果
    
    format = args.format;
    filename = args.filename;
    
    try
        switch format
            case 'mat'
                % 导出为MATLAB格式
                save(sprintf('%s.mat', filename), 'por_f', 'por_b', 'dens_tot', 'T', 'xx_MTS');
                result = struct();
                result.success = true;
                result.message = sprintf('结果已导出为 %s.mat', filename);
                
            case 'csv'
                % 导出为CSV格式
                writematrix(por_f, sprintf('%s_por_f.csv', filename));
                writematrix(dens_tot, sprintf('%s_dens_tot.csv', filename));
                result = struct();
                result.success = true;
                result.message = sprintf('结果已导出为 %s_*.csv', filename);
                
            case 'json'
                % 导出为JSON格式
                data = struct();
                data.porosity = por_f;
                data.density = dens_tot;
                data.temperature = T;
                data.concentration = xx_MTS;
                
                fid = fopen(sprintf('%s.json', filename), 'w');
                fprintf(fid, jsonencode(data));
                fclose(fid);
                
                result = struct();
                result.success = true;
                result.message = sprintf('结果已导出为 %s.json', filename);
                
            otherwise
                error('不支持的导出格式: %s', format);
        end
        
    catch ME
        result = struct();
        result.success = false;
        result.error = ME.message;
    end
end

function result = compareWithExperimental(args)
    %compareWithExperimental 与实验数据比较
    
    experimental_file = args.experimental_file;
    comparison_type = args.comparison_type;
    
    try
        % 检查实验文件是否存在
        if ~exist(experimental_file, 'file')
            error('实验数据文件不存在: %s', experimental_file);
        end
        
        % 加载实验数据
        exp_data = load(experimental_file);
        
        % 执行比较
        Compare();
        
        result = struct();
        result.success = true;
        result.message = sprintf('已完成与实验数据的%s比较', comparison_type);
        
    catch ME
        result = struct();
        result.success = false;
        result.error = ME.message;
    end
end
