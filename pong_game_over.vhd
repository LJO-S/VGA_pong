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

    type LETTER_X_ARRAY is array(0 to 7) of natural;

    constant c_LETTER_WIDTH  : natural := 1;
    constant c_LETTER_LENGTH : natural := 3;

    constant c_LETTER_Y_TOP : natural := 16;
    constant c_LETTER_Y_BOT : natural := c_LETTER_Y_TOP + c_LETTER_LENGTH;

    -- left values of letters, to be followed by c_LETTER_WIDTH in checking statement (12 + 2*8)
    constant c_LETTER_X_ARRAY : LETTER_X_ARRAY := (12, 14, 16, 18, 20, 22, 24, 26);

    constant c_2HZ_VALUE : natural := 12_500_000; -- NOTE: only works for 25 MHz input clock

    signal w_letter_active : std_logic_vector(7 downto 0) := (others => '0');

    signal w_col_count_div : std_logic_vector(5 downto 0); -- 40
    signal w_row_count_div : std_logic_vector(5 downto 0); -- 30
    signal w_col_addr      : std_logic_vector(2 downto 0) := (others => '0'); -- 0-7 X
    signal w_row_addr      : std_logic_vector(3 downto 0) := (others => '0'); -- 0-15 Y

    signal r_ROM_addr : std_logic_vector(11 downto 0) := (others => '0');
    signal r_ROM_data : std_logic_vector(7 downto 0)  := (others => '0');
    signal r_bit_draw : std_logic                     := '0';

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

    gen_active_letters : for i in 0 to 7 generate
        w_letter_active(i)             <= '1' when (unsigned(w_col_count_div) >= c_LETTER_X_ARRAY(i))
        and (unsigned(w_col_count_div) <= c_LETTER_X_ARRAY(i) + 1)
        and (unsigned(w_row_count_div) >= c_LETTER_Y_TOP)
        and (unsigned(w_row_count_div) <= c_LETTER_Y_BOT) else
        '0';
    end generate;

    process (i_CLK)
        variable v_letter_active : std_logic;
    begin
        if rising_edge(i_CLK) then
            r_ROM_addr <= w_letter_active & w_row_addr;

            v_letter_active := '0';
            l_check_letter_active : for i in 0 to 7 loop
                v_letter_active := v_letter_active or w_letter_active(i);
            end loop; -- l_check_letter_active
            if (v_letter_active = '1' and r_strobe = '1' and i_game_over = '1') then
                -- Note: reversing index order by using NOT operator
                r_bit_draw <= r_ROM_data(to_integer(unsigned(not w_col_addr)));
            else
                r_bit_draw <= '0';
            end if;
        end if;
    end process;

    p_2Hz_counter : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            if (to_integer(r_counter) = c_2HZ_VALUE) then
                r_strobe <= not r_strobe;
            else
                r_strobe <= r_strobe;
            end if;
        end if;
    end process;

    -- 1:1 tile scaling = 8x16 ROM 
    -- TODO: fix addresses to use new r_ROM_addr
    p_ROM : process (i_CLK)
    begin
        if rising_edge(i_CLK) then
            case r_ROM_addr is
                    -- G
                when x"010" => r_ROM_data <= "00000000";
                when x"011" => r_ROM_data <= "00111000";
                when x"012" => r_ROM_data <= "01000100";
                when x"013" => r_ROM_data <= "11000110";
                when x"014" => r_ROM_data <= "11000110";
                when x"015" => r_ROM_data <= "11000000";
                when x"016" => r_ROM_data <= "11011110";
                when x"017" => r_ROM_data <= "11000110";
                when x"018" => r_ROM_data <= "11000110";
                when x"019" => r_ROM_data <= "11000110";
                when x"01A" => r_ROM_data <= "01000100";
                when x"01B" => r_ROM_data <= "00111000";
                when x"01C" => r_ROM_data <= "00000000";
                when x"01D" => r_ROM_data <= "00000000";
                when x"01E" => r_ROM_data <= "00000000";
                when x"01F" => r_ROM_data <= "00000000";
                    -- A
                when x"020" => r_ROM_data <= "00000000";
                when x"021" => r_ROM_data <= "00000000";
                when x"022" => r_ROM_data <= "00111000";
                when x"023" => r_ROM_data <= "01101100";
                when x"024" => r_ROM_data <= "01101100";
                when x"025" => r_ROM_data <= "11000110";
                when x"026" => r_ROM_data <= "11000110";
                when x"027" => r_ROM_data <= "11000110";
                when x"028" => r_ROM_data <= "11111110";
                when x"029" => r_ROM_data <= "11000110";
                when x"02A" => r_ROM_data <= "11000110";
                when x"02B" => r_ROM_data <= "11000110";
                when x"02C" => r_ROM_data <= "00000000";
                when x"02D" => r_ROM_data <= "00000000";
                when x"02E" => r_ROM_data <= "00000000";
                when x"02F" => r_ROM_data <= "00000000";
                    -- M
                when x"040" => r_ROM_data <= "00000000";
                when x"041" => r_ROM_data <= "00000000";
                when x"042" => r_ROM_data <= "11000011";
                when x"043" => r_ROM_data <= "11100111";
                when x"044" => r_ROM_data <= "11011011";
                when x"045" => r_ROM_data <= "11000011";
                when x"046" => r_ROM_data <= "11000011";
                when x"047" => r_ROM_data <= "11000011";
                when x"048" => r_ROM_data <= "11000011";
                when x"049" => r_ROM_data <= "11000011";
                when x"04A" => r_ROM_data <= "11000011";
                when x"04B" => r_ROM_data <= "11000011";
                when x"04C" => r_ROM_data <= "00000000";
                when x"04D" => r_ROM_data <= "00000000";
                when x"04E" => r_ROM_data <= "00000000";
                when x"04F" => r_ROM_data <= "00000000";
                    -- E
                when x"080" | x"400" => r_ROM_data <= "00000000";
                when x"081" | x"401" => r_ROM_data <= "00000000";
                when x"082" | x"402" => r_ROM_data <= "11111110";
                when x"083" | x"403" => r_ROM_data <= "11000000";
                when x"084" | x"404" => r_ROM_data <= "11000000";
                when x"085" | x"405" => r_ROM_data <= "11000000";
                when x"086" | x"406" => r_ROM_data <= "11111000";
                when x"087" | x"407" => r_ROM_data <= "11000000";
                when x"088" | x"408" => r_ROM_data <= "11000000";
                when x"089" | x"409" => r_ROM_data <= "11000000";
                when x"08A" | x"40A" => r_ROM_data <= "11000000";
                when x"08B" | x"40B" => r_ROM_data <= "11111110";
                when x"08C" | x"40C" => r_ROM_data <= "00000000";
                when x"08D" | x"40D" => r_ROM_data <= "00000000";
                when x"08E" | x"40E" => r_ROM_data <= "00000000";
                when x"08F" | x"40F" => r_ROM_data <= "00000000";
                    -- O
                when x"100" => r_ROM_data <= "00000000";
                when x"101" => r_ROM_data <= "00000000";
                when x"102" => r_ROM_data <= "00111000";
                when x"103" => r_ROM_data <= "01101100";
                when x"104" => r_ROM_data <= "11000110";
                when x"105" => r_ROM_data <= "11000110";
                when x"106" => r_ROM_data <= "11000110";
                when x"107" => r_ROM_data <= "11000110";
                when x"108" => r_ROM_data <= "11000110";
                when x"109" => r_ROM_data <= "11000110";
                when x"10A" => r_ROM_data <= "01101100";
                when x"10B" => r_ROM_data <= "00111000";
                when x"10C" => r_ROM_data <= "00000000";
                when x"10D" => r_ROM_data <= "00000000";
                when x"10E" => r_ROM_data <= "00000000";
                when x"10F" => r_ROM_data <= "00000000";
                    -- V
                when x"200" => r_ROM_data <= "00000000";
                when x"201" => r_ROM_data <= "00000000";
                when x"202" => r_ROM_data <= "11000110";
                when x"203" => r_ROM_data <= "11000110";
                when x"204" => r_ROM_data <= "11000110";
                when x"205" => r_ROM_data <= "11000110";
                when x"206" => r_ROM_data <= "11000110";
                when x"207" => r_ROM_data <= "11000110";
                when x"208" => r_ROM_data <= "11000110";
                when x"209" => r_ROM_data <= "01101100";
                when x"20A" => r_ROM_data <= "01101100";
                when x"20B" => r_ROM_data <= "00010000";
                when x"20C" => r_ROM_data <= "00000000";
                when x"20D" => r_ROM_data <= "00000000";
                when x"20E" => r_ROM_data <= "00000000";
                when x"20F" => r_ROM_data <= "00000000";
                    -- R
                when x"800" => r_ROM_data <= "00000000";
                when x"801" => r_ROM_data <= "00000000";
                when x"802" => r_ROM_data <= "11111000";
                when x"803" => r_ROM_data <= "11001100";
                when x"804" => r_ROM_data <= "11000110";
                when x"805" => r_ROM_data <= "11000110";
                when x"806" => r_ROM_data <= "11000110";
                when x"807" => r_ROM_data <= "11001100";
                when x"808" => r_ROM_data <= "11110000";
                when x"809" => r_ROM_data <= "11011000";
                when x"80A" => r_ROM_data <= "11001100";
                when x"80B" => r_ROM_data <= "11000110";
                when x"80C" => r_ROM_data <= "00000000";
                when x"80D" => r_ROM_data <= "00000000";
                when x"80E" => r_ROM_data <= "00000000";
                when x"80F" => r_ROM_data <= "00000000";
                    -- others
                when others => r_ROM_data <= (others => '0');
            end case;
        end if;
    end process;
end architecture;