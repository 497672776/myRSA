# note

## reset
- current_state = s0
- next_state = s0

## start
- clk 低电平时，next_state = current_state
- start 先0，S0->S1
- start 后1，S1->S2
- S2->S3

## current state
- reset:0
- start0： S1
- start1:  S2
- 等一个周期:  S3

## state chage out
- S2 raise load, 但是S3的时候才开始计数

## load
- pc, psa 清零
- int_x = x
- count = COUNT

## process
- S3开始时候
  - cout = 192
  - e = exp_k
  - int_x = x
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