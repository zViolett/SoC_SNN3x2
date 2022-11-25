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
        self.parameter_in       = CSRStorage(name="param_wdata",description='Param data send SNN', reset=0x0, size=368)
        self.param_winc         = CSRStorage(name="param_winc",description='Enable signal write param to CSRAM of SNN', reset=0x0, size=1)

        self.neuron_inst        = CSRStorage(name="neuron_inst_wdata",description='neuron_inst data send SNN', reset=0x0, size=2)
        self.neuron_inst_winc   = CSRStorage(name="neuron_inst_winc",description='Enable signal write neuron instruction to CSRAM of SNN', reset=0x0, size=1)

        self.packet_winc        = CSRStorage(name="packet_winc",description='Enable signal write packet in to CSRAM of SNN', reset=0x0, size=1)
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

        self.specials += Instance(
            "SNN_3x2"                                           ,
            i_clk               = self.clk                      ,
            i_reset_n           = ~ResetSignal()                ,
            i_sys_clk           = ClockSignal()                 ,
            i_sys_reset_n       = ~ResetSignal()                ,
            i_next_core         = self.next_core.storage        ,
            i_parameter_in      = self.parameter_in.storage     ,
            i_param_winc        = self.param_winc.storage       ,
            i_neuron_inst_wdata = self.neuron_inst.storage      ,
            i_neuron_inst_winc  = self.neuron_inst_winc.storage ,
            i_packet_winc       = self.packet_winc.storage      ,
            i_packet_wdata      = self.packet_wdata.storage     ,
            i_spike_en          = self.spike_en.storage         ,
            i_load_end          = self.load_end.storage         ,
            o_next_core_en      = self.next_core_en.we          ,
            o_tick_ready        = self.tick_ready.we            ,
            o_complete          = self.complete.we              ,
            o_spike_out         = self.spike_out.dat_w          ,
            o_grid_state        = self.grid_state.dat_w
        )

        platform.add_source_dir("ranc3x2")
        platform.add_source_dir("snn3x2")
        platform.add_source_dir("async_fifo")


            


