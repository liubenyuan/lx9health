--
-- adxl345 wrapper
--
-------------------------------------------------------------------------------
-- Revision
-- 2014-05-20 (init)

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adxl345 is
    generic (
        input_clk : integer := 100_000_000;
        bus_clk : integer := 400_000);
    port (
        clk : in std_logic;
        reset : in std_logic;
        trigger : in std_logic;
        data : out std_logic_vector(7 downto 0);
        valid : out std_logic;
        sda : inout std_logic;
        scl : inout std_logic);
end entity adxl345;

architecture logic of adxl345 is
    signal reset_n : std_logic;
    signal i2c_ena,i2c_rw,i2c_busy : std_logic;
    signal busy_prev : std_logic;
    signal dv_w,dv : std_logic;
    constant SLAVE_ADDR : std_logic_vector(6 downto 0) := "0011101";   -- ADXL345: 1D
    signal sdata : std_logic_vector(7 downto 0);
    signal i2c_data_rd : std_logic_vector(7 downto 0);
    --
    type machine is (idle,get_data);
    signal state : machine;

    -- i2c master
    COMPONENT i2c_master IS
    GENERIC(
        input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
        bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
    PORT(
        clk       : IN     STD_LOGIC;                    --system clock
        reset_n   : IN     STD_LOGIC;                    --active low reset
        ena       : IN     STD_LOGIC;                    --latch in command
        addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
        rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
        data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
        busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
        data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
        ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
        sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
        scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
    END COMPONENT i2c_master;

begin
    -- I2C peripheral
    reset_n <= not reset;
    U_I2C : i2c_master  generic map (
                            input_clk => input_clk,
                            bus_clk => bus_clk )
                        port map (
                            clk => clk,
                            reset_n => reset_n,
                            ena => i2c_ena,
                            addr => SLAVE_ADDR,
                            rw => i2c_rw,
                            data_wr => sdata,
                            busy => i2c_busy,
                            data_rd => i2c_data_rd,
                            ack_error => open,
                            sda => sda,
                            scl => scl);

    -- Control Logic
    p_ctrl : process(reset,clk) is
        variable busy_cnt : integer range 0 to 31;
    begin
        if reset = '1' then
            state    <= idle;
            busy_cnt := 0;
            sdata    <= (others => '0');
            i2c_ena  <= '0';
            i2c_rw   <= '1';
            dv       <= '0';
        elsif rising_edge(clk) then
            i2c_ena  <= '0';  -- default power-down
            i2c_rw   <= '0';
            dv       <= '0';  -- default data-valid
            case state is
                when idle =>
                    if trigger = '1' then                       -- external trigger
                        busy_cnt := 0;                          -- reset busy_cnt for next transaction
                        state <= get_data;
                    end if;
                when get_data =>
                    busy_prev <= i2c_busy;                      -- latch the rising_edge of i2c_busy
                    if busy_prev='0' and i2c_busy='1' then
                        busy_cnt := busy_cnt + 1;
                    end if;
                    case busy_cnt is
                        -- I2C reg_op 1 --
                        when 0 =>                               -- command(0,1) REG_WRITE 'DATA_FORMAT' 0x31
                            i2c_ena <= '1';                     -- where 0x01 denotes :
                            i2c_rw  <= '0';                     --     D6(0) 4-wire SPI, D3(0) 10bit mode
                            sdata   <= x"31";                   --     D1-D0 (01) +-4g range
                        when 1 =>
                            i2c_ena <= '1';
                            i2c_rw  <= '0';
                            sdata   <= x"01";
                        when 2 =>                               -- command(2) stop
                            i2c_ena <= '0';
                            if i2c_busy='0' then
                                busy_cnt := busy_cnt + 1;
                            end if;
                        -- I2C reg_op 2 --
                        when 3 =>                               -- command(3,4) REG_WRITE 'BW_RATE' 0x2C
                            i2c_ena <= '1';                     -- where 'sdata' denotes :
                            i2c_rw  <= '0';                     --     D3-D0(0xC) 400Hz, 200Hz BW mode
                            sdata   <= x"2C";                   --     D3-D0(0xB) 200Hz, 100Hz BW
                        when 4 =>                               --     D3-D0(0xA) 100Hz, 50Hz BW (default)
                            i2c_ena <= '1';
                            i2c_rw  <= '0';
                            sdata   <= x"0B";
                        when 5 =>                               -- command(5) stop
                            i2c_ena <= '0';
                            if i2c_busy='0' then
                                busy_cnt := busy_cnt + 1;
                            end if;
                        -- I2C reg_op 3 --
                        when 6 =>                               -- command(6,7) REG_WRITE 'POWER_CTL' 0x2D
                            i2c_ena <= '1';                     -- where 0x08 denotes :
                            i2c_rw  <= '0';                     --     D4(0) disable auto sleep
                            sdata   <= x"2D";                   --     D3(1) for measure, 0 for standby
                        when 7 =>
                            i2c_ena <= '1';
                            i2c_rw  <= '0';
                            sdata   <= x"08";
                        when 8 =>                               -- command(8) stop
                            i2c_ena <= '0';
                            if i2c_busy='0' then
                                busy_cnt := busy_cnt + 1;
                            end if;
                        -- I2C continuous read --
                        when 9 =>                               -- command(9) REG_WRITE 'DATA_X0' 0x32
                            i2c_ena <= '1';
                            i2c_rw  <= '0';
                            sdata   <= x"72";                   -- 0x72, (MSB-1)=1 continuous read
                        when 10 =>                              -- command(10) REG_READ (restart)
                            i2c_ena <= '1';
                            i2c_rw  <= '1';
                        when 11 to 15 =>
                            i2c_ena <= '1';
                            i2c_rw  <= '1';
                            dv      <= not i2c_busy;            -- latch data from previous command
                        when 16 =>                              -- command(16) end transactions
                            i2c_ena <= '0';
                            dv      <= not i2c_busy;
                            if i2c_busy='0' then
                                busy_cnt := 0;
                                sdata <= (others => '0');
                                state <= idle;
                            end if;
                        when others => null;
                    end case;
                when others => null;
            end case;
        end if;
    end process;

    -- register output
    p_obuf : process(clk) is
    begin
        if rising_edge(clk) then
            dv_w <= dv;
        end if;
        valid <= '0';                 -- data is not registered
        if dv_w='0' and dv='1' then
            valid <= '1';             -- data is valid with rising edge of dv
            data <= i2c_data_rd;      -- latch data to the output port
        end if;
    end process p_obuf;

end architecture logic;
