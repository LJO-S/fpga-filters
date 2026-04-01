-------------------------------------------------------------------------------
-- Implements a Sequential Transposed Polyphase Decimator Filter
-- 
-- Pros:
--      > Sequential structure preferable since parallel wouldn't make sense when decimating
-- Cons:
--      > N/A
-- 
-- 
--                      DECIMATION-BY-3 EXAMPLE
--    x[n]---------+-----------------+-----------------+                           
--         _       |         _       |         _       | 
--        / |      |        / |      |        / |      | 
--  CNT--|  |-----(x) CNT--|  |-----(x) CNT--|  |-----(x) 
--        \_|      |        \_|      |        \_|      |     
--                 |                 |                 |                                 _____
--                 +--|Z|-|Z|-|Z|---(+)--|Z|-|Z|-|Z|--(+)--|Z|-|Z|-|Z|-(+)----+---------|  OUT|---> y[m]                                     
--                                                                      |     |     +---|?=M  |
--    ________                                                          +-|Z|-+     |   |_____|
--   | CNT++  |---------------------------------------------------------------------+
--   |________|---> CNT
-- 
--  
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- 
use std.textio.all;
-- 
use work.polyphase_pkg.all;
-- 

entity polyphase_decimate_sequential is
    generic (
        G_DATA_WIDTH       : natural := 16;
        G_COEFF_WIDTH      : natural := 16;
        G_FILTER_ORDER     : natural := 64;
        G_MULTIRATE_FACTOR : natural := 4;
        G_INIT_FILE        : string  := "../../data/filter_coefficients/DDC4_16b_fpass13000_fstop27000_fs80000.txt"
    );
    port (
        clk : in std_logic;
        -- Input
        i_data  : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        i_valid : in std_logic;
        -- Output
        o_data  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        o_valid : out std_logic
    );
end entity polyphase_decimate_sequential;

architecture rtl of polyphase_decimate_sequential is
    --------------------
    -- Constants
    --------------------
    constant C_COEFF_FRAC_WIDTH : natural                           := G_COEFF_WIDTH - 1;
    constant C_COEFFS_PER_PHASE : natural                           := G_FILTER_ORDER / G_MULTIRATE_FACTOR;
    constant C_BIT_GROWTH_A     : natural                           := integer(ceil(log2(real(C_COEFFS_PER_PHASE))));
    constant C_BIT_GROWTH_B     : natural                           := integer(ceil(log2(real(G_MULTIRATE_FACTOR))));
    constant C_CLIP_MAX_SIGNED  : signed(G_DATA_WIDTH - 1 downto 0) := (G_DATA_WIDTH - 1 => '0', others => '1');
    constant C_CLIP_MIN_SIGNED  : signed(G_DATA_WIDTH - 1 downto 0) := (G_DATA_WIDTH - 1 => '1', others => '0');
    --------------------
    -- Functions
    --------------------
    -- The following code either initializes the memory values to a specified file or to all zeros to match hardware
    impure function init_ram_from_file return t_array_slv is
        file v_read_file : text open read_mode is G_INIT_FILE;
        variable v_line  : line;
        variable v_slv   : std_logic_vector(G_COEFF_WIDTH - 1 downto 0);
        variable v_ram   : t_array_slv(0 to G_FILTER_ORDER - 1)(G_COEFF_WIDTH - 1 downto 0);
        variable v_idx   : natural := 0;
    begin
        v_idx := 0;
        while not endfile(v_read_file) loop
            readline(v_read_file, v_line);
            read(v_line, v_slv);
            v_ram(v_idx) := v_slv;
            v_idx        := v_idx + 1;
        end loop;
        return v_ram;
    end function;
    --------------------
    -- Signals
    --------------------
    signal coefficient_memory   : t_array_slv(0 to G_FILTER_ORDER - 1)(G_COEFF_WIDTH - 1 downto 0)                                                            := init_ram_from_file;
    signal r_data, r_data_d1    : std_logic_vector(G_DATA_WIDTH - 1 downto 0)                                                                                 := (others => '0');
    signal r_valid, r_valid_d1  : std_logic                                                                                                                   := '0';
    signal r_valid_out          : std_logic                                                                                                                   := '0';
    signal r_valid_post_proc    : std_logic                                                                                                                   := '0';
    signal r_valid_post_proc_d1 : std_logic                                                                                                                   := '0';
    signal r_coeff              : t_array_slv(0 to C_COEFFS_PER_PHASE - 1)(G_COEFF_WIDTH - 1 downto 0)                                                        := (others => (others => '0'));
    signal r_delay_line         : t_array_slv(0 to G_MULTIRATE_FACTOR * (C_COEFFS_PER_PHASE - 1))(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH_A - 1 downto 0) := (others => (others => '0'));
    signal r_acc                : signed(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH_A - 1 downto 0)                                                          := (others => '0');
    signal r_acc_valid          : std_logic                                                                                                                   := '0';
    signal r_acc_shifted        : signed(G_DATA_WIDTH + C_BIT_GROWTH_A downto 0)                                                                              := (others => '0');
    signal r_acc_clip           : std_logic_vector(G_DATA_WIDTH - 1 downto 0)                                                                                 := (others => '0');
    signal r_phase_counter      : unsigned(integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0)                                                        := (others => '0');

begin
    -- ================================================================
    -- Combinatorial
    o_data  <= r_acc_clip;
    o_valid <= r_valid_post_proc_d1;
    -- ================================================================
    p_phase_counter : process (clk)
    begin
        if rising_edge(clk) then
            -- Default
            r_phase_counter <= (others => '0');
            if (r_valid = '1') then
                -- Increment phase/"coefficient" counter
                r_phase_counter <= r_phase_counter + 1;
                if (r_phase_counter >= G_MULTIRATE_FACTOR - 1) then
                    r_phase_counter <= (others => '0');
                end if;
            end if;
            -- Read input (and override above 'r_valid')
            r_valid <= i_valid;
            r_data  <= i_data;
        end if;
    end process p_phase_counter;
    -- ================================================================
    p_mac_and_delay_line : process (clk)
        variable v_result : signed(G_DATA_WIDTH + G_COEFF_WIDTH - 1 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            -- Note: this implements a Transposed filter
            for tap in 0 to C_COEFFS_PER_PHASE - 1 loop
                ---------------
                -- PIPE 0
                -- Get coefficient
                ---------------
                r_coeff(tap) <= coefficient_memory(((C_COEFFS_PER_PHASE - (tap + 1)) * G_MULTIRATE_FACTOR) + to_integer(r_phase_counter));
                ---------------
                -- PIPE 1
                -- MAC
                ---------------
                if (r_valid_d1 = '1') then
                    -- Multiply
                    v_result := signed(r_data_d1) * signed(r_coeff(tap));
                    -- Accumulate & delay line
                    if (tap = 0) then
                        r_delay_line(0) <= std_logic_vector(resize(v_result, r_delay_line(0)'length));
                    else
                        r_delay_line(tap * G_MULTIRATE_FACTOR) <= std_logic_vector(resize(v_result + signed(r_delay_line(tap * G_MULTIRATE_FACTOR - 1)), r_delay_line(0)'length));
                        for idx in 1 to G_MULTIRATE_FACTOR - 1 loop
                            r_delay_line(tap * G_MULTIRATE_FACTOR - (idx)) <= r_delay_line(tap * G_MULTIRATE_FACTOR - (idx) - 1);
                        end loop;
                    end if;
                end if;
            end loop;
            -- Pipe logic outside loop
            r_valid_d1  <= r_valid;
            r_data_d1   <= r_data;
            r_valid_out <= r_valid_d1;
        end if;
    end process p_mac_and_delay_line;
    -- ================================================================
    -- Accumulate and read output
    p_read_output : process (clk)
    begin
        if rising_edge(clk) then
            r_acc_valid <= '0';
            if (r_valid_out = '1') then
                -- TODO: probably need a separate register for this
                r_acc <= r_acc + resize(signed(r_delay_line(r_delay_line'high)), r_acc'length);
                if (r_phase_counter >= G_MULTIRATE_FACTOR - 1) then
                    r_acc_valid <= '1';
                end if;
            end if;
        end if;
    end process p_read_output;
    -- ================================================================
    p_saturate_and_ovf : process (clk)
    begin
        if rising_edge(clk) then
            ------------------
            -- PIPE 0
            -- Scale
            ------------------
            r_acc_shifted     <= resize(shift_right(r_acc, C_COEFF_FRAC_WIDTH), r_acc_shifted'length);
            r_valid_post_proc <= r_acc_valid;
            ------------------
            -- PIPE 1
            -- Clip
            ------------------
            if (r_acc_shifted > C_CLIP_MAX_SIGNED) then
                r_acc_clip <= std_logic_vector(C_CLIP_MAX_SIGNED);
            elsif (r_acc_shifted < C_CLIP_MIN_SIGNED) then
                r_acc_clip <= std_logic_vector(C_CLIP_MIN_SIGNED);
            else
                r_acc_clip <= std_logic_vector(resize(r_acc_shifted, G_DATA_WIDTH));
            end if;
            r_valid_post_proc_d1 <= r_valid_post_proc;
        end if;
    end process p_saturate_and_ovf;
    -- ================================================================
end architecture;