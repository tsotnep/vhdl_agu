----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Tsotnep
-- 
-- Create Date: 07/06/2015 06:09:40 PM
-- Design Name: 
-- Module Name: tb_agu - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SINGLEPORT_SRAM_AGU_types_n_constants.all;
use WORK.misc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_agu is
--  Port ( );
end tb_agu;

architecture Behavioral of tb_agu is
	component SINGLEPORT_SRAM_AGU is
		port(
			instr_complete_out : out STD_LOGIC;
			-- signals to memory START>>
			rw_addrs_out       : out STD_LOGIC_VECTOR(log2_ceil(RAM_DEPTH) - 1 downto 0); -- in memory: "A6, A5. . A0"
			Chip_Enable_out    : out STD_LOGIC; --in memory: CEB -- TODO this signal should be sent out from somewhere else, or, i should receive and bypass it
			Write_Enable_out   : out STD_LOGIC; --in memory: WEB
			--memory also receives Data ("D127. . D0"), and clock. 
			--memory sends out data ("Q127. . Q0")
			-- signals to memory END<<

			instr_in           : in  STD_LOGIC_VECTOR(INSTR_WIDTH - 1 downto 0);
			ReadORWrite_in     : in  STD_LOGIC;
			clk                : in  std_logic;
			rst                : in  std_logic
		);
	end component SINGLEPORT_SRAM_AGU;

	constant t : time := 10 ns;

	signal instr_complete_out : STD_LOGIC;
	signal rw_addrs_out       : STD_LOGIC_VECTOR(log2_ceil(RAM_DEPTH) - 1 downto 0);
	signal Chip_Enable_out    : STD_LOGIC;
	signal Write_Enable_out   : STD_LOGIC;
	signal instr              : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 downto 0);
	signal ReadORWrite_in     : STD_LOGIC;
	signal clk                : std_logic;
	signal rst                : std_logic;

	alias I_en_in                        : STD_LOGIC is instr(en_in_s); --Instruction_Enable_Input, this alias is on INSTR_IN, NOT on instr, because it will take 1 more clock cycle, when its '1' we accept incoming instruction
	-- Common
	alias I_mode                         : STD_LOGIC is instr(I_mode_s);
	alias I_start_addrs                  : STD_LOGIC_VECTOR is instr(I_start_addrs_e downto I_start_addrs_s);
	alias I_block_write_compressed       : STD_LOGIC_VECTOR is instr(I_block_write_e downto I_block_write_s);
	alias I_no_of_repetitions            : STD_LOGIC_VECTOR is instr(I_no_of_repetitions_e downto I_no_of_repetitions_s);
	alias I_repetition_delay             : STD_LOGIC_VECTOR is instr(I_repetition_delay_e downto I_repetition_delay_s);
	alias I_middle_delay                 : STD_LOGIC_VECTOR is instr(I_middle_delay_e downto I_middle_delay_s);
	alias I_initial_delay                : STD_LOGIC_VECTOR is instr(I_initial_delay_e downto I_initial_delay_s);
	-- Linear
	alias I_addr_range_Lin               : STD_LOGIC_VECTOR is instr(I_addr_range_Lin_e downto I_addr_range_Lin_s);
	alias I_addr_incr_signed             : STD_LOGIC_VECTOR is instr(I_addr_incr_signed_e downto I_addr_incr_signed_s);
	alias I_repetition_incr_signed       : STD_LOGIC_VECTOR is instr(I_repetition_incr_signed_e downto I_repetition_incr_signed_s);
	-- Bit Reverse
	alias I_addr_range_BitRev_compressed : STD_LOGIC_VECTOR is instr(I_addr_range_BitRev_e downto I_addr_range_BitRev_s);
	alias I_start_stage                  : STD_LOGIC_VECTOR is instr(I_start_stage_e downto I_start_stage_s);
	alias I_end_stage                    : STD_LOGIC_VECTOR is instr(I_end_stage_e downto I_end_stage_s);

begin
	SINGLEPORT_SRAM_AGU_inst : entity work.SINGLEPORT_SRAM_AGU
		port map(
			instr_complete_out => instr_complete_out,
			rw_addrs_out       => rw_addrs_out,
			Chip_Enable_out    => Chip_Enable_out,
			Write_Enable_out   => Write_Enable_out,
			instr_in           => instr,
			ReadORWrite_in     => ReadORWrite_in,
			clk                => clk,
			rst                => rst
		);

	clock_driver : process
	begin
		clk <= '0';
		wait for t / 2;
		clk <= '1';
		wait for t / 2;
	end process clock_driver;

	simulation : process is
	begin
		wait for 100 ns;

		wait;
	end process simulation;

end Behavioral;

