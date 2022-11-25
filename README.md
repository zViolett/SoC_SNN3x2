# SoC_SNN3x2

## Origin design
```Shell
All neuron parameter are initial by constant value so tool not synthesis them as register, except a little bit like these:
    "else if(update_potential) begin
        for(i = 0; i<256; i = i + 1) neuron_parameter[i][111:103] <= potential_out[i];
    end"
    Total flip flip will be synthesis is (9*256*5)= 11520
```

## Flex_loader_all desgin
```Shell
Because we use a fifo to load parameter into SNN, the memory used to store value of neuron parameter will be synthesis as register (flip flop). So total of flip flip will be synthesis is (356*256*5) = 471040. 
So we cant synthesis the design using kc705 which just has about 400000 flip flop
That why using another FPGA with more cell will be fine~ 
```
## Flex_loader_packet design
```Shell
This design fixed parameter in CSRAM like original design and change the fixed packet_in, use a fifo to load packet_in.
If we use kc705 so we need to use this. The total of flip flop after synthesis is 59395 (met requirement)
```

## Finally
```Shell
To integrated SNN vs SoC in LiteX. You need to modify files: soc_linux.py, make.py
    import migen module to soc_linux.py then add a function to initial an SNN
    Then call that function in make.py
```
