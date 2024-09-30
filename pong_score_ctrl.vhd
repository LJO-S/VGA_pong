library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pong_pkg.all;

entity pong_score_ctrl is
    port
    (
        i_CLK        : in std_logic;
        i_score_wall : in std_logic_vector(3 downto 0);
        i_col_count  : in std_logic_vector(9 downto 0);
        i_row_count  : in std_logic_vector(9 downto 0);

        o_draw_score : out std_logic
    );
end entity;

architecture rtl of pong_score_ctrl is

    constant c_SCORE_X_LEFT  : integer := c_GAME_WIDTH/2;
    constant c_SCORE_X_RIGHT : integer := c_SCORE_X_LEFT + 1; -- +1=16 bits
    constant c_SCORE_Y_TOP   : integer := 0;
    constant c_SCORE_Y_BOT   : integer := c_SCORE_Y_TOP + 3; -- +3=64 bits

    signal w_col_count_div : std_logic_vector(5 downto 0); -- 40
    signal w_row_count_div : std_logic_vector(5 downto 0); -- 30
    signal w_col_addr      : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_row_addr      : std_logic_vector(3 downto 0) := (others => '0'); -- 0-15 Y
    signal w_score_active  : std_logic;

    signal r_score_wall : std_logic_vector(i_score_wall'left downto 0) := (others => '0');
    signal r_ROM_addr   : std_logic_vector(7 downto 0)                 := (others => '0');
    signal r_ROM_data   : std_logic_vector(7 downto 0)                 := (others => '0');
    signal r_bit_draw   : std_logic                                    := '0';

begin
    -- Tile scaling: 1:16
    -- Each pixel becomes 16 pixels in X/Y
    w_col_count_div <= i_col_count(i_col_count'left downto 4);
    w_row_count_div <= i_row_count(i_row_count'left downto 4);

    -- Tile scaling: 1:4
    -- Each pixel becomes 4 pixels in X/Y
    w_col_addr <= i_col_count(4 downto 2);
    w_row_addr <= i_row_count(5 downto 2);

    w_score_active             <= '1' when (unsigned(w_col_count_div) >= c_SCORE_X_LEFT) and
        (unsigned(w_col_count_div) <= c_SCORE_X_RIGHT) and
        (unsigned(w_row_count_div) >= c_SCORE_Y_TOP) and
        (unsigned(w_row_count_div) <= c_SCORE_Y_BOT) else
        '0';

    o_draw_score <= r_bit_draw;

    p_draw : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            r_score_wall <= i_score_wall;
            r_ROM_addr   <= r_score_wall & w_row_addr;
            if (w_score_active = '1') then
                -- Note: reversing index order by using NOT operator
                r_bit_draw <= r_ROM_data(to_integer(unsigned(not w_col_addr)));
            else
                r_bit_draw <= '0';
            end if;
        end if;
    end process;

    -- 1:1 tile scaling = 8x16 ROM 
    p_ROM : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            case r_ROM_addr is
                    -- 0
                when x"00" => r_ROM_data <= "00000000";
                when x"01" => r_ROM_data <= "00000000";
                when x"02" => r_ROM_data <= "00111000";
                when x"03" => r_ROM_data <= "01101100";
                when x"04" => r_ROM_data <= "11000110";
                when x"05" => r_ROM_data <= "11001110";
                when x"06" => r_ROM_data <= "11010110";
                when x"07" => r_ROM_data <= "11100110";
                when x"08" => r_ROM_data <= "11000110";
                when x"09" => r_ROM_data <= "11000110";
                when x"0A" => r_ROM_data <= "01101100";
                when x"0B" => r_ROM_data <= "00111000";
                when x"0C" => r_ROM_data <= "00000000";
                when x"0D" => r_ROM_data <= "00000000";
                when x"0E" => r_ROM_data <= "00000000";
                when x"0F" => r_ROM_data <= "00000000";
                    -- 1
                when x"10" => r_ROM_data <= "00000000";
                when x"11" => r_ROM_data <= "00000000";
                when x"12" => r_ROM_data <= "00011000";
                when x"13" => r_ROM_data <= "00111000";
                when x"14" => r_ROM_data <= "01111000";
                when x"15" => r_ROM_data <= "00011000";
                when x"16" => r_ROM_data <= "00011000";
                when x"17" => r_ROM_data <= "00011000";
                when x"18" => r_ROM_data <= "00011000";
                when x"19" => r_ROM_data <= "00011000";
                when x"1A" => r_ROM_data <= "01111110";
                when x"1B" => r_ROM_data <= "01111110";
                when x"1C" => r_ROM_data <= "00000000";
                when x"1D" => r_ROM_data <= "00000000";
                when x"1E" => r_ROM_data <= "00000000";
                when x"1F" => r_ROM_data <= "00000000";
                    -- 2
                when x"20" => r_ROM_data <= "00000000";
                when x"21" => r_ROM_data <= "00000000";
                when x"22" => r_ROM_data <= "11111110";
                when x"23" => r_ROM_data <= "11111110";
                when x"24" => r_ROM_data <= "00000110";
                when x"25" => r_ROM_data <= "00000110";
                when x"26" => r_ROM_data <= "11111110";
                when x"27" => r_ROM_data <= "11111110";
                when x"28" => r_ROM_data <= "11000000";
                when x"29" => r_ROM_data <= "11000000";
                when x"2A" => r_ROM_data <= "11111110";
                when x"2B" => r_ROM_data <= "11111110";
                when x"2C" => r_ROM_data <= "00000000";
                when x"2D" => r_ROM_data <= "00000000";
                when x"2E" => r_ROM_data <= "00000000";
                when x"2F" => r_ROM_data <= "00000000";
                    -- 3
                when x"30" => r_ROM_data <= "00000000";
                when x"31" => r_ROM_data <= "00000000";
                when x"32" => r_ROM_data <= "11111110";
                when x"33" => r_ROM_data <= "11111110";
                when x"34" => r_ROM_data <= "00000110";
                when x"35" => r_ROM_data <= "00000110";
                when x"36" => r_ROM_data <= "00111110";
                when x"37" => r_ROM_data <= "00111110";
                when x"38" => r_ROM_data <= "00000110";
                when x"39" => r_ROM_data <= "00000110";
                when x"3A" => r_ROM_data <= "11111110";
                when x"3B" => r_ROM_data <= "11111110";
                when x"3C" => r_ROM_data <= "00000000";
                when x"3D" => r_ROM_data <= "00000000";
                when x"3E" => r_ROM_data <= "00000000";
                when x"3F" => r_ROM_data <= "00000000";
                    -- 4
                when x"40" => r_ROM_data <= "00000000";
                when x"41" => r_ROM_data <= "00000000";
                when x"42" => r_ROM_data <= "11000110";
                when x"43" => r_ROM_data <= "11000110";
                when x"44" => r_ROM_data <= "11000110";
                when x"45" => r_ROM_data <= "11000110";
                when x"46" => r_ROM_data <= "11111110";
                when x"47" => r_ROM_data <= "11111110";
                when x"48" => r_ROM_data <= "00000110";
                when x"49" => r_ROM_data <= "00000110";
                when x"4A" => r_ROM_data <= "00000110";
                when x"4B" => r_ROM_data <= "00000110";
                when x"4C" => r_ROM_data <= "00000000";
                when x"4D" => r_ROM_data <= "00000000";
                when x"4E" => r_ROM_data <= "00000000";
                when x"4F" => r_ROM_data <= "00000000";
                    -- 5
                when x"50" => r_ROM_data <= "00000000";
                when x"51" => r_ROM_data <= "00000000";
                when x"52" => r_ROM_data <= "11111110";
                when x"53" => r_ROM_data <= "11111110";
                when x"54" => r_ROM_data <= "11000000";
                when x"55" => r_ROM_data <= "11000000";
                when x"56" => r_ROM_data <= "11111110";
                when x"57" => r_ROM_data <= "11111110";
                when x"58" => r_ROM_data <= "00000110";
                when x"59" => r_ROM_data <= "00000110";
                when x"5A" => r_ROM_data <= "11111110";
                when x"5B" => r_ROM_data <= "11111110";
                when x"5C" => r_ROM_data <= "00000000";
                when x"5D" => r_ROM_data <= "00000000";
                when x"5E" => r_ROM_data <= "00000000";
                when x"5F" => r_ROM_data <= "00000000";
                    -- 6
                when x"60" => r_ROM_data <= "00000000";
                when x"61" => r_ROM_data <= "00000000";
                when x"62" => r_ROM_data <= "11111110";
                when x"63" => r_ROM_data <= "11111110";
                when x"64" => r_ROM_data <= "11000000";
                when x"65" => r_ROM_data <= "11000000";
                when x"66" => r_ROM_data <= "11111110";
                when x"67" => r_ROM_data <= "11111110";
                when x"68" => r_ROM_data <= "11000110";
                when x"69" => r_ROM_data <= "11000110";
                when x"6A" => r_ROM_data <= "11111110";
                when x"6B" => r_ROM_data <= "11111110";
                when x"6C" => r_ROM_data <= "00000000";
                when x"6D" => r_ROM_data <= "00000000";
                when x"6E" => r_ROM_data <= "00000000";
                when x"6F" => r_ROM_data <= "00000000";
                    -- 7
                when x"70" => r_ROM_data <= "00000000";
                when x"71" => r_ROM_data <= "00000000";
                when x"72" => r_ROM_data <= "11111110";
                when x"73" => r_ROM_data <= "11111110";
                when x"74" => r_ROM_data <= "11000110";
                when x"75" => r_ROM_data <= "00000110";
                when x"76" => r_ROM_data <= "00000110";
                when x"77" => r_ROM_data <= "00000110";
                when x"78" => r_ROM_data <= "00000110";
                when x"79" => r_ROM_data <= "00000110";
                when x"7A" => r_ROM_data <= "00000110";
                when x"7B" => r_ROM_data <= "00000110";
                when x"7C" => r_ROM_data <= "00000000";
                when x"7D" => r_ROM_data <= "00000000";
                when x"7E" => r_ROM_data <= "00000000";
                when x"7F" => r_ROM_data <= "00000000";
                    -- 8
                when x"80" => r_ROM_data <= "00000000";
                when x"81" => r_ROM_data <= "00000000";
                when x"82" => r_ROM_data <= "11111110";
                when x"83" => r_ROM_data <= "11111110";
                when x"84" => r_ROM_data <= "11000110";
                when x"85" => r_ROM_data <= "11000110";
                when x"86" => r_ROM_data <= "11111110";
                when x"87" => r_ROM_data <= "11111110";
                when x"88" => r_ROM_data <= "11000110";
                when x"89" => r_ROM_data <= "11000110";
                when x"8A" => r_ROM_data <= "11111110";
                when x"8B" => r_ROM_data <= "11111110";
                when x"8C" => r_ROM_data <= "00000000";
                when x"8D" => r_ROM_data <= "00000000";
                when x"8E" => r_ROM_data <= "00000000";
                when x"8F" => r_ROM_data <= "00000000";
                    -- 9
                when x"90" => r_ROM_data <= "00000000";
                when x"91" => r_ROM_data <= "00000000";
                when x"92" => r_ROM_data <= "11111110";
                when x"93" => r_ROM_data <= "11111110";
                when x"94" => r_ROM_data <= "11000110";
                when x"95" => r_ROM_data <= "11000110";
                when x"96" => r_ROM_data <= "11111110";
                when x"97" => r_ROM_data <= "11111110";
                when x"98" => r_ROM_data <= "00000110";
                when x"99" => r_ROM_data <= "00000110";
                when x"9A" => r_ROM_data <= "11111110";
                when x"9B" => r_ROM_data <= "11111110";
                when x"9C" => r_ROM_data <= "00000000";
                when x"9D" => r_ROM_data <= "00000000";
                when x"9E" => r_ROM_data <= "00000000";
                when x"9F" => r_ROM_data <= "00000000";
                    -- others
                when others => r_ROM_data <= (others => '0');
            end case;
        end if;
    end process;
end architecture;