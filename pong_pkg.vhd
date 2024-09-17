package pong_pkg is

    -- Tile scaled by 16: 640-480 ==> 40-30
    constant c_GAME_WIDTH  : integer := 40;
    constant c_GAME_HEIGHT : integer := 30;

    constant c_PLAYER_PADEL_X : integer := c_GAME_WIDTH - 1;
    constant c_PADEL_SPEED    : integer := 250_000; -- 1 tile movement every 10 ms 
    constant c_PADEL_HEIGHT   : integer := 3;

    constant c_BALL_SPEED : integer := 250_000;

    constant c_SCORE_LIMIT : integer := 10;
    

    -- If work.entity gives you problems, declare components
    -- in here and just instantiate in architecture.
end package;