script "com.hyperxtalk.library.test"
/*
A minimal test library for verifying the hxtpm package manager pipeline.
Install via: hxtpmInstall "com.hyperxtalk.library.test"
*/

on extensionInitialize
   if the target is not me then
      pass extensionInitialize
   end if
   insert the script of me into back
end extensionInitialize

on extensionFinalize
   if the target is not me then
      pass extensionFinalize
   end if
   remove the script of me from back
end extensionFinalize

/**

Title: hxtpm Test Library

Author: HyperXTalk

Type: library

Version: 1.0.0

Description:
Minimal test library for verifying the hxtpm package manager install pipeline.

*/

/**

Summary: Confirm the test library is loaded and return a status string.

Returns:
A string confirming the library version and that it is live in the message path.

Example:
   answer hxtpmTestPing()

*/
function hxtpmTestPing
   return "hxtpm test library v1.0.0 is loaded and working."
end hxtpmTestPing
