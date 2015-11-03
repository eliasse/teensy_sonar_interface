#include <Wire.h>

#define TWI_ADDR 10
bool new_data = false;
char buf[100];

void setup()
{
  Serial.begin(115200);
  Wire.begin(TWI_ADDR);
  Wire.setClock(1000000);
  Wire.onReceive(i2c_receiveEvent);
}

void loop()
{
  delay(100);
  if (new_data)
    {
      Serial.print("BUFFER: ");
      Serial.print(buf);
      new_data = false;
    }
}

void i2c_receiveEvent(int n_bytes)
{
  char *i = buf;
  
  while ( Wire.available() )
    {
      *(i++) = Wire.read();
    }
  *i = '\0';
  new_data = true;
}