--
-- arbitrary clock divider
--
-- Author: liu benyuan <liubenyuan@gmail.com>
-- Date  : 2013-04-16
--
------------------------------------------------------------
-- Revision History
-- (2013-04-16) intialize
-- (2013-04-18) synthesis under XST. (done)
-- (2014-03-01) tab completion
--
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.ceil;
use ieee.math_real.log2;

entity clkdiv is
    generic (
        RefValue  : natural := 499);
    Port (
        clkin    : in    STD_LOGIC;
        clkout   : out   STD_LOGIC;
        rst      : in    STD_LOGIC);
end entity clkdiv;

architecture rtl of clkdiv is
    -- constant
    constant ADDR_WIDTH : integer := integer(ceil(log2(real(RefValue))));

    ------------------------------------------------------------------------
    -- General control and timing signals
    ------------------------------------------------------------------------
    signal fClkInternal : STD_LOGIC := '0';

    ------------------------------------------------------------------------
    -- Data path signals
    ------------------------------------------------------------------------
    signal cValue       : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');

begin
    -- Output clock follows the internal toggled bit
    clkout <= fClkInternal;

    p_div: process(rst, clkin)
    begin
        -- Reset Behavior
        if (rst = '1') then
            fClkInternal <= '0';
            cValue <= (others => '0');
        -- On the rising edge increment the counter
        elsif rising_edge(clkin) then
            if (cValue = RefValue) then
                -- Toggle the clock on a counter delay at the reference
                fClkInternal <= not fClkInternal;
                -- And Reset the counter.
                cValue <= (others => '0');
            else
                cValue <= cValue + 1;
            end if;
        end if;
    end process p_div;

end architecture rtl;

