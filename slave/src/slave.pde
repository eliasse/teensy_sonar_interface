#include <Wire.h>
#include  "Sonar.h"

#define TWI_ADDR 12
#define ledPin 13

char *TeensyName = "SLAVE";

Sonar Sonar3(3,"S3");
char buffer3[70];
char pretty_dpt3[50];
int i3;

Sonar Sonar4(4,"S4");
char buffer4[70];
char pretty_dpt4[50];
int i4;

enum PINGMODES {INTERVAL, REQUEST} PingMode=INTERVAL;
enum TO_SEND {SONAR3, SONAR4} send=SONAR3;


void setup() {
  delay(500); // Just to make sure Teensy's doesn't start at same time (unnecessary?)
  
  Wire.begin(TWI_ADDR);         
  Wire.onRequest(requestEvent);
  
  pinMode(ledPin, OUTPUT);

  Serial.begin(115200);  
  Serial2.begin(4800);
  Serial3.begin(4800);

  // Change sonar baudrate to 38400
  SetBaudRate(&Sonar3, &Serial2);
  SetBaudRate(&Sonar4, &Serial3);

  delay(500);
  
  EnableSentenceDPT(&Sonar3, &Serial2);
  EnableSentenceDPT(&Sonar4, &Serial3);
  //SetManualPing(&Sonar1, &Serial1);
  //EnableIntervalPinging(&Sonar3, &Serial3);
}

void loop() {
  ReadPort(&Sonar3, &Serial2, buffer3, &i3);
  ReadPort(&Sonar4, &Serial3, buffer4, &i4);
  
  if (Sonar3.depth_updated)
    {
      Sonar3.depth_updated = false;
      // Make pretty sentence
      strcpy(pretty_dpt3,"$");
      strcat(pretty_dpt3,Sonar3.NAME);
      strcat(pretty_dpt3,",");
      strcat(pretty_dpt3,Sonar3.last_dpt);
      strcat(pretty_dpt3,"*00\r\n");
    }

    if (Sonar4.depth_updated)
    {
      Sonar4.depth_updated = false;
      // Make pretty sentence
      strcpy(pretty_dpt4,"$");
      strcat(pretty_dpt4,Sonar4.NAME);
      strcat(pretty_dpt4,",");
      strcat(pretty_dpt4,Sonar4.last_dpt);
      strcat(pretty_dpt4,"*00\r");
    }
  
  blinkLED();
  delay(10);
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
  	  Serial.print(buffer);
	  
  	  if (int n_good = s->decode_buffer(buffer))
  	    {
	      // Do Something GOOOD
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

void requestEvent() {
  if (send == SONAR3) {
    Wire.write(pretty_dpt3);
    send = SONAR4;
    return;
  }
  if (send == SONAR4) {
    Wire.write(pretty_dpt4);
    send = SONAR3;
    return;
  }
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