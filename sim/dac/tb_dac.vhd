-- Author:
--   Unai Sainz-Estebanez
-- Email:
--  <unai.sainze@ehu.eus>
--
-- Licensed under the GNU General Public License v3.0;
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.gnu.org/licenses/gpl-3.0.html

library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_dac is
  generic (
    runner_cfg : string
  );
end entity;

architecture tb of tb_dac is

signal clk, rst_n: std_logic := '0';
signal din, sync_n, sclk: std_logic := '0';
signal wr_a, wr_b: std_logic := '0';
signal value_a, value_b : std_logic_vector(15 downto 0);

constant clk_period : time := 8 ns;

-- Logging

constant logger : logger_t := get_logger("tb_dac");
constant file_handler : log_handler_t := new_log_handler(
  output_path(runner_cfg) & "log.csv",
  format => csv,
  use_color => false
);

signal start, done_1, done_2: boolean := false;

constant data_items : natural := 2;
type data_t is array (0 to data_items-1) of std_logic_vector(15 downto 0);
constant data : data_t := (
x"f549",
(others => 'X')
);

begin

serial_dac856x_uut : entity work.serial_dac856x
                                               generic map (
                                                           g_sclk_div => 1
                                                           )
                                               port map (
                                                        clk_i => clk,
                                                        rst_n_i => rst_n,
                                                        value_a_i => value_a,
                                                        wr_a_i => wr_a,
                                                        value_b_i => value_b,
                                                        wr_b_i => wr_b,
                                                        sclk_o => sclk,
                                                        d_o => din,
                                                        sync_n_o => sync_n
                                                        );


clk <= not clk after clk_period/2;

main: process
begin
test_runner_setup(runner, runner_cfg);
while test_suite loop
  if run("test") then
    set_log_handlers(logger, (display_handler, file_handler));
    show_all(logger, file_handler);
    show_all(logger, display_handler);
    
    rst_n <= '0';
    wait for 1*clk_period;
    rst_n <= '1';  
    info(logger, "Init test");
    wait until rising_edge(clk);
    start <= true;
    wait until rising_edge(clk);
    start <= false;
    wait until (done_1 and done_2 and rising_edge(clk));
    info(logger, "Test done!");
  end if;
end loop;
test_runner_cleanup(runner);
wait;
end process;

write: process
  begin
    done_1 <= false;
    wait until start and rising_edge(clk);
    info(logger, "Writing started!");
    wr_a <= '0';
    wr_b <= '0';
    wait until rising_edge(clk);
    info(logger, "Write " & to_string(data(0)) & " (hex: " & to_hstring(data(0)) & ") to value_a");
    value_a <= data(0);
    wr_a <= '1';
    wait until rising_edge(clk);
    info(logger, "value_a: " & to_string(value_a) & " (hex: " & to_hstring(value_a) & ")");
    info(logger, "Write " & to_string(data(1)) & " (hex: " & to_hstring(data(1)) & ") to value_a");
    value_a <= data(1);
    wr_a <= '0';
    wait until rising_edge(clk);
    info(logger, "value_a: " & to_string(value_a) & " (hex: " & to_hstring(value_a) & ")");
    done_1 <= true;
    info(logger, "Writing done!");
    wait;
end process;

receive: process
    variable buf : std_logic_vector(23 downto 0);
    variable cnt : natural;
  begin
    done_2 <= false;
    wait until start and rising_edge(clk);
    wait until sync_n = '0';
    while sync_n = '0' loop
      wait until falling_edge(sclk);
      buf := buf(22 downto 0) & din;
      cnt := cnt + 1;
      if cnt = 24 then
        info(logger, "[" & to_string(cnt) & "] received: " & to_string(buf) & " " & to_hstring(buf));
        wait until rising_edge(clk);
        done_2 <= true;
      else
        info(logger, "[" & to_string(cnt) & "] received: " & to_string(buf) & " " & to_hstring(buf));
      end if;
    end loop;
    wait;
end process;

end architecture;
