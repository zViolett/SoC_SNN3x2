from sqlite3 import complete_statement
from migen import *

from litex.soc.interconnect.csr import *

from litex.soc.interconnect.csr_eventmanager import *

from litex.soc.integration.doc import AutoDoc, ModuleDoc

class snn_3x2(Module, AutoCSR, AutoDoc):
    def __init__(self, platform):
        self.intro = ModuleDoc(""" SNN 3x2 """)

        self.clk            = Signal()


        self.next_core          = CSRStorage(name="next_core",description='Core number will be load parameter', reset=0x0, size=3)
        # self.parameter_in       = CSRStorage(name="param_wdata",description='Param data send SNN', reset=0x0, size=368)
        # self.param_winc         = CSRStorage(name="param_winc",description='Enable signal write param to CSRAM of SNN', reset=0x0, size=1)
        self.param_wdata  = Signal(384)
        self.param0       = CSRStorage(name="param_wdata0",description='Param data0 send SNN', reset=0x0, size=32)
        self.param1       = CSRStorage(name="param_wdata1",description='Param data1 send SNN', reset=0x0, size=32)
        self.param2       = CSRStorage(name="param_wdata2",description='Param data2 send SNN', reset=0x0, size=32)
        self.param3       = CSRStorage(name="param_wdata3",description='Param data3 send SNN', reset=0x0, size=32)
        self.param4       = CSRStorage(name="param_wdata4",description='Param data4 send SNN', reset=0x0, size=32)
        self.param5       = CSRStorage(name="param_wdata5",description='Param data5 send SNN', reset=0x0, size=32)
        self.param6       = CSRStorage(name="param_wdata6",description='Param data6 send SNN', reset=0x0, size=32)
        self.param7       = CSRStorage(name="param_wdata7",description='Param data7 send SNN', reset=0x0, size=32)
        self.param8       = CSRStorage(name="param_wdata8",description='Param data8 send SNN', reset=0x0, size=32)
        self.param9       = CSRStorage(name="param_wdata9",description='Param data9 send SNN', reset=0x0, size=32)
        self.param10      = CSRStorage(name="param_wdata10",description='Param data10 send SNN', reset=0x0, size=32)
        self.param11      = CSRStorage(name="param_wdata11",description='Param data11 send SNN', reset=0x0, size=16)

        self.neuron_inst        = CSRStorage(name="neuron_inst_wdata",description='neuron_inst data send SNN', reset=0x0, size=2)
        # self.neuron_inst_winc   = CSRStorage(name="neuron_inst_winc",description='Enable signal write neuron instruction to CSRAM of SNN', reset=0x0, size=1)

        # self.packet_winc        = CSRStorage(name="packet_winc",description='Enable signal write packet in to CSRAM of SNN', reset=0x0, size=1)
        self.packet_wdata       = CSRStorage(name="packet_wdata",description='Packet data send SNN', reset=0x0, size=30)
        self.spike_en           = CSRStorage(name="spike_en",description='Enable signal to shoot spike out', reset=0x0, size=1)
        self.load_end           = CSRStorage(name="load_end",description='Signal notify that process ', reset=0x0, size=1)

        self.tick_ready         = CSRStorage(name="tick_ready",description='tick_ready', reset=0x0, size=1, write_from_dev=True)
        self.complete           = CSRStorage(name="complete",description='Complete process', reset=0x0, size=1, write_from_dev=True)
        self.spike_out          = CSRStorage(name="spike_out",description='Spike out from SNN', reset=0x0, size=250, write_from_dev=True)
        self.next_core_en       = CSRStorage(name="next_core_en",description='Enable next core to load param', reset=0x0, size=1, write_from_dev=True)
        self.grid_state         = CSRStorage(name="grid_state",description='Grid state of SNN', reset=0x0, size=3, write_from_dev=True)

        self.comb += self.next_core_en.dat_w.eq(1)
        self.comb += self.grid_state.we.eq(1)
        self.comb += self.tick_ready.dat_w.eq(1)
        self.comb += self.complete.dat_w.eq(1)
        self.comb += self.spike_out.we.eq(1)

        self.comb += self.param_wdata.eq(Cat(self.param0.storage, 
            self.param1.storage , 
            self.param2.storage , 
            self.param3.storage , 
            self.param4.storage , 
            self.param5.storage , 
            self.param6.storage , 
            self.param7.storage , 
            self.param8.storage , 
            self.param9.storage , 
            self.param10.storage,
            self.param11.storage 
        ))

        self.specials += Instance(
            "SNN_3x2"                                           ,
            i_clk               = self.clk                      ,
            i_reset_n           = ~ResetSignal()                ,
            i_sys_clk           = ClockSignal()                 ,
            i_sys_reset_n       = ~ResetSignal()                ,
            i_next_core         = self.next_core.storage        ,
            i_parameter_in      = self.param_wdata              ,
            i_param_winc        = self.param11.re               ,
            i_neuron_inst_wdata = self.neuron_inst.storage      ,
            i_neuron_inst_winc  = self.neuron_inst.re           ,
            i_packet_winc       = self.packet_wdata.re          ,
            i_packet_wdata      = self.packet_wdata.storage     ,
            i_spike_en          = self.spike_en.storage         ,
            i_load_end          = self.load_end.storage         ,
            o_next_core_en      = self.next_core_en.we          ,
            o_tick_ready        = self.tick_ready.we            ,
            o_complete          = self.complete.we              ,
            o_spike_out         = self.spike_out.dat_w          ,
            o_grid_state        = self.grid_state.dat_w
        )

        platform.add_source_dir("./ranc_sequence/ranc3x2")
        platform.add_source_dir("./ranc_sequence")
        platform.add_source_dir("./ranc_sequence/async_fifo")


            


