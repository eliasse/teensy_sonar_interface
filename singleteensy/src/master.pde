#include <i2c_t3.h>
#include "Sonar.h"
#include <HardwareSerial.h>

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

char pretty_dpt3[50], pretty_dpt4[50]; // Received from slave
bool dpt3_updated = false, dpt4_updated = false;
char wireBuffer[100]; int buffer_ptr = 0;

HardwareSerial *XBee;

void setup() {
  Wire.begin(I2C_MASTER,0,I2C_PINS_18_19,I2C_PULLUP_EXT,I2C_RATE_1000);
		      
  Serial.begin(115200);    
  Serial1.begin(19200); // XBee

  XBee = &Serial1;

  Serial2.begin(38400);
  Serial3.begin(38400);

  delay(5000);

  // Try to get response from DUE
  Wire.beginTransmission(ARDUINO_DUE_ADDR);
  Wire.endTransmission();
  if (Wire.status() == I2C_WAITING) I2C_DUE_OK = true;

  // Try to get response from slave
  Wire.beginTransmission(SLAVE_ADDR);
  Wire.endTransmission();
  if (Wire.status() == I2C_WAITING) I2C_SLAVE_OK = true;

  
  // Change sonar baudrate to 38400
  /* SetBaudRate(&Sonar1, &Serial2); */
  /* SetBaudRate(&Sonar2, &Serial3); */

  delay(500);
  
  //EnableSentenceDPT(&Sonar1, &Serial2);
  //EnableSentenceDPT(&Sonar2, &Serial3);

  pinMode(ledPin,OUTPUT);
}

void loop() {
  static unsigned long xbee_timer = 0;
  static unsigned long request_timer = 0;
  static unsigned long shit_timer = 0;

  /* if (millis() - shit_timer > 1000) */
  /* { */
  /*   shit_timer = millis(); */
  /*   Wire.beginTransmission(ARDUINO_DUE_ADDR); */
  /*   Wire.write(wireBuffer); */
  /*   Wire.endTransmission(); */
  /* } */

  // Request data from slave teensy
  if (millis() - request_timer > 100)
    {
      if (I2C_SLAVE_OK) {
	SendRequest();
	request_timer = millis();
      }
    }
  
  // If theres new sonar data, send it to the DUE
  if (Sonar1.depth_updated) {
    Sonar1.depth_updated = false;
    strcpy(pretty_dpt1,"$");
    strcat(pretty_dpt1,Sonar1.NAME);
    strcat(pretty_dpt1,",");
    strcat(pretty_dpt1,Sonar1.last_dpt);
    strcat(pretty_dpt1,"*00\r\n\0");

    if (I2C_DUE_OK) {
      Wire.beginTransmission(ARDUINO_DUE_ADDR);
      Wire.write(pretty_dpt1);
      Wire.endTransmission();
    }

    XBee->print(pretty_dpt1);
    Serial.write(pretty_dpt1); Serial.flush();
  }
  if (Sonar2.depth_updated) {
    Sonar2.depth_updated = false;
    strcpy(pretty_dpt2,"$");
    strcat(pretty_dpt2,Sonar2.NAME);
    strcat(pretty_dpt2,",");
    strcat(pretty_dpt2,Sonar2.last_dpt);
    strcat(pretty_dpt2,"*00\r\n\0");

    if (I2C_DUE_OK) {
      Wire.beginTransmission(ARDUINO_DUE_ADDR);
      Wire.write(pretty_dpt2);
      Wire.endTransmission();
    }

    XBee->print(pretty_dpt2);
    Serial.write(pretty_dpt2); Serial.flush();
  }
  if (dpt3_updated)
    {
      if (I2C_DUE_OK) {
	Wire.beginTransmission(ARDUINO_DUE_ADDR);
	Wire.write(pretty_dpt3);
	Wire.endTransmission();
      }
      Serial.print(pretty_dpt3);
      XBee->print(pretty_dpt3);
      dpt3_updated=false;
    }
  if (dpt4_updated)
    {
      if (I2C_DUE_OK) {
	Wire.beginTransmission(ARDUINO_DUE_ADDR);
	Wire.write(pretty_dpt4);
	Wire.endTransmission();
      }
      Serial.print(pretty_dpt4);
      XBee->print(pretty_dpt4);
      dpt4_updated=false;
    }

  CheckI2C();
 
  ReadUART2();
  delay(10);
  ReadUART3();

  blinkLED();
  //delay(10);
}

void CheckI2C()
{
  unsigned long timer = 0;

  if (millis() - timer > 2000) {
    timer = millis();
    if (!I2C_DUE_OK)   TestDueCommunication();
    if (!I2C_SLAVE_OK) TestSlaveCommunication();
  }
}

void TestDueCommunication()
{
  Wire.beginTransmission(ARDUINO_DUE_ADDR);
  Wire.endTransmission();
  if (Wire.status() == I2C_WAITING) I2C_DUE_OK = true;
  else I2C_DUE_OK = false;
}

void TestSlaveCommunication()
{
  Wire.beginTransmission(SLAVE_ADDR);
  Wire.endTransmission();
  if (Wire.status() == I2C_WAITING) I2C_SLAVE_OK = true;
  else I2C_SLAVE_OK = false;
}

void SendRequest()
{
  // Request data from slave
  // Request Sonar3 data
  Wire.requestFrom(SLAVE_ADDR,50);

  while (Wire.available())
    {
      if (int b = Wire.read()) {
	wireBuffer[buffer_ptr++] = (char)b;
	if ((char)b == '\n')
	  {
	    wireBuffer[buffer_ptr] = '\0';
	    break;
	  }
      }
    }
  buffer_ptr = 0;

  //Serial.print(wireBuffer);
  //XBee->print(wireBuffer);

  //  Is it Sonar3 or Sonar4 data?
  if (strncmp(wireBuffer,"$S3", 3) == 0)
    {
      strcpy(pretty_dpt3,wireBuffer);
      dpt3_updated = true;
    }
  else if (strncmp(wireBuffer,"$S4", 3) == 0)
    {
      strcpy(pretty_dpt4,wireBuffer);
      dpt4_updated = true;
    }

  wireBuffer[0] = '\0';
}

void ReadUART2()
{
  while (Serial2.available())
    {
      int b = Serial2.read();
      if (b>0)
	{
	  buffer1[i1] = (char)b;
	  buffer1[i1+1] = '\0';
	  i1++;
	}
      else return;
    }
      
  if ((buffer1[i1] == '\n') || (i1 >= sizeof(buffer1) - 1))
    {
      i1 = 0;
      Sonar1.decode_buffer(buffer1);
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
	  buffer2[i2] = (char)b;
	  buffer2[i2+1] = '\0';
	  i2++;
	}
      else return;
    }
  
  if ((buffer2[i2] == '\n') || (i2 >= sizeof(buffer2) - 1))
    {
      i2 = 0;
      Sonar2.decode_buffer(buffer2);
      return;
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