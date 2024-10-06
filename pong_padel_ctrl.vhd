library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pong_pkg.all;


entity pong_padel_ctrl is
    generic
    (
        g_PLAYER_PADEL_X : integer
    );
    port
    (
        i_CLK           : in std_logic;
        i_UP            : in std_logic;
        i_DOWN          : in std_logic;
        i_col_count_div : in std_logic_vector(5 downto 0);
        i_row_count_div : in std_logic_vector(5 downto 0);
        o_draw_padel    : out std_logic;
        o_padel_Y       : out std_logic_vector(5 downto 0)
    );
end entity;

architecture rtl of pong_padel_ctrl is

    signal w_col_index : natural range 0 to (2 ** i_col_count_div'length) := 0;
    signal w_row_index : natural range 0 to (2 ** i_row_count_div'length) := 0;

    signal r_padel_count    : natural range 0 to c_PADEL_SPEED := 0;

    -- Start location of padel
    signal r_padel_Y : natural range 0 to (c_GAME_HEIGHT - c_PADEL_HEIGHT - 1) := (c_GAME_HEIGHT - c_PADEL_HEIGHT - 1)/2;

    signal r_draw_padel : std_logic := '0';
begin
    w_col_index <= to_integer(unsigned(i_col_count_div));
    w_row_index <= to_integer(unsigned(i_row_count_div));

    p_padel_counter : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (i_UP = '1') xor (i_DOWN = '1') then
                if (r_padel_count = c_PADEL_SPEED) then
                    r_padel_count <= 0;
                else
                    r_padel_count <= r_padel_count + 1;
                end if;
            else
                r_padel_count <= 0;
            end if;
        end if;
    end process;

    p_move_padel : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (i_UP = '1') and (r_padel_count = c_PADEL_SPEED) then
                if (r_padel_Y = 0) then
                    r_padel_Y <= 0;
                else
                    r_padel_Y <= r_padel_Y - 1;
                end if;
            elsif (i_DOWN = '1') and (r_padel_count = c_PADEL_SPEED) then
                if (r_padel_Y = (c_GAME_HEIGHT - c_PADEL_HEIGHT - 1)) then
                    r_padel_Y <= (c_GAME_HEIGHT - c_PADEL_HEIGHT - 1);
                else
                    r_padel_Y <= r_padel_Y + 1;
                end if;
            else
                r_padel_Y <= r_padel_Y;
            end if;
        end if;
    end process;

    p_draw_padel : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (w_col_index = g_PLAYER_PADEL_X) and
                (w_row_index >= r_padel_Y) and
                (w_row_index <= r_padel_Y + c_PADEL_HEIGHT) then
                r_draw_padel <= '1';
            else
                r_draw_padel <= '0';
            end if;
        end if;
    end process;
    o_draw_padel <= r_draw_padel;
    o_padel_Y    <= std_logic_vector(to_unsigned(r_padel_Y, o_padel_Y'length));

    end architecture;