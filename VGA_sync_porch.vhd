library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_sync_porch is
    generic
    (
        g_VIDEO_WIDTH : integer;
        g_TOTAL_COLS  : integer;
        g_TOTAL_ROWS  : integer;
        g_ACTIVE_COLS : integer;
        g_ACTIVE_ROWS : integer
    );
    port
    (
        i_CLK   : in std_logic;
        i_HSYNC : in std_logic;
        i_VSYNC : in std_logic;

        o_HSYNC : out std_logic;
        o_VSYNC : out std_logic;

        i_RED_video : in std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        i_GRN_video : in std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        i_BLU_video : in std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        o_RED_video : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        o_GRN_video : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        o_BLU_video : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0)
    );
end VGA_sync_porch;

architecture arch of VGA_sync_porch is
    constant c_FRONT_PORCH_HORZ : integer := 18; -- (16)
    constant c_BACK_PORCH_HORZ  : integer := 50; -- (48)
    constant c_FRONT_PORCH_VERT : integer := 10; -- 10
    constant c_BACK_PORCH_VERT  : integer := 33; -- 33

    signal w_col_count : std_logic_vector(9 downto 0);
    signal w_row_count : std_logic_vector(9 downto 0);
    signal w_HSYNC     : std_logic;
    signal w_VSYNC     : std_logic;
    signal r_HSYNC     : std_logic := '0';
    signal r_VSYNC     : std_logic := '0';

    signal r_RED_video : std_logic_vector(g_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal r_GRN_video : std_logic_vector(g_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal r_BLU_video : std_logic_vector(g_VIDEO_WIDTH - 1 downto 0) := (others => '0');

    component VGA_sync_to_count
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
    end component;

begin

    VGA_sync_to_count_inst : VGA_sync_to_count
    generic
    map(
    g_TOTAL_COLS => g_TOTAL_COLS,
    g_TOTAL_ROWS => g_TOTAL_ROWS
    )
    port map
    (
        i_CLK       => i_CLK,
        i_HSYNC     => i_HSYNC,
        i_VSYNC     => i_VSYNC,
        o_HSYNC     => w_HSYNC,
        o_VSYNC     => w_VSYNC,
        o_col_count => w_col_count,
        o_row_count => w_row_count
    );

    p_sync_porch : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (to_integer(unsigned(w_col_count)) < g_ACTIVE_COLS + c_FRONT_PORCH_HORZ) or
                (to_integer(unsigned(w_col_count)) > g_TOTAL_COLS - 1 - c_BACK_PORCH_HORZ) then
                r_HSYNC <= '1';
            else
                r_HSYNC <= w_HSYNC;
            end if;

            if (to_integer(unsigned(w_row_count)) < g_ACTIVE_ROWS + c_FRONT_PORCH_VERT) or
                (to_integer(unsigned(w_row_count)) > g_TOTAL_ROWS - 1 - c_BACK_PORCH_VERT) then
                r_VSYNC <= '1';
            else
                r_VSYNC <= w_VSYNC;
            end if;
        end if;
    end process; -- p_sync_porch

    -- Pipelined video to align it to o_HSYNC/o_VSYNC
    p_video_align : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            r_BLU_video <= i_BLU_video;
            r_GRN_video <= i_GRN_video;
            r_RED_video <= i_RED_video;
                     
            o_BLU_video <= r_BLU_video;
            o_GRN_video <= r_GRN_video;
            o_RED_video <= r_RED_video;
        end if;
    end process;

    o_HSYNC <= r_HSYNC;
    o_VSYNC <= r_VSYNC;

end architecture;