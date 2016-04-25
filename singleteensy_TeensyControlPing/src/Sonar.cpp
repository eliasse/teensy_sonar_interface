#include "Sonar.h"
//#include <Arduino.h>

Sonar::Sonar(int id, char *name) 
{
  ID = id; 
  strcpy(NAME,name);
}

int Sonar::decode_buffer(char in_buffer[])
{
  char buf[100];
  int  k = 0, l = 0, cs, n_found = 0;

  while (in_buffer[k] != '\0'){

    // Find starting character
    while (in_buffer[k++] != '$'){
      if (in_buffer[k] == '\0')
	return n_found;
    };

    // Add chars until end character is found
    do {
      buf[l++] = in_buffer[k];
    } while ((in_buffer[++k] != '*') && (buf[l-1] != '\0'));

     buf[l] = '\0';

    // Verify sentence
    char crc[3];
    crc[0] = in_buffer[++k];
    crc[1] = in_buffer[++k];
    crc[2] = '\0';
    
    cs = checksum(buf);

    char cs_string[3];
    sprintf(cs_string,"%02X",cs);
    
    l = 0;

    
    // Decode sentence if checksums matches
    if (!strcmp(crc,cs_string)) {
      // Count comma's 
      // Count double-occurrances and determine empty spots
      uint8_t i = 0;
      uint8_t n_fields = 0; // Number of commas found (thus the number of elements)
      bool is_empty[20];
      
      while (buf[i] != '\0'){
	if ((buf[i] == ',') || (buf[i] == '*')) {
	  n_fields++;
	  is_empty[n_fields] = false; // Just to make sure the bool is initialized
	  
	  if (buf[i-1] == ',') { 
	    is_empty[n_fields] = true;
	  }
	}
	i++;
      }
      n_fields++;

      char *tok;
      
      if (strstr(buf,"SDDPT"))
	{
	  // Copy the sentence into a pretty string with sonar name
	  strcpy(last_dpt,buf);
	  tok = strtok(buf,",*");
	  decode_DPT(n_fields, is_empty);
	  n_found++;
	  depth_updated = true;
	}
      else if (strstr(buf,"SDDPT"))
	{
	  strcpy(last_mtw,buf);
	  tok = strtok(buf,",*");
	  decode_MTW(n_fields, is_empty);
	  n_found++;
	  temperature_updated = true;
	}
      
      // Returns to the beginning of the while loop to check remaining buffer
    }
  }

  return n_found; // Probably unnecessary 
}

void Sonar::decode_DPT(uint8_t n_fields, bool is_empty[])
{
  char * tmp;
  
  for (uint8_t element = 2; element <= n_fields; element++)
    {
      //if (is_empty[element] == true) { continue; }
      
      switch (element)
	{
	default:
	  break;
	case 2:
          if (is_empty[element]) {
            dbt = -2;
            break;
          }
	  tmp = strtok(NULL,",*");
	  dbt = atof(tmp);
	  break;
	  
	case 3:
          if (is_empty[element]) {
            offset = -2;
            break;
          }
	  tmp = strtok(NULL,",*");
	  offset = atof(tmp);
	  break;
	
      	case 4:
          if (is_empty[element]) {
            max_range_scale = -2;
            break;
          }
	  tmp = strtok(NULL,",*");
	  if (!tmp) break;
	  max_range_scale = atof(tmp);
	  break;
	
	}
    }
}

void Sonar::decode_MTW(uint8_t n_fields, bool is_empty[])
{
  char * tmp;
  
  for (uint8_t element = 2; element <= n_fields; element++)
    {
      if (is_empty[element] == true) { continue; }
      
      switch (element)
	{
	default:
	  // Required if some elements are skipped
	  char * dump;
	  dump = strtok(NULL,",*");
	  (void)dump; 
	  break;

	case 2:
	  tmp = strtok(NULL,",*");
	  if (!tmp) break;
	  sea_water_temperature = atof(tmp);
	  break;
	}
    }
}

int Sonar::checksum(char * s) {
  int c = 0;
 
  while(*s)
        c ^= *s++;
 
  return c;
}

