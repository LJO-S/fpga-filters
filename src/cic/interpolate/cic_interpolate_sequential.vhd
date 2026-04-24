-------------------------------------------------------------------------------
-- Implements a Transposed Sequential CIC Interpolator
-- 
-- Pros:
--      > Sequential architecture avoids a wide output and a bunch of parallellism in the integrator stages
-- Cons:
--      > Ready goes low for L (interpolate factor) cycles while the machinery is processing the current input sample
-- 
-- 
-- Example:
-- 
-- x(n)---+----->(-)--|z|--> ... -->|INTERPOLATE|--->(+)--|z|--+--> ... --> y(m)
--        |       |                                   |        V 
--        +--|z|--+                                   +--------+ 
--     \________________/                          \_____________/
--       1 comb stage                             1 integrator stage
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- 
use std.textio.all;
-- 
use work.cic_interpolate_pkg.all;
-- 
entity cic_interpolate_sequential is
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
        o_ready : out std_logic;
        -- Output
        o_data  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        o_valid : out std_logic
    );
end entity cic_interpolate_sequential;

architecture rtl of cic_interpolate_sequential is
    type t_array_signed is array (natural range <>) of signed;
    signal r_ready_out            : std_logic                                                            := '1';
    signal r_ready_counter        : unsigned(integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => '0');
    signal w_fir_data_in          : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal w_fir_valid_in         : std_logic;
    signal r_integrator_sum_array : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_integrator_valid_slv : std_logic_vector(G_CIC_ORDER - 1 downto 0)                                                                                    := (others => '0');
    signal r_comb_delay_array     : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_comb_diff_array      : t_array_signed(0 to G_CIC_ORDER - 1)(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0) := (others => (others => '0'));
    signal r_comb_valid_slv       : std_logic_vector(G_CIC_ORDER - 1 downto 0)                                                                                    := (others => '0');
    signal r_interpolate_counter  : unsigned(integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0)                                                          := (others => '0');
    signal r_interpolate_data     : signed(G_DATA_WIDTH + G_CIC_ORDER * integer(ceil(log2(real(G_MULTIRATE_FACTOR)))) - 1 downto 0)                               := (others => '0');
    signal r_interpolate_valid    : std_logic                                                                                                                     := '0';
    signal r_norm_data            : signed(G_DATA_WIDTH - 1 downto 0)                                                                                             := (others => '0');
    signal r_norm_valid           : std_logic                                                                                                                     := '0';
    signal w_fir_comp_data_out    : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal w_fir_comp_valid_out   : std_logic;
begin
    -- ================================================================
    -- Combinatorial
    o_ready <= r_ready_out;
    o_data  <= std_logic_vector(r_norm_data);
    o_valid <= r_norm_valid;
    -- ================================================================
    -- Generate ready signal for output stage
    p_ready_out : process (clk)
    begin
        if rising_edge(clk) then
            -- Start machinery when valid input is received and ready is high
            if (i_valid = '1') and (r_ready_out = '1') then
                r_ready_out     <= '0';
                r_ready_counter <= r_ready_counter + 1;
            end if;
            -- Count clock cycles until ready can be re-asserted
            if (r_ready_out = '0') then
                r_ready_counter <= r_ready_counter + 1;
                if (r_ready_counter >= G_MULTIRATE_FACTOR - 2) then
                    r_ready_out     <= '1';
                    r_ready_counter <= (others => '0');
                end if;
            end if;
        end if;
    end process p_ready_out;
    -- ================================================================
    -- 1. FIR Compensation Filter 
    w_fir_data_in  <= i_data;
    w_fir_valid_in <= i_valid and r_ready_out;

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
            i_data  => w_fir_data_in,
            i_valid => w_fir_valid_in,
            o_data  => w_fir_comp_data_out,
            o_valid => w_fir_comp_valid_out
        );
    -- ================================================================
    -- 2. Comb stages
    p_comb : process (clk)
    begin
        if rising_edge(clk) then
            if (w_fir_comp_valid_out = '1') then
                -- Valid
                r_comb_valid_slv <= r_comb_valid_slv(r_comb_valid_slv'high - 1 downto 0) & '1';
                -- Comb
                r_comb_delay_array(0) <= resize(signed(w_fir_comp_data_out), r_comb_delay_array(0)'length);
                r_comb_diff_array(0)  <= resize(signed(w_fir_comp_data_out), r_comb_diff_array(0)'length) - r_comb_delay_array(0);
                for i in 1 to G_CIC_ORDER - 1 loop
                    r_comb_delay_array(i) <= r_comb_diff_array(i - 1);
                    r_comb_diff_array(i)  <= r_comb_diff_array(i - 1) - r_comb_delay_array(i);
                end loop;
            end if;
        end if;
    end process p_comb;
    -- ================================================================
    -- 2. Interpolate
    p_interpolate : process (clk)
    begin
        if rising_edge(clk) then
            -- Interpolate 
            if (r_interpolate_valid = '1') then
                r_interpolate_data    <= (others => '0');
                r_interpolate_counter <= r_interpolate_counter + 1;
                if (r_interpolate_counter >= G_MULTIRATE_FACTOR - 1) then
                    r_interpolate_valid   <= '0';
                    r_interpolate_counter <= (others => '0');
                end if;
            end if;
            -- Latch output data
            if (w_fir_comp_valid_out = '1') and (r_comb_valid_slv(r_comb_valid_slv'high) = '1') then
                r_interpolate_valid   <= '1';
                r_interpolate_data    <= r_comb_diff_array(r_comb_diff_array'high);
                r_interpolate_counter <= (others => '0');
            end if;
        end if;
    end process p_interpolate;
    -- ================================================================
    -- 3. Integrator stages
    p_integrator : process (clk)
    begin
        if rising_edge(clk) then
            if (r_interpolate_valid = '1') then
                r_integrator_valid_slv    <= r_integrator_valid_slv(r_integrator_valid_slv'high - 1 downto 0) & '1';
                r_integrator_sum_array(0) <= r_integrator_sum_array(0) + r_interpolate_data;
                for i in 1 to G_CIC_ORDER - 1 loop
                    r_integrator_sum_array(i) <= r_integrator_sum_array(i) + r_integrator_sum_array(i - 1);
                end loop;
            end if;
        end if;
    end process p_integrator;
    -- ================================================================
    -- 4. Normalize 
    -- Note: The division (D^Q)/R is performed as a right-shift by K bits, where K = (Q-1) * log2(D) and Q is the number of stages and D is the decimation factor
    -- ... That assumes that R = D, which is often the case for CIC filters. If R != D, then the division by R can be implemented as a multiplication by 1/R, which can be implemented as a fixed-point multiplication by a pre-computed coefficient.
    p_normalize : process (clk)
    begin
        if rising_edge(clk) then
            r_norm_data <= resize(
                shift_right(r_integrator_sum_array(r_integrator_sum_array'high), (G_CIC_ORDER - 1) * integer(ceil(log2(real(G_MULTIRATE_FACTOR))))),
                r_norm_data'length
                );
            r_norm_valid <= r_comb_valid_slv(r_comb_valid_slv'high) and (r_interpolate_valid and r_integrator_valid_slv(r_integrator_valid_slv'high));
        end if;
    end process p_normalize;
    -- ================================================================
end architecture;