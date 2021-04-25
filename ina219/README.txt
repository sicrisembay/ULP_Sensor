Based from:
https://stackoverflow.com/questions/39713799/adafruit-ina219-module-shunt-voltage-values-and-calibration


VBUS_MAX = 16V
VSHUNT_MAX = 0.32    (Assumes Gain 8, 320mV)
RSHUNT = 0.1         (Resistor value in ohms)

1. Determine max possible current
   MaxPossible_I = VSHUNT_MAX / RSHUNT
   MaxPossible_I = 0.32 / 0.1 = 3.2A

2. Determine max expected current
   MaxExpected_I = 3.2A

3. Calculate possible range of LSBs (Min = 15-bit, Max = 12-bit)
   MinimumLSB = MaxExpected_I/32767
   MinimumLSB = 3.2A / 32767 = 0.0000977 (97.7uA per bit)
   MaximumLSB = MaxExpected_I/4096
   MaximumLSB = 3.2A / 4096 = 0.000781 (781uA per bit)

4. Choose an LSB between the min and max values
   (Preferrably a roundish number close to MinLSB)
   CurrentLSB = 0.00043 (430uA per bit)

5. Compute the calibration register
   Cal = trunc (0.04096 / (Current_LSB * RSHUNT))
   Cal = trunc (0.04096 / (0.00043 * 0.1)) = 953 (0x03B9)

6. Calculate the power LSB
   PowerLSB = 20 * CurrentLSB
   PowerLSB = 20 * 0.000430 = 0.0086 (8.6mW per bit)

7. Compute the maximum current and shunt voltage values before overflow
   Max_Current = Current_LSB * 32767
   Max_Current = 14.0898A before overflow

// If Max_Current > Max_Possible_I then
//    Max_Current_Before_Overflow = MaxPossible_I
// Else
//    Max_Current_Before_Overflow = Max_Current
// End If
//
// Max_Current_Before_Overflow = MaxPossible_I
// Max_Current_Before_Overflow = 3.2A
//
// Max_ShuntVoltage = Max_Current_Before_Overflow * RSHUNT
// Max_ShuntVoltage = 0.32V
//
// If Max_ShuntVoltage >= VSHUNT_MAX
//    Max_ShuntVoltage_Before_Overflow = VSHUNT_MAX
// Else
//    Max_ShuntVoltage_Before_Overflow = Max_ShuntVoltage
// End If
//
// Max_ShuntVoltage_Before_Overflow = VSHUNT_MAX
// Max_ShuntVoltage_Before_Overflow = 0.32V

// 8. Compute the Maximum Power
// MaximumPower = Max_Current_Before_Overflow * VBUS_MAX
// MaximumPower = 3.2 * 16V
// MaximumPower = 51.2W

// Set multipliers to convert raw current/power values
ina219_currentDivider_mA = 2.326;  // Current LSB = 430uA per bit (1000/430 = 2.326)
ina219_powerDivider_mW = 8.6;     // Power LSB = 8.6mW per bit
