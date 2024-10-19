library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_game_over is
    port (
        i_CLK : in std_logic;

        -- FSM activates this when score reaches set value ('1' ON / '0' OFF)
        i_game_over : in std_logic;

        i_col_count : in std_logic_vector(9 downto 0);
        i_row_count : in std_logic_vector(9 downto 0);

        o_DRAW_GAMEOVER : out std_logic
    );
end entity;
architecture rtl of pong_game_over is

    type LETTER_X_ARRAY is array(0 to 8) of natural;

    constant c_LETTER_LENGTH : natural := 3;

    constant c_LETTER_Y_TOP : natural := 16;
    constant c_LETTER_Y_BOT : natural := c_LETTER_Y_TOP + c_LETTER_LENGTH;

    -- left values of letters, to be followed by c_LETTER_WIDTH in checking statement (12 + 2*8)
    constant c_LETTER_X_ARRAY : LETTER_X_ARRAY := (10, 12, 14, 16, 20, 22, 24, 26, 28);

    signal w_letter_active : std_logic_vector(8 downto 0) := (others => '0'); -- 0-9
    signal r_letter_active : std_logic_vector(3 downto 0) := (others => '0');

    signal w_col_count_div : std_logic_vector(5 downto 0); -- 40
    signal w_row_count_div : std_logic_vector(5 downto 0); -- 30
    signal w_col_addr      : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d1   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d2   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d3   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d4   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X

    signal w_row_addr : std_logic_vector(3 downto 0) := (others => '0'); -- 0-15 Y

    -- Vivado does not like to infer BRAM if r_ROM_addr is initialized
    signal r_ROM_addr : std_logic_vector(7 downto 0);
    signal r_ROM_data : std_logic_vector(7 downto 0) := (others => '0');
    signal r_bit_draw : std_logic                    := '0';

    signal r_strobe  : std_logic             := '0';
    signal r_counter : unsigned(23 downto 0) := (others => '0');

begin

    -- We have 2 tile scaling schemes: 1:16 and 1:4
    -- The smaller tile will fit into the larger tile x4 times
    -- Thus, when updating tiles using _count_div we need to 
    -- ... account for 4 smaller tiles moving along.

    -- Tile scaling: 1:16
    -- Each pixel becomes 16 pixels in X/Y
    w_col_count_div <= i_col_count(i_col_count'left downto 4);
    w_row_count_div <= i_row_count(i_row_count'left downto 4);

    -- Tile scaling: 1:4
    -- Each pixel becomes 4 pixels in X/Y
    w_col_addr <= i_col_count(4 downto 2);
    w_row_addr <= i_row_count(5 downto 2);

    -- Strobe
    r_strobe <= r_counter(r_counter'left);

    -- Output
    o_DRAW_GAMEOVER <= r_bit_draw;

    ------------------------------------------------------------------------------------
    gen_active_letters : for i in 0 to 8 generate
        w_letter_active(i)             <= '1' when (unsigned(w_col_count_div) >= c_LETTER_X_ARRAY(i))
        and (unsigned(w_col_count_div) <= c_LETTER_X_ARRAY(i) + 1)
        and (unsigned(w_row_count_div) >= c_LETTER_Y_TOP)
        and (unsigned(w_row_count_div) <= c_LETTER_Y_BOT) else
        '0';
    end generate;
    process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            case w_letter_active is
                when "000000001" => r_letter_active <= std_logic_vector(to_unsigned(0, r_letter_active'length));
                when "000000010" => r_letter_active <= std_logic_vector(to_unsigned(1, r_letter_active'length));
                when "000000100" => r_letter_active <= std_logic_vector(to_unsigned(2, r_letter_active'length));
                when "000001000" => r_letter_active <= std_logic_vector(to_unsigned(3, r_letter_active'length));
                when "000010000" => r_letter_active <= std_logic_vector(to_unsigned(4, r_letter_active'length));
                when "000100000" => r_letter_active <= std_logic_vector(to_unsigned(5, r_letter_active'length));
                when "001000000" => r_letter_active <= std_logic_vector(to_unsigned(6, r_letter_active'length));
                when "010000000" => r_letter_active <= std_logic_vector(to_unsigned(7, r_letter_active'length));
                when "100000000" => r_letter_active <= std_logic_vector(to_unsigned(8, r_letter_active'length));
                when others      => r_letter_active <= (others => '1'); 
            end case;
        end if;
    end process;
    ------------------------------------------------------------------------------------

    --gen_active_letters : for i in 0 to 8 generate
    --    w_letter_active                <= std_logic_vector(to_unsigned(i, w_letter_active'length)) when (unsigned(w_col_count_div) >= c_LETTER_X_ARRAY(i))
    --        and (unsigned(w_col_count_div) <= c_LETTER_X_ARRAY(i) + 1)
    --        and (unsigned(w_row_count_div) >= c_LETTER_Y_TOP)
    --        and (unsigned(w_row_count_div) <= c_LETTER_Y_BOT) else
    --        (others => '0');
    --end generate;

    --p_letter_active : process (i_CLK)
    --    variable ind : integer range 0 to 9 := 0;
    --begin
    --    if rising_edge(i_CLK) then
    --        if (unsigned(w_col_count_div) >= c_LETTER_X_ARRAY(ind))
    --            and (unsigned(w_col_count_div) <= c_LETTER_X_ARRAY(ind) + 1)
    --            and (unsigned(w_row_count_div) >= c_LETTER_Y_TOP)
    --            and (unsigned(w_row_count_div) <= c_LETTER_Y_BOT) then
    --            r_letter_active                <= to_unsigned(ind, r_letter_active'length);
    --        end if;
    --    end if;
    --end process;

    -- This pipeline stage is needed due to r_ROM_data being subsequently
    -- updated after r_ROM_addr which in turn depends on the clocked col_addr, 
    -- thus requiring a 2 clk period pipeline stage to correctly align output data.
    p_pipeline : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            w_col_addr_d1 <= w_col_addr;
            w_col_addr_d2 <= w_col_addr_d1;
            w_col_addr_d3 <= w_col_addr_d2;
            w_col_addr_d4 <= w_col_addr_d3;
        end if;
    end process;

    p_draw_output : process (i_CLK)
        variable v_letter_active : std_logic;
    begin
        if rising_edge(i_CLK) then
            r_ROM_addr <= r_letter_active & w_row_addr;
            --l_check_letter_active : for i in 0 to 9 loop -- TODO 
            --    v_letter_active := v_letter_active or w_letter_active(i);
            --end loop; -- l_check_letter_active
            if (to_integer(unsigned(w_letter_active)) > 0) then
                v_letter_active := '1';
            else
                v_letter_active := '0';
            end if;
            if (v_letter_active = '1' and r_strobe = '1' and i_game_over = '1') then
                -- Note: reversing index order by using NOT operator
                r_bit_draw <= r_ROM_data(to_integer(unsigned(not w_col_addr_d4)));
            else
                r_bit_draw <= '0';
            end if;
        end if;
    end process;

    p_2Hz_counter : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            r_counter <= r_counter + 1;
        end if;
    end process;

    -- 1:1 tile scaling = 8x16 ROM 
    p_ROM : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            case r_ROM_addr is
                    -- G
                when x"00" => r_ROM_data <= "00000000";
                when x"01" => r_ROM_data <= "00000000";
                when x"02" => r_ROM_data <= "00111000";
                when x"03" => r_ROM_data <= "01000100";
                when x"04" => r_ROM_data <= "11000110";
                when x"05" => r_ROM_data <= "11000000";
                when x"06" => r_ROM_data <= "11011110";
                when x"07" => r_ROM_data <= "11000110";
                when x"08" => r_ROM_data <= "11000110";
                when x"09" => r_ROM_data <= "11000110";
                when x"0A" => r_ROM_data <= "01000100";
                when x"0B" => r_ROM_data <= "00111000";
                when x"0C" => r_ROM_data <= "00000000";
                when x"0D" => r_ROM_data <= "00000000";
                when x"0E" => r_ROM_data <= "00000000";
                when x"0F" => r_ROM_data <= "00000000";
                    -- A
                when x"10" => r_ROM_data <= "00000000";
                when x"11" => r_ROM_data <= "00000000";
                when x"12" => r_ROM_data <= "00111000";
                when x"13" => r_ROM_data <= "01101100";
                when x"14" => r_ROM_data <= "01101100";
                when x"15" => r_ROM_data <= "11000110";
                when x"16" => r_ROM_data <= "11000110";
                when x"17" => r_ROM_data <= "11000110";
                when x"18" => r_ROM_data <= "11111110";
                when x"19" => r_ROM_data <= "11000110";
                when x"1A" => r_ROM_data <= "11000110";
                when x"1B" => r_ROM_data <= "11000110";
                when x"1C" => r_ROM_data <= "00000000";
                when x"1D" => r_ROM_data <= "00000000";
                when x"1E" => r_ROM_data <= "00000000";
                when x"1F" => r_ROM_data <= "00000000";
                    -- M
                when x"20" => r_ROM_data <= "00000000";
                when x"21" => r_ROM_data <= "00000000";
                when x"22" => r_ROM_data <= "11000110";
                when x"23" => r_ROM_data <= "11101110";
                when x"24" => r_ROM_data <= "11010110";
                when x"25" => r_ROM_data <= "11000110";
                when x"26" => r_ROM_data <= "11000110";
                when x"27" => r_ROM_data <= "11000110";
                when x"28" => r_ROM_data <= "11000110";
                when x"29" => r_ROM_data <= "11000110";
                when x"2A" => r_ROM_data <= "11000110";
                when x"2B" => r_ROM_data <= "11000110";
                when x"2C" => r_ROM_data <= "00000000";
                when x"2D" => r_ROM_data <= "00000000";
                when x"2E" => r_ROM_data <= "00000000";
                when x"2F" => r_ROM_data <= "00000000";
                    -- E (TODO: if still not BRAM, fix this)
                when x"30" | x"60" => r_ROM_data <= "00000000";
                when x"31" | x"61" => r_ROM_data <= "00000000";
                when x"32" | x"62" => r_ROM_data <= "11111110";
                when x"33" | x"63" => r_ROM_data <= "11000000";
                when x"34" | x"64" => r_ROM_data <= "11000000";
                when x"35" | x"65" => r_ROM_data <= "11000000";
                when x"36" | x"66" => r_ROM_data <= "11111000";
                when x"37" | x"67" => r_ROM_data <= "11000000";
                when x"38" | x"68" => r_ROM_data <= "11000000";
                when x"39" | x"69" => r_ROM_data <= "11000000";
                when x"3A" | x"6A" => r_ROM_data <= "11000000";
                when x"3B" | x"6B" => r_ROM_data <= "11111110";
                when x"3C" | x"6C" => r_ROM_data <= "00000000";
                when x"3D" | x"6D" => r_ROM_data <= "00000000";
                when x"3E" | x"6E" => r_ROM_data <= "00000000";
                when x"3F" | x"6F" => r_ROM_data <= "00000000";
                    -- O
                when x"40" => r_ROM_data <= "00000000";
                when x"41" => r_ROM_data <= "00000000";
                when x"42" => r_ROM_data <= "00111000";
                when x"43" => r_ROM_data <= "01101100";
                when x"44" => r_ROM_data <= "11000110";
                when x"45" => r_ROM_data <= "11000110";
                when x"46" => r_ROM_data <= "11000110";
                when x"47" => r_ROM_data <= "11000110";
                when x"48" => r_ROM_data <= "11000110";
                when x"49" => r_ROM_data <= "11000110";
                when x"4A" => r_ROM_data <= "01101100";
                when x"4B" => r_ROM_data <= "00111000";
                when x"4C" => r_ROM_data <= "00000000";
                when x"4D" => r_ROM_data <= "00000000";
                when x"4E" => r_ROM_data <= "00000000";
                when x"4F" => r_ROM_data <= "00000000";
                    -- V
                when x"50" => r_ROM_data <= "00000000";
                when x"51" => r_ROM_data <= "00000000";
                when x"52" => r_ROM_data <= "11000110";
                when x"53" => r_ROM_data <= "11000110";
                when x"54" => r_ROM_data <= "11000110";
                when x"55" => r_ROM_data <= "11000110";
                when x"56" => r_ROM_data <= "11000110";
                when x"57" => r_ROM_data <= "11000110";
                when x"58" => r_ROM_data <= "11000110";
                when x"59" => r_ROM_data <= "01101100";
                when x"5A" => r_ROM_data <= "01101100";
                when x"5B" => r_ROM_data <= "00010000";
                when x"5C" => r_ROM_data <= "00000000";
                when x"5D" => r_ROM_data <= "00000000";
                when x"5E" => r_ROM_data <= "00000000";
                when x"5F" => r_ROM_data <= "00000000";
                    -- R
                when x"70" => r_ROM_data <= "00000000";
                when x"71" => r_ROM_data <= "00000000";
                when x"72" => r_ROM_data <= "11111000";
                when x"73" => r_ROM_data <= "11001100";
                when x"74" => r_ROM_data <= "11000110";
                when x"75" => r_ROM_data <= "11000110";
                when x"76" => r_ROM_data <= "11000110";
                when x"77" => r_ROM_data <= "11001100";
                when x"78" => r_ROM_data <= "11110000";
                when x"79" => r_ROM_data <= "11011000";
                when x"7A" => r_ROM_data <= "11001100";
                when x"7B" => r_ROM_data <= "11000110";
                when x"7C" => r_ROM_data <= "00000000";
                when x"7D" => r_ROM_data <= "00000000";
                when x"7E" => r_ROM_data <= "00000000";
                when x"7F" => r_ROM_data <= "00000000";
                    -- !
                when x"80" => r_ROM_data <= "00000000";
                when x"81" => r_ROM_data <= "00000000";
                when x"82" => r_ROM_data <= "00110000";
                when x"83" => r_ROM_data <= "00110000";
                when x"84" => r_ROM_data <= "00110000";
                when x"85" => r_ROM_data <= "00110000";
                when x"86" => r_ROM_data <= "00110000";
                when x"87" => r_ROM_data <= "00110000";
                when x"88" => r_ROM_data <= "00110000";
                when x"89" => r_ROM_data <= "00000000";
                when x"8A" => r_ROM_data <= "00110000";
                when x"8B" => r_ROM_data <= "00110000";
                when x"8C" => r_ROM_data <= "00000000";
                when x"8D" => r_ROM_data <= "00000000";
                when x"8E" => r_ROM_data <= "00000000";
                when x"8F" => r_ROM_data <= "00000000";
                    -- others
                when others => r_ROM_data <= (others => '0');
            end case;
        end if;
    end process;
end architecture;