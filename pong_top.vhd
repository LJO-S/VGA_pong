library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pong_pkg.all;

entity pong_top is
    generic (
        g_VIDEO_WIDTH : integer;
        g_TOTAL_COLS  : integer;
        g_TOTAL_ROWS  : integer;
        g_ACTIVE_COLS : integer;
        g_ACTIVE_ROWS : integer
    );
    port (
        i_CLK   : in std_logic; -- 25 MHz 
        i_HSYNC : in std_logic;
        i_VSYNC : in std_logic;

        i_game_start : in std_logic;
        i_UP         : in std_logic;
        i_DOWN       : in std_logic;

        o_HSYNC : out std_logic;
        o_VSYNC : out std_logic;

        o_RED_VIDEO : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        o_GRN_VIDEO : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0);
        o_BLU_VIDEO : out std_logic_vector(g_VIDEO_WIDTH - 1 downto 0)

    );
end pong_top;

architecture arch of pong_top is
    type t_STATE is (t_IDLE, t_RUNNING, t_WALL_WINS, t_GAME_OVER, t_CLEANUP);
    signal STATE : t_STATE := t_IDLE;

    signal w_HSYNC : std_logic;
    signal w_VSYNC : std_logic;

    signal w_col_count     : std_logic_vector(9 downto 0); -- accounts for 480p
    signal w_row_count     : std_logic_vector(9 downto 0); -- accounts for 640p
    signal w_col_count_div : std_logic_vector(5 downto 0)                         := (others => '0'); -- resolves to 480/16 = 30;
    signal w_row_count_div : std_logic_vector(5 downto 0)                         := (others => '0'); -- resolves to 640/16 = 40;
    signal w_col_index     : integer range 0 to (2 ** w_col_count_div'length - 1) := 0;
    signal w_row_index     : integer range 0 to (2 ** w_row_count_div'length - 1) := 0;

    signal w_draw_PADEL : std_logic;
    signal w_padel_Y    : std_logic_vector(5 downto 0);

    signal w_draw_BALL : std_logic;
    signal w_ball_X    : std_logic_vector(5 downto 0);
    signal w_ball_Y    : std_logic_vector(5 downto 0);

    signal w_draw_WALL : std_logic;

    signal w_draw_SCORE : std_logic;

    signal w_draw_ANY  : std_logic := '0';

    signal w_game_active : std_logic := '0';

    signal w_game_over : std_logic := '0';
    signal w_draw_GAMEOVER : std_logic := '0';

    signal w_padel_Y_bot : unsigned(5 downto 0) := (others => '0');
    signal w_padel_Y_top : unsigned(5 downto 0) := (others => '0');
    signal w_wall_Y_top  : unsigned(5 downto 0) := (others => '0');
    signal w_wall_Y_bot  : unsigned(5 downto 0) := (others => '0');

    signal w_WALL_score : std_logic_vector(3 downto 0)     := (others => '0');
    signal r_WALL_score : integer range 0 to c_SCORE_LIMIT := c_SCORE_LIMIT;

begin
    ------------------------------------------------------------------------------------------
    VGA_sync_to_count_INST : entity work.VGA_sync_to_count
        generic map
        (
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
    ------------------------------------------------------------------------------------------
    -- process to update VSYNC/HSYNC
    p_register_syncs : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            o_HSYNC <= w_HSYNC;
            o_VSYNC <= w_VSYNC;
        end if;
    end process;

    -- Use upper 6 bits to effectively divide by 16 (XX<<4) to create 640x480-->40x30
    w_col_count_div <= w_col_count(w_col_count'left downto 4);
    w_row_count_div <= w_row_count(w_row_count'left downto 4);

    ------------------------------------------------------------------------------------------
    -- instantiate player draw
    pong_padel_ctrl_INST : entity work.pong_padel_ctrl
        generic map(
            g_PLAYER_PADEL_X => c_PLAYER_PADEL_X
        )
        port map
        (
            i_CLK           => i_CLK,
            i_UP            => i_UP,
            i_DOWN          => i_DOWN,
            i_col_count_div => w_col_count_div,
            i_row_count_div => w_row_count_div,
            o_draw_padel    => w_draw_PADEL,
            o_padel_Y       => w_padel_Y
        );
    ------------------------------------------------------------------------------------------

    -- inst wall draw
    pong_wall_ctrl_INST : entity work.pong_wall_ctrl
        port map
        (
            i_CLK           => i_CLK,
            i_row_count_div => w_row_count_div,
            i_col_count_div => w_col_count_div,
            o_draw_wall     => w_draw_WALL
        );
    ------------------------------------------------------------------------------------------
    -- inst ball draw
    pong_ball_ctrl_INST : entity work.pong_ball_ctrl
        port map
        (
            i_CLK           => i_CLK,
            i_game_active   => w_game_active,
            i_col_count_div => w_col_count_div,
            i_row_count_div => w_row_count_div,
            o_draw_ball     => w_draw_BALL,
            o_ball_X        => w_ball_X,
            o_ball_Y        => w_ball_Y
        );
    ------------------------------------------------------------------------------------------
    -- inst score ctrl
    pong_score_ctrl_inst : entity work.pong_score_ctrl
        port map
        (
            i_CLK        => i_CLK,
            i_score_wall => w_WALL_score,
            i_col_count  => w_col_count,
            i_row_count  => w_row_count,
            o_draw_score => w_draw_SCORE
        );

    w_WALL_score <= std_logic_vector(TO_UNSIGNED(r_WALL_score, w_WALL_score'length));
    ------------------------------------------------------------------------------------------
    -- inst game over
    pong_game_over_inst : entity work.pong_game_over
        port map
        (
            i_CLK           => i_CLK,
            i_game_over     => w_game_over,
            i_col_count     => w_col_count,
            i_row_count     => w_row_count,
            o_DRAW_GAMEOVER => w_draw_GAMEOVER
        );

    ------------------------------------------------------------------------------------------
    -- create top/bottom-boundaries
    w_padel_Y_bot <= unsigned(w_padel_Y);
    w_padel_Y_top <= w_padel_Y_bot + to_unsigned(c_PADEL_HEIGHT, w_padel_Y_top'length);

    w_wall_Y_bot <= to_unsigned(0, w_wall_Y_bot'length); -- should cover top to bottom
    w_wall_Y_top <= to_unsigned(c_GAME_HEIGHT - 1, w_wall_Y_top'length);
    ------------------------------------------------------------------------------------------
    -- state machine time :-)
    process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            case STATE is
                    ------------------------------------------------------------------------------
                when t_IDLE =>
                    if (i_game_start = '1') then
                        STATE <= t_RUNNING;
                    end if;
                    ------------------------------------------------------------------------------
                when t_RUNNING =>
                    -- WALL at 0, PADEL at c_GAME_WIDTH-1
                    if (to_integer(unsigned(w_ball_X)) = c_GAME_WIDTH - 1) then
                        -- MISS?
                        if (unsigned(w_ball_Y) < unsigned(w_padel_Y_bot)) or (unsigned(w_ball_Y) > unsigned(w_padel_Y_top)) then
                            STATE <= t_WALL_WINS;
                        end if;
                    end if;
                    ------------------------------------------------------------------------------
                when t_WALL_WINS =>
                    r_WALL_score <= r_WALL_score - 1;
                    if (r_WALL_score = 1) then
                        STATE        <= t_GAME_OVER;
                    else
                        STATE        <= t_CLEANUP;
                    end if;
                    ------------------------------------------------------------------------------
                when t_GAME_OVER =>
                    if (i_game_start = '1') then
                        r_WALL_score <= c_SCORE_LIMIT;
                        STATE <= t_IDLE;
                    end if;
                    ------------------------------------------------------------------------------
                when t_CLEANUP =>
                    STATE <= t_IDLE;
                    ------------------------------------------------------------------------------
                when others =>
                    STATE <= t_IDLE;
                    ------------------------------------------------------------------------------
            end case;
        end if;
    end process;

    -- concurrent statements
    w_game_active <= '1' when STATE = t_RUNNING else
        '0';
    w_game_over <= '1' when STATE = t_GAME_OVER else
        '0';

    -- big OR
    w_draw_ANY <= w_draw_BALL or w_draw_PADEL or w_draw_WALL or w_draw_SCORE or w_draw_GAMEOVER;
    -- Color assignments. 
    -- Specific color combinations for different entities can be set here.
    o_RED_VIDEO <= (others => '1') when w_draw_ANY = '1' else
        (others                => '0');
    o_GRN_VIDEO <= (others => '1') when w_DRAW_ANY = '1' else
        (others                => '0');
    o_BLU_VIDEO <= (others => '1') when w_DRAW_ANY = '1' else
        (others                => '0');

end architecture;