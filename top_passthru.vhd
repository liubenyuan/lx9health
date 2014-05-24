--
-- Author: liu benyuan <liubenyuan@gmail.com>
-- Date  : 2013-04-22
--
------------------------------------------------------------
-- Revision History
-- (2013-04-22) intialize
-- (2013-04-22) verified using XST, done
-- (2014-03-01) tab completion and importing i2c_master.vhd
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pycs.all;

--
entity top is
    port (
        clkin     : in STD_LOGIC;
        rst       : in STD_LOGIC; -- active low
        --
        gpio_led1 : out STD_LOGIC;
        gpio_led2 : out STD_LOGIC;
        gpio_led3 : out STD_LOGIC;
        gpio_led4 : out STD_LOGIC;
        --
        RN42_RTS : in std_logic;
        RN42_CTS : out std_logic;
        RN42_TXD : in std_logic;
        RN42_RXD : out std_logic;
        RN42_RST : out std_logic;
        RN42_STATUS : in std_logic;
        --
        USB_RS232_RXD : in std_logic;
        USB_RS232_TXD : out std_logic;
        --
        AD2_SDA   : inout std_logic;
        AD2_SCL   : inout std_logic;
        AD2_SDA_ALT : out std_logic;
        AD2_SCL_ALT : out std_logic);
end entity top;

architecture rtl of top is
    -- clk region signals
    signal sysclk,clkdiv1,clkdiv2,clkdiv2_w : std_logic;
    signal adc_trigger : std_logic;
    -- component ADC
    signal ad_cnt : std_logic_vector(7 downto 0);
    signal dout : std_logic_vector(7 downto 0);
    signal valid : std_logic;
    -- fifo
    signal rd_fifo : std_logic;
    signal fifo_data_rd : std_logic_vector(7 downto 0);
    signal fifo_valid,fifo_empty : std_logic;
    -- uart
    type uart_machine is (idle,read,probe);
    signal uart_state : uart_machine;
    signal uart_in_data : std_logic_vector(7 downto 0);
    signal uart_in_stb, uart_in_ack : std_logic;

begin
    -- first stage divider (100MHz -> 400KHz)
    p1 : clkdiv generic map (RefValue => 124)
                port map (clkin => clkin, clkout => clkdiv1, rst => rst);
    -- second stage divider (400KHz -> 250Hz)
    p2 : clkdiv generic map (RefValue => 799)
                port map (clkin => clkdiv1, clkout => clkdiv2, rst => rst);
    -- now start our functional block
    sysclk <= clkin;

    -- sample the edge of clkdiv2.
    p_sample : process(clkin) is
    begin
        if rising_edge(clkin) then
            clkdiv2_w <= clkdiv2;
        end if;
    end process p_sample;
    adc_trigger <= '1' when clkdiv2_w='0' and clkdiv2='1' else '0';

    -- ad7991
    U_AD7991 : ad7991   generic map (
                            input_clk => 100_000_000,
                            bus_clk   => 400_000)
                        port map (
                            clk => sysclk,
                            reset => rst,
                            adc_trigger => adc_trigger,
                            data => dout,
                            valid => valid,
                            sda => AD2_SDA,
                            scl => AD2_SCL);

    -- fifo
    U_FIFO : fifo   generic map (
                        DATA_WIDTH => 8,
                        FIFO_DEPTH => 16)
                    port map (
                        clk => sysclk,
                        rst => rst,
                        wr => valid,
                        din => dout,
                        rd => rd_fifo,
                        dout => fifo_data_rd,
                        valid => fifo_valid,
                        empty => fifo_empty,
                        full => open);

    -- uart control
    p_uart : process(rst,sysclk) is
    begin
        if rst='1' then
            uart_state <= idle;
            rd_fifo <= '0';
            uart_in_stb <= '0';
        elsif rising_edge(sysclk) then
            rd_fifo <= '0';
            uart_in_stb <= '0';
            case uart_state is
                when idle =>
                    if fifo_empty='0' then          -- ADC purged in fifo
                        rd_fifo <= '1';             -- read samples out
                        uart_state <= read;
                    end if;
                when read =>
                    if fifo_valid='1' then
                        uart_state <= probe;        -- wait for FIFO valid
                    end if;
                when probe =>
                    uart_in_data <= fifo_data_rd;   -- put data &
                    uart_in_stb <= '1';             -- stb signals on bus
                    if uart_in_ack='1' then         -- wait for uart ACK
                        uart_in_stb <= '0';
                        uart_state <= idle;
                    end if;
                when others => null;
            end case;
        end if;
    end process p_uart;

    -- usb_uart
    U_CP2012 : uart generic map (
                        baud_rate => 115200,
                        clock_frequency => 100_000_000)
                    port map (
                        clock => sysclk,
                        reset => rst,
                        data_stream_in => uart_in_data,
                        data_stream_in_stb => uart_in_stb,
                        data_stream_in_ack => uart_in_ack,
                        data_stream_out => open,
                        data_stream_out_stb => open,
                        data_stream_out_ack => '0',
                        tx => open,  -- passthru USB_RS232_TXD
                        rx => '1');  -- USB_RS232_RXD

    -- gpio leds
    p_gpio : process (rst,clkdiv2) is
    begin
        if (rst = '1') then
            ad_cnt <= (others => '0');
        elsif rising_edge(clkdiv2) then
            ad_cnt <= std_logic_vector(unsigned(ad_cnt) + 1);
        end if;
    end process p_gpio;
    -- led output
    gpio_led1 <= '0';
    gpio_led2 <= '1';
    gpio_led3 <= RN42_STATUS;
    gpio_led4 <= ad_cnt(ad_cnt'high);

    -- The PmodAD2 has dual SDA and SCL lines for daisy chaining TWI bus devices. If
    -- these other pins are brought low accadentially, then the device will refuse to
    -- transmit data. To prevent this, we drive them as high impedance if they are
    -- connected. If they are disconnected, they are left floating and the system
    -- should still work.
    AD2_SDA_ALT <= 'Z';
    AD2_SCL_ALT <= 'Z';

    -- handle the RN42
    RN42_RST <= '1';            -- low active, pull up by PMODBT2
    RN42_CTS <= RN42_RTS;       -- wired
    USB_RS232_TXD <= RN42_TXD;  -- passthru
    RN42_RXD <= USB_RS232_RXD;

end architecture rtl;

