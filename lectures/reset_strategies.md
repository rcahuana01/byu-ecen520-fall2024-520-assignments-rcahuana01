
# Reset Strategies


Like clocking, reset signals are a global signal that go to many flip-flops.
The timing of resets is as important as clocking and must be considered as part of the timing closure process.
This lecture will review reset strategies and their timing implications.

## Reading

   * [Cummings SNUG 2002](https://github.com/byu-cpe/ECEN_620/blob/main/docs/reference/cummingssnug2002sj_resets.pdf)
   * [Cummings SNUG 2003](https://github.com/byu-cpe/ECEN_620/blob/main/docs/reference/cummingssnug2003boston_resets.pdf)

## Key Concepts

  * Purpose of a reset signal. 
  * Use of resets in FPGAs
  * RTL implications of resets (not mixing asynchronous/synchronous, proper reset RTL coding)
  * Synchronous vs asynchronous resets (pros and cons of each)
  * Timing implications of reset strategies

