--
-- ROM interface
--     can be intialized using a rom file in radix-2 format
--     the bus width must match the coeff width.
--
-- Author : liu benyuan <liubenyuan@gmail.com>
-- Date   : 2013-04-19
-------------------------------------------------------------------------------
-- Revisions
-- 2014-03-02 : tab completion

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity rom is
    generic
    (
        ADDR_WIDTH : integer := 10;
        DATA_WIDTH : integer := 19;
        INPUT_FILE : string  := "data.coe"
    );
    port
    (
        clk     : in std_logic;
        rd      : in std_logic;
        addr    : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        dout    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity rom;

architecture rtl of rom is
    -- instance of memory
    constant DIM : natural := 2**ADDR_WIDTH;
    type memory_type is array(0 to DIM-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- impure function (referenced by stackexchange.com)
    impure function fillMemory (file_name : in string) return memory_type is
        FILE romfile : text is in file_name;
        variable l_in : LINE;
        variable temp_b : bit_vector(DATA_WIDTH-1 downto 0);
        variable rom : memory_type;
    begin
        for i in memory_type'range loop
            readline(romfile, l_in);
            read(l_in, temp_b);
            rom(i) := to_stdlogicvector(temp_b);
        end loop;
        return rom;
    end function;

    -- rom (unless otherwise initialized, stay with the values in .coe)
    signal mem : memory_type := fillMemory(INPUT_FILE);
    signal d_mem : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    -- indexed output. XST will synthesis out a ROM. 
    -- you can force the synthesis result in Block ROM by using the advanced
    -- synthesis options.                      (Liu)
    p_rom : process(clk) is
    begin
        if rising_edge(clk) then
            if rd = '1' then
                d_mem <= mem(to_integer(unsigned(addr)));
            end if;
        end if;
    end process p_rom;
    dout <= d_mem;

end architecture rtl;
