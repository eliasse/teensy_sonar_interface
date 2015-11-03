#include <i2c_t3.h>
#include  "Sonar.h"

#define TWI_ADDR 12
#define ledPin 13

char *TeensyName = "SLAVE";

Sonar Sonar3(3,"S3");
char buffer3[70];
char pretty_dpt3[50];
int i3 = 0;

Sonar Sonar4(4,"S4");
char buffer4[70];
char pretty_dpt4[50];
int i4 = 0;

enum PINGMODES {INTERVAL, REQUEST} PingMode=INTERVAL;
enum TO_SEND {SONAR3, SONAR4} send=SONAR3;


void setup() {
  delay(500); // Just to make sure Teensy's doesn't start at same time (unnecessary?)
  
  Wire.begin(I2C_SLAVE,TWI_ADDR,I2C_PINS_18_19,I2C_PULLUP_EXT,I2C_RATE_1000);         
  Wire.onRequest(requestEvent);
  
  pinMode(ledPin, OUTPUT);

  Serial.begin(115200);  
  Serial2.begin(38400);
  Serial3.begin(38400);

  // Change sonar baudrate to 38400
  //SetBaudRate(&Sonar3, &Serial2);
  //SetBaudRate(&Sonar4, &Serial3);

  delay(5000);
  
  //EnableSentenceDPT(&Sonar3, &Serial2);
  //EnableSentenceDPT(&Sonar4, &Serial3);
  //SetManualPing(&Sonar1, &Serial1);
  //EnableIntervalPinging(&Sonar3, &Serial3);
}

void loop() {
  static unsigned long serial_port_timer = 0;

  /* if (millis() - serial_port_timer > 1000) { */
  /*   serial_port_timer = millis(); */
  /*   Serial.write(pretty_dpt3); Serial.flush(); */
  /*   Serial.write(pretty_dpt4); Serial.flush(); */
  /* } */
  
  ReadUART2(); // Sonar 3
  ReadUART3(); // Sonar 4
  
  /* if (Sonar3.depth_updated) */
  /*   { */
  /*     // Make pretty sentence */
  /*     strcpy(pretty_dpt3,"$"); */
  /*     strcat(pretty_dpt3,Sonar3.NAME); */
  /*     strcat(pretty_dpt3,","); */
  /*     strcat(pretty_dpt3,Sonar3.last_dpt); */
  /*     strcat(pretty_dpt3,"*00\r\n\0"); */
  /*     Serial.write(pretty_dpt3); Serial.flush(); */
  /*   } */

  /*   if (Sonar4.depth_updated) */
  /*   { */
  /*     // Make pretty sentence */
  /*     strcpy(pretty_dpt4,"$"); */
  /*     strcat(pretty_dpt4,Sonar4.NAME); */
  /*     strcat(pretty_dpt4,","); */
  /*     strcat(pretty_dpt4,Sonar4.last_dpt); */
  /*     strcat(pretty_dpt4,"*00\r\n\0"); */
  /*     Serial.write(pretty_dpt4); Serial.flush(); */
  /*   } */
  
  blinkLED();
  delay(10);
}

void ReadUART2()
{
  while (Serial2.available())
    {
      int b = Serial2.read();
      if (b>0)
	{
	  buffer3[i3] = (char)b;
	  buffer3[i3+1] = '\0';
	  i3++;
	}
      else return;
    }

  if ((buffer3[i3] == '\n') || (i3 >= sizeof(buffer3) - 1))
    {
      i3 = 0;
      Sonar3.decode_buffer(buffer3);
      return;
    }
}

void ReadUART3()
{
  while (Serial3.available())
    {
      int b = Serial3.read();
      if (b>0)
	{
	  buffer4[i4] = (char)b;
	  buffer4[i4+1] = '\0';
	  i4++;
	}
      else return;
    }
  
  if ((buffer4[i4] == '\n') || (i4 >= sizeof(buffer4) - 1))
    {
      i4 = 0;
      Sonar4.decode_buffer(buffer4);
      return;
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
  if ((send == SONAR3) && Sonar3.depth_updated) {
    // Make pretty sentence
    strcpy(pretty_dpt3,"$");
    strcat(pretty_dpt3,Sonar3.NAME);
    strcat(pretty_dpt3,",");
    strcat(pretty_dpt3,Sonar3.last_dpt);
    strcat(pretty_dpt3,"*00\r\n\0");
    Wire.write(pretty_dpt3);
    send = SONAR4;
    return;
  }
  else if ((send == SONAR4) && Sonar4.depth_updated) {
    // Make pretty sentence
    strcpy(pretty_dpt4,"$");
    strcat(pretty_dpt4,Sonar4.NAME);
    strcat(pretty_dpt4,",");
    strcat(pretty_dpt4,Sonar4.last_dpt);
    strcat(pretty_dpt4,"*00\r\n\0");
    Wire.write(pretty_dpt4);
    send = SONAR3;
    return;
  }
  else Wire.write("NSU");
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