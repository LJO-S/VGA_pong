library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_wall_ctrl is
    port
    (
        i_CLK           : in std_logic;
        i_row_count_div : in std_logic_vector(5 downto 0);
        i_col_count_div : in std_logic_vector(5 downto 0);

        o_draw_wall : out std_logic
    );
end entity;

architecture rtl of pong_wall_ctrl is
    signal w_col_index : natural range 0 to (2 ** i_col_count_div'length) := 0;
    signal w_row_index : natural range 0 to (2 ** i_row_count_div'length) := 0;

    signal r_draw_wall : std_logic := '0';
begin
    w_col_index <= to_integer(unsigned(i_col_count_div));
    w_row_index <= to_integer(unsigned(i_row_count_div));

    p_draw_wall : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (w_col_index = 0) then
                r_draw_wall <= '1';
            else
                r_draw_wall <= '0';
            end if;
        end if;
    end process;

    o_draw_wall <= r_draw_wall;

end architecture;