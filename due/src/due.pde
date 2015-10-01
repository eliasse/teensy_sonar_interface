#include <Wire.h>

#define TWI_ADDR 10
bool new_data = false;

void setup()
{
  Serial.begin(115200);
  Wire.begin(TWI_ADDR);
  Wire.onReceive(i2c_receiveEvent);
}

void loop()
{
  delay(1000);
}

void i2c_receiveEvent(int n_bytes)
{
  char buf[100];
  char *i = buf;
  
  while ( Wire.available() )
    {
      *(i++) = Wire.read();
    }
  *i = '\0';
  new_data = true;

  Serial.println(buf);
}