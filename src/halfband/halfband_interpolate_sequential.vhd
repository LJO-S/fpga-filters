-------------------------------------------------------------------------------
-- Implements a Sequential Transposed Halfband Interpolator
-- 
-- Pros:
--      > Sequential structure handles the x2 output sample from each stage accordingly
-- Cons:
--      > Unused silicon when moving onto next sub-stage
-- 
-- 
-- Example: Interpolate-by-8
--       ____       ______       ____       ______       ____       ______ 
--      |    |     | Img  |     |    |     | Img  |     |    |     | Img  |
--      | ^2 |---->|Reject|---->| ^2 |---->|Reject|---->| ^2 |---->|Reject|
--      |____|     |______|     |____|     |______|     |____|     |______|
--      \_________________/
--           1 substage
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
entity halfband_interpolate_sequential is
    generic (
        G_DATA_WIDTH       : natural := 16;
        G_COEFF_WIDTH      : natural := 16;
        G_FILTER_ORDER     : natural := 16;
        G_MULTIRATE_FACTOR : natural := 4;
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
end entity halfband_interpolate_sequential;

architecture rtl of halfband_interpolate_sequential is
    --------------------
    -- Constants
    --------------------
    constant C_NUM_STAGES : natural := integer(ceil(log2(real(G_MULTIRATE_FACTOR))));
    --------------------
    -- Signals
    --------------------
    signal r_stage_data  : t_array_slv(0 to C_NUM_STAGES)(G_DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
    signal r_stage_valid : std_logic_vector(C_NUM_STAGES downto 0)                   := (others => '0');
    signal r_ready_out   : std_logic                                                 := '0';
begin
    -- ================================================================
    -- Combinatorial
    o_data           <= r_stage_data(r_stage_data'high);
    o_valid          <= r_stage_valid(r_stage_valid'high);
    o_ready          <= r_ready_out;
    r_stage_data(0)  <= i_data;
    r_stage_valid(0) <= i_valid and (r_ready_out or r_stage_valid(r_stage_valid'high));
    -- ================================================================
    process (clk)
    begin
        if rising_edge(clk) then
            if (i_valid = '1') then
                r_ready_out <= '0';
            end if;
            if (r_stage_valid(r_stage_valid'high) = '1') then
                r_ready_out <= '1';
            end if;
        end if;
    end process;
    -- ================================================================
    g_generate_interpolate_stage : for i in 0 to C_NUM_STAGES - 1 generate
        signal w_stage_data_out     : t_array_slv(0 to 1)(G_DATA_WIDTH - 1 downto 0);
        signal w_stage_data_out_slv : std_logic_vector(2 * G_DATA_WIDTH - 1 downto 0);
        signal w_stage_valid_out    : std_logic;
        signal w_fifo_empty         : std_logic;
        signal w_fifo_rd_data       : std_logic_vector(2 * G_DATA_WIDTH - 1 downto 0);
        signal r_sel                : std_logic := '0';
    begin
        ---------------------------------------------------
        halfband_interpolate_stage_inst : entity work.halfband_interpolate_stage
            generic map(
                G_DATA_WIDTH   => G_DATA_WIDTH,
                G_COEFF_WIDTH  => G_COEFF_WIDTH,
                G_FILTER_ORDER => G_FILTER_ORDER,
                G_INIT_FILE    => integer'image(i) & "_" & G_INIT_FILE
            )
            port map
            (
                clk     => clk,
                i_data  => r_stage_data(i),
                i_valid => r_stage_valid(i),
                o_data  => w_stage_data_out,
                o_valid => w_stage_valid_out
            );
        ---------------------------------------------------
        w_stage_data_out_slv <= w_stage_data_out(1) & w_stage_data_out(0);
        ---------------------------------------------------
        sync_standard_fifo_inst : entity work.sync_standard_fifo
            generic map(
                G_DATA_WIDTH => 2 * G_DATA_WIDTH,
                G_DATA_DEPTH => (2 ** i) - 1
            )
            port map
            (
                clk       => clk,
                rst_sync  => '0',
                i_wr_en   => w_stage_valid_out,
                i_wr_data => w_stage_data_out_slv,
                o_full    => open, -- Size guarantees that this should never occur
                i_rd_en   => r_sel,
                o_rd_data => w_fifo_rd_data,
                o_empty   => w_fifo_empty
            );
        ---------------------------------------------------
        -- Bridge data between stages
        p_bridge_data : process (clk)
        begin
            if rising_edge(clk) then
                r_stage_data(i + 1)  <= (others => '0');
                r_stage_valid(i + 1) <= '0';
                -- Drain FIFO
                if (w_fifo_empty = '0') then
                    r_sel                <= not(r_sel);
                    r_stage_valid(i + 1) <= '1';
                    if (r_sel = '0') then
                        r_stage_data(i + 1) <= w_fifo_rd_data(G_DATA_WIDTH - 1 downto 0);
                    else
                        r_stage_data(i + 1) <= w_fifo_rd_data(2 * G_DATA_WIDTH - 1 downto G_DATA_WIDTH);
                    end if;
                end if;
            end if;
        end process p_bridge_data;
        ---------------------------------------------------
    end generate;
    -- ================================================================
end architecture;