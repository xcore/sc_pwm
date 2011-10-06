/**
 * Function that executes up to 16 pwm channels on one-bit ports. To use
 * this function, another thread needs to supply switch-times and initial
 * values over the channel. First a word shall be out ontot hte channel
 * that contains the initial pwm values (bit 0 of the word is the initial
 * value for element 0 of the array). Then the initial time at which the
 * first value is driven should be output on the channel end. Then, in a
 * single master transaction, a value should be read over the channel
 * (indicating that the pwm thread is ready for more values), N time values
 * should be output, and one extra time value which indicates the end of
 * the PWM cycle; for compatibility with other interfaces.
 *
 * \param c        chanend over which to control the pwm channels
 * \param pwmPorts array with one-bit ports.
 * \param N        number of pwm channels.
 */
void pwmSingle(chanend c, port pwmPorts[], int N);
