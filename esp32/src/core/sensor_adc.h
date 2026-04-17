#pragma once

#include <Arduino.h>

/** Simple averaged ADC read to reduce noise (WiFi/EMI). */
inline int readAdcAvg(int pin, int samples, unsigned int delayUs) {
  if (samples <= 1) {
    return analogRead(pin);
  }
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    if (delayUs > 0) {
      delayMicroseconds(delayUs);
    }
  }
  return static_cast<int>(sum / samples);
}
