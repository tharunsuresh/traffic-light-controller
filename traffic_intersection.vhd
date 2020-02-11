----------------------------------------------------------------------------------
-- Company: University of Alberta
-- Engineer: Tharun Suresh	
-- 
-- Create Date: 05/11/2019 11:22:20 AM

----------------------------------------------------------------------------------
-- East/West and North/South intersection working. btn(0) used to see status of lights on respective direction of travel.
-- Red light camera on each direction of travel.
-- Night time quick green if red on direction of travel (e.g. North/South or East/West) and no vehicles on other direction of travel (e.g. North/South or East/West) 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_intersection is
    Port ( 
            clk:    in STD_LOGIC;
            btn :   in STD_LOGIC_VECTOR(3 DOWNTO 0);    -- btn(0) press to see traffic light status for North/South or East/West lights.
                                                        -- btn(3) press to emulate vehicle passing from North/South direction, btn(2) for East/West.
            sw:     in STD_LOGIC_VECTOR(3 DOWNTO 0);
            
            led6_r : out STD_LOGIC;     --Traffic light status as Red
            led6_g : out STD_LOGIC;     --Traffic light status as Green
            led6_b : out STD_LOGIC;     --Traffic light status as Yello=>Blue on board
            
            led: out STD_LOGIC_VECTOR(1 downto 0);        --Monitor states [ led(0), led(1) ] 
            red_led: out STD_LOGIC_VECTOR (1 downto 0):="00";    -- Red Light Camera [red_led(0), red_led(1) ];
            CC :        out STD_LOGIC;                     --Common cathode input to select respective 7-segment digit.
            out_7seg :  out STD_LOGIC_VECTOR (6 downto 0);  -- Output  signal for selected 7 Segment display. 
            
            Row: in STD_LOGIC_VECTOR(3 DOWNTO 0); --keypad input row
            Col : out STD_LOGIC_VECTOR (3 downto 0);
            DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0)

           );
end traffic_intersection;

architecture Behavioral of traffic_intersection is
component Clock_OneHz is
    port (  clk: in STD_LOGIC;
            clk_1Hz: out STD_LOGIC
          );
end component;

signal clk_1Hz: std_logic;
signal count, Count_OneSecDelay_MSD, Count_OneSecDelay_LSD, digit_7seg_display, count_7seg : natural;
signal Count_OneSecDelay: natural:=9;       
signal states_mon: std_logic_vector(1 downto 0):="00";


TYPE STATES IS (S0,S1,S2,S3,S4,S5,S6);
signal state: STATES:=S0;

signal NTSwitch: std_logic:='0';
signal VehiclesPresence: std_logic_vector(1 downto 0);
signal red_light_camera: std_logic_vector(1 downto 0):="00";
signal Count_RedLight: natural:=0;
signal blinking:STD_LOGIC:='0';
signal clk_out: std_logic:='0';
signal select_segment, clk_7seg_cc:std_logic:='0';
signal MAXCOUNTDOWN: natural:=9;

signal sclk :STD_LOGIC_VECTOR(19 downto 0);

begin    
    Decoder_4to7Segment: process (clk)
    begin

        case digit_7seg_display is
            when 0 =>  
                          out_7seg<="0111111";          --digit 0 display on segment #1 when CC='0' on segment #2 when CC='1'
            when 1 =>  
                          out_7seg<="0110000";          --digit 1 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 2 =>  
                          out_7seg<="1011011";          --digit 2 display on segment #1  when CC='0' on segment #2 when CC='1'          
            when 3 =>  
                          out_7seg<="1111001";          --digit 3 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 4 =>  
                          out_7seg<="1110100";          --digit 4 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 5 =>  
                          out_7seg<="1101101";          --digit 5 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 6 =>  
                          out_7seg<="1101111";          --digit 6 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 7 =>  
                          out_7seg<="0111000";          --digit 7 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 8 =>  
                          out_7seg<="1111111";          --digit 8 display on segment #1  when CC='0' on segment #2 when CC='1'
            when 9 =>  
                          out_7seg<="1111101";          --digit 9 display on segment #1  when CC='0' on segment #2 when CC='1'
            when others =>
                          out_7seg<="0111111"; 
        end case;
    end process;


    --Instatitiate components
    clock_1Hz: process(clk)
    begin
        if rising_edge(clk) then
            if(count<125000000) then       
                count<=count+1;
            else
                count<=0;
                clk_out<=not clk_out;
                clk_1Hz<=clk_out;
            end if;

            if (count_7seg<10000) then
                count_7seg<=count_7seg+1;
            else
                select_segment<=not select_segment;
                count_7seg<=0;
            end if;
        end if;
    end process;

    Select_7Segment: process (clk,clk_1Hz,select_segment)
    begin
        if select_segment='1' then
            digit_7seg_display<= Count_OneSecDelay;           
        else
            case state is 
                when S0 => digit_7seg_display<= 0;
                when S1 => digit_7seg_display<= 1;
                when S2 => digit_7seg_display<= 2;
                when S3 => digit_7seg_display<= 3;
                when others => digit_7seg_display<= 9;
            end case;
        end if;

        CC<=select_segment;

    end process;
      
   NightLight: process(clk) 
   begin
 
 --design lines here to capture vehicles presence and Night Time input (LDR).
-- update VehiclesPresence(0)
        if sw(0)='1' then
            VehiclesPresence(0)<='1';
        else 
            VehiclesPresence(0)<='0';
        end if;
        
--  update VehiclesPresence(1)
        if sw(1)='1' then
            VehiclesPresence(1)<='1';
        else 
            VehiclesPresence(1)<='0';
        end if;
        
--  update NTSwitch
        if sw(3)='1' then
            NTSwitch<='1';
        else 
            NTSwitch<='0';
        end if;
        
   end process NightLight;   
--End of design lines.
   
   LEDDisplay: process(clk)
   begin
        case state is 
            when S0 =>
                if btn(0)='0' then              --Since only have one RGB light, else no need. btn(0)='0' => East/West  btn(0)='1'=> North/South
                    led6_r<='0';
                    led6_b<='0';
                    led6_g<='1';
                else
                    led6_r<='1';
                    led6_b<='0';
                    led6_g<='0';
                end if;
                states_mon<="00";
            when S1 =>
                if btn(0)='0' then         --Since only have one RGB light, else no need. btn(0)='0' => East/West  btn(0)='1'=> North/South
                    led6_r<='0';
                    led6_b<='1';
                    led6_g<='0';
                else
                    led6_r<='1';
                    led6_b<='0';
                    led6_g<='0';
                end if;
                states_mon<="01";
            when S2 =>
                if btn(0)='0' then         --Since only have one RGB light, else no need. btn(0)='0' => East/West  btn(0)='1'=> North/South
                    led6_r<='1';
                    led6_b<='0';
                    led6_g<='0';
                else
                    led6_r<='0';
                    led6_b<='0';
                    led6_g<='1';
                end if;
                states_mon<="10";
            when S3 => 
                if btn(0)='0' then            --Since only have one RGB light, else no need. btn(0)='0' => East/West  btn(0)='1'=> North/South
                    led6_r<='1';
                    led6_b<='0';
                    led6_g<='0';
                else
                    led6_r<='0';
                    led6_b<='1';
                    led6_g<='0';
                end if;                                
                states_mon<="11";
            when others =>
                led6_r<='1';
                led6_b<='1';
                led6_g<='1';
        end case;    
   end process LEDDisplay; 
  
   TrafficIntersection: process (clk_1Hz)
   begin
        if btn(1)='1' then
            state<=S0;  --reset situation. state<=S0, countdown<=20 and LEDs light up. 
        end if;

        if rising_edge(clk_1Hz) then 
            Count_OneSecDelay<=Count_OneSecDelay-1;     --Increment one second count. ~1.84 sec delay here        
    
            case state is
                when S0 =>                              --East/West direction light green
                        if Count_OneSecDelay>0 then
                            state<=S0;
                        else
                            state<=S1;                      
                            Count_OneSecDelay<=2;
                        end if;
                        
                        if NTSwitch='1' and VehiclesPresence="10" then
                            state<=S1;
                            Count_OneSecDelay<=2;
                        end if;
                when S1 =>                             --East/West direction light yellow=>blue on board                    
                        if Count_OneSecDelay>0 then
                            state<=S1;
                        else
                            state<=S2;
                            Count_OneSecDelay<=MAXCOUNTDOWN;
                        end if;
                when S2 =>                              -- East/West direction light red and North/South direction green.
                        if Count_OneSecDelay>0 then
                            state<=S2;
                        else
                            state<=S3;
                            Count_OneSecDelay<=2;
                        end if;
                   
                        if NTSwitch='1' and VehiclesPresence="01" then
                            state<=S3;
                            Count_OneSecDelay<=2;
                        end if;
                when S3 =>
                        if Count_OneSecDelay>0 then
                            state<=S3;
                        else
                            state<=S0;
                            Count_OneSecDelay<=MAXCOUNTDOWN;
                        end if;
                when others =>                      --Error condition
                        state<=S0;
                        Count_OneSecDelay<=MAXCOUNTDOWN;
            end case;
        end if;
    end process;

    -- process for Red Light Camera feature at the intersection.

    redlightcam: process (clk) is
    begin
        case state is
            when S0 =>   --N/S direction light red
                red_led(0) <= '0';
                if btn(3) = '1' then 
                    red_led(1) <= '1';
                else 
                    red_led(1) <= '0';
                end if;
            when S1 =>  --N/S direction light red
                red_led(0) <= '0';
                if btn(3) = '1' then 
                    red_led(1) <= '1';
                else 
                    red_led(1) <= '0';
                end if;
            when S2 => --E/W direction light red
                red_led(1) <= '0';
                if btn(2) = '1' then 
                    red_led(0) <= '1';
                else 
                    red_led(0) <= '0';
                end if;
            when S3 => --E/W direction light red
                red_led(1) <= '0';
                if btn(2) = '1' then 
                    red_led(0) <= '1';
                else 
                    red_led(0) <= '0';    
                end if;
            when others => 
                red_led <= "00";
        end case;
    end process redlightcam; 
    
    -- End of redlightcam

    led<=states_mon;

    Decoder_process: process(clk) is
    begin 
    if clk'event and clk = '1' then
        -- 1ms
        if sclk = "00011000011010100000" then 
            --C1
            Col<= "0111";
            sclk <= sclk+1;
        -- check row pins
        elsif sclk = "00011000011010101000" then	
            --R1
            if Row = "0111" then
                DecodeOut <= "0001";	--1
            --R2
            elsif Row = "1011" then
                DecodeOut <= "0100"; --4
            --R3
            elsif Row = "1101" then
                DecodeOut <= "0111"; --7
            --R4
            elsif Row = "1110" then
                DecodeOut <= "0000"; --0
            end if;
            sclk <= sclk+1;
        -- 2ms
        elsif sclk = "00110000110101000000" then	
            --C2
            Col<= "1011";
            sclk <= sclk+1;
        -- check row pins
        elsif sclk = "00110000110101001000" then	
            --R1
            if Row = "0111" then		
                DecodeOut <= "0010"; --2
            --R2
            elsif Row = "1011" then
                DecodeOut <= "0101"; --5
            --R3
            elsif Row = "1101" then
                DecodeOut <= "1000"; --8
            --R4
            elsif Row = "1110" then
                DecodeOut <= "1111"; --F
            end if;
            sclk <= sclk+1;	
        --3ms
        elsif sclk = "01001001001111100000" then 
            --C3
            Col<= "1101";
            sclk <= sclk+1;
        -- check row pins
        elsif sclk = "01001001001111101000" then 
            --R1
            if Row = "0111" then
                DecodeOut <= "0011"; --3	
            --R2
            elsif Row = "1011" then
                DecodeOut <= "0110"; --6
            --R3
            elsif Row = "1101" then
                DecodeOut <= "1001"; --9
            --R4
            elsif Row = "1110" then
                DecodeOut <= "1110"; --E
            end if;
            sclk <= sclk+1;
        --4ms
        elsif sclk = "01100001101010000000" then 			
            --C4
            Col<= "1110";
            sclk <= sclk+1;
        -- check row pins
        elsif sclk = "01100001101010001000" then 
            --R1
            if Row = "0111" then
                DecodeOut <= "1010"; --A
            --R2
            elsif Row = "1011" then
                DecodeOut <= "1011"; --B
            --R3
            elsif Row = "1101" then
                DecodeOut <= "1100"; --C
            --R4
            elsif Row = "1110" then
                DecodeOut <= "1101"; --D
            end if;
            sclk <= "00000000000000000000";	
        else
            sclk <= sclk+1;	
        end if;
    end if;
    end process Decoder_process;

        
end Behavioral;
