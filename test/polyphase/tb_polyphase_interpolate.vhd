library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- 
use std.textio.all;
-- 
use work.polyphase_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity polyphase_interpolate_tb is
    generic (
        runner_cfg         : string;
        G_DATA_WIDTH       : natural;
        G_COEFF_WIDTH      : natural;
        G_FILTER_ORDER     : natural;
        G_MULTIRATE_FACTOR : natural;
        G_INIT_FILE        : string
    );
end;

architecture bench of polyphase_interpolate_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant TB_INIT_FILE : string := output_path(runner_cfg) & "/" & G_INIT_FILE;
    -- Ports
    signal clk     : std_logic := '0';
    signal i_data  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal i_valid : std_logic;
    signal o_data  : t_array_slv(0 to G_MULTIRATE_FACTOR - 1)(G_DATA_WIDTH - 1 downto 0);
    signal o_valid : std_logic;
    -- Testbench
    type t_tb_array_float is array (0 to G_MULTIRATE_FACTOR - 1) of real;

    signal tb_input_data_float  : real             := 0.0;
    signal tb_output_data_float : t_tb_array_float := (others => 0.0);
    signal tb_auto_set          : boolean          := false;
    signal tb_auto_done         : boolean          := false;
    signal auto_data_input      : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal auto_data_valid      : std_logic;
    -- Procedure
    procedure wait_clock (clk_ticks : integer) is
    begin
        for i in 0 to clk_ticks - 1 loop
            wait until rising_edge(clk);
        end loop;
    end procedure;
begin
    -- ================================================================
    clk <= not clk after clk_period/2;
    -- ================================================================
    -- Read input file
    p_read_input_file : process
        file v_read_file      : text open read_mode is output_path(runner_cfg) & "/" & "input_data.txt";
        variable v_line       : line;
        variable v_data_input : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
        tb_auto_done <= false;
        wait until tb_auto_set = TRUE;
        while not endfile(v_read_file) loop
            readline(v_read_file, v_line);
            -- Data
            BINARY_READ(v_line, v_data_input);
            auto_data_input <= v_data_input;
            auto_data_valid <= '1';
            wait_clock(1);
            auto_data_input <= (others => '0');
            auto_data_valid <= '0';
            wait_clock(2);
        end loop;
        tb_auto_done <= true;
        wait;
    end process p_read_input_file;
    -- ================================================================
    -- ===================================================================
    -- Assign inputs
    i_data  <= auto_data_input;
    i_valid <= auto_data_valid;
    -- ===================================================================
    -- Write output file
    p_write_output_file : process (clk)
        file v_write_file     : text open write_mode is output_path(runner_cfg) & "/" & "output_data.txt";
        variable v_line       : line;
        variable v_output_slv : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
        if rising_edge(clk) then
            if (o_valid = '1') then
                for phase in 0 to G_MULTIRATE_FACTOR - 1 loop
                    v_output_slv := o_data(phase);
                    write(v_line, v_output_slv, right, o_data'length + 4);
                end loop;
                -- Write output obtained
                -- Write to file
                writeline(v_write_file, v_line);
            end if;
        end if;
    end process p_write_output_file;
    -- ===================================================================
    polyphase_interpolate_inst : entity work.polyphase_interpolate
        generic map(
            G_DATA_WIDTH       => G_DATA_WIDTH,
            G_COEFF_WIDTH      => G_COEFF_WIDTH,
            G_FILTER_ORDER     => G_FILTER_ORDER,
            G_MULTIRATE_FACTOR => G_MULTIRATE_FACTOR,
            G_INIT_FILE        => TB_INIT_FILE
        )
        port map
        (
            clk     => clk,
            i_data  => i_data,
            i_valid => i_valid,
            o_data  => o_data,
            o_valid => o_valid
        );
    -- ================================================================
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        if run("auto") then
            info("Hello world!");
            wait until clk = '1';
            wait_clock(1);
            tb_auto_set <= true;
            wait until tb_auto_done = true;
        end if;
        test_runner_cleanup(runner);
    end process main;
    -- ===================================================================
    -- Update debugs
    tb_input_data_float  <= real(to_integer(signed(i_data))) / (2.0 ** G_DATA_WIDTH);
    g_output_debug : for phase in 0 to G_MULTIRATE_FACTOR - 1 generate
        tb_output_data_float(phase) <= real(to_integer(signed(o_data(phase)))) / (2.0 ** G_DATA_WIDTH);
    end generate;
    -- ===================================================================
end;