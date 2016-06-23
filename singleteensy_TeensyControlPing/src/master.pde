#include <Wire.h>
//#include <i2c_t3.h>
#include "Sonar.h"
#include <array>

#if defined BUFFER_LENGTH && BUFFER_LENGTH < 64
#error "I2C Buffer is too small! Increase the size in Wire.h to at least 64."
#endif

#define ARDUINO_DUE_ADDR 10
#define TWI_ADDR 11
#define SLAVE_ADDR 12
#define ledPin 13

char *TeensyName = "MASTER";

bool I2C_DUE_OK = false;
bool I2C_SLAVE_OK = false;

Sonar Sonar1(1,"S1");
char buffer1[70];
char pretty_dpt1[50];
int i1 = 0;

Sonar Sonar2(2,"S2");
char buffer2[70];
char pretty_dpt2[50];
int i2 = 0;

Sonar Sonar3(3,"S3");
char buffer3[70];
char pretty_dpt3[50];
int i3 = 0;

char wireBuffer[100]; int buffer_ptr = 0;

// Controls what sonar to ping next
enum {S1 = 0, S2 = 1, S3 = 2};
int ping[3] = {S1, S2, S3};   // The order of these determines the order of pinging
int stp = 0;
bool do_ping = true;
unsigned long ping_ms     = 0;
unsigned long response_ms = 0;

void setup() {
  Wire.begin();//I2C_MASTER,0,I2C_PINS_18_19,I2C_PULLUP_EXT,I2C_RATE_1000);

  Serial.begin(115200);
  Serial1.begin(38400);
  Serial2.begin(38400);
  Serial3.begin(38400);

  delay(10000); // Wait for sonars to wake up

  // Disable interval pinging and set sentence to be output on ping
  EnableManualPing(&Sonar1, &Serial1);
  EnableManualPing(&Sonar2, &Serial2);
  EnableManualPing(&Sonar3, &Serial3);

  // Clean serial ports
  CleansePort(&Serial1);
  CleansePort(&Serial2);
  CleansePort(&Serial3);

  // Verify sonar configuration

  // Setup the debug LED
  pinMode(ledPin,OUTPUT);
}

void loop() {
  static unsigned long xbee_timer = 0;
  static unsigned long request_timer = 0;
  static unsigned long shit_timer = 0;
  static unsigned long t1 = 0, t2 = 0, t3 = 0;

  if (Serial1.available()) ReadUART1();
  if (Serial2.available()) ReadUART2();
  if (Serial3.available()) ReadUART3();

  // Send a ping
  if (do_ping)
    {
      // Determine what sonar to ping
      stp = ++stp % (sizeof(ping)/4);
      // Ping the sonar
      switch ( stp )
	{
	default:
	  Serial.println("Trying to ping non-existing sonar...");
	  break;
	case S1:
	  Serial1.print(Sonar1.ping);
	  break;
	case S2:
	  Serial2.print(Sonar2.ping);
	  break;
	case S3:
	  Serial3.print(Sonar3.ping);
	  break;
	}
      // Don't ping next until response is received
      do_ping = false;
      ping_ms = millis();
    }

  // Don't wait for a response forever...
  if (millis() - response_ms >= 300)
    {
      do_ping = true;
    }

  // If theres new sonar data, send it to the DUE
  if (Sonar1.depth_updated) {
    Sonar1.depth_updated = false;
    strcpy(pretty_dpt1,"$");
    strcat(pretty_dpt1,Sonar1.NAME);
    strcat(pretty_dpt1,",");
    strcat(pretty_dpt1,Sonar1.last_dpt);
    strcat(pretty_dpt1,"*00\r\n\0");

    if (millis() - t1 > 0) {
      Wire.beginTransmission(ARDUINO_DUE_ADDR);
      Wire.write(pretty_dpt1);
      Wire.endTransmission();
      t1 = millis();
    }
    Serial.print(pretty_dpt1);

    do_ping = true;
    response_ms = millis();
  }

  delay(100);

  if (Sonar2.depth_updated) {
    Sonar2.depth_updated = false;
    strcpy(pretty_dpt2,"$");
    strcat(pretty_dpt2,Sonar2.NAME);
    strcat(pretty_dpt2,",");
    strcat(pretty_dpt2,Sonar2.last_dpt);
    strcat(pretty_dpt2,"*00\r\n\0");

    if (millis() - t2 > 0) {
      Wire.beginTransmission(ARDUINO_DUE_ADDR);
      Wire.write(pretty_dpt2);
      Wire.endTransmission();
      t2 = millis();
    }
    Serial.print(pretty_dpt2);

    do_ping = true;
    response_ms = millis();
  }

  delay(100);

  if (Sonar3.depth_updated) {
    Sonar3.depth_updated = false;
    strcpy(pretty_dpt3,"$");
    strcat(pretty_dpt3,Sonar3.NAME);
    strcat(pretty_dpt3,",");
    strcat(pretty_dpt3,Sonar3.last_dpt);
    strcat(pretty_dpt3,"*00\r\n\0");

    if (millis() - t3 > 0) {
      Wire.beginTransmission(ARDUINO_DUE_ADDR);
      Wire.write(pretty_dpt3);
      Wire.endTransmission();
      t3 = millis();
    }
    Serial.print(pretty_dpt3);

    do_ping = true;
    response_ms = millis();
  }

  delay(100);

  //CheckI2C();
  blinkLED();
}

void CleansePort(HardwareSerial *hws)
{
  while (hws->available())
    int b = hws->read();
}

/* void CheckI2C() */
/* { */
/*   unsigned long timer = 0; */

/*   if (millis() - timer > 2000) { */
/*     timer = millis(); */
/*     if (!I2C_DUE_OK)   TestDueCommunication(); */
/*     if (!I2C_SLAVE_OK) TestSlaveCommunication(); */
/*   } */
/* } */

/* void TestDueCommunication() */
/* { */
/*   Wire.beginTransmission(ARDUINO_DUE_ADDR); */
/*   Wire.endTransmission(); */
/*   if (Wire.status() == I2C_WAITING) I2C_DUE_OK = true; */
/*   else I2C_DUE_OK = false; */
/* } */

/* void TestSlaveCommunication() */
/* { */
/*   Wire.beginTransmission(SLAVE_ADDR); */
/*   Wire.endTransmission(); */
/*   if (Wire.status() == I2C_WAITING) I2C_SLAVE_OK = true; */
/*   else I2C_SLAVE_OK = false; */
/* } */

void ReadUART1()
{
  while (Serial1.available())
    {
      int b = Serial1.read();
      if (b>0)
	{
	  buffer1[i1] = (char)b;
	  buffer1[i1+1] = '\0';
	  i1++;
	}
      else return;

      if ((buffer1[i1-1] == '\n') || (i1 >= sizeof(buffer1) - 1))
	{
	  i1 = 0;

	  Sonar1.decode_buffer(buffer1);
	  Serial.print(buffer1);

	  buffer1[0] = '\0';
	  return;
	}
    }
}

void ReadUART2()
{
  while (Serial2.available())
    {
      int b = Serial2.read();
      if (b>0)
	{
	  buffer2[i2] = (char)b;
	  buffer2[i2+1] = '\0';
	  i2++;
	}
      else return;

      if ((buffer2[i2-1] == '\n') || (i2 >= sizeof(buffer2) - 1))
	{
	  i2 = 0;

	  Sonar2.decode_buffer(buffer2);
	  Serial.print(buffer2);

	  buffer2[0] = '\0';
	  return;
	}
    }
}

void ReadUART3()
{
  while (Serial3.available())
    {
      int b = Serial3.read();
      if (b>0)
	{
	  buffer3[i3] = (char)b;
	  buffer3[i3+1] = '\0';
	  i3++;
	}
      else return;

      if ((buffer3[i3-1] == '\n') || (i3 >= sizeof(buffer3) - 1))
	{
	  i3 = 0;

	  Sonar3.decode_buffer(buffer3);
	  Serial.print(buffer1);

	  buffer3[0] = '\0';
	  return;
	}
    }
}

// Read sonar data from serial port
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
