--------------------------------------------------------------------------------
--                            XilinxRSCM_comb_uid2
-- VHDL generated for Kintex7 @ 0MHz
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bastien Barbe, Florent de Dinechin (2026)
--------------------------------------------------------------------------------
-- combinatorial
-- Clock period (ns): inf
-- Target frequency (MHz): 0
-- Input signals: a sel
-- Output signals: y
--  approx. input signal timings: a: 0.000000nssel: 0.000000ns
--  approx. output signal timings: y: 0.000000ns

--------------------------------------------------------------------------------
library UNISIM;
use UNISIM.Vcomponents.all;
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

entity XilinxRSCM_comb_uid2 is
    port (a : in  std_logic_vector(5 downto 0);
          sel : in  std_logic_vector(5 downto 0);
          y : out  std_logic_vector(11 downto 0)   );
end entity;

architecture arch of XilinxRSCM_comb_uid2 is


signal left_adder_1_o :  std_logic_vector(8 downto 0);
   -- timing of left_adder_1_o: 0.000000ns
signal right_adder_1_o :  std_logic_vector(7 downto 0);
   -- timing of right_adder_1_o: 0.000000ns
signal a_shift1 :  std_logic_vector(6 downto 0);
   -- timing of a_shift1: 0.000000ns
signal a_shift2 :  std_logic_vector(7 downto 0);
   -- timing of a_shift2: 0.000000ns
signal a_shift3 :  std_logic_vector(8 downto 0);
   -- timing of a_shift3: 0.000000ns
signal left_adder_1_o_shift1 :  std_logic_vector(9 downto 0);
   -- timing of left_adder_1_o_shift1: 0.000000ns
signal right_adder_1_o_shift4 :  std_logic_vector(11 downto 0);
   -- timing of right_adder_1_o_shift4: 0.000000ns
signal left_adder_1_o_sel :  std_logic_vector(1 downto 0);
   -- timing of left_adder_1_o_sel: 0.000000ns
signal left_adder_1_o_s :  std_logic_vector(11 downto 0);
   -- timing of left_adder_1_o_s: 0.000000ns
signal left_adder_1_o_di :  std_logic_vector(11 downto 0);
   -- timing of left_adder_1_o_di: 0.000000ns
signal left_adder_1_o_carry_co :  std_logic_vector(11 downto 0);
   -- timing of left_adder_1_o_carry_co: 0.000000ns
signal left_adder_1_o_carry_o :  std_logic_vector(11 downto 0);
   -- timing of left_adder_1_o_carry_o: 0.000000ns
signal left_adder_1_o_carry_in :  std_logic;
   -- timing of left_adder_1_o_carry_in: 0.000000ns
signal right_adder_1_o_sel :  std_logic_vector(1 downto 0);
   -- timing of right_adder_1_o_sel: 0.000000ns
signal right_adder_1_o_s :  std_logic_vector(7 downto 0);
   -- timing of right_adder_1_o_s: 0.000000ns
signal right_adder_1_o_di :  std_logic_vector(7 downto 0);
   -- timing of right_adder_1_o_di: 0.000000ns
signal right_adder_1_o_carry_co :  std_logic_vector(7 downto 0);
   -- timing of right_adder_1_o_carry_co: 0.000000ns
signal right_adder_1_o_carry_o :  std_logic_vector(7 downto 0);
   -- timing of right_adder_1_o_carry_o: 0.000000ns
signal right_adder_1_o_carry_in :  std_logic;
   -- timing of right_adder_1_o_carry_in: 0.000000ns
signal y_sel :  std_logic_vector(1 downto 0);
   -- timing of y_sel: 0.000000ns
signal y_s :  std_logic_vector(11 downto 0);
   -- timing of y_s: 0.000000ns
signal y_di :  std_logic_vector(11 downto 0);
   -- timing of y_di: 0.000000ns
signal y_carry_co :  std_logic_vector(11 downto 0);
   -- timing of y_carry_co: 0.000000ns
signal y_carry_o :  std_logic_vector(11 downto 0);
   -- timing of y_carry_o: 0.000000ns
signal y_carry_in :  std_logic;
   -- timing of y_carry_in: 0.000000ns
begin
   a_shift1 <= std_logic_vector(shift_left(resize(signed(a), 7), 1));
   a_shift2 <= std_logic_vector(shift_left(resize(signed(a), 8), 2));
   a_shift3 <= std_logic_vector(shift_left(resize(signed(a), 9), 3));
   left_adder_1_o_shift1 <= std_logic_vector(shift_left(resize(signed(left_adder_1_o), 10), 1));
   right_adder_1_o_shift4 <= std_logic_vector(shift_left(resize(signed(right_adder_1_o), 12), 4));
   left_adder_1_o_sel <= sel(5 downto 4);
   left_adder_1_o_s(9) <= '0';
   left_adder_1_o_di(9) <= '0';
   left_adder_1_o_s(10) <= '0';
   left_adder_1_o_di(10) <= '0';
   left_adder_1_o_s(11) <= '0';
   left_adder_1_o_di(11) <= '0';
   left_adder_1_o_carry_in <= left_adder_1_o_sel(1);
   left_adder_1_o <= left_adder_1_o_carry_o(8 downto 0);
   right_adder_1_o_sel <= sel(3 downto 2);
   right_adder_1_o_carry_in <= right_adder_1_o_sel(1);
   right_adder_1_o <= right_adder_1_o_carry_o(7 downto 0);
   y_sel <= sel(1 downto 0);
   y_carry_in <= '1';
   y <= y_carry_o(11 downto 0);
   left_adder_1_o_lut_0: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(0),
                 i3 => a_shift2(0),
                 i4 => a_shift3(0),
                 i5 => '1',
                 o5 => left_adder_1_o_di(0),
                 o6 => left_adder_1_o_s(0));
   left_adder_1_o_lut_1: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(1),
                 i3 => a_shift2(1),
                 i4 => a_shift3(1),
                 i5 => '1',
                 o5 => left_adder_1_o_di(1),
                 o6 => left_adder_1_o_s(1));
   left_adder_1_o_lut_2: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(2),
                 i3 => a_shift2(2),
                 i4 => a_shift3(2),
                 i5 => '1',
                 o5 => left_adder_1_o_di(2),
                 o6 => left_adder_1_o_s(2));
   left_adder_1_o_lut_3: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(3),
                 i3 => a_shift2(3),
                 i4 => a_shift3(3),
                 i5 => '1',
                 o5 => left_adder_1_o_di(3),
                 o6 => left_adder_1_o_s(3));
   left_adder_1_o_lut_4: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(4),
                 i3 => a_shift2(4),
                 i4 => a_shift3(4),
                 i5 => '1',
                 o5 => left_adder_1_o_di(4),
                 o6 => left_adder_1_o_s(4));
   left_adder_1_o_lut_5: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift2(5),
                 i4 => a_shift3(5),
                 i5 => '1',
                 o5 => left_adder_1_o_di(5),
                 o6 => left_adder_1_o_s(5));
   left_adder_1_o_lut_6: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift2(6),
                 i4 => a_shift3(6),
                 i5 => '1',
                 o5 => left_adder_1_o_di(6),
                 o6 => left_adder_1_o_s(6));
   left_adder_1_o_lut_7: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift2(7),
                 i4 => a_shift3(7),
                 i5 => '1',
                 o5 => left_adder_1_o_di(7),
                 o6 => left_adder_1_o_s(7));
   left_adder_1_o_lut_8: LUT6_2
      generic map ( init => x"F2947A1C7E187E18")
      port map ( i0 => left_adder_1_o_sel(0),
                 i1 => left_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift2(7),
                 i4 => a_shift3(8),
                 i5 => '1',
                 o5 => left_adder_1_o_di(8),
                 o6 => left_adder_1_o_s(8));
   left_adder_1_o_carry4_0: CARRY4
      port map ( ci => '0',
                 cyinit => left_adder_1_o_carry_in,
                 di => left_adder_1_o_di(3 downto 0),
                 s => left_adder_1_o_s(3 downto 0),
                 co => left_adder_1_o_carry_co(3 downto 0),
                 o => left_adder_1_o_carry_o(3 downto 0));
   left_adder_1_o_carry4_1: CARRY4
      port map ( ci => left_adder_1_o_carry_co(3),
                 cyinit => '0',
                 di => left_adder_1_o_di(7 downto 4),
                 s => left_adder_1_o_s(7 downto 4),
                 co => left_adder_1_o_carry_co(7 downto 4),
                 o => left_adder_1_o_carry_o(7 downto 4));
   left_adder_1_o_carry4_2: CARRY4
      port map ( ci => left_adder_1_o_carry_co(7),
                 cyinit => '0',
                 di => left_adder_1_o_di(11 downto 8),
                 s => left_adder_1_o_s(11 downto 8),
                 co => left_adder_1_o_carry_co(11 downto 8),
                 o => left_adder_1_o_carry_o(11 downto 8));
   right_adder_1_o_lut_0: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(0),
                 i3 => a_shift1(0),
                 i4 => a_shift2(0),
                 i5 => '1',
                 o5 => right_adder_1_o_di(0),
                 o6 => right_adder_1_o_s(0));
   right_adder_1_o_lut_1: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(1),
                 i3 => a_shift1(1),
                 i4 => a_shift2(1),
                 i5 => '1',
                 o5 => right_adder_1_o_di(1),
                 o6 => right_adder_1_o_s(1));
   right_adder_1_o_lut_2: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(2),
                 i3 => a_shift1(2),
                 i4 => a_shift2(2),
                 i5 => '1',
                 o5 => right_adder_1_o_di(2),
                 o6 => right_adder_1_o_s(2));
   right_adder_1_o_lut_3: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(3),
                 i3 => a_shift1(3),
                 i4 => a_shift2(3),
                 i5 => '1',
                 o5 => right_adder_1_o_di(3),
                 o6 => right_adder_1_o_s(3));
   right_adder_1_o_lut_4: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(4),
                 i3 => a_shift1(4),
                 i4 => a_shift2(4),
                 i5 => '1',
                 o5 => right_adder_1_o_di(4),
                 o6 => right_adder_1_o_s(4));
   right_adder_1_o_lut_5: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift1(5),
                 i4 => a_shift2(5),
                 i5 => '1',
                 o5 => right_adder_1_o_di(5),
                 o6 => right_adder_1_o_s(5));
   right_adder_1_o_lut_6: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift1(6),
                 i4 => a_shift2(6),
                 i5 => '1',
                 o5 => right_adder_1_o_di(6),
                 o6 => right_adder_1_o_s(6));
   right_adder_1_o_lut_7: LUT6_2
      generic map ( init => x"AFBE8D9C37AE158C")
      port map ( i0 => right_adder_1_o_sel(0),
                 i1 => right_adder_1_o_sel(1),
                 i2 => a(5),
                 i3 => a_shift1(6),
                 i4 => a_shift2(7),
                 i5 => '1',
                 o5 => right_adder_1_o_di(7),
                 o6 => right_adder_1_o_s(7));
   right_adder_1_o_carry4_0: CARRY4
      port map ( ci => '0',
                 cyinit => right_adder_1_o_carry_in,
                 di => right_adder_1_o_di(3 downto 0),
                 s => right_adder_1_o_s(3 downto 0),
                 co => right_adder_1_o_carry_co(3 downto 0),
                 o => right_adder_1_o_carry_o(3 downto 0));
   right_adder_1_o_carry4_1: CARRY4
      port map ( ci => right_adder_1_o_carry_co(3),
                 cyinit => '0',
                 di => right_adder_1_o_di(7 downto 4),
                 s => right_adder_1_o_s(7 downto 4),
                 co => right_adder_1_o_carry_co(7 downto 4),
                 o => right_adder_1_o_carry_o(7 downto 4));
   y_lut_0: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(0),
                 i3 => left_adder_1_o_shift1(0),
                 i4 => right_adder_1_o_shift4(0),
                 i5 => '1',
                 o5 => y_di(0),
                 o6 => y_s(0));
   y_lut_1: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(1),
                 i3 => left_adder_1_o_shift1(1),
                 i4 => right_adder_1_o_shift4(1),
                 i5 => '1',
                 o5 => y_di(1),
                 o6 => y_s(1));
   y_lut_2: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(2),
                 i3 => left_adder_1_o_shift1(2),
                 i4 => right_adder_1_o_shift4(2),
                 i5 => '1',
                 o5 => y_di(2),
                 o6 => y_s(2));
   y_lut_3: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(3),
                 i3 => left_adder_1_o_shift1(3),
                 i4 => right_adder_1_o_shift4(3),
                 i5 => '1',
                 o5 => y_di(3),
                 o6 => y_s(3));
   y_lut_4: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(4),
                 i3 => left_adder_1_o_shift1(4),
                 i4 => right_adder_1_o_shift4(4),
                 i5 => '1',
                 o5 => y_di(4),
                 o6 => y_s(4));
   y_lut_5: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(5),
                 i3 => left_adder_1_o_shift1(5),
                 i4 => right_adder_1_o_shift4(5),
                 i5 => '1',
                 o5 => y_di(5),
                 o6 => y_s(5));
   y_lut_6: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(6),
                 i3 => left_adder_1_o_shift1(6),
                 i4 => right_adder_1_o_shift4(6),
                 i5 => '1',
                 o5 => y_di(6),
                 o6 => y_s(6));
   y_lut_7: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(7),
                 i3 => left_adder_1_o_shift1(7),
                 i4 => right_adder_1_o_shift4(7),
                 i5 => '1',
                 o5 => y_di(7),
                 o6 => y_s(7));
   y_lut_8: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(8),
                 i3 => left_adder_1_o_shift1(8),
                 i4 => right_adder_1_o_shift4(8),
                 i5 => '1',
                 o5 => y_di(8),
                 o6 => y_s(8));
   y_lut_9: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(8),
                 i3 => left_adder_1_o_shift1(9),
                 i4 => right_adder_1_o_shift4(9),
                 i5 => '1',
                 o5 => y_di(9),
                 o6 => y_s(9));
   y_lut_10: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(8),
                 i3 => left_adder_1_o_shift1(9),
                 i4 => right_adder_1_o_shift4(10),
                 i5 => '1',
                 o5 => y_di(10),
                 o6 => y_s(10));
   y_lut_11: LUT6_2
      generic map ( init => x"F960069FCA53CA53")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => left_adder_1_o(8),
                 i3 => left_adder_1_o_shift1(9),
                 i4 => right_adder_1_o_shift4(11),
                 i5 => '1',
                 o5 => y_di(11),
                 o6 => y_s(11));
   y_carry4_0: CARRY4
      port map ( ci => '0',
                 cyinit => y_carry_in,
                 di => y_di(3 downto 0),
                 s => y_s(3 downto 0),
                 co => y_carry_co(3 downto 0),
                 o => y_carry_o(3 downto 0));
   y_carry4_1: CARRY4
      port map ( ci => y_carry_co(3),
                 cyinit => '0',
                 di => y_di(7 downto 4),
                 s => y_s(7 downto 4),
                 co => y_carry_co(7 downto 4),
                 o => y_carry_o(7 downto 4));
   y_carry4_2: CARRY4
      port map ( ci => y_carry_co(7),
                 cyinit => '0',
                 di => y_di(11 downto 8),
                 s => y_s(11 downto 8),
                 co => y_carry_co(11 downto 8),
                 o => y_carry_o(11 downto 8));
end architecture;

