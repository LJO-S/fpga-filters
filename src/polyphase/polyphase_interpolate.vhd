-------------------------------------------------------------------------------
-- Implements a polyphase interpolator
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

entity polyphase_interpolate is
    generic (
        G_DATA_WIDTH       : natural := 16;
        G_COEFF_WIDTH      : natural := 16;
        G_FILTER_ORDER     : natural := 1;
        G_MULTIRATE_FACTOR : natural := 1;
        G_INIT_FILE        : string
    );
    port (
        clk : in std_logic;
        -- Input
        i_data  : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        i_valid : in std_logic;
        -- Output
        o_data  : out t_array_slv(0 to G_MULTIRATE_FACTOR - 1)(G_DATA_WIDTH - 1 downto 0);
        o_valid : out std_logic
    );
end entity polyphase_interpolate;

architecture rtl of polyphase_interpolate is
    --------------------
    -- Constants
    --------------------
    constant C_LATENCY : natural := 5;

    constant C_COEFF_FRAC_WIDTH   : natural                                                          := G_COEFF_WIDTH - 1;
    constant C_COEFFS_PER_PHASE   : natural                                                          := G_FILTER_ORDER / G_MULTIRATE_FACTOR;
    constant C_BIT_GROWTH         : natural                                                          := integer(ceil(log2(real(C_COEFFS_PER_PHASE))));
    constant C_ROUND_VALUE_SIGNED : signed(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH - 1 downto 0) := (G_COEFF_WIDTH - 1 downto 0 => '1', others => '0');
    constant C_CLIP_MAX_SIGNED    : signed(G_DATA_WIDTH - 1 downto 0)                                := (G_DATA_WIDTH - 1 => '0', others => '1');
    constant C_CLIP_MIN_SIGNED    : signed(G_DATA_WIDTH - 1 downto 0)                                := (G_DATA_WIDTH - 1 => '1', others => '0');
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
    signal coefficient_memory : t_array_slv(0 to G_FILTER_ORDER - 1)(G_COEFF_WIDTH - 1 downto 0)    := init_ram_from_file;
    signal r_data             : std_logic_vector(G_DATA_WIDTH - 1 downto 0)                         := (others => '0');
    signal r_valid            : std_logic                                                           := '0';
    signal r_valid_shreg      : std_logic_vector(C_LATENCY - 1 downto 0)                            := (others => '0');
    signal r_acc_clip         : t_array_slv(0 to G_MULTIRATE_FACTOR - 1)(G_DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
    --------------------
    -- Constants
    --------------------

begin
    -- ================================================================
    -- Combinatorial
    o_data  <= r_acc_clip;
    o_valid <= r_valid_shreg(r_valid_shreg'high) and (i_valid);
    -- ================================================================
    p_register_input : process (clk)
    begin
        if rising_edge(clk) then
            -- Shift valid
            if (i_valid = '1') then
                r_valid_shreg <= r_valid_shreg(r_valid_shreg'high - 1 downto r_valid_shreg'low) & '1';
            end if;
        end if;
    end process p_register_input;
    -- ================================================================
    g_gen_phase : for phase in 0 to G_MULTIRATE_FACTOR - 1 generate
        signal r_delay_line  : t_array_slv(0 to C_COEFFS_PER_PHASE - 1)(G_DATA_WIDTH - 1 downto 0)        := (others => (others => '0'));
        signal r_acc         : std_logic_vector(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH - 1 downto 0) := (others => '0');
        signal r_acc_round   : signed(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH downto 0)               := (others => '0');
        signal r_acc_shifted : signed(G_DATA_WIDTH + C_BIT_GROWTH downto 0)                               := (others => '0');
    begin
        ---------------------------------------------------------------
        p_delay_line : process (clk)
            variable v_result : signed(G_DATA_WIDTH + G_COEFF_WIDTH - 1 downto 0)                := (others => '0');
            variable v_acc    : signed(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH - 1 downto 0) := (others => '0');
        begin
            if rising_edge(clk) then
                if (i_valid = '1') then
                    ------------------
                    -- Delay Line
                    ------------------
                    r_delay_line <= i_data & r_delay_line(r_delay_line'low to r_delay_line'high - 1);
                    ------------------
                    -- Mult & accum
                    ------------------
                    v_acc := (others => '0');
                    for tap in 0 to C_COEFFS_PER_PHASE - 1 loop
                        v_result := signed(coefficient_memory(phase + (tap * G_MULTIRATE_FACTOR))) * signed(r_delay_line(tap));
                        -- Note: Might be troublesome for large CLK or high tap count
                        v_acc := v_acc + v_result;
                    end loop;
                    r_acc <= std_logic_vector(v_acc);
                end if;
            end if;
        end process p_delay_line;
        ---------------------------------------------------------------
        p_saturate_and_ovf : process (clk)
        begin
            if rising_edge(clk) then
                ------------------
                -- Round
                ------------------
                -- Assume positive
                r_acc_round <= resize(signed(r_acc) + C_ROUND_VALUE_SIGNED, r_acc_round'length);
                if (r_acc(r_acc'high) = '1') then
                    -- Negative
                    r_acc_round <= resize(signed(r_acc) - C_ROUND_VALUE_SIGNED, r_acc_round'length);
                end if;
                ------------------
                -- Scale
                ------------------
                r_acc_shifted <= resize(shift_right(r_acc_round, C_COEFF_FRAC_WIDTH), r_acc_shifted'length);
                ------------------
                -- Clip
                ------------------
                if (r_acc_shifted > C_CLIP_MAX_SIGNED) then
                    r_acc_clip(phase) <= std_logic_vector(C_CLIP_MAX_SIGNED);
                elsif (r_acc_shifted < C_CLIP_MIN_SIGNED) then
                    r_acc_clip(phase) <= std_logic_vector(C_CLIP_MIN_SIGNED);
                else
                    r_acc_clip(phase) <= std_logic_vector(resize(r_acc_shifted, G_DATA_WIDTH));
                end if;
            end if;
        end process p_saturate_and_ovf;
        ---------------------------------------------------------------
    end generate g_gen_phase;
    -- ================================================================
end architecture;