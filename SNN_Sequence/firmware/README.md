[> Run compile
----------------------
python3 firmware.py --build-path='../build/xilinx_kc705'


[> Build and Load over LiteX-Term
---------------------------------
litex_term /dev/ttyUSB0 --kernel=firmware.bin
