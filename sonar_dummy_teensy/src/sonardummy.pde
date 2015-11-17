#include "Wire.h"

char *dummy1 = "$SDDPT,3.123,0.000,17.123*54\r\n";
char *dummy2 = "$SDDPT,,,*57\r\n";

long slump;

void setup()
{
  Serial.begin(115200);
  Serial1.begin(38400);
  Serial2.begin(38400);
  Serial3.begin(38400);
  Wire.begin();
  randomSeed(analogRead(A0));
}

void loop()
{
  delay(250);
  sendSonarI2C();
  //sendShortI2C();
}

void sendShortI2C()
{
  Wire.beginTransmission(10);
  Wire.write("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefgh\n");
  Wire.endTransmission();
}

void sendSonarI2C()
{
  unsigned long timer = 0;

  if (millis() - timer < 1000) return;
  else timer = millis();

  slump = random(20000);

  if (slump < 5000) {
    Serial1.print(dummy2);
    Serial2.print(dummy2);
    Serial3.print(dummy2);
  }
  else {
    String body = "SDDPT,";
    body += ftoString((float)slump/1000.0f, 3) + ",";
    body += ftoString(0.000f, 3) + ",";
    body += ftoString(17.123f, 3);
    
    int cs = checksum(body.c_str());
    char CS[3];
    sprintf(CS,"%02X",cs);
    
    body += String("*") + CS + String("\r\n");
    String out1 = "$S1," + body;
    String out2 = "$S2," + body;
    String out3 = "$S3," + body;

    Wire.beginTransmission(10);
    Wire.write(out1.c_str());
    Wire.endTransmission();

    delay(100);

    Wire.beginTransmission(10);
    Wire.write(out2.c_str());
    Wire.endTransmission();

    delay(100);

    Wire.beginTransmission(10);
    Wire.write(out3.c_str());
    Wire.endTransmission();

    Serial.println(out1);
  }
}

void sendSonar()
{
  unsigned long timer = 0;

  if (millis() - timer < 1000) return;
  else timer = millis();

  slump = random(20000);

  if (slump < 5000) {
    Serial1.print(dummy2);
    Serial2.print(dummy2);
    Serial3.print(dummy2);
  }
  else {
    String body = "SDDPT,";
    body += ftoString((float)slump/1000.0f, 3) + ",";
    body += ftoString(0.000f, 3) + ",";
    body += ftoString(17.123f, 3);
    
    int cs = checksum(body.c_str());
    char CS[3];
    sprintf(CS,"%02X",cs);
    
    body += String("*") + CS + String("\r\n");
    String out1 = "$S1" + body;
    String out2 = "$S2" + body;
    String out3 = "$S3" + body;
    Serial1.print(out1);
    Serial2.print(out2);
    Serial3.print(out3);
  }
}

int checksum(const char * s) {
  int c = 0;
 
  while(*s)
        c ^= *s++;
 
  return c;
}

String ftoString(double number, uint8_t digits)
{
  String fstr;
  char str_[20];

  if (isnan(number)) return fstr = "nan";
  if (isinf(number)) return fstr = "inf";
  if (number > 4294967040.0) return fstr = "ovf";
  if (number < -4294967040.0) return fstr = "ovf";

  if (number < 0.0)
    {
      fstr += "-";
      number = -number;
    }

  // Rounding so that (1.999, 2) becomes "2.00"
  double rounding = 0.5;
  for (uint8_t i = 0; i<digits; ++i)
    rounding /=10.0;

  number += rounding;

  // Integer part
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;

  itoa(int_part, str_, 10);
  fstr += str_;

  if (digits > 0) {
    fstr += ".";
  }

  while (digits-- > 0)
    {
      remainder *= 10.0;
      int toPrint = int(remainder);
      itoa(toPrint,str_,10);
      fstr += str_;
      remainder -= toPrint;
    }

  return fstr;  
}