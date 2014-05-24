--
-- RAM interface (true dual port, synced clock)
--
-- Author : liu benyuan <liubenyuan@gmail.com>
-- Date   : 2013-04-19
-------------------------------------------------------------------------------
-- Revisions
-- 2014-03-02 : tab completion
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dualram is
    generic (
        DATA_WIDTH : natural := 19;
        ADDR_WIDTH : natural := 10
        );
    port (
        clk   : in std_logic;
        -- Port A
        a_wr    : in  std_logic;
        a_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        a_din   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        a_dout  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Port B
        b_wr    : in  std_logic;
        b_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        b_din   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        b_dout  : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end entity dualram;

architecture rtl of dualram is
    --
    constant DIM : natural := 2**ADDR_WIDTH;
    type memory_type is array(0 to DIM - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : memory_type;

begin

    -- **write first** true dual-port ram with synced clock
    -- will be auto-infered by XST. you can also toggle the 
    -- Block options in properties of the synthesis.    (Liu)
    p_mem : process(clk) is
    begin
        if rising_edge(clk) then
            -- Port A
            if a_wr = '1' then
                mem(to_integer(unsigned(a_addr))) <= a_din;
            end if;
            a_dout <= mem(to_integer(unsigned(a_addr)));
            -- Port B
            if b_wr = '1' then
                mem(to_integer(unsigned(b_addr))) <= b_din;
            end if;
            b_dout <= mem(to_integer(unsigned(b_addr)));
        end if;
    end process p_mem;

end architecture rtl;
