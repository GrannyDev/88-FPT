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
    port (a : in  std_logic_vector(2 downto 0);
          sel : in  std_logic_vector(2 downto 0);
          y : out  std_logic_vector(6 downto 0)   );
end entity;

architecture arch of XilinxRSCM_comb_uid2 is


signal a_shift2 :  std_logic_vector(4 downto 0);
   -- timing of a_shift2: 0.000000ns
signal y_sel :  std_logic_vector(2 downto 0);
   -- timing of y_sel: 0.000000ns
signal y_s :  std_logic_vector(7 downto 0);
   -- timing of y_s: 0.000000ns
signal y_di :  std_logic_vector(7 downto 0);
   -- timing of y_di: 0.000000ns
signal y_carry_co :  std_logic_vector(7 downto 0);
   -- timing of y_carry_co: 0.000000ns
signal y_carry_o :  std_logic_vector(7 downto 0);
   -- timing of y_carry_o: 0.000000ns
signal y_carry_in :  std_logic;
   -- timing of y_carry_in: 0.000000ns
begin
   a_shift2 <= std_logic_vector(shift_left(resize(unsigned(a), 5), 2));
   y_sel <= sel(2 downto 0);
   y_s(7) <= '0';
   y_di(7) <= '0';
   y_carry_in <= y_sel(2);
   y <= y_carry_o(6 downto 0);
   y_lut_0: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => a(0),
                 i4 => a_shift2(0),
                 i5 => '1',
                 o5 => y_di(0),
                 o6 => y_s(0));
   y_lut_1: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => a(1),
                 i4 => a_shift2(1),
                 i5 => '1',
                 o5 => y_di(1),
                 o6 => y_s(1));
   y_lut_2: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => a(2),
                 i4 => a_shift2(2),
                 i5 => '1',
                 o5 => y_di(2),
                 o6 => y_s(2));
   y_lut_3: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => '0',
                 i4 => a_shift2(3),
                 i5 => '1',
                 o5 => y_di(3),
                 o6 => y_s(3));
   y_lut_4: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => '0',
                 i4 => a_shift2(4),
                 i5 => '1',
                 o5 => y_di(4),
                 o6 => y_s(4));
   y_lut_5: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => '0',
                 i4 => '0',
                 i5 => '1',
                 o5 => y_di(5),
                 o6 => y_s(5));
   y_lut_6: LUT6_2
      generic map ( init => x"E54C59F0CFC43B30")
      port map ( i0 => y_sel(0),
                 i1 => y_sel(1),
                 i2 => y_sel(2),
                 i3 => '0',
                 i4 => '0',
                 i5 => '1',
                 o5 => y_di(6),
                 o6 => y_s(6));
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
end architecture;

