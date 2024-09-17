library ieee;
use ieee.std_logic_1164.all;

library work;
use work.pong_pkg.all;

entity PROJECT_TOP is
    port
    (
        i_CLK        : in std_logic;
        i_UP         : in std_logic;
        i_DOWN       : in std_logic;
        i_game_start : in std_logic;

        o_HSYNC : out std_logic;
        o_VSYNC : out std_logic;

        o_RED_video_0 : out std_logic;
        o_RED_video_1 : out std_logic;
        o_RED_video_2 : out std_logic;

        o_GRN_video_0 : out std_logic;
        o_GRN_video_1 : out std_logic;
        o_GRN_video_2 : out std_logic;

        o_BLU_video_0 : out std_logic;
        o_BLU_video_1 : out std_logic;
        o_BLU_video_2 : out std_logic
    );
end entity;

architecture rtl of PROJECT_TOP is

    constant c_VIDEO_WIDTH : integer := 3;
    constant c_TOTAL_COLS  : integer := 800;
    constant c_TOTAL_ROWS  : integer := 525;
    constant c_ACTIVE_COLS : integer := 640;
    constant c_ACTIVE_ROWS : integer := 480;

    -- VGA
    signal w_HSYNC_VGA : std_logic := '0';
    signal w_VSYNC_VGA : std_logic := '0';

    -- Pushbuttons
    signal w_UP   : std_logic := '0';
    signal w_DOWN : std_logic := '0';

    -- Pong signals
    signal w_game_start     : std_logic                                    := '0';
    signal w_row_count      : std_logic_vector(9 downto 0)                 := (others => '0');
    signal w_col_count      : std_logic_vector(9 downto 0)                 := (others => '0');
    signal w_HSYNC_PONG     : std_logic                                    := '0';
    signal w_VSYNC_PONG     : std_logic                                    := '0';
    signal w_RED_video_PONG : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal w_BLU_video_PONG : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal w_GRN_video_PONG : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');

    -- Output signals
    signal w_RED_video_OUT : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal w_BLU_video_OUT : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal w_GRN_video_OUT : std_logic_vector(c_VIDEO_WIDTH - 1 downto 0) := (others => '0');
    signal w_HSYNC_OUT     : std_logic                                    := '0';
    signal w_VSYNC_OUT     : std_logic                                    := '0';

begin
    ----------------------------------------------------------------------
    pong_top_inst : entity work.pong_top
        generic
        map (
        g_VIDEO_WIDTH => c_VIDEO_WIDTH,
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS
        )
        port map
        (
            i_CLK        => i_CLK,
            i_HSYNC      => w_HSYNC_VGA,
            i_VSYNC      => w_VSYNC_VGA,
            i_game_start => w_game_start,
            i_UP         => w_UP,
            i_DOWN       => w_DOWN,
            o_HSYNC      => w_HSYNC_PONG,
            o_VSYNC      => w_VSYNC_PONG,
            o_RED_VIDEO  => w_RED_video_PONG,
            o_GRN_VIDEO  => w_GRN_video_PONG,
            o_BLU_VIDEO  => w_BLU_video_PONG
        );
    ----------------------------------------------------------------------
    VGA_sync_pulses_inst : entity work.VGA_sync_pulses
        generic
        map (
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS
        )
        port
        map (
        i_CLK       => i_CLK,
        o_row_count => open,
        o_col_count => open,
        o_HSYNC     => w_HSYNC_VGA,
        o_VSYNC     => w_VSYNC_VGA
        );
    ----------------------------------------------------------------------
    VGA_sync_porch_inst : entity work.VGA_sync_porch
        generic
        map (
        g_VIDEO_WIDTH => c_VIDEO_WIDTH,
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS
        )
        port
        map (
        i_CLK       => i_CLK,
        i_HSYNC     => w_HSYNC_PONG,
        i_VSYNC     => w_VSYNC_PONG,
        o_HSYNC     => w_HSYNC_OUT,
        o_VSYNC     => w_VSYNC_OUT,
        i_RED_video => w_RED_video_PONG,
        i_GRN_video => w_GRN_video_PONG,
        i_BLU_video => w_BLU_video_PONG,
        o_RED_video => w_RED_video_OUT,
        o_GRN_video => w_GRN_video_OUT,
        o_BLU_video => w_BLU_video_OUT
        );
    ----------------------------------------------------------------------
    PB_debounce_inst_1 : entity work.PB_debounce
        port
        map (
        i_CLK         => i_CLK,
        i_PB          => i_UP,
        o_PB_debounce => w_UP
        );

    PB_debounce_inst_2 : entity work.PB_debounce
        port
        map (
        i_CLK         => i_CLK,
        i_PB          => i_DOWN,
        o_PB_debounce => w_DOWN
        );

    PB_debounce_inst_3 : entity work.PB_debounce
        port
        map (
        i_CLK         => i_CLK,
        i_PB          => i_game_start,
        o_PB_debounce => w_game_start
        );
    ----------------------------------------------------------------------
    -- Output signals
    o_RED_video_0 <= w_RED_video_OUT(0);
    o_RED_video_1 <= w_RED_video_OUT(1);
    o_RED_video_2 <= w_RED_video_OUT(2);

    o_BLU_video_0 <= w_BLU_video_OUT(0);
    o_BLU_video_1 <= w_BLU_video_OUT(1);
    o_BLU_Video_2 <= w_BLU_video_OUT(2);

    o_GRN_video_0 <= w_GRN_video_OUT(0);
    o_GRN_video_1 <= w_GRN_video_OUT(1);
    o_GRN_video_2 <= w_GRN_video_OUT(2);

    o_HSYNC <= w_HSYNC_OUT;
    o_VSYNC <= w_VSYNC_OUT;

    ----------------------------------------------------------------------
end architecture;