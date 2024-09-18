library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pong_pkg.all;
entity pong_score_ctrl is
    port
    (
        i_CLK        : in std_logic;
        i_score_wall : in std_logic;
        i_col_count  : in std_logic_vector(9 downto 0);
        i_row_count  : in std_logic_vector(9 downto 0);

        o_draw_score : out std_logic
    );
end entity;

architecture rtl of pong_score_ctrl is

    constant c_SCORE_X : integer := c_GAME_WIDTH/2;
    constant c_SCORE_Y : integer := 1;

    signal w_col_count_div_LARGE : std_logic_vector(5 downto 0); -- 40
    signal w_row_count_div_LARGE : std_logic_vector(5 downto 0); -- 30

    signal w_col_count_div_SMALL : std_logic_vector(5 downto 0); -- 
    signal w_row_count_div_SMALL : std_logic_vector(5 downto 0); -- 

    signal r_row_addr : std_logic_vector(4 downto 0) := (others => '0'); -- 16 Y
    signal r_col_addr : std_logic_vector(3 downto 0) := (others => '0'); -- 8 X

    signal w_score_active : std_logic := '0';
    signal r_bit_draw     : std_logic := '0';

begin
    w_col_count_div_LARGE <= i_col_count(i_col_count'left downto 4);
    w_row_count_div_LARGE <= i_row_count(i_row_count'left downto 4);
    --w_col_count_div_SMALL <= i_col_count(XXX downto XXX);
    --w_row_count_div_SMALL <= i_row_count(XXX downto XXX);

    w_score_active <= '1' when (unsigned(w_col_count_div_LARGE) = c_SCORE_X and unsigned(w_row_count_div_LARGE) = c_SCORE_Y) else
        '0';
    
    -- PROCESS access ROM
    process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (w_score_active = '1') then
                
            end if;
        end if;
    end process;

    

end architecture;