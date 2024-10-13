library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: 
-- 1. Fix counter strobing at 2 Hz
-- 2. Fix letter ON/OFF constants
-- 3. Fix ROM
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

    type LETTER_X_ARRAY is array(0 to 9) of natural;

    constant c_LETTER_LENGTH : natural := 3;

    constant c_LETTER_Y_TOP : natural := 16;
    constant c_LETTER_Y_BOT : natural := c_LETTER_Y_TOP + c_LETTER_LENGTH;

    -- left values of letters, to be followed by c_LETTER_WIDTH in checking statement (12 + 2*8)
    constant c_LETTER_X_ARRAY : LETTER_X_ARRAY := (10, 12, 14, 16, 18, 20, 22, 24, 26, 28);

    constant c_2HZ_VALUE : natural := 12_500_000; -- NOTE: only works for 25 MHz input clock

    signal w_letter_active : std_logic_vector(9 downto 0) := (others => '0');

    signal w_col_count_div : std_logic_vector(5 downto 0); -- 40
    signal w_row_count_div : std_logic_vector(5 downto 0); -- 30
    signal w_col_addr      : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d1   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_col_addr_d2   : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X

    signal w_row_addr : std_logic_vector(3 downto 0) := (others => '0'); -- 0-15 Y

    -- Vivado does not like to infer BRAM if r_ROM_addr is initialized
    signal r_ROM_addr : std_logic_vector(15 downto 0);
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

    -- Output
    o_DRAW_GAMEOVER <= r_bit_draw;

    gen_active_letters : for i in 0 to 9 generate
        w_letter_active(i)             <= '1' when (unsigned(w_col_count_div) >= c_LETTER_X_ARRAY(i))
        and (unsigned(w_col_count_div) <= c_LETTER_X_ARRAY(i) + 1)
        and (unsigned(w_row_count_div) >= c_LETTER_Y_TOP)
        and (unsigned(w_row_count_div) <= c_LETTER_Y_BOT) else
        '0';
    end generate;

    -- This pipeline stage is needed due to r_ROM_data being subsequently
    -- updated after r_ROM_addr which in turn depends on the clocked col_addr, 
    -- thus requiring a 2 clk period pipeline stage to correctly align output data.
    p_pipeline : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            w_col_addr_d1 <= w_col_addr;
            w_col_addr_d2 <= w_col_addr_d1;
        end if;
    end process;

    p_draw_output : process (i_CLK)
        variable v_letter_active : std_logic;
    begin
        if rising_edge(i_CLK) then
            r_ROM_addr <= "00" & w_letter_active & w_row_addr;

            v_letter_active := '0';
            l_check_letter_active : for i in 0 to 9 loop
                v_letter_active := v_letter_active or w_letter_active(i);
            end loop; -- l_check_letter_active
            if (v_letter_active = '1' and r_strobe = '1' and i_game_over = '1') then
                -- Note: reversing index order by using NOT operator
                r_bit_draw <= r_ROM_data(to_integer(unsigned(not w_col_addr_d2)));
            else
                r_bit_draw <= '0';
            end if;
        end if;
    end process;

    p_2Hz_counter : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (to_integer(r_counter) = c_2HZ_VALUE) then
                r_strobe  <= not r_strobe;
                r_counter <= (others => '0');
            else
                r_counter <= r_counter + 1;
            end if;
        end if;
    end process;

    -- 1:1 tile scaling = 8x16 ROM 
    p_ROM : process (r_ROM_addr)
    begin
        --if rising_edge(i_CLK) then
        case r_ROM_addr is
                -- G
            when x"0010" => r_ROM_data <= "00000000";
            when x"0011" => r_ROM_data <= "00000000";
            when x"0012" => r_ROM_data <= "00111000";
            when x"0013" => r_ROM_data <= "01000100";
            when x"0014" => r_ROM_data <= "11000110";
            when x"0015" => r_ROM_data <= "11000000";
            when x"0016" => r_ROM_data <= "11011110";
            when x"0017" => r_ROM_data <= "11000110";
            when x"0018" => r_ROM_data <= "11000110";
            when x"0019" => r_ROM_data <= "11000110";
            when x"001A" => r_ROM_data <= "01000100";
            when x"001B" => r_ROM_data <= "00111000";
            when x"001C" => r_ROM_data <= "00000000";
            when x"001D" => r_ROM_data <= "00000000";
            when x"001E" => r_ROM_data <= "00000000";
            when x"001F" => r_ROM_data <= "00000000";
                -- A
            when x"0020" => r_ROM_data <= "00000000";
            when x"0021" => r_ROM_data <= "00000000";
            when x"0022" => r_ROM_data <= "00111000";
            when x"0023" => r_ROM_data <= "01101100";
            when x"0024" => r_ROM_data <= "01101100";
            when x"0025" => r_ROM_data <= "11000110";
            when x"0026" => r_ROM_data <= "11000110";
            when x"0027" => r_ROM_data <= "11000110";
            when x"0028" => r_ROM_data <= "11111110";
            when x"0029" => r_ROM_data <= "11000110";
            when x"002A" => r_ROM_data <= "11000110";
            when x"002B" => r_ROM_data <= "11000110";
            when x"002C" => r_ROM_data <= "00000000";
            when x"002D" => r_ROM_data <= "00000000";
            when x"002E" => r_ROM_data <= "00000000";
            when x"002F" => r_ROM_data <= "00000000";
                -- M
            when x"0040" => r_ROM_data <= "00000000";
            when x"0041" => r_ROM_data <= "00000000";
            when x"0042" => r_ROM_data <= "11000110";
            when x"0043" => r_ROM_data <= "11101110";
            when x"0044" => r_ROM_data <= "11010110";
            when x"0045" => r_ROM_data <= "11000110";
            when x"0046" => r_ROM_data <= "11000110";
            when x"0047" => r_ROM_data <= "11000110";
            when x"0048" => r_ROM_data <= "11000110";
            when x"0049" => r_ROM_data <= "11000110";
            when x"004A" => r_ROM_data <= "11000110";
            when x"004B" => r_ROM_data <= "11000110";
            when x"004C" => r_ROM_data <= "00000000";
            when x"004D" => r_ROM_data <= "00000000";
            when x"004E" => r_ROM_data <= "00000000";
            when x"004F" => r_ROM_data <= "00000000";
                -- E
            when x"0080" | x"0800" => r_ROM_data <= "00000000";
            when x"0081" | x"0801" => r_ROM_data <= "00000000";
            when x"0082" | x"0802" => r_ROM_data <= "11111110";
            when x"0083" | x"0803" => r_ROM_data <= "11000000";
            when x"0084" | x"0804" => r_ROM_data <= "11000000";
            when x"0085" | x"0805" => r_ROM_data <= "11000000";
            when x"0086" | x"0806" => r_ROM_data <= "11111000";
            when x"0087" | x"0807" => r_ROM_data <= "11000000";
            when x"0088" | x"0808" => r_ROM_data <= "11000000";
            when x"0089" | x"0809" => r_ROM_data <= "11000000";
            when x"008A" | x"080A" => r_ROM_data <= "11000000";
            when x"008B" | x"080B" => r_ROM_data <= "11111110";
            when x"008C" | x"080C" => r_ROM_data <= "00000000";
            when x"008D" | x"080D" => r_ROM_data <= "00000000";
            when x"008E" | x"080E" => r_ROM_data <= "00000000";
            when x"008F" | x"080F" => r_ROM_data <= "00000000";
                -- O
            when x"0200" => r_ROM_data <= "00000000";
            when x"0201" => r_ROM_data <= "00000000";
            when x"0202" => r_ROM_data <= "00111000";
            when x"0203" => r_ROM_data <= "01101100";
            when x"0204" => r_ROM_data <= "11000110";
            when x"0205" => r_ROM_data <= "11000110";
            when x"0206" => r_ROM_data <= "11000110";
            when x"0207" => r_ROM_data <= "11000110";
            when x"0208" => r_ROM_data <= "11000110";
            when x"0209" => r_ROM_data <= "11000110";
            when x"020A" => r_ROM_data <= "01101100";
            when x"020B" => r_ROM_data <= "00111000";
            when x"020C" => r_ROM_data <= "00000000";
            when x"020D" => r_ROM_data <= "00000000";
            when x"020E" => r_ROM_data <= "00000000";
            when x"020F" => r_ROM_data <= "00000000";
                -- V
            when x"0400" => r_ROM_data <= "00000000";
            when x"0401" => r_ROM_data <= "00000000";
            when x"0402" => r_ROM_data <= "11000110";
            when x"0403" => r_ROM_data <= "11000110";
            when x"0404" => r_ROM_data <= "11000110";
            when x"0405" => r_ROM_data <= "11000110";
            when x"0406" => r_ROM_data <= "11000110";
            when x"0407" => r_ROM_data <= "11000110";
            when x"0408" => r_ROM_data <= "11000110";
            when x"0409" => r_ROM_data <= "01101100";
            when x"040A" => r_ROM_data <= "01101100";
            when x"040B" => r_ROM_data <= "00010000";
            when x"040C" => r_ROM_data <= "00000000";
            when x"040D" => r_ROM_data <= "00000000";
            when x"040E" => r_ROM_data <= "00000000";
            when x"040F" => r_ROM_data <= "00000000";
                -- R
            when x"1000" => r_ROM_data <= "00000000";
            when x"1001" => r_ROM_data <= "00000000";
            when x"1002" => r_ROM_data <= "11111000";
            when x"1003" => r_ROM_data <= "11001100";
            when x"1004" => r_ROM_data <= "11000110";
            when x"1005" => r_ROM_data <= "11000110";
            when x"1006" => r_ROM_data <= "11000110";
            when x"1007" => r_ROM_data <= "11001100";
            when x"1008" => r_ROM_data <= "11110000";
            when x"1009" => r_ROM_data <= "11011000";
            when x"100A" => r_ROM_data <= "11001100";
            when x"100B" => r_ROM_data <= "11000110";
            when x"100C" => r_ROM_data <= "00000000";
            when x"100D" => r_ROM_data <= "00000000";
            when x"100E" => r_ROM_data <= "00000000";
            when x"100F" => r_ROM_data <= "00000000";
                -- !
            when x"2000" => r_ROM_data <= "00000000";
            when x"2001" => r_ROM_data <= "00000000";
            when x"2002" => r_ROM_data <= "00110000";
            when x"2003" => r_ROM_data <= "00110000";
            when x"2004" => r_ROM_data <= "00110000";
            when x"2005" => r_ROM_data <= "00110000";
            when x"2006" => r_ROM_data <= "00110000";
            when x"2007" => r_ROM_data <= "00110000";
            when x"2008" => r_ROM_data <= "00110000";
            when x"2009" => r_ROM_data <= "00110000";
            when x"200A" => r_ROM_data <= "00000000";
            when x"200B" => r_ROM_data <= "00110000";
            when x"200C" => r_ROM_data <= "00000000";
            when x"200D" => r_ROM_data <= "00000000";
            when x"200E" => r_ROM_data <= "00000000";
            when x"200F" => r_ROM_data <= "00000000";
                -- others
            when others => r_ROM_data <= (others => '0');
        end case;
        --end if;
    end process;
end architecture;