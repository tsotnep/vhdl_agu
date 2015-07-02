package SINGLEPORT_SRAM_AGU_types_n_constants is
	TYPE AGU_SRAM_STATE_TYPE IS (IDLEst, CALCULATIONst, DELAYst); --in old version it was COUNT, RDRW, BITREV, REPEAT);
	TYPE AGU_SRAM_DELAY_TYPE IS (INITIAL, MIDDLE, REPETITION, NO_DELAY); -- added NODELAY state, maybe we dont need it, idk yet.

	TYPE AGU_SRAM_ADD1_TYPE IS (decr_initial_delay, decr_middle_delay, decr_repetition_delay, decr_block_write, bypass_input, reset);
	TYPE AGU_SRAM_ADD2_TYPE IS (decr_no_of_repetitions, decr_stage_count, bypass_input, reset);
	TYPE AGU_SRAM_ADD3_TYPE IS (decr_current_addrs, decr_point_count, bypass_input, reset);
	TYPE AGU_SRAM_ADD4_TYPE IS (decr_start_addrs, decr_end_addrs_Lin, decr_end_addrs_BitRev, bypass_input, reset);

	-- General
	CONSTANT INSTR_WIDTH : INTEGER := 68;
	CONSTANT RAM_DEPTH   : INTEGER := 128;

	-- Common
	CONSTANT i_mode_s              : integer := 0;
	CONSTANT i_start_addrs_s       : integer := 1;
	CONSTANT i_start_addrs_e       : integer := 7;
	--in this area there are linear & constant declarations
	CONSTANT i_block_write_s       : integer := 31;
	CONSTANT i_block_write_e       : integer := 33;
	CONSTANT i_no_of_repetitions_s : integer := 34;
	CONSTANT i_no_of_repetitions_e : integer := 42;
	CONSTANT i_repetition_delay_s  : integer := 43;
	CONSTANT i_repetition_delay_e  : integer := 51;
	CONSTANT i_middle_delay_s      : integer := 52;
	CONSTANT i_middle_delay_e      : integer := 60;
	CONSTANT i_initial_delay_s     : integer := 61;
	CONSTANT i_initial_delay_e     : integer := 66;
	CONSTANT en_in_s               : integer := 67;

	-- Linear
	CONSTANT i_addr_range_Lin_s         : integer := 8;
	CONSTANT i_addr_range_Lin_e         : integer := 14;
	CONSTANT i_addr_incr_signed_s       : integer := 15;
	CONSTANT i_addr_incr_signed_e       : integer := 22;
	CONSTANT i_repetition_incr_signed_s : integer := 23;
	CONSTANT i_repetition_incr_signed_e : integer := 30;

	-- Bit Reverse
	CONSTANT i_addr_range_BitRev_s : integer := 8;
	CONSTANT i_addr_range_BitRev_e : integer := 9;
	CONSTANT i_start_stage_s       : integer := 10;
	CONSTANT i_start_stage_e       : integer := 12;
	CONSTANT i_end_stage_s         : integer := 13;
	CONSTANT i_end_stage_e         : integer := 15;

end package SINGLEPORT_SRAM_AGU_types_n_constants;
