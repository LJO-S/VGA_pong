library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_sync_pulses is
    generic
    (
        g_TOTAL_COLS  : integer;
        g_TOTAL_ROWS  : integer;
        g_ACTIVE_ROWS : integer;
        g_ACTIVE_COLS : integer
    );
    port
    (
        i_CLK       : in std_logic; -- 25 MHz
        o_row_count : out std_logic_vector(9 downto 0);
        o_col_count : out std_logic_vector(9 downto 0);
        o_HSYNC     : out std_logic;
        o_VSYNC     : out std_logic
    );
end VGA_sync_pulses;

architecture arch of VGA_sync_pulses is
    signal r_col_count : natural range 0 to g_TOTAL_COLS - 1 := 0;
    signal r_row_count : natural range 0 to g_TOTAL_ROWS - 1 := 0;
begin
    main : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (r_col_count = g_TOTAL_COLS - 1) then
                r_col_count <= 0;
                if (r_row_count = g_TOTAL_ROWS - 1) then
                    r_row_count <= 0;
                else
                    r_row_count <= r_row_count + 1;
                end if;
            else
                r_col_count <= r_col_count + 1;
            end if;
        end if;
    end process; -- main

    o_HSYNC <= '1' when (r_col_count < g_ACTIVE_COLS) else
        '0';
    o_VSYNC <= '1' when (r_row_count < g_ACTIVE_ROWS) else
        '0';
    o_row_count <= std_logic_vector(to_unsigned(r_row_count, o_row_count'length));
    o_col_count <= std_logic_vector(to_unsigned(r_col_count, o_col_count'length));

end architecture;