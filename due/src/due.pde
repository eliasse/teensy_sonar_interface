#include <Wire.h>

#define TWI_ADDR 10

void setup()
{
  Serial.begin(115200);
  Wire.begin();
}

void loop()
{
  Serial.println("Sending request");
  Wire.requestFrom(11,30);
  
  while (Wire.available()) { // slave may send less than requested
    char c = Wire.read(); // receive a byte as character
    Serial.print(c);         // print the character
  }

  delay(1000);
}