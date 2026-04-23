-------------------------------------------------------------------------------
-- Implements a CIC Decimator
-- 
-- Pros:
--      > Allows for full stream processing of input samples
-- Cons:
--      > 
-- 
-- Example:
--      
--  x(n)------>(+)---|z|---+-->-- ... -->|DECIMATE|-------+-------(-)---|z|---> ... --> y(m)
--              |          V                              |        | 
--              +----------+                              +--|z|---+  
--             \________________/                       \________________/
--             1 integrator stage                          1 comb stage
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- 
use std.textio.all;
-- 
use work.cic_decimate_pkg.all;
-- 
entity cic_decimate is
    generic (
        G_DATA_WIDTH       : natural := 16;
        G_CIC_ORDER        : natural := 4;
        G_MULTIRATE_FACTOR : natural := 32;
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
end entity cic_decimate;

architecture rtl of cic_decimate is
    type t_array_signed is array (natural range <>) of signed;
    signal r_integrator_sum_array : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_integrator_valid_slv : std_logic_vector(G_CIC_ORDER - 1 downto 0)                                                                                    := (others => '0');
    signal r_comb_delay_array     : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_comb_diff_array      : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_comb_valid_slv       : std_logic_vector(G_CIC_ORDER - 1 downto 0)                                                                                    := (others => '0');
    signal r_decimate_counter     : unsigned(integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0)                                                          := (others => '0');
    signal r_decimate_data        : signed(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0)                               := (others => '0');
    signal r_decimate_valid       : std_logic                                                                                                                     := '0';
    signal r_norm_data            : signed(G_DATA_WIDTH - 1 downto 0)                                                                                             := (others => '0');
    signal r_norm_valid           : std_logic                                                                                                                     := '0';
    signal w_fir_comp_data_out    : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal w_fir_comp_valid_out   : std_logic;
begin
    -- ================================================================
    -- Combinatorial
    o_data  <= w_fir_comp_data_out;
    o_valid <= w_fir_comp_valid_out;
    -- ================================================================
    -- 1. Integrator stages
    p_integrator : process (clk)
    begin
        if rising_edge(clk) then
            if (i_valid = '1') then
                r_integrator_valid_slv    <= r_integrator_valid_slv(r_integrator_valid_slv'high - 1 downto 0) & '1';
                r_integrator_sum_array(0) <= r_integrator_sum_array(0) + signed(i_data);
                for i in 1 to G_CIC_ORDER - 1 loop
                    r_integrator_sum_array(i) <= r_integrator_sum_array(i) + r_integrator_sum_array(i - 1);
                end loop;
            end if;
        end if;
    end process p_integrator;
    -- ================================================================
    -- 2. Decimate
    p_decimate : process (clk)
    begin
        if rising_edge(clk) then
            r_decimate_valid <= '0';
            if (i_valid = '1') and (r_integrator_valid_slv(r_integrator_valid_slv'high) = '1') then
                r_decimate_counter <= r_decimate_counter + 1;
                if (r_decimate_counter >= G_MULTIRATE_FACTOR - 1) then
                    r_decimate_counter <= (others => '0');
                    -- Output valid sample
                    r_decimate_data  <= r_integrator_sum_array(r_integrator_sum_array'high);
                    r_decimate_valid <= '1';
                end if;
            end if;
        end if;
    end process p_decimate;
    -- ================================================================
    -- 3. Comb stages
    p_comb : process (clk)
    begin
        if rising_edge(clk) then
            if (r_decimate_valid = '1') then
                -- Valid
                r_comb_valid_slv <= r_comb_valid_slv(r_comb_valid_slv'high - 1 downto 0) & '1';
                -- Comb
                r_comb_delay_array(0) <= r_decimate_data;
                r_comb_diff_array(0)  <= r_decimate_data - r_comb_delay_array(0);
                for i in 1 to G_CIC_ORDER - 1 loop
                    r_comb_delay_array(i) <= r_comb_diff_array(i - 1);
                    r_comb_diff_array(i)  <= r_comb_diff_array(i - 1) - r_comb_delay_array(i);
                end loop;
            end if;
        end if;
    end process p_comb;
    -- ================================================================
    -- 4. Normalize 
    -- Note: The division D^Q is performed as a right-shift by K bits, where K = Q * log2(D) and Q is the number of stages and D is the decimation factor
    p_normalize : process (clk)
    begin
        if rising_edge(clk) then
            r_norm_data <= resize(
                shift_right(r_comb_diff_array(r_comb_diff_array'high), G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR))))),
                r_norm_data'length
                );
            r_norm_valid <= r_comb_valid_slv(r_comb_valid_slv'high) and r_decimate_valid;
        end if;
    end process p_normalize;
    -- ================================================================
    -- 5. FIR Compensation Filter 
    fir_compensation_filter_inst : entity work.fir_compensation_filter
        generic map(
            G_DATA_WIDTH       => G_DATA_WIDTH,
            G_COEFF_WIDTH      => C_COEFF_WIDTH,
            G_COEFF_FRAC_WIDTH => C_COEFF_FRAC_WIDTH,
            G_NUM_TAPS         => C_NUM_TAPS,
            G_INIT_FILE        => G_INIT_FILE
        )
        port map
        (
            clk     => clk,
            i_data  => std_logic_vector(r_norm_data),
            i_valid => r_norm_valid,
            o_data  => w_fir_comp_data_out,
            o_valid => w_fir_comp_valid_out
        );
    -- ================================================================
end architecture;