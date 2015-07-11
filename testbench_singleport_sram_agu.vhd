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

entity tb_agu is
--  Port ( );
end tb_agu;

architecture Behavioral of tb_agu is

	---------------------SRAM DECLARATIONS-------------
	signal instr_complete_out : STD_LOGIC;
	signal rw_addrs_out       : STD_LOGIC_VECTOR(log2_ceil(RAM_DEPTH) - 1 downto 0);
	signal Chip_Enable_out    : STD_LOGIC;
	signal Write_Enable_out   : STD_LOGIC;
	signal instr_in           : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 downto 0);
	signal ReadORWrite_in     : STD_LOGIC;
	signal clk                : std_logic;
	signal rst                : std_logic;

	---------------------MEMORY DECLARATIONS-------------
	signal CEB   : STD_LOGIC;
	signal WEB   : STD_LOGIC;
	signal TSEL0 : STD_LOGIC := '1';
	signal TSEL1 : STD_LOGIC := '0';
	signal A     : STD_LOGIC_VECTOR(6 downto 0);
	signal D     : STD_LOGIC_VECTOR(127 downto 0);
	signal Q     : STD_LOGIC_VECTOR(127 downto 0);
	signal BWEB  : STD_LOGIC_VECTOR(127 downto 0);

	---------------------INSTR_IN DECLARATIONS FOR TESTING DIFFERENT INPUTS----------
	alias I_en_in                        : STD_LOGIC is instr_in(en_in_s); --Instruction_Enable_Input, this alias is on INSTR_IN, NOT on instr, because it will take 1 more clock cycle, when its '1' we accept incoming instruction
	-- Common
	alias I_mode                         : STD_LOGIC is instr_in(I_mode_s);
	alias I_start_addrs                  : STD_LOGIC_VECTOR is instr_in(I_start_addrs_e downto I_start_addrs_s);
	alias I_block_write_compressed       : STD_LOGIC_VECTOR is instr_in(I_block_write_e downto I_block_write_s);
	alias I_no_of_repetitions            : STD_LOGIC_VECTOR is instr_in(I_no_of_repetitions_e downto I_no_of_repetitions_s);
	alias I_repetition_delay             : STD_LOGIC_VECTOR is instr_in(I_repetition_delay_e downto I_repetition_delay_s);
	alias I_middle_delay                 : STD_LOGIC_VECTOR is instr_in(I_middle_delay_e downto I_middle_delay_s);
	alias I_initial_delay                : STD_LOGIC_VECTOR is instr_in(I_initial_delay_e downto I_initial_delay_s);
	-- Linear
	alias I_addr_range_Lin               : STD_LOGIC_VECTOR is instr_in(I_addr_range_Lin_e downto I_addr_range_Lin_s);
	alias I_addr_incr_signed             : STD_LOGIC_VECTOR is instr_in(I_addr_incr_signed_e downto I_addr_incr_signed_s);
	alias I_repetition_incr_signed       : STD_LOGIC_VECTOR is instr_in(I_repetition_incr_signed_e downto I_repetition_incr_signed_s);
	-- Bit Reverse
	alias I_addr_range_BitRev_compressed : STD_LOGIC_VECTOR is instr_in(I_addr_range_BitRev_e downto I_addr_range_BitRev_s);
	alias I_start_stage                  : STD_LOGIC_VECTOR is instr_in(I_start_stage_e downto I_start_stage_s);
	alias I_end_stage                    : STD_LOGIC_VECTOR is instr_in(I_end_stage_e downto I_end_stage_s);

	---------------------REST OF THE DECLARATIONS-------------
	constant t : time := 10 ns;

begin

	---------------------ACTUAL STIMULATION ------------------
	simulation : process is
	begin
		wait for 100 ns;

		wait;
	end process simulation;

	-------------------------- NO MUCH NEED TO TOUCH THINGS BELOW ----------------------
	CEB <= Chip_Enable_out;
	WEB <= Write_Enable_out;
	A   <= rw_addrs_out;                --note that 6 should go to 0 and etc <=> bit numbers should be reversed

	clock_driver : process
	begin
		clk <= '0';
		wait for t / 2;
		clk <= '1';
		wait for t / 2;
	end process clock_driver;

	SINGLEPORT_SRAM_AGU_inst : entity work.SINGLEPORT_SRAM_AGU
		port map(
			instr_complete_out => instr_complete_out,
			rw_addrs_out       => rw_addrs_out,
			Chip_Enable_out    => Chip_Enable_out,
			Write_Enable_out   => Write_Enable_out,
			instr_in           => instr_in,
			ReadORWrite_in     => ReadORWrite_in,
			clk                => clk,
			rst                => rst
		);

	TS1GE128X128M4_inst : entity work.TS1GE128X128M4
		--	generic map(
		--		numWord     => numWord,
		--		numRow      => numRow,
		--		numCM       => numCM,
		--		numBit      => numBit,
		--		numWordAddr => numWordAddr,
		--		numCMAddr   => numCMAddr,
		--		numSRSize   => numSRSize,
		--		numAddr     => numAddr,
		--		numOut      => numOut,
		--		wordDepth   => wordDepth,
		--		mem_sel     => mem_sel,
		--		cy          => cy,
		--		inidata     => inidata
		--	)

		port map(
			CLK     => clk,
			CEB     => CEB,
			WEB     => WEB,
			A0      => A(6),
			A1      => A(5),
			A2      => A(4),
			A3      => A(3),
			A4      => A(2),
			A5      => A(1),
			A6      => A(0),
			D0      => D(0),
			D1      => D(1),
			D2      => D(2),
			D3      => D(3),
			D4      => D(4),
			D5      => D(5),
			D6      => D(6),
			D7      => D(7),
			D8      => D(8),
			D9      => D(9),
			D10     => D(10),
			D11     => D(11),
			D12     => D(12),
			D13     => D(13),
			D14     => D(14),
			D15     => D(15),
			D16     => D(16),
			D17     => D(17),
			D18     => D(18),
			D19     => D(19),
			D20     => D(20),
			D21     => D(21),
			D22     => D(22),
			D23     => D(23),
			D24     => D(24),
			D25     => D(25),
			D26     => D(26),
			D27     => D(27),
			D28     => D(28),
			D29     => D(29),
			D30     => D(30),
			D31     => D(31),
			D32     => D(32),
			D33     => D(33),
			D34     => D(34),
			D35     => D(35),
			D36     => D(36),
			D37     => D(37),
			D38     => D(38),
			D39     => D(39),
			D40     => D(40),
			D41     => D(41),
			D42     => D(42),
			D43     => D(43),
			D44     => D(44),
			D45     => D(45),
			D46     => D(46),
			D47     => D(47),
			D48     => D(48),
			D49     => D(49),
			D50     => D(50),
			D51     => D(51),
			D52     => D(52),
			D53     => D(53),
			D54     => D(54),
			D55     => D(55),
			D56     => D(56),
			D57     => D(57),
			D58     => D(58),
			D59     => D(59),
			D60     => D(60),
			D61     => D(61),
			D62     => D(62),
			D63     => D(63),
			D64     => D(64),
			D65     => D(65),
			D66     => D(66),
			D67     => D(67),
			D68     => D(68),
			D69     => D(69),
			D70     => D(70),
			D71     => D(71),
			D72     => D(72),
			D73     => D(73),
			D74     => D(74),
			D75     => D(75),
			D76     => D(76),
			D77     => D(77),
			D78     => D(78),
			D79     => D(79),
			D80     => D(80),
			D81     => D(81),
			D82     => D(82),
			D83     => D(83),
			D84     => D(84),
			D85     => D(85),
			D86     => D(86),
			D87     => D(87),
			D88     => D(88),
			D89     => D(89),
			D90     => D(90),
			D91     => D(91),
			D92     => D(92),
			D93     => D(93),
			D94     => D(94),
			D95     => D(95),
			D96     => D(96),
			D97     => D(97),
			D98     => D(98),
			D99     => D(99),
			D100    => D(100),
			D101    => D(101),
			D102    => D(102),
			D103    => D(103),
			D104    => D(104),
			D105    => D(105),
			D106    => D(106),
			D107    => D(107),
			D108    => D(108),
			D109    => D(109),
			D110    => D(110),
			D111    => D(111),
			D112    => D(112),
			D113    => D(113),
			D114    => D(114),
			D115    => D(115),
			D116    => D(116),
			D117    => D(117),
			D118    => D(118),
			D119    => D(119),
			D120    => D(120),
			D121    => D(121),
			D122    => D(122),
			D123    => D(123),
			D124    => D(124),
			D125    => D(125),
			D126    => D(126),
			D127    => D(127),
			BWEB0   => BWEB(0),
			BWEB1   => BWEB(1),
			BWEB2   => BWEB(2),
			BWEB3   => BWEB(3),
			BWEB4   => BWEB(4),
			BWEB5   => BWEB(5),
			BWEB6   => BWEB(6),
			BWEB7   => BWEB(7),
			BWEB8   => BWEB(8),
			BWEB9   => BWEB(9),
			BWEB10  => BWEB(10),
			BWEB11  => BWEB(11),
			BWEB12  => BWEB(12),
			BWEB13  => BWEB(13),
			BWEB14  => BWEB(14),
			BWEB15  => BWEB(15),
			BWEB16  => BWEB(16),
			BWEB17  => BWEB(17),
			BWEB18  => BWEB(18),
			BWEB19  => BWEB(19),
			BWEB20  => BWEB(20),
			BWEB21  => BWEB(21),
			BWEB22  => BWEB(22),
			BWEB23  => BWEB(23),
			BWEB24  => BWEB(24),
			BWEB25  => BWEB(25),
			BWEB26  => BWEB(26),
			BWEB27  => BWEB(27),
			BWEB28  => BWEB(28),
			BWEB29  => BWEB(29),
			BWEB30  => BWEB(30),
			BWEB31  => BWEB(31),
			BWEB32  => BWEB(32),
			BWEB33  => BWEB(33),
			BWEB34  => BWEB(34),
			BWEB35  => BWEB(35),
			BWEB36  => BWEB(36),
			BWEB37  => BWEB(37),
			BWEB38  => BWEB(38),
			BWEB39  => BWEB(39),
			BWEB40  => BWEB(40),
			BWEB41  => BWEB(41),
			BWEB42  => BWEB(42),
			BWEB43  => BWEB(43),
			BWEB44  => BWEB(44),
			BWEB45  => BWEB(45),
			BWEB46  => BWEB(46),
			BWEB47  => BWEB(47),
			BWEB48  => BWEB(48),
			BWEB49  => BWEB(49),
			BWEB50  => BWEB(50),
			BWEB51  => BWEB(51),
			BWEB52  => BWEB(52),
			BWEB53  => BWEB(53),
			BWEB54  => BWEB(54),
			BWEB55  => BWEB(55),
			BWEB56  => BWEB(56),
			BWEB57  => BWEB(57),
			BWEB58  => BWEB(58),
			BWEB59  => BWEB(59),
			BWEB60  => BWEB(60),
			BWEB61  => BWEB(61),
			BWEB62  => BWEB(62),
			BWEB63  => BWEB(63),
			BWEB64  => BWEB(64),
			BWEB65  => BWEB(65),
			BWEB66  => BWEB(66),
			BWEB67  => BWEB(67),
			BWEB68  => BWEB(68),
			BWEB69  => BWEB(69),
			BWEB70  => BWEB(70),
			BWEB71  => BWEB(71),
			BWEB72  => BWEB(72),
			BWEB73  => BWEB(73),
			BWEB74  => BWEB(74),
			BWEB75  => BWEB(75),
			BWEB76  => BWEB(76),
			BWEB77  => BWEB(77),
			BWEB78  => BWEB(78),
			BWEB79  => BWEB(79),
			BWEB80  => BWEB(80),
			BWEB81  => BWEB(81),
			BWEB82  => BWEB(82),
			BWEB83  => BWEB(83),
			BWEB84  => BWEB(84),
			BWEB85  => BWEB(85),
			BWEB86  => BWEB(86),
			BWEB87  => BWEB(87),
			BWEB88  => BWEB(88),
			BWEB89  => BWEB(89),
			BWEB90  => BWEB(90),
			BWEB91  => BWEB(91),
			BWEB92  => BWEB(92),
			BWEB93  => BWEB(93),
			BWEB94  => BWEB(94),
			BWEB95  => BWEB(95),
			BWEB96  => BWEB(96),
			BWEB97  => BWEB(97),
			BWEB98  => BWEB(98),
			BWEB99  => BWEB(99),
			BWEB100 => BWEB(100),
			BWEB101 => BWEB(101),
			BWEB102 => BWEB(102),
			BWEB103 => BWEB(103),
			BWEB104 => BWEB(104),
			BWEB105 => BWEB(105),
			BWEB106 => BWEB(106),
			BWEB107 => BWEB(107),
			BWEB108 => BWEB(108),
			BWEB109 => BWEB(109),
			BWEB110 => BWEB(110),
			BWEB111 => BWEB(111),
			BWEB112 => BWEB(112),
			BWEB113 => BWEB(113),
			BWEB114 => BWEB(114),
			BWEB115 => BWEB(115),
			BWEB116 => BWEB(116),
			BWEB117 => BWEB(117),
			BWEB118 => BWEB(118),
			BWEB119 => BWEB(119),
			BWEB120 => BWEB(120),
			BWEB121 => BWEB(121),
			BWEB122 => BWEB(122),
			BWEB123 => BWEB(123),
			BWEB124 => BWEB(124),
			BWEB125 => BWEB(125),
			BWEB126 => BWEB(126),
			BWEB127 => BWEB(127),
			Q0      => Q(0),
			Q1      => Q(1),
			Q2      => Q(2),
			Q3      => Q(3),
			Q4      => Q(4),
			Q5      => Q(5),
			Q6      => Q(6),
			Q7      => Q(7),
			Q8      => Q(8),
			Q9      => Q(9),
			Q10     => Q(10),
			Q11     => Q(11),
			Q12     => Q(12),
			Q13     => Q(13),
			Q14     => Q(14),
			Q15     => Q(15),
			Q16     => Q(16),
			Q17     => Q(17),
			Q18     => Q(18),
			Q19     => Q(19),
			Q20     => Q(20),
			Q21     => Q(21),
			Q22     => Q(22),
			Q23     => Q(23),
			Q24     => Q(24),
			Q25     => Q(25),
			Q26     => Q(26),
			Q27     => Q(27),
			Q28     => Q(28),
			Q29     => Q(29),
			Q30     => Q(30),
			Q31     => Q(31),
			Q32     => Q(32),
			Q33     => Q(33),
			Q34     => Q(34),
			Q35     => Q(35),
			Q36     => Q(36),
			Q37     => Q(37),
			Q38     => Q(38),
			Q39     => Q(39),
			Q40     => Q(40),
			Q41     => Q(41),
			Q42     => Q(42),
			Q43     => Q(43),
			Q44     => Q(44),
			Q45     => Q(45),
			Q46     => Q(46),
			Q47     => Q(47),
			Q48     => Q(48),
			Q49     => Q(49),
			Q50     => Q(50),
			Q51     => Q(51),
			Q52     => Q(52),
			Q53     => Q(53),
			Q54     => Q(54),
			Q55     => Q(55),
			Q56     => Q(56),
			Q57     => Q(57),
			Q58     => Q(58),
			Q59     => Q(59),
			Q60     => Q(60),
			Q61     => Q(61),
			Q62     => Q(62),
			Q63     => Q(63),
			Q64     => Q(64),
			Q65     => Q(65),
			Q66     => Q(66),
			Q67     => Q(67),
			Q68     => Q(68),
			Q69     => Q(69),
			Q70     => Q(70),
			Q71     => Q(71),
			Q72     => Q(72),
			Q73     => Q(73),
			Q74     => Q(74),
			Q75     => Q(75),
			Q76     => Q(76),
			Q77     => Q(77),
			Q78     => Q(78),
			Q79     => Q(79),
			Q80     => Q(80),
			Q81     => Q(81),
			Q82     => Q(82),
			Q83     => Q(83),
			Q84     => Q(84),
			Q85     => Q(85),
			Q86     => Q(86),
			Q87     => Q(87),
			Q88     => Q(88),
			Q89     => Q(89),
			Q90     => Q(90),
			Q91     => Q(91),
			Q92     => Q(92),
			Q93     => Q(93),
			Q94     => Q(94),
			Q95     => Q(95),
			Q96     => Q(96),
			Q97     => Q(97),
			Q98     => Q(98),
			Q99     => Q(99),
			Q100    => Q(100),
			Q101    => Q(101),
			Q102    => Q(102),
			Q103    => Q(103),
			Q104    => Q(104),
			Q105    => Q(105),
			Q106    => Q(106),
			Q107    => Q(107),
			Q108    => Q(108),
			Q109    => Q(109),
			Q110    => Q(110),
			Q111    => Q(111),
			Q112    => Q(112),
			Q113    => Q(113),
			Q114    => Q(114),
			Q115    => Q(115),
			Q116    => Q(116),
			Q117    => Q(117),
			Q118    => Q(118),
			Q119    => Q(119),
			Q120    => Q(120),
			Q121    => Q(121),
			Q122    => Q(122),
			Q123    => Q(123),
			Q124    => Q(124),
			Q125    => Q(125),
			Q126    => Q(126),
			Q127    => Q(127),
			TSEL0   => TSEL0,
			TSEL1   => TSEL1
		);

end Behavioral;

