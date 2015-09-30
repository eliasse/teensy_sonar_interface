#ifndef _Sonar_
#define _Sonar_

#include <Arduino.h>

class Sonar {
  public:
  int ID;
  char NAME[10];
  bool depth_updated       = true; // Variable to verify data is updated
  bool temperature_updated = true;
  
  float dbt;                    // Depth relative to transducer (SDDPT) [m]
  float offset;                 // Offset from transducer      (SDDPT)
  float max_range_scale;        // Maximum depth in current mode of operation
  float sea_water_temperature;  // Sea water temperature (SDMTW) [Celcius]

  char *last_dpt = "SDDPT,-1.0,-1.000,-1.0*79"; // Last received depth sentence
  char *last_mtw = "SDDPT,-1.0,-1.000,-1.0*79"; // Last received temperature sentence
  
  char *disable_all_sentences    = "$PAMTC,EN,ALL,0*1D\r\n";
  char *enable_sentence_dpt      = "$PAMTC,EN,DPT,1*1D\r\n"; // Yes the checksums are the same!
  char *enable_sentence_at_ping  = "$PAMTC,OPTION,SET,OUTPUTMC,PING*0B\r\n";
  char *disable_interval_pinging = "$PAMTC,OPTION,SET,PING,OFF*55\r\n";
  char *enable_interval_pinging  = "$PAMTC,OPTION,SET,PING,ON*1B\r\n";
  char *ping                     = "$PAMTC,OPTION,SET,PING,ONCE*1D\r\n";
  char *factory_reset            = "$PAMTC,ERST*77\r\n";
  char *set_baudrate_38400       = "$PAMTC,BAUD,38400*66\r\n";
  
  Sonar(int id, char *name);
  
  int decode_buffer(char *buf); // Returns the number of sentences found in buf
  void decode_DPT(uint8_t n_fields, bool is_empty[]);
  void decode_MTW(uint8_t n_fields, bool is_empty[]);
  int checksum(char *s);
};

#endif
