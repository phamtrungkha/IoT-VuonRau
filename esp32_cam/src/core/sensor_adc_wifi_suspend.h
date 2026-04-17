#pragma once

/**
 * Non-blocking job: turn WiFi off, average ADC on `pin`, turn WiFi back on.
 * Call soilAdcWifiSuspendJobStart then soilAdcWifiSuspendJobPoll from loop until it returns true.
 */

void soilAdcWifiSuspendJobStart(int pin, int samples, unsigned int delayUs);

/** @return false while in progress; true when finished (`*outRaw` set, may be -1 on WiFi timeout). */
bool soilAdcWifiSuspendJobPoll(int *outRaw);

bool soilAdcWifiSuspendJobIsActive();
