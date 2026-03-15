# 支付流程模板 - 最终修正版

<div style="background-color: white; padding: 30px; border-radius: 10px;">

```mermaid
%%{init: { 'theme': 'base', 'themeVariables': { 'primaryColor': '#1A237E', 'primaryTextColor': '#333333', 'primaryBorderColor': '#00E5FF', 'lineColor': '#3F51B5', 'mainBkg': '#FFFFFF' } } }%%

sequenceDiagram
    autonumber

    %% 【2. 角色声明区】
    actor U as 最终用户
    
    box "商城内部系统" #f9f9f9
    participant O as 订单服务
    participant DB as 数据库
    end
    
    participant P as 第三方支付网关

    %% 【3. 业务流程区】
    rect rgba(0, 229, 255, 0.05)
    Note over U, DB: 阶段一：创建订单
    U->>O: 1. 提交购物车
    activate O
    
    O->>DB: 2. 写入订单数据
    activate DB
    DB-->>O: 3. 确认写入完毕
    deactivate DB
    
    O-->>U: 4. 返回订单ID
    deactivate O
    end

    rect rgba(124, 77, 255, 0.05)
    Note over U, P: 阶段二：支付处理
    U->>O: 5. 发起支付请求
    activate O
    
    alt 账户余额充足
        O->>P: 6a. 调用支付接口
        activate P
        P-->>O: 7a. 支付成功
        deactivate P
    else 余额不足
        O-->>U: 6b. 提示：请更换支付方式
    end
    
    loop 每3秒检查一次
        O->>P: 8. 查询支付最终状态
        P-->>O: 9. 状态确认中/已完成
    end
    
    O-)DB: 10. 异步记录支付日志
    
    O-->>U: 11. 支付完成通知
    deactivate O
    end