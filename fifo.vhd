--
-- handcraft fifo
-- liubenyuan (modified from http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/)
-- date : 2014-03-02
-------------------------------------------------------------------------------
-- Revisions
-- 2014-03-02 : tab completion

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity fifo is
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
end fifo;

architecture logic of fifo is

begin

    -- Memory Pointer Process
    fifo_proc : process (clk)
        type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        variable Memory : FIFO_Memory;
        variable Head : natural range 0 to FIFO_DEPTH - 1;
        variable Tail : natural range 0 to FIFO_DEPTH - 1;
        variable Looped : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                Head := 0;
                Tail := 0;
                Looped := false;
                valid <= '0';
                full  <= '0';
                empty <= '1';
            else
                valid <= '0';
                if (rd = '1') then                                  -- handle FIFO read
                    if ((Looped = true) or (Head /= Tail)) then
                        dout <= Memory(Tail);                       -- data outputs
                        valid <= '1';
                        if (Tail = FIFO_DEPTH - 1) then             -- Update Tail pointer as needed
                            Tail := 0;
                            Looped := false;
                        else
                            Tail := Tail + 1;
                        end if;
                    end if;
                end if;
                if (wr = '1') then                                  -- handle FIFO write
                    if ((Looped = false) or (Head /= Tail)) then
                        Memory(Head) := din;                        -- write DATA to memory
                        if (Head = FIFO_DEPTH - 1) then             -- Increment Head pointer as needed
                            Head := 0;
                            Looped := true;
                        else
                            Head := Head + 1;
                        end if;
                    end if;
                end if;
                if (Head = Tail) then                               -- update empty and full flags
                    if Looped then
                        full <= '1';
                    else
                        empty <= '1';
                    end if;
                else
                    empty   <= '0';
                    full    <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture logic;
