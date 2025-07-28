/*
File : pcie_tlp_uvm.sv
Idea : A simple UVM testbench to create random PCIe TLP transactions.
By : Albert Chiang

*/

interface Vintf (input bit clk, input bit rst);
  logic valid;
  logic [4:0] cmd_type;
  logic [4:0] requestor_id;
  
endinterface

class DataPcie extends uvm_sequence_item;
  rand bit [4:0] cmd_type;
  rand bit [15:0] requestor_id;

  `uvm_object_utils_begin(DataPcie)
  `uvm_field_int(cmd_type, UVM_ALL_ON)
  `uvm_field_int(requestor_id, UVM_ALL_ON)
  `uvm_object_utils_end
  
  constraint cons_pcie_0 {
    requestor_id <= 5; // only five
  }
  function print_all(string msg="");
    $display("%s PCIe cmd_type is %h, requestor_id is %h\n", msg, cmd_type, requestor_id);
  endfunction
endclass

class SequencePcie extends uvm_sequence#(DataPcie);
  
  `uvm_object_utils(SequencePcie)
  int nop = 1; // number of packets
  task body();
    
    DataPcie req = DataPcie::type_id::create("req");    
    `uvm_info("Start_Item  ", "before ", UVM_HIGH);    
    start_item(req);
    `uvm_info("Start_Item  ", "after ", UVM_HIGH);    
    req.cmd_type = 5'b11011;
    `uvm_info("Finish_Item  ", "before ", UVM_HIGH);   
    req.print_all("***DATA CREATED***");
    finish_item(req);
    `uvm_info("Finish_Item  ", "after ", UVM_HIGH);    
    
    
        
    `uvm_info("Sequence Body  ", "pre-do ", UVM_HIGH);    
     req = DataPcie::type_id::create("req");
    `uvm_do_with(req, {cmd_type==5'b00100;}) 
    req.print_all("***DATA CREATED***");    
    `uvm_info("Sequence Body  ", "post-do ", UVM_HIGH);
    
    repeat(nop) begin
    `uvm_info("Sequence Body  ", "pre-do ", UVM_HIGH);    
     req = DataPcie::type_id::create("req");
    `uvm_do(req)
    req.print_all("***DATA CREATED***");      
    `uvm_info("Sequence Body  ", "post-do ", UVM_HIGH);
    end
  endtask // body
endclass

class DriverPcie extends uvm_driver#(DataPcie);
  
  `uvm_component_utils(DriverPcie) // registered with the factory
  virtual Vintf vintf_0;
  
  function new(string name = "DriverPcie", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual Vintf)::get(this, "", "vintf", vintf_0))
      `uvm_fatal("NOVIF", "Failed to get virtual interface")
      
  endfunction
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    @vintf_0.clk;
    forever begin // critical! else 9200 timeout
    `uvm_info("DriverPcie", "run_phase", UVM_HIGH);

    `uvm_info("DriverPcie ", "before get_next_item", UVM_HIGH);
    seq_item_port.get_next_item(req);
    // req.print_all();
    `uvm_info("DriverPcie ", "after get_next_item", UVM_HIGH);
    #0 vintf_0.valid = 1'b1;
    #0 vintf_0.cmd_type = req.cmd_type;
    @vintf_0.clk;
    #0 vintf_0.requestor_id = req.requestor_id;   
    @vintf_0.clk;
    #0 vintf_0.valid = 1'b0;      
    @vintf_0.clk;

      
    #200;
    `uvm_info("DriverPcie ", "before item_done", UVM_HIGH);    
    seq_item_port.item_done(req);
    `uvm_info("DriverPcie ", "after item_done", UVM_HIGH);
    end // forever

  endtask; // run_phase
endclass

class MonitorPcie extends uvm_monitor; // uvm_subscriber#(DataPcie);
  
  `uvm_component_utils(MonitorPcie)
  virtual Vintf vintf_0;
    
  function  new(string name="", uvm_component parent);
    super.new(name, parent);
  endfunction 
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual Vintf)::get(this, "", "vintf", vintf_0))
      `uvm_fatal("NOVIF", "Failed to get virtual interface")
      
  endfunction  
  task run_phase(uvm_phase uvm);
    super.run_phase(uvm);
    forever begin
      @vintf_0.clk;
      @(posedge vintf_0.valid)
          $display("MonitorPcie cmd_type = %h \n", vintf_0.cmd_type);
    end
  endtask
endclass

class AgentPcie extends uvm_agent;

  `uvm_component_utils(AgentPcie)
  DriverPcie driverpcie_0;
  typedef uvm_sequencer#(DataPcie) SequencerPcie;
  SequencerPcie sequencerpcie_0;
  MonitorPcie monitorpcie_0;
  virtual Vintf vintf_0;
  

  
  // declare an anlysis port to connect to coverage
  // declare an anlysis port to connect to scoreboard
  uvm_analysis_port #(DataPcie)   ap_out;
  
  function new(string name="", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driverpcie_0 = DriverPcie::type_id::create("driverpcie_0", this);
    sequencerpcie_0 = SequencerPcie::type_id::create("sequencerpcie_0", this);
    monitorpcie_0 = MonitorPcie::type_id::create("monitorpcie_0", this);
    ap_out = new("ap_out", this); // new(); // uvm_analysis_port #(DataPcie)::type_id::create("ap_out", this);
    
  // create an anlysis port to connect to coverage
  // create an anlysis port to connect to 
    
    
  
  endfunction 
  
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driverpcie_0.seq_item_port.connect(sequencerpcie_0.seq_item_export);
    // connect monitor to port to scoreboard
    // connect monitor to port to coverage
    
  endfunction 
  
endclass

class ScoreboardPcie extends uvm_scoreboard;
  `uvm_component_utils(ScoreboardPcie)
  function new(string name="", uvm_component parent);
    super.new(name, parent);
  endfunction 
  
endclass

class CoveragePcie extends uvm_subscriber#(DataPcie); // uvm_coverage;
  `uvm_component_utils(CoveragePcie)
  
  function new(string name="", uvm_component parent);
    super.new(name, parent);
  endfunction 
  
  covergroup CgPcie (DataPcie t);    
      cmd_type_bin: coverpoint t.cmd_type;
  endgroup
  
  function void write(DataPcie datain); // Virtual method 'write' not implemented 
  endfunction


endclass

class EnvPcie extends uvm_env;
  `uvm_component_utils(EnvPcie)
  AgentPcie agentpcie_0;
  ScoreboardPcie scoreboardpcie_0;
  CoveragePcie coveragepcie_0;
 
  function new(string name="", uvm_component parent);
    super.new(name, parent);
  endfunction 
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("EnvPcie", "build_phase", UVM_HIGH);
    agentpcie_0 = AgentPcie::type_id::create("agentpci_0", this);    
    
    
    coveragepcie_0 = new("coveragepcie_0", this); //  CoveragePcie::type_id::create("coveragepcie_0", this);
    
    scoreboardpcie_0 = new("scoreboardpcie_0", this); // ScoreboardPcie::type_id::create("scoreboardpcie_0", this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
  endfunction 
endclass // EnvPcie


class TestPcie extends uvm_test;
  
  `uvm_component_utils(TestPcie)
  EnvPcie envpcie_0;
  SequencePcie sequencepcie_0;
  
  function new(string name="", uvm_component parent);
    super.new(name,parent);
  endfunction 
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TestPcie", "build_phase", UVM_HIGH);
    uvm_config_db#(int)::set(this, "*", "nop", 10);    
    sequencepcie_0 = SequencePcie::type_id::create("sequencepcie_0"); // , this);
    envpcie_0 = EnvPcie::type_id::create("envpcie_0", this);

  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("TestPcie", "run_phase", UVM_HIGH);
    phase.raise_objection(this);

    
    // sequencepcie_0 = SequencePcie::type_id::create("sequencepcie_0"); //, this);

    sequencepcie_0.start(envpcie_0.agentpcie_0.sequencerpcie_0);
    #300;
    phase.drop_objection(this);

  endtask
endclass



module dut (i_clk, i_rst, i_valid, i_cmd_type, i_requestor_id, o_requestor_id, o_data);
  input i_clk;
  input i_rst;  
  input i_valid;
  input [3:0] i_cmd_type;
  input i_requestor_id;
  output o_requestor_id;
  output [15:0] o_data;

endmodule

module top;
  
  reg clk;
  reg rst;
  
  Vintf dutintf(
    .clk(clk),
    .rst(rst)
  );

  initial begin
    // $vcdpluson;
    $dumpfile("dump.vcd"); 
    $dumpvars(0, top);
  end

  
  initial begin
    clk = 1'b0;
  end
  
  always begin
    #25 clk = ~clk;
    $display("clk wiggle is %b \n", clk);
  end
  
  
  initial begin
    
    `uvm_info("Module Top", "Started! ", UVM_LOW);
    // uvm_test_top :
    uvm_config_db#(virtual Vintf)::set(null, "uvm_test_top.*", "vintf", dutintf); // works
    //uvm_config_db#(virtual Vintf)::set(null, "uvm_test_top.*", "vintf_0", dutintf); // doesn't work
    
    // uvm_config_db#(virtual Vintf)::set(null, "top.*", "vintf_0", dutintf); // works
    
    
    run_test("TestPcie");
  end
endmodule










