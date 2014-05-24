--
-- package pycs
--
-- including all the packages for
--     1. DWT based compression for pysiological signals
--     2. CS based compression for physiological signals
--     3. Util functions
--
-- Author : liu benyuan <liubenyuan@gmail.com>
-- date   : 2013-04-22
--

--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pycs is

-- clock divider
component clkdiv is
    generic ( RefValue : natural := 499);
    Port    (
        clkin   : in STD_LOGIC;
        clkout  : out STD_LOGIC;
        rst     : in STD_LOGIC);
end component clkdiv;

-- fifo
component fifo is
    Generic (
        constant DATA_WIDTH : positive := 8;
        constant FIFO_DEPTH : positive := 16
    );
    Port (
        clk     : in  std_logic;                                       -- Clock input
        rst     : in  std_logic;                                       -- Active high reset
        wr      : in  std_logic;                                       -- Write enable signal
        din     : in  std_logic_vector (DATA_WIDTH - 1 downto 0);      -- Data input bus
        rd      : in  std_logic;                                       -- Read enable signal
        dout    : out std_logic_vector (DATA_WIDTH - 1 downto 0);      -- Data output bus
        valid   : out std_logic;                                       -- Data outputs valid
        empty   : out std_logic;                                       -- FIFO empty flag
        full    : out std_logic                                        -- FIFO full flag
    );
end component;

-- ad7991
component ad7991 is
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
end component ad7991;

-- adxl345
component adxl345 is
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
end component adxl345;

-- i2c cluster, bad handwritting code
component i2c_cluster is
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
end component i2c_cluster;

-- usb_rs232
component uart is
    generic (
        baud_rate : positive;
        clock_frequency : positive);
    port (
        clock               :   in      std_logic;
        reset               :   in      std_logic; -- high active
        DATA_STREAM_IN      :   in      std_logic_vector(7 downto 0);
        DATA_STREAM_IN_STB  :   in      std_logic;
        DATA_STREAM_IN_ACK  :   out     std_logic := '0';
        DATA_STREAM_OUT     :   out     std_logic_vector(7 downto 0);
        DATA_STREAM_OUT_STB :   out     std_logic;
        DATA_STREAM_OUT_ACK :   in      std_logic;
        TX                  :   out     std_logic;
        RX                  :   in      std_logic  -- Async Receive
    );
end component uart;

end package pycs;

-------------------------------------------------------------------------------
package body pycs is
--
-- Yes, you can configure which architecture you want to use in your project.
--                                                              -- Liu
--

-- for all:macCell use entity WORK.macCell(rtl);
-- for all:sortCell use entity WORK.sortCell(rtl);
end pycs;
