--
-- I2C devices cluster
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_cluster is
    generic (
        DW : integer := 8);
    port (
        reset : in std_logic;
        clk : in std_logic;
        trigger : in std_logic;
        wr : out std_logic;
        data : out std_logic_vector(DW-1 downto 0);
        --
        token0 : out std_logic;
        num0 : in integer;
        wr0 : in std_logic;
        data0 : in std_logic_vector(DW-1 downto 0);
        --
        token1 : out std_logic;
        num1 : in integer;
        wr1 : in std_logic;
        data1 : in std_logic_vector(DW-1 downto 0));
end entity i2c_cluster;

architecture rtl of i2c_cluster is
    type machine is (idle,s0,s1);
    signal state : machine;
    signal reset_n : std_logic;
begin
    reset_n <= not reset;
    p_state : process(clk,reset_n) is
        variable counter : integer range 0 to 127;
    begin
        if reset_n='0' then
            state <= idle;
            token0 <= '0';
            token1 <= '0';
            wr <= '0';
            data <= (others => '0');
        elsif rising_edge(clk) then
            token0 <= '0';
            token1 <= '0';
            wr <= '0';
            case state is
                when idle =>
                    if trigger='1' then
                        token0 <= '1';
                        counter := 0;
                        state <= s0;
                    end if;
                -- device 0 --
                when s0 =>
                    wr <= wr0;
                    data <= data0;
                    if wr0='1' then
                        counter := counter + 1;
                        if counter=num0 then
                            token1 <= '1';
                            counter := 0;
                            state <= s1;
                        end if;
                    end if;
                -- device 1 --
                when s1 =>
                    wr <= wr1;
                    data <= data1;
                    if wr1='1' then
                        counter := counter + 1;
                        if counter=num1 then
                            counter := 0;
                            state <= idle;
                        end if;
                    end if;
                when others => null;
            end case;
        end if;
    end process p_state;

end architecture rtl;
