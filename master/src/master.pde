#include <Wire.h>
#include "Sonar.h"
#include <HardwareSerial.h>

#define TWI_ADDR 11
#define SLAVE_ADDR 12
#define ledPin 13

char *TeensyName = "MASTER";

Sonar Sonar1(1,"SONAR1");
char buffer1[70];
char pretty_dpt1[50];
int i1;

Sonar Sonar2(2,"SONAR2");
char buffer2[70];
char pretty_dpt2[50];
int i2;

char pretty_dpt3[50], pretty_dpt4[50]; // Received from slave
char wireBuffer[100]; int buffer_ptr = 0;

HardwareSerial *XBee;

void setup() {
  Wire.begin();        // join i2c bus (address optional for master)
		      
  Serial.begin(115200);    
  Serial1.begin(57600); // XBee

  XBee = &Serial1;

  Serial2.begin(4800);
  Serial3.begin(4800);

  // Change sonar baudrate to 38400
  SetBaudRate(&Sonar1, &Serial2);
  SetBaudRate(&Sonar2, &Serial3);

  delay(500);
  
  EnableSentenceDPT(&Sonar1, &Serial2);
  EnableSentenceDPT(&Sonar2, &Serial3);

  pinMode(ledPin,OUTPUT);
}

void loop() {
  static unsigned long xbee_timer = 0;
  static unsigned long request_timer = 0;

  if (millis() - request_timer > 1000)
    {
      SendRequest();
      request_timer = millis();
    }

  
  // Send data on XBee regardless of its updated or not
  if (millis() - xbee_timer > 1000) {
    xbee_timer = millis();
    XBee->print(pretty_dpt1);
    XBee->print(pretty_dpt2);
    Serial.print(pretty_dpt1);
    Serial.print(pretty_dpt2);
  }
  
  // If theres new sonar data, send it to the DUE
  if (Sonar1.depth_updated) {
    Sonar1.depth_updated = false;
    strcpy(pretty_dpt1,"$");
    strcat(pretty_dpt1,Sonar1.NAME);
    strcat(pretty_dpt1,",");
    strcat(pretty_dpt1,Sonar1.last_dpt);
    strcat(pretty_dpt1,"*00\r\n");

    Wire.beginTransmission(10);
    Wire.write(pretty_dpt1);
    Wire.endTransmission();
  }
  if (Sonar2.depth_updated) {
    Sonar2.depth_updated = false;
    strcpy(pretty_dpt2,"$");
    strcat(pretty_dpt2,Sonar2.NAME);
    strcat(pretty_dpt2,",");
    strcat(pretty_dpt2,Sonar2.last_dpt);
    strcat(pretty_dpt2,"*00\r\n");

    Wire.beginTransmission(10);
    Wire.write(pretty_dpt2);
    Wire.endTransmission();
  }  
  
  ReadPort(&Sonar1, &Serial2, buffer1, &i1);
  ReadPort(&Sonar2, &Serial3, buffer2, &i2);
  blinkLED();
  delay(10);
}

void SendRequest()
{
  // Request data from slave
  // Request Sonar3 data
  Wire.requestFrom(SLAVE_ADDR,50);

  while (Wire.available())
    {
      if (int b = Wire.read())
	wireBuffer[buffer_ptr++] = (char)b;
    }
  buffer_ptr = 0;

  Serial.print(wireBuffer);
  XBee->print(wireBuffer);
  // Is it Sonar3 or Sonar4 data?
  char *tok;
  tok = strtok(wireBuffer,"$ ,*");
  
}

void ReadPort(Sonar *s, HardwareSerial *hws, char *buffer, int *i)
{
  while (hws->available())
    {
      // Add byte to buffer
      if (*i >= sizeof(buffer) - 1)
  	{
  	  *i = 0;
  	  break;
  	}
      buffer[*i] = hws->read();
      buffer[++*i] = '\0';

      // If last read byte is newline, decode the buffer
      if (buffer[*i-1] == '\n')
  	{
	  *i = 0;
  	  //Serial.print(buffer);
	  
  	  if (int n_good = s->decode_buffer(buffer))
  	    {
	      // Maybe something good?
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