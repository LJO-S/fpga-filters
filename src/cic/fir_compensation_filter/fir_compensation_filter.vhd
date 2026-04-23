-------------------------------------------------------------------------------
-- Implements a Transposed Folded FIR Filter
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- 
use std.textio.all;
-- 
entity fir_compensation_filter is
    generic (
        G_DATA_WIDTH       : natural := 16;
        G_COEFF_WIDTH      : natural := 16;
        G_COEFF_FRAC_WIDTH : natural := 16;
        G_NUM_TAPS         : natural := 16;
        G_INIT_FILE        : string
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
end entity fir_compensation_filter;

architecture rtl of fir_compensation_filter is
    --------------------
    -- Constants
    --------------------
    constant C_BIT_GROWTH      : natural                           := integer(ceil(log2(real(G_NUM_TAPS))));
    constant C_CLIP_MAX_SIGNED : signed(G_DATA_WIDTH - 1 downto 0) := (G_DATA_WIDTH - 1 => '0', others => '1');
    constant C_CLIP_MIN_SIGNED : signed(G_DATA_WIDTH - 1 downto 0) := (G_DATA_WIDTH - 1 => '1', others => '0');
    --------------------
    -- Types
    --------------------
    type t_array_slv is array (natural range<>) of std_logic_vector;
    type t_array_of_array_slv is array (natural range<>) of t_array_slv;
    --------------------
    -- Functions
    --------------------
    -- The following code either initializes the memory values to a specified file or to all zeros to match hardware
    impure function init_ram_from_file return t_array_slv is
        file v_read_file : text open read_mode is G_INIT_FILE;
        variable v_line  : line;
        variable v_slv   : std_logic_vector(G_COEFF_WIDTH - 1 downto 0);
        variable v_ram   : t_array_slv(0 to (G_NUM_TAPS/2) - 1)(G_COEFF_WIDTH - 1 downto 0);
        variable v_idx   : natural := 0;
    begin
        v_idx := 0;
        for i in 0 to (G_NUM_TAPS/2) - 1 loop
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
    signal coefficient_memory   : t_array_slv(0 to (G_NUM_TAPS/2) - 1)(G_COEFF_WIDTH - 1 downto 0)                           := init_ram_from_file;
    signal r_delay_line         : t_array_slv(0 to G_NUM_TAPS - 1)(G_DATA_WIDTH + G_COEFF_WIDTH + C_BIT_GROWTH - 1 downto 0) := (others => (others => '0'));
    signal r_dlyline_valid      : std_logic                                                                                  := '0';
    signal r_dlyline_shifted    : signed(G_DATA_WIDTH + (G_COEFF_WIDTH - G_COEFF_FRAC_WIDTH) + C_BIT_GROWTH - 1 downto 0)    := (others => '0');
    signal r_valid_post_proc    : std_logic                                                                                  := '0';
    signal r_acc_clip           : std_logic_vector(G_DATA_WIDTH - 1 downto 0)                                                := (others => '0');
    signal r_valid_post_proc_d1 : std_logic                                                                                  := '0';
begin
    -- ================================================================
    -- Combinatorial
    o_data  <= r_acc_clip;
    o_valid <= r_valid_post_proc_d1;
    -- ================================================================
    p_mac_and_delay_line_upper : process (clk)
        variable v_result : signed(G_DATA_WIDTH + G_COEFF_WIDTH - 1 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            -- Note: this implements a Transposed Folded filter
            if (i_valid = '1') then
                ------------------
                -- MAC & Delay Line
                ------------------
                for tap in 0 to (G_NUM_TAPS/2) - 1 loop
                    -- Multiply
                    v_result := signed(coefficient_memory(tap)) * signed(i_data);
                    -- Accumulate delay line
                    if (tap = 0) then
                        r_delay_line(tap)               <= std_logic_vector(resize(v_result, r_delay_line(0)'length));
                        r_delay_line(r_delay_line'high) <= std_logic_vector(resize(signed(r_delay_line(r_delay_line'high - 1)) + v_result, r_delay_line(0)'length));
                    else
                        r_delay_line(tap)                     <= std_logic_vector(resize(signed(r_delay_line(tap - 1)) + v_result, r_delay_line(0)'length));
                        r_delay_line(r_delay_line'high - tap) <= std_logic_vector(resize(signed(r_delay_line(r_delay_line'high - tap - 1)) + v_result, r_delay_line(0)'length));
                    end if;
                end loop;
            end if;
            r_dlyline_valid <= i_valid;
        end if;
    end process p_mac_and_delay_line_upper;
    -- ================================================================
    p_saturate_and_ovf : process (clk)
    begin
        if rising_edge(clk) then
            ------------------
            -- PIPE 0
            -- Scale
            ------------------
            r_dlyline_shifted <= resize(shift_right(signed(r_delay_line(r_delay_line'high)), G_COEFF_FRAC_WIDTH), r_dlyline_shifted'length);
            r_valid_post_proc <= r_dlyline_valid;
            ------------------
            -- PIPE 1
            -- Clip
            ------------------
            if (r_dlyline_shifted > C_CLIP_MAX_SIGNED) then
                r_acc_clip <= std_logic_vector(C_CLIP_MAX_SIGNED);
            elsif (r_dlyline_shifted < C_CLIP_MIN_SIGNED) then
                r_acc_clip <= std_logic_vector(C_CLIP_MIN_SIGNED);
            else
                r_acc_clip <= std_logic_vector(resize(r_dlyline_shifted, r_acc_clip'length));
            end if;
            r_valid_post_proc_d1 <= r_valid_post_proc;
        end if;
    end process p_saturate_and_ovf;
    -- ================================================================
end architecture;