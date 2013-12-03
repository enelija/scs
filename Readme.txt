Requirements:
=========================================================================================
- 4-channel audio system

- pd-extended

- Windows only because of the used Ambisonic driver


Installation:
=========================================================================================
- Download and install pd-extended

- Download and install Processing
 -- Go to 'Sketch' menu -> 'Import Library' -> 'Add library' and install the oscP5 and 
    the controlP5 library


Configuration:
=========================================================================================
- If necessary, change the port number for receiving OSC messages 
 (object at the top of the patch: "udpreceive <port>")

- If desired, exchange the sounds in the SpatialSoundCave directory (.wav)
 -- if the sounds have different names, change the main.pd patch accordingly:

- Description of the sounds:
 -- CAVE USER POSITION (looped):      requires sound file which loops seamlessly 
                                      played constantly, sound moves with the CAVE user 
									  position
 -- CAVE USER VELOCITY:               sound file which is retriggered in a hearbeat rate
                                      ([60,180] beats per minute) depending on the CAVE 
									  user velocity
 -- BUMP INTERACTION:                 sound file played when both user's position overlap
 -- TOUCH INTERACTION (looped):       requires sound file which loops seamlessly
                                      is triggered with a start event and ended with an 
									  end event in-between its played constanly while the
									  CAVE user touches the ROOM user softly
 -- HIT INTERACTION:                  played when the CAVE user touches the ROOM user 
                                      with a fast movement


Documentation:
=========================================================================================
The pd patch receives OSC UDP network messages with the URL /SonicCave/<n> with the 
number <n> which determines the sound file number (see object "routeOSC"):
 /0 - CAVE USER POSITION
 /1 - CAVE USER VELOCTIY
 /2 - BUMP INTERACTION
 /3 - TOUCH INTERACTION
 /4 - HIT INTERACTION
LinePanLooper is used for looped sounds, LinePanPlayer is used for sounds played once. 

The processing sketch is used as simulation tool for the CAVE and ROOM user's movements 
and the CAVE user's interactions. Depending on the action/movement/speed of movement the
according events are sent as OSC messages to the sound system (pd patch).  

The pd patch does not depend on the Processing sketch, it can receive OSC messages from 
any system.

- Run the main.pd patch
 -- press "enable DSP"
 -- the yellow sliders visualize the response for all four loudspeakers

- Run the Processing sketch
 -- turn on all sounds which should be heared (upper left corner)
 -- grab and move the CAVE user (red) and ROOM user (green) and experience the spatial 
    sound (related to the CAVE user)
 -- bump is triggered when the positions overlap
 -- hit is triggered with a middle mouse button click on the ROOM user
 -- touch is triggered with a right mouse button click on the ROOM user