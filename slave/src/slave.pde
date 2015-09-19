#include <Wire.h>
#include  "Sonar.h"
const int ledPin = 13;

Sonar Sonar1(1,"UART1");
char buffer1[70];
int i1;

enum PINGMODES {INTERVAL, REQUEST} PingMode=INTERVAL;


void setup() {
  Wire.begin(8);                // join i2c bus with address #8
  Wire.onRequest(requestEvent); // register event
  pinMode(ledPin, OUTPUT);

  Serial.begin(115200);  
  Serial1.begin(4800);

  SetBaudRate(&Sonar1, &Serial1);
  //SetManualPing(&Sonar1, &Serial1);
  EnableIntervalPinging(&Sonar1, &Serial1);
}

void loop() {
  ReadPort(&Sonar1, &Serial1);
  blinkLED();
}

void ReadPort(Sonar *s, HardwareSerial *hws)
{
  while (hws->available())
    {
      // Add byte to buffer
      if (i1 >= sizeof(buffer1) - 1)
  	{
  	  i1 = 0;
  	  break;
  	}
      buffer1[i1] = hws->read();
      buffer1[++i1] = '\0';

      // If last read byte is newline, decode the buffer
      if (buffer1[i1-1] == '\n')
  	{
	  i1 = 0;
  	  Serial.print(buffer1);
	  
  	  if (int n_good = s->decode_buffer(buffer1))
  	    {
  	      Serial.print("Depth: "); Serial.println(s->dbt);
  	      Serial.print("Temp: "); Serial.println(s->sea_water_temperature);
  	    }
  	}
    }
}

void EnableIntervalPinging(Sonar *s, HardwareSerial *hws)
{
  hws->print(s->enable_interval_pinging);
}

void EnableSentenceDPT(Sonar *s, HardwareSerial *hws)
{
  hws->flush();
  hws->print(s->disable_all_sentences);
  hws->flush();
  hws->print(s->enable_sentence_dpt);
}

void EnableManualPing(Sonar *s, HardwareSerial *hws)
{
  hws->print(s->enable_sentence_at_ping);
  hws->flush();
  hws->print(s->disable_interval_pinging);
  hws->flush();
}

void SetBaudRate(Sonar *s, HardwareSerial *hws)
{
  hws->flush();
  hws->print(s->set_baudrate_38400);
  hws->end();
  hws->begin(38400);
}

// function that executes whenever data is requested by master
// this function is registered as an event, see setup()
void requestEvent() {
  Wire.write("hello "); // respond with message of 6 bytes
  // as expected by master
}

void blinkLED()
{
  static unsigned long last_change = 0;
  static bool onoff;
  
  if (millis() - last_change > 500)
    {
      digitalWrite(ledPin, onoff ? HIGH : LOW);
      onoff = !onoff;
      last_change = millis();
    }
}