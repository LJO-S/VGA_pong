library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_sync_to_count is
    generic
    (
        g_TOTAL_COLS : integer;
        g_TOTAL_ROWS : integer
    );
    port
    (
        i_CLK   : in std_logic;
        i_HSYNC : in std_logic;
        i_VSYNC : in std_logic;

        o_HSYNC     : out std_logic;
        o_VSYNC     : out std_logic;
        o_col_count : out std_logic_vector(9 downto 0);
        o_row_count : out std_logic_vector(9 downto 0)
    );
end VGA_sync_to_count;

architecture arch of VGA_sync_to_count is
    signal r_HSYNC       : std_logic := '0';
    signal r_VSYNC       : std_logic := '0';
    signal w_frame_start : std_logic;

    signal r_col_count : unsigned(9 downto 0) := (others => '0');
    signal r_row_count : unsigned(9 downto 0) := (others => '0');

begin
    p_reg_syncs : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            r_VSYNC <= i_VSYNC;
            r_HSYNC <= i_HSYNC;
        end if;
    end process; -- p_reg_syncs

    p_row_col_count : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (w_frame_start = '1') then
                r_col_count <= (others => '0');
                r_row_count <= (others => '0');
            else
                if (r_col_count = to_unsigned(g_TOTAL_COLS - 1, r_col_count'length)) then
                    r_col_count <= (others => '0');
                    if (r_row_count = to_unsigned(g_TOTAL_ROWS - 1, r_row_count'length)) then
                        r_row_count <= (others => '0');
                    else
                        r_row_count <= r_row_count + 1;
                    end if;
                else
                    r_col_count <= r_col_count + 1;
                end if;
            end if;
        end if;
    end process; -- p_row_col_count

    w_frame_start <= '1' when (r_VSYNC = '0') and (i_VSYNC = '1') else
        '0';

    o_VSYNC <= r_VSYNC;
    o_HSYNC <= r_HSYNC;

    o_row_count <= std_logic_vector(r_row_count);
    o_col_count <= std_logic_vector(r_col_count);

end architecture;