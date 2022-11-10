# note

## 上升沿触发或下降沿触发，测试输入信号看右值，其他信号看左值
## 或者看上升沿触发前后的信号变化
## 如果判断信号有可能为为
## clk上升沿的时候或者rst_n下降沿的时候，若rst_n为低电平，则触发，如果复位没有成功，也有可能因为上升沿<= next_state
- current_state = s0

## start低电平要保证有多于一个时钟周期
- note: 因为如果这个上升沿，看的是next_state的左值，next_state还没变，而下个上升沿，next_state受到输入信号start影响为0，则刚好跳过next_state为1这一个状态。
- clk 低电平时，next_state = current_state
- start 先0，S0->S1
- start 后1，S1->S2
- S2->S3

## current state
- IDLE
- START
- LOAD： raise load
- CE_P
- ENDING

## load
- pc, psa 清零
- int_x = x
- count = COUNT

## process
- S3开始时候
  - cout = 191
  - pc, psa 清零， xi获得正确值后
  - y_by_xi = xi * y  
  - a = p + y_by_xi
  - b = a + m
  - if (a mod 2) = 0 then p = a/2; else p = b/2;
  - next_pc, next_psa获得对应的值
- 下个时钟
  - count--
  - pc, psa = next_pc, next_psa
  - 移位寄存器右移
  - xi 获得下个值
  - y_by_xi = xi * y
  - a = p + y_by_xi
  - b = a + m
  - if (a mod 2) = 0 then p = a/2; else p = b/2;
  - next_pc, next_psa获得对应的值
- count == 0 的末尾
  - current_state = S4
  - z get value
- S4
  - 再等一个timer delay，保持输出
  - delay后，进入S0,done=1