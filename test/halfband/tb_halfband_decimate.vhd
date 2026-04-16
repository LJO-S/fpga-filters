
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library src_lib;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity halfband_decimate_tb is
    generic (
        runner_cfg : string
    );
end;

architecture bench of halfband_decimate_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant G_DATA_WIDTH       : natural := 16;
    constant G_COEFF_WIDTH      : natural := 16;
    constant G_MULTIRATE_FACTOR : natural := 4;
    constant G_INIT_FILE        : string  := "";
    -- Ports
    signal clk     : std_logic;
    signal i_data  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal i_valid : std_logic;
    signal o_data  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal o_valid : std_logic;
begin

    halfband_decimate_inst : entity work.halfband_decimate
        generic map(
            G_DATA_WIDTH       => G_DATA_WIDTH,
            G_COEFF_WIDTH      => G_COEFF_WIDTH,
            G_MULTIRATE_FACTOR => G_MULTIRATE_FACTOR,
            G_INIT_FILE        => G_INIT_FILE
        )
        port map
        (
            clk     => clk,
            i_data  => i_data,
            i_valid => i_valid,
            o_data  => o_data,
            o_valid => o_valid
        );
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");
                wait for 100 * clk_period;
                test_runner_cleanup(runner);

            elsif run("test_0") then
                info("Hello world test_0");
                wait for 100 * clk_period;
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    -- clk <= not clk after clk_period/2;

end;