---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described OUT this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to TUT(Tallinn University of Technology), School of ICT, Tallinn.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-- This is a single port agu for sram, single port, with linear and bitreverse addressing
-- 
--
-- Authors: Tsotne Putkaradze: MSc student, Tallinn University of Technology, Tallinn, Estonia
-- Contact: tsotnep@gmail.com

-- MANUAL : 
-- in order to easily find unresolved problems i'm thinking/doubting about, in this .vhd file search following "todo" or "fixme" (in capitals) this notations are inserted before the problems
-- "R_" prefix on signal means that they are registered
-- "I_" prefix on signal means that they are coming from instruction, and they are used for initialization, of internal registers. p.s. "rst" will set registers to Initial(from instruction) values
-- "C_" prefix means that this is a constant
-- "Temp_" prefix means that those signals are mediator signals, they are written into Registers only and those Registers are used
-- "_F" suffix on signals means that they are flags, all flags are set in the process:  "p_agu_flags"
-- "_out" for outputs, "_in" for inputs that are coming/going out of this level. p.s. "clk" & "rst" are not included, because they are obviously coming in
-- "D_" prefix means that the signal is for debugging purposes only
--
--
--how instruction is constructed	:>>>	https://docs.google.com/spreadsheets/d/1zUvdOKi023mmes7M3CIJklkbMKO7kdfh_HAJW8fpqao/edit?usp=sharing
--how datapath(adders) are working	:>>> 	https://docs.google.com/spreadsheets/d/1J7qNa5KIMdewgwvclDDZ3f-6xOBjqZQdGJDXpvqDDs4/edit?usp=sharing
--testing results/"temporary" 		:>>>	https://docs.google.com/spreadsheets/d/1c6jzTM9B4mgosP96rNVu41_JvnBQc66nKKg-5qb8KQo/edit?usp=sharing
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SINGLEPORT_SRAM_AGU_types_n_constants.all;
use WORK.misc.all;

-- this version is not complite, it works only with delays > 2
-- date of updaing this comment
-- Fri 3 Jul 01:44:31 (GEO)


entity SINGLEPORT_SRAM_AGU is
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
end entity SINGLEPORT_SRAM_AGU;

--Note about TSEL0, TSEL1:
--The timing data is characterized based on TSEL[1]=0 and TSEL[0]=1 setting.
--The following is the detail description.
--(TSEL[1],TSEL[0])=(0,0) : Aggressive read margin setting. The operation voltage range is guaranteed from 1.08v to 1.32v  based on simulation data.
--(TSEL[1],TSEL[0])=(0,1) : Please use this setting. Recommended setting with the optimized design margin
--(TSEL[1],TSEL[0])=(1,0) : Used for functional debugging purpose.
--(TSEL[1],TSEL[0])=(1,1) : Used for functional debugging purpose.

architecture RTL of SINGLEPORT_SRAM_AGU is
	-- Constants 
	constant C_zero6    : STD_LOGIC_VECTOR(5 downto 0)                                           := (others => '0');
	constant C_zero7    : STD_LOGIC_VECTOR(6 downto 0)                                           := (others => '0');
	constant C_zero8    : STD_LOGIC_VECTOR(7 downto 0)                                           := (others => '0');
	constant C_zero9    : STD_LOGIC_VECTOR(8 downto 0)                                           := (others => '0');
	constant C_one6     : STD_LOGIC_VECTOR(5 downto 0)                                           := (0 => '1', others => '0');
	constant C_one7     : STD_LOGIC_VECTOR(6 downto 0)                                           := (0 => '1', others => '0');
	constant C_one9     : STD_LOGIC_VECTOR(8 downto 0)                                           := (0 => '1', others => '0');
	constant C_signNeg1 : signed(I_no_of_repetitions_e - I_no_of_repetitions_s downto 0)         := (others => '1');
	constant C_signPos1 : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0) := (0 => '1', others => '0');

	--Instructions, values for Initialization
	--general
	--signal skip_incr, start_instr_exe : std_logic; -- TODO for FFT, previous designer was using this signal fft-skip_incr
	signal AGUst, AGUnst : AGU_SRAM_STATE_TYPE; -- main FSMs State and NextState
	signal DELAYdecoder  : AGU_SRAM_DELAY_TYPE; -- Delay FSMs State and NextState

	ALIAS I_en_in                        : STD_LOGIC is instr_in(en_in_s); --Instruction_Enable_Input, this alias is on INSTR_IN, NOT on instr, because it will take 1 more clock cycle, when its '1' we accept incoming instruction
	signal instr                         : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 downto 0); --we are just coping instr_in - in here; --I_mode = 0 for Linear, =1 for Bitreverse accessing
	-- Common
	ALIAS I_mode                         : STD_LOGIC is instr(I_mode_s);
	ALIAS I_start_addrs                  : STD_LOGIC_VECTOR is instr(I_start_addrs_e downto I_start_addrs_s);
	ALIAS I_block_write_compressed       : STD_LOGIC_VECTOR is instr(I_block_write_e downto I_block_write_s);
	signal I_block_write                 : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	ALIAS I_no_of_repetitions            : STD_LOGIC_VECTOR is instr(I_no_of_repetitions_e downto I_no_of_repetitions_s);
	ALIAS I_repetition_delay             : STD_LOGIC_VECTOR is instr(I_repetition_delay_e downto I_repetition_delay_s);
	ALIAS I_middle_delay                 : STD_LOGIC_VECTOR is instr(I_middle_delay_e downto I_middle_delay_s);
	ALIAS I_initial_delay                : STD_LOGIC_VECTOR is instr_in(I_initial_delay_e downto I_initial_delay_s);
	-- Linear
	ALIAS I_addr_range_Lin               : STD_LOGIC_VECTOR is instr(I_addr_range_Lin_e downto I_addr_range_Lin_s);
	ALIAS I_addr_incr_signed             : STD_LOGIC_VECTOR is instr(I_addr_incr_signed_e downto I_addr_incr_signed_s);
	ALIAS I_repetition_incr_signed       : STD_LOGIC_VECTOR is instr(I_repetition_incr_signed_e downto I_repetition_incr_signed_s);
	--	signal I_addr_incr_signed_signed       : signed(I_addr_incr_signed_e - I_addr_incr_signed_s downto 0); --this signal is actually alias of "instr", it holds the value that should be added to address after every address generation
	--	signal I_repetition_incr_signed_signed : signed(I_repetition_incr_signed_e - I_repetition_incr_signed_s downto 0); --this signal is actually alias of "instr", it holds the value that should be added to "start_address" after every repetition
	-- Bit Reverse
	ALIAS I_addr_range_BitRev_compressed : STD_LOGIC_VECTOR is instr(I_addr_range_BitRev_e downto I_addr_range_BitRev_s);
	signal I_addrs_range_BitRev          : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	ALIAS I_start_stage                  : STD_LOGIC_VECTOR is instr(I_start_stage_e downto I_start_stage_s);
	ALIAS I_end_stage                    : STD_LOGIC_VECTOR is instr(I_end_stage_e downto I_end_stage_s);

	-- REGISTERS
	-- Common / Linear
	signal R_start_addrs        : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	signal R_current_addrs      : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	signal R_addrs_range_Lin    : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	signal R_block_write        : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	signal R_no_of_repetitions  : STD_LOGIC_VECTOR(I_no_of_repetitions_e - I_no_of_repetitions_s downto 0); --:= (others => '1'); --infinite loop will actually be "bypass_input" command for adder
	signal R_repetition_delay   : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0); --:= (others => '1'); --repetition delay register, we count down this, then we assign I_repetition_delay and we count down again
	signal R_middle_delay       : STD_LOGIC_VECTOR(I_middle_delay_e - I_middle_delay_s downto 0); --:= (others => '1'); --middle delay register, we count down this, then we assign I_middle_delay and we count down again
	signal R_initial_delay      : STD_LOGIC_VECTOR(I_initial_delay_e - I_initial_delay_s downto 0); --:= (others => '1'); --we are using this only once, so, we can register it only once, instead of two(I_initial_delay and initial_delay_reg) 
	-- Bit Reverse
	signal R_addrs_range_BitRev : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0); --:= (others => '1'); -- +3 to get 1024 points for FFT	
	signal R_start_stage        : STD_LOGIC_VECTOR(I_start_stage_e - I_start_stage_s downto 0); --:= (others => '1');

	-- FLAGS
	signal F_Addrs_Range_BitRev_IsZero_wire, F_Addrs_range_BitRev_IsZero_Reg1, F_Addrs_range_BitRev_IsZero_Reg2 : STD_LOGIC;
	signal F_addrs_range_Lin_IsZero_wire, F_addrs_range_Lin_IsZero_Reg1, F_addrs_range_Lin_IsZero_Reg2          : STD_LOGIC;
	signal F_addrs_range_Lin_IsOne_wire, F_addrs_range_Lin_IsOne_reg1 : STD_LOGIC;

	signal F_initial_delay_IsZero             : std_logic;
	signal F_middle_delay_IsZero              : std_logic;
	signal F_repetition_delay_IsZero          : std_logic;
	signal F_block_write_IsZero               : std_logic;
	signal F_no_of_repetitions_IsZero         : std_logic;
	signal F_start_stage_r_Is_Equal_end_Stage : std_logic;
	signal F_middle_delay_IsZero_reg1         : std_logic;

	signal F_i_block_write_IsZero : std_logic;
	signal F_i_block_write_IsOne  : std_logic;

	signal F_i_repetition_delay_IsZero : std_logic;
	signal F_i_middle_delay_IsZero     : std_logic;
	signal F_i_initial_delay_IsZero    : std_logic;

	signal F_i_repetition_delay_IsOne : std_logic;
	signal F_i_middle_delay_IsOne     : std_logic;
	signal F_i_initial_delay_IsOne    : std_logic;

	-- ADDERS stuff
	signal ADD1_select : AGU_SRAM_ADD1_TYPE; -- R_initial_delay, R_middle_delay, R_repetition_delay, R_block_write;
	signal ADD2_select : AGU_SRAM_ADD2_TYPE; -- R_start_stage, R_no_of_repetitions;
	signal ADD3_select : AGU_SRAM_ADD3_TYPE; -- R_addrs_range_BitRev, R_current_addrs; 
	signal ADD4_select : AGU_SRAM_ADD4_TYPE; -- R_start_addrs;
	signal ADD5_select : AGU_SRAM_ADD5_TYPE; -- R_addr_range_Lin;

	signal temp_ADD1_A   : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0);
	signal temp_ADD1_ans : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0);

	signal temp_ADD2_A   : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0);
	signal temp_ADD2_B   : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0);
	signal temp_ADD2_ans : STD_LOGIC_VECTOR(I_repetition_delay_e - I_repetition_delay_s downto 0);

	-- +1 in range because we are adding 8 bit signed number, 7 bit is for address value, 
	-- FIXME i think we can do same with 7 bit, because its 2's power, and it makes circle like stuff
	signal temp_ADD3_A   : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);
	signal temp_ADD3_B   : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);
	signal temp_ADD3_ans : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);

	-- +1 in range because we are adding 8 bit signed number, 7 bit for addrs value.
	-- FIXME i think we can do same with 7 bit, because its 2's power, and it makes circle like stuff
	signal temp_ADD4_A   : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);
	signal temp_ADD4_B   : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);
	signal temp_ADD4_ans : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s + 1 downto 0);

	-- FIXME its not efficient having 5 adders but at this moment I need smth working
	signal temp_ADD5_A   : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);
	signal temp_ADD5_ans : STD_LOGIC_VECTOR(I_start_addrs_e - I_start_addrs_s downto 0);

	-- signals made with debugging intentions
	--signal D_I_addr_range_Lin               : STD_LOGIC_VECTOR (I_addr_range_Lin_e downto I_addr_range_Lin_s);
	signal D_counter_for_debugging : STD_LOGIC_VECTOR(32 downto 0) := (others => '0'); --just counter to easily calculate clock cycles
	signal D_which_condition       : integer                       := 0; --in simulation, when anything happens, this signal shows by which IF condition was this caused 
	signal addrs_generated         : STD_LOGIC                     := '0';
	signal write_enable_out_wire   : STD_LOGIC;
	signal Chip_Enable_out_reg1    : STD_LOGIC;
	signal chip_enable_out_wire    : STD_LOGIC;

begin
	--	I_addr_incr_signed_signed          <= signed(I_addr_incr_signed); 		--just to use this std_logic signal as signed
	--	I_repetition_incr_signed_signed    <= signed(I_repetition_incr_signed); --just to use this std_logic signal as signed
	I_block_write        <= STD_LOGIC_VECTOR(to_unsigned(2 ** to_integer(unsigned(I_block_write_compressed)) - 1, 7)); --because it 2's power
	I_addrs_range_BitRev <= STD_LOGIC_VECTOR(to_unsigned(2 ** to_integer(unsigned(I_addr_range_BitRev_compressed)) - 1, 7)); --this is same as block write, so we can remove this signal

	rw_addrs_out     <= R_current_addrs when (delaydecoder = ADDRESS_CALCULATION) else (others => '0'); --remove ELSE if you want to reduce dynamic power consumption
	Chip_Enable_out  <= '0' when (delaydecoder = ADDRESS_CALCULATION) else '1';
	Write_Enable_out <= ReadORWrite_in when (delaydecoder = ADDRESS_CALCULATION) else '1';


	D_debugging : process(rst, clk)
	begin
		if rst = '1' then
			D_counter_for_debugging <= (others => '0');
		elsif rising_edge(clk) then
			D_counter_for_debugging <= STD_LOGIC_VECTOR(unsigned(D_counter_for_debugging) + 1);
		end if;
	end process;

	p_state_reg : process(clk, rst) is
	begin
		if rst = '1' then
			AGUst <= IDLEst;
		elsif rising_edge(clk) then
			AGUst <= AGUnst;            --main/top FSMs state transition
		end if;
	end process p_state_reg;

	p_instr_reg : process(rst, clk)
	begin
		if rst = '1' then
			instr <= (others => '0');
		elsif rising_edge(clk) then
			if I_en_in = '1' then
				instr <= instr_in;
			end if;
		end if;
	end process;

	-- address generation is valid when: 
	-- delaydecoder is in ADDRESS_CALCULATION 

	p_agu_fsm : process (AGUst, F_addrs_range_Lin_IsOne_wire, F_addrs_range_Lin_IsZero_Reg1, F_addrs_range_Lin_IsZero_wire, F_block_write_IsZero, F_i_block_write_IsZero, F_i_initial_delay_IsOne, F_initial_delay_IsZero, F_middle_delay_IsZero, F_no_of_repetitions_IsZero, F_repetition_delay_IsZero, instr_in)  
	begin
		ADD5_select        <= bypass_input; --default state
		ADD4_select        <= bypass_input; --default state
		ADD3_select        <= bypass_input; --default state
		ADD2_select        <= bypass_input; --default state
		ADD1_select        <= bypass_input; --default state
		DELAYdecoder       <= NO_ACTION;
		instr_complete_out <= '0';
		D_which_condition <= 30;
		case AGUst is
			when IDLEst =>
				instr_complete_out <= '1';
				if I_en_in = '1' then
					D_which_condition <= 31;
					--Reseting DataPath - ADD1 and ADDv
					ADD1_select       <= reset1_delays_and_block_write;
					ADD2_select       <= reset2_no_of_reps_and_stage_count;
					ADD3_select       <= reset3_Current_Addrs_and_Addrs_Range_BitRev_initial;
					ADD4_select       <= reset4_start_addrs;
					ADD5_select       <= reset5_Addrs_Range_Lin;
					DELAYdecoder      <= NO_ACTION;
					
					if F_i_initial_delay_IsOne = '1' then
						AGUnst            <= CALCULATIONst;
					else
						AGUnst            <= INITIAL_DELAY_st;
					end if;
				end if;
			when CALCULATIONst =>
				DELAYdecoder <= ADDRESS_CALCULATION;
				if F_no_of_repetitions_IsZero = '1' then
					D_which_condition <= 1;
					AGUnst            <= IDLEst;
					delaydecoder      <= NO_ACTION;
				else
					if F_addrs_range_Lin_IsZero_wire = '1' then
						D_which_condition <= 2;
						-------------------------------------------------- last clock cycle
						--decr start address
						--decr no of repetition
						ADD4_select       <= decr4_start_addrs;
						ADD2_select       <= decr2_no_of_repetitions;
						ADD1_select       <= decr1_block_write;
						delaydecoder      <= NO_ACTION;

					elsif F_addrs_range_Lin_IsZero_Reg1 = '1' then
						D_which_condition <= 3;
						-------------------------------------------- after last clock cycle n 
						-------------------------------------------- addrs range sets automatically - combinationally
						-- current address becomes start address
						-- stage changes for bitreverse
						-- we go in repetition delay state
						ADD2_select       <= decr2_stage_count;
						delaydecoder      <= NO_ACTION;
						
--						AGUnst            <= REPETITION_DELAY_st;
						
--							ADD3_select       <= decr3_current_addrs;
--							ADD5_select       <= decr5_addrs_range_Lin;
						

					else
						if F_i_block_write_IsZero = '1' then
							D_which_condition <= 4;
							--generate address
							--decr addrs range
							--go in middle delay
							ADD3_select       <= decr3_current_addrs;
							ADD5_select       <= decr5_addrs_range_Lin;
							AGUnst            <= MIDDLE_DELAY_st;
							
						
						if F_addrs_range_Lin_IsOne_wire = '1' then
							
							D_which_condition <= 401;
							ADD4_select       <= decr4_start_addrs;
							ADD2_select       <= decr2_no_of_repetitions;
							ADD1_select       <= decr1_block_write;
							
							AGUnst            <= REPETITION_DELAY_st;
						end if;
						else
							if F_block_write_IsZero = '1' then
								D_which_condition <= 5;
								--go in middle delay
								AGUnst            <= MIDDLE_DELAY_st;
							ADD5_select       <= decr5_addrs_range_Lin;
						if F_addrs_range_Lin_IsOne_wire = '1' then
							
							D_which_condition <= 501;
							ADD5_select       <= decr5_addrs_range_Lin;
							ADD4_select       <= decr4_start_addrs;
							ADD2_select       <= decr2_no_of_repetitions;
							ADD1_select       <= decr1_block_write;
							
							AGUnst            <= REPETITION_DELAY_st;
						end if;
						
							else
								D_which_condition <= 6;
								--generate adddress
								--decr block write
								--decr addrs range
								ADD3_select       <= decr3_current_addrs;
								ADD1_select       <= decr1_block_write;
								ADD5_select       <= decr5_addrs_range_Lin;

							end if;
						end if;
					end if;
				end if;
			when REPETITION_DELAY_st =>
				delaydecoder <= NO_ACTION;
				ADD1_select  <= decr1_repetition_delay;
				if F_repetition_delay_IsZero = '1' then
					D_which_condition <= 25;
					AGUnst            <= CALCULATIONst;
				else
					D_which_condition <= 26;
					AGUnst            <= REPETITION_DELAY_st;
				end if;
			when INITIAL_DELAY_st =>
				delaydecoder <= NO_ACTION;
				ADD1_select  <= decr1_initial_delay;
				if F_initial_delay_IsZero = '1' then
					D_which_condition <= 21;
					AGUnst            <= CALCULATIONst;
				else
					D_which_condition <= 22;
					AGUnst            <= INITIAL_DELAY_st;
				end if;
			when MIDDLE_DELAY_st =>
				delaydecoder <= NO_ACTION;
				ADD1_select  <= decr1_middle_delay;
				if F_middle_delay_IsZero = '1' then
					D_which_condition <= 23;
					AGUnst            <= CALCULATIONst;
				else
					D_which_condition <= 24;
					AGUnst            <= MIDDLE_DELAY_st;
				end if;
		end case;
	end process;


	-------------------------------------------------------------------------------------------------------
	------------------------------------------------DATAPATH-----------------------------------------------
	-------------------------------------------------------------------------------------------------------	
	p_agu_add1_calc : process(ADD1_select, R_block_write, R_initial_delay, R_middle_delay, R_repetition_delay)
	begin
		case ADD1_select is             --value A selection for Adder1 
			when decr1_initial_delay           => temp_ADD1_A <= "000" & R_initial_delay;
			when decr1_middle_delay            => temp_ADD1_A <= R_middle_delay;
			when decr1_repetition_delay        => temp_ADD1_A <= R_repetition_delay;
			when decr1_block_write             => temp_ADD1_A <= "00" & R_block_write;
			when bypass_input                  => temp_ADD1_A <= (others => '0');
			when reset1_delays_and_block_write => temp_ADD1_A <= (others => '0');
		end case;
	end process;
	p_agu_add1_writeback : process(temp_ADD1_A, clk)
	begin
		temp_ADD1_ans <= STD_LOGIC_VECTOR(unsigned(temp_ADD1_A) - 1); --subtraction
		if rising_edge(clk) then
			case ADD1_select is         --writeback into the register 
				when decr1_initial_delay           => R_initial_delay <= temp_ADD1_ans(I_initial_delay_e - I_initial_delay_s downto 0);
				when decr1_middle_delay            => R_middle_delay <= temp_ADD1_ans;
				when decr1_repetition_delay        => R_repetition_delay <= temp_ADD1_ans;
				when decr1_block_write             => R_block_write <= temp_ADD1_ans(I_start_addrs_e - I_start_addrs_s downto 0);
				when reset1_delays_and_block_write =>
					R_middle_delay     <= STD_LOGIC_VECTOR(unsigned(I_middle_delay) - 1);
					R_repetition_delay <= STD_LOGIC_VECTOR(UNSIGNED(I_repetition_delay) - 1);
					R_block_write      <= I_block_write;
				when bypass_input =>
					R_initial_delay    <= R_initial_delay;
					R_middle_delay     <= R_middle_delay;
					R_repetition_delay <= R_repetition_delay;
					R_block_write      <= R_block_write;
			end case;

			if F_block_write_IsZero = '1' then
				R_block_write <= I_block_write;
			end if;
			if I_en_in = '1' then
				R_initial_delay <= STD_LOGIC_VECTOR(unsigned(I_initial_delay) - 1);
			end if;
			if F_middle_delay_IsZero = '1' then
				R_middle_delay <= STD_LOGIC_VECTOR(unsigned(I_middle_delay) - 1);
			end if;
			if F_repetition_delay_IsZero = '1' then
				R_repetition_delay <= STD_LOGIC_VECTOR(unsigned(I_repetition_delay) - 1);
			end if;
		end if;

	end process;
	p_agu_add2_calc : process(ADD2_select, R_no_of_repetitions, R_start_stage)
	begin
		case ADD2_select is
			when decr2_stage_count =>
				temp_ADD2_A <= "000000" & R_start_stage;
				temp_add2_B <= C_signPos1;
			when decr2_no_of_repetitions =>
				temp_ADD2_A <= R_no_of_repetitions;
				temp_add2_B <= STD_LOGIC_VECTOR(C_signNeg1);
			when bypass_input =>
				temp_ADD2_A <= (others => '0');
				temp_ADD2_B <= (others => '0');
			when reset2_no_of_reps_and_stage_count =>
				temp_ADD2_A <= (others => '0');
				temp_ADD2_B <= (others => '0');
		end case;
	end process;
	p_agu_add2_writeback : process(clk, temp_ADD2_A, temp_ADD2_B)
	begin
		temp_ADD2_ans <= STD_LOGIC_VECTOR(signed(temp_ADD2_A) + signed(temp_ADD2_B));
		if rising_edge(clk) then
			case ADD2_select is
				when decr2_no_of_repetitions =>
					R_no_of_repetitions <= temp_ADD2_ans(I_repetition_delay_e - I_repetition_delay_s downto 0);
				when decr2_stage_count =>
					R_start_stage <= temp_ADD2_ans(I_start_stage_e - I_start_stage_s downto 0);
				when bypass_input =>
					R_no_of_repetitions <= R_no_of_repetitions;
					R_start_stage       <= R_start_stage;
				when reset2_no_of_reps_and_stage_count =>
					R_no_of_repetitions <= I_no_of_repetitions;
					R_start_stage       <= I_start_stage;
			end case;
		end if;
	end process;
	p_agu_add3_calc : process(ADD3_select, R_current_addrs, I_addr_incr_signed, R_addrs_range_BitRev)
	begin
		case ADD3_select is
			when decr3_current_addrs =>
				temp_ADD3_A <= '0' & R_current_addrs;
				temp_ADD3_B <= I_addr_incr_signed;
			when decr3_addrs_range_BitRev =>
				temp_ADD3_A <= '0' & R_addrs_range_BitRev;
				temp_ADD3_B <= STD_LOGIC_VECTOR(C_signNeg1(C_signNeg1'left - 1 downto 0));
			when bypass_input =>
				temp_ADD3_A <= (others => '0');
				temp_ADD3_B <= (others => '0');
			when reset3_Current_Addrs_and_Addrs_Range_BitRev =>
				temp_ADD3_A <= (others => '0');
				temp_ADD3_B <= (others => '0');
			when reset3_Current_Addrs_and_Addrs_Range_BitRev_initial =>
				temp_ADD3_A <= (others => '0');
				temp_ADD3_B <= (others => '0');
		end case;
	end process;
	p_agu_add3_writeback : process(clk, temp_ADD3_A, temp_ADD3_B)
	begin
		temp_ADD3_ans <= STD_LOGIC_VECTOR(signed(temp_ADD3_A) + signed(temp_ADD3_B));
		if rising_edge(clk) then
			case ADD3_select is
				when decr3_current_addrs =>
					R_current_addrs <= temp_ADD3_ans(I_start_addrs_e - I_start_addrs_s downto 0);
				when decr3_addrs_range_BitRev =>
					R_addrs_range_BitRev <= temp_ADD3_ans(I_start_addrs_e - I_start_addrs_s downto 0);
				when bypass_input =>
					R_current_addrs      <= R_current_addrs;
					R_addrs_range_BitRev <= R_addrs_range_BitRev;
				when reset3_Current_Addrs_and_Addrs_Range_BitRev =>
					R_current_addrs      <= R_start_addrs;
					R_addrs_range_BitRev <= I_addrs_range_BitRev;
				when reset3_Current_Addrs_and_Addrs_Range_BitRev_initial =>
					R_current_addrs      <= I_start_addrs;
					R_addrs_range_BitRev <= I_addrs_range_BitRev;
			end case;
			if F_addrs_range_Lin_IsZero_Reg1 = '1' then
				R_current_addrs <= R_start_addrs;
			end if;
		end if;
	end process;
	p_agu_add4_calc : process(ADD4_select, instr, R_start_addrs)
	begin
		case ADD4_select is
			when decr4_start_addrs =>
				temp_ADD4_A <= '0' & R_start_addrs;
				temp_ADD4_B <= I_repetition_incr_signed;
			when bypass_input =>
				temp_ADD4_A <= (others => '0');
				temp_ADD4_B <= (others => '0');
			when reset4_start_addrs =>
				temp_ADD4_A <= (others => '0');
				temp_ADD4_B <= (others => '0');
		end case;
	end process;
	p_agu_add4_writeback : process(clk, temp_ADD4_A, temp_ADD4_B)
	begin
		temp_ADD4_ans <= STD_LOGIC_VECTOR(signed(temp_ADD4_A) + signed(temp_ADD4_B));
		if rising_edge(clk) then
			case ADD4_select is
				when decr4_start_addrs  => R_start_addrs <= temp_ADD4_ans(I_start_addrs_e - I_start_addrs_s downto 0);
				when bypass_input       => R_start_addrs <= R_start_addrs;
				when reset4_start_addrs => R_start_addrs <= I_start_addrs;
			end case;
		end if;
	end process;
	p_agu_add5_calc : process(ADD5_select, R_addrs_range_Lin)
	begin
		case ADD5_select is
			when decr5_addrs_range_Lin  => temp_ADD5_A <= R_addrs_range_Lin;
			when reset5_Addrs_Range_Lin => temp_ADD5_A <= (others => '0');
			when bypass_input           => temp_ADD5_A <= (others => '0');
		end case;
	end process;
	p_agu_add5_writeback : process(clk, temp_ADD5_A)
	begin
		temp_ADD5_ans <= STD_LOGIC_VECTOR(unsigned(temp_ADD5_A) - 1); --subtraction
		if rising_edge(clk) then
			case ADD5_select is
				when decr5_addrs_range_Lin  => R_addrs_range_Lin <= temp_ADD5_ans;
				when reset5_Addrs_Range_Lin => R_addrs_range_Lin <= STD_LOGIC_VECTOR(UNSIGNED(I_addr_range_Lin)); --STD_LOGIC_VECTOR(UNSIGNED(I_addr_range_Lin) - 1);
				when bypass_input           => R_addrs_range_Lin <= R_addrs_range_Lin;
			end case;

			if F_addrs_range_Lin_IsZero_wire = '1' then
				R_addrs_range_Lin <= STD_LOGIC_VECTOR(UNSIGNED(I_addr_range_Lin));
			end if;

		end if;
	end process;

	p_agu_flags : process(I_block_write, R_addrs_range_BitRev, R_addrs_range_Lin, R_block_write, R_initial_delay, R_middle_delay, R_no_of_repetitions, R_repetition_delay, R_start_stage, clk, instr, rst, instr_in)
	begin

		--flags on initial instruction, I use this to avoid unnecesary transitions
		if I_block_write = C_zero7 then		F_i_block_write_IsZero <= '1';		else			F_i_block_write_IsZero <= '0';		end if;	
		if I_initial_delay = C_zero6 then			F_i_initial_delay_IsZero <= '1';		else			F_i_initial_delay_IsZero <= '0';		end if;		
		if I_middle_delay = C_zero9 then			F_i_middle_delay_IsZero <= '1';		else			F_i_middle_delay_IsZero <= '0';		end if;
		if I_repetition_delay = C_zero9 then			F_i_repetition_delay_IsZero <= '1';		else			F_i_repetition_delay_IsZero <= '0';		end if;
		
		if I_block_write = C_one7 then			F_i_block_write_IsOne <= '1';		else			F_i_block_write_IsOne <= '0';		end if;
		if I_initial_delay = C_one6 then			F_i_initial_delay_IsOne <= '1';		else			F_i_initial_delay_IsOne <= '0';		end if;
		if I_middle_delay = C_one9 then			F_i_middle_delay_IsOne <= '1';		else			F_i_middle_delay_IsOne <= '0';		end if;
		if I_repetition_delay = C_one9 then			F_i_repetition_delay_IsOne <= '1';		else			F_i_repetition_delay_IsOne <= '0';		end if;

		--adder 1 flags
		if R_block_write = C_zero7 then		F_block_write_IsZero <= '1';	else	F_block_write_IsZero <= '0';	end if;
		if R_initial_delay = C_zero6 then	F_initial_delay_IsZero <= '1';	else	F_initial_delay_IsZero <= '0';	end if;
		if R_middle_delay = C_zero9 then	F_middle_delay_IsZero <= '1';	else	F_middle_delay_IsZero <= '0';	end if;
		if R_repetition_delay = C_zero9 then	F_repetition_delay_IsZero <= '1';	else	F_repetition_delay_IsZero <= '0';	end if;

		--adder 2 flags
		if R_no_of_repetitions = C_zero9 then	F_no_of_repetitions_IsZero <= '1';	else	F_no_of_repetitions_IsZero <= '0';	end if;
		if R_start_stage = I_end_stage then		F_start_stage_r_Is_Equal_end_Stage <= '1';	else	F_start_stage_r_Is_Equal_end_Stage <= '0';	end if;

		--adder 3 flags
		if R_addrs_range_BitRev = C_zero7 then	F_Addrs_Range_BitRev_IsZero_wire <= '1';	else	F_Addrs_Range_BitRev_IsZero_wire <= '0';	end if;

		--adder 4 flags --we dont need flag for checking this

		--adder 5 flags
		if R_addrs_range_Lin = C_zero7 then		F_addrs_range_Lin_IsZero_wire <= '1';	else	F_addrs_range_Lin_IsZero_wire <= '0';	end if;
		if R_addrs_range_Lin = C_one7 then	F_addrs_range_Lin_IsOne_wire <= '1';	else	F_addrs_range_Lin_IsOne_wire <= '0';	end if;

		--registering flag twice, to locate(in time) LAST then FIRST address generation (in an iteration)
		if rst = '1' then
			F_addrs_range_Lin_IsZero_Reg1    <= '0';
			F_Addrs_range_BitRev_IsZero_Reg1 <= '0';
			F_addrs_range_Lin_IsZero_Reg2    <= '0';
			F_Addrs_range_BitRev_IsZero_Reg2 <= '0';
		elsif rising_edge(clk) then

			--Linear: . .reg2 give us flag in the beginning of next iteration, . .reg1 1 clock cycle before that
			F_addrs_range_Lin_IsZero_Reg1 <= F_addrs_range_Lin_IsZero_wire;
			F_addrs_range_Lin_IsZero_Reg2 <= F_addrs_range_Lin_IsZero_Reg1;
			F_addrs_range_Lin_IsOne_reg1 <= F_addrs_range_Lin_IsOne_wire;
			--BitReverse: . .reg2 give us flag in the beginning of next iteration, . .reg1 1 clock cycle before that
			F_Addrs_range_BitRev_IsZero_Reg1 <= F_Addrs_Range_BitRev_IsZero_wire;
			F_Addrs_range_BitRev_IsZero_Reg2 <= F_Addrs_range_BitRev_IsZero_Reg1;
		end if;
	end process;

end architecture RTL;
