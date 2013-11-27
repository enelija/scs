/* ************************************************
    SoundCave simulator by enelija
      
      to use with the pd patch ICSpatialSoundCave
      
      cu stands for cave user
      su stands for sound user
      
      the drawing coordinate system is mapped to  
      the sound coordinate system [-1.0, 1.0] in
      each dimension, the center is at [0.0, 0.0]
   ************************************************ */
// import libraries
import oscP5.*;
import netP5.*;
import controlP5.*;
   
// sets debug on / off
final boolean DEBUG = true;

// sounds, set numbers as used in the PD patch
// numbers have to be in consecutive ascending order
final int POSITION = 0;
final int VELOCITY = 1;
final int BUMP = 2;
final int TOUCH = 3;
final int HIT = 4;
final int NUMBER_INTERACTIONS = 5;
float [] volumes = {1.0, 1.0, 1.0, 1.0, 1.0};
SpatialSoundEvent soundEvents[] = new SpatialSoundEvent[NUMBER_INTERACTIONS];

// absolute width and height for the canvas
int w = 800, h = 800;

// normalized user representation dimension
float uDim = 0.075;
float uDimHalf = uDim / 2.0;

// background color, cave and sound user colors
color bgColor = color(0, 0, 0);
color cuColor = color(255, 0, 0);
color suColor = color(0, 255, 0);

// stroke weight for user representation
int sw = 2;

// normalized sound source, cave and sound user starting positions
float centerX = 0.0, centerY = 0.0;
float cuX = centerX, cuY = centerY, suX = 1.0, suY = 1.0;
float oCuX = centerX, oCuY = centerY;
float epsilon = 0.0000000001;
float cuDistFromCenter = 0.0, cuAngle = 0.0, normVelocity, hearbeat;
float maxVelocity = 2.0;
int minHeartbeat = 1, maxHeartbeat = 3;    // beats per second (* 60 = beats per minute 60/180)
int heartbeat = 0;

// variable for calculating the velocity
int oldTimeStamp = 0;
int lastHeartbeat = 0;

int lastInteraction = 0;
float interactDistance = 0.0, interactAngle = 0.0;

// interaction variables
boolean isCuDraggingActive = false, isSuDraggingActive = false;
boolean isNewOverlap = true;
boolean isTouch = false, isHit = false;

/* ----------------- Setup and main loop ----------------- */
void setup() {
  size(w, h);
  background(bgColor);
  rectMode(CENTER);
  noFill();
  strokeWeight(sw);
  textSize(12);
  
  oldTimeStamp = lastHeartbeat = millis();
  
  setupSounds();
  setupGUI();
  setupCommunication();
}

void draw() {  
  // update simulation drawings
  background(bgColor);
  drawUserPositions(cuColor, cuX, cuY);
  drawUserPositions(suColor, suX, suY);
  drawInstructions();
  drawDetails();
 
  // update old cave user positions and the old timestamp
  update();
}

void update() {
  // for cave user movement calculate the distance of the cave user from the center
  cuDistFromCenter = dist(centerX, centerY, cuX, cuY);
  cuAngle = 180.0 + atan2((centerY - cuY), (centerX - cuX)) * 180.0 / PI;
  
  reactOnCaveUserMovement();    
  reactOnCaveUserInteractions();
  
  oCuX = cuX;
  oCuY = cuY;
  oldTimeStamp = millis();
  isHit = false;
}

/* ----------------------- Functions ----------------------- */
void setupSounds() {
  soundEvents[POSITION] = new SpatialSoundEvent(0);
  soundEvents[POSITION].setIsLooped(true);
  soundEvents[VELOCITY] = new SpatialSoundEvent(1);
  soundEvents[BUMP]     = new SpatialSoundEvent(2);
  soundEvents[TOUCH]    = new SpatialSoundEvent(3);
  soundEvents[TOUCH].setIsLooped(true);
  soundEvents[HIT]      = new SpatialSoundEvent(4);
 
  // set volumes for all sounds
  for (int i = 0; i < NUMBER_INTERACTIONS; ++i)
    soundEvents[i].setVolume(volumes[i]);
}

// update cave user sound source position 
void reactOnCaveUserMovement() {
  if (updateCaveUserPosition()) 
    sendSoundDataAndEvent(POSITION, cuDistFromCenter, cuAngle);
    
  // send heartbeat more or less often, depending on the velocity of the cave user
  int now = millis();
  float diff = dist(oCuX, oCuY, cuX, cuY);
  float td = float(now - oldTimeStamp);
  float velocity = diff / td * 1000;
  
  // normlize veloctiy
  normVelocity = map(velocity, 0, maxVelocity, 0.0, 1.0);
  heartbeat = int(map(velocity, 0.0, maxVelocity, minHeartbeat, maxHeartbeat));
  
  // if enough time passed, send a new heartbeat sound event
  if (float(now - lastHeartbeat) > 1.0 / float(heartbeat) * 1000.0) {
    sendSoundDataAndEvent(VELOCITY, cuDistFromCenter, cuAngle);
    lastHeartbeat = now;
  } 
}

// react on cave user interactions bump, hit, touch
void reactOnCaveUserInteractions() {
  // react on BUMP
  if (isNewOverlap && isOverlap()) {
    lastInteraction = BUMP;
    sendSoundDataAndEvent(BUMP, cuDistFromCenter, cuAngle);
    isNewOverlap = false;
  } else if (!isOverlap())
    isNewOverlap = true;
 
  // react on HIT
  if (isHit) {
    // for hit calculate the distance of the hit position
    lastInteraction = HIT;
    interactDistance = dist(normalizeW(mouseX), normalizeH(mouseY), suX, suY);
    interactAngle = 180.0 + atan2((centerY - suY), (centerX - suX)) * 180.0 / PI;
    sendSoundDataAndEvent(HIT, interactDistance, interactAngle);
    
  // react on TOUCH
  } else if (isTouch) {
    lastInteraction = TOUCH;
    // for touch calculate the distance of the touch position
    interactDistance = dist(normalizeW(mouseX), normalizeH(mouseY), suX, suY);
    interactAngle = 180.0 + atan2((centerY - suY), (centerX - suX)) * 180.0 / PI;
    if (!soundEvents[TOUCH].isOn()) 
      soundEvents[TOUCH].setIsOn(true);
    sendSoundDataAndEvent(TOUCH, interactDistance, interactAngle);
  } else if (!isTouch && soundEvents[TOUCH].isOn()) {
    soundEvents[TOUCH].setIsOn(false);
    sendSoundEventOff(soundEvents[TOUCH]);
  }
}

// update the sound source data and send the event to the pd patch
void sendSoundDataAndEvent(int interaction, float distance, float angle) {
    // set distance and angle for spatial sound
    soundEvents[interaction].setDistance(distance);
    soundEvents[interaction].setAngle(angle);
    // send sound event, but only when the sound is turned on
    sendSoundEvent(soundEvents[interaction]);
}

boolean updateCaveUserPosition() {
  return (abs(oCuX - cuX) > epsilon && abs(oCuY - cuY) > epsilon);
}

boolean isOverlap() {
  return (dist(cuX, cuY, suX, suY) < uDim);
}

// returns true if the coordinate ix/iy is inside a rectangle with the center
// coordinate cx, cy, using the dimension uDim
boolean isInside(float cx, float cy, float ix, float iy) {
  return (ix > (cx - uDimHalf) && ix < (cx + uDimHalf) &&
          iy > (cy - uDimHalf) && iy < (cy + uDimHalf));
}

// normlize an x coordinate
float normalizeW(float x) {
  return map(x, 0, width, -1.0, 1.0);
}

// normlize a y coordinate
float normalizeH(float y) {
  return map(y, 0, height, -1.0, 1.0);
}

// normlize an x coordinate
float upscaleX(float x) {
  return map(x, -1.0, 1.0, 0, width);
}

// normlize a y coordinate
float upscaleY(float y) {
  return map(y, -1.0, 1.0, 0, height);
}

/* ---------------------- Drawing ---------------------- */
// maps sound system coordinates to processing coordinates
void drawUserPositions(color c, float x, float y) {
  stroke(c);
  noFill();
  rect(upscaleX(x), upscaleY(y), upscaleX(uDim - 1.0), upscaleY(uDim - 1.0));
  line(upscaleX(x), upscaleY(y), upscaleX(x + uDim * 0.75), upscaleY(y));
}

// uses processing coordinates
void drawInstructions() {
  fill(cuColor);
  text("CAVE user", 10, h - 50);
  fill(suColor);
  text("SOUND user", 10, h - 30);
  fill(255);
  text("LMB: drag users / RMB: touch sound user", 10, h - 10);
  noFill();
}

// uses processing coordinates
void drawDetails() {
  fill(255);
  String a = String.format("%.2f", cuDistFromCenter);
  String b = String.format("%.2f", cuAngle);
  text("Cave user distance / angle: \n  " + a + " / " + b, width - 220, 25);
  
  a = String.format("%.2f", normVelocity);
  text("Cave user velocity / heartbeat: \n  " + a + " / " + heartbeat * 60, width - 220, 70);
  
  String ia = String.format("%.2f", interactDistance);
  String ib = String.format("%.2f", interactAngle);
  String i = "NONE";
  if (lastInteraction == BUMP) {
    i = "BUMP";
    text("Cave user interaction: " + i + "\n  " + a + " / " + b, width - 220, 115);
  } else {
    if (lastInteraction == HIT)
      i = "HIT";
    else if (lastInteraction == TOUCH)
      i = "TOUCH";
    text("Cave user interaction: " + i + "\n  " + a + " / " + b, width - 220, 115);
  }  
  
  a = String.format("%.2f", cuX);
  b = String.format("%.2f", cuY);
  text("CAVE user:  [" + upscaleX(cuX) + ", " + upscaleY(cuY) + "]", width - 250, height - 80);
  text("                  [" + a + ", " + b + "]", width - 250, height - 60);
  a = String.format("%.2f", suX);
  b = String.format("%.2f", suY);
  text("SOUND user: [" + upscaleX(suX) + ", " + upscaleY(suY) + "]", width - 250, height - 30);
  text("                   [" + a + ", " + b + "]", width - 250, height - 10);
}

/* ---------------------- Interaction ---------------------- */
void mouseDragged() {
  if (isCuDraggingActive) {
      cuX = normalizeW(mouseX);
      cuY = normalizeH(mouseY);
  } else if (isSuDraggingActive) {
      suX = normalizeW(mouseX);
      suY = normalizeH(mouseY);
  }
}

void mousePressed() {
  if (mouseButton == RIGHT && isInside(normalizeW(mouseX), normalizeH(mouseY), suX, suY))
    isTouch = true;
 
  if (mouseButton == CENTER && isInside(normalizeW(mouseX), normalizeH(mouseY), suX, suY))
    isHit = true;
 
  // do not let the user move a rectangle into the button area
  if (mouseY < h) {
    if (isInside(normalizeW(mouseX), normalizeW(mouseY), suX, suY)) {
      isSuDraggingActive = true;
    } else if (isInside(normalizeW(mouseX), normalizeH(mouseY), cuX, cuY)) {
      isCuDraggingActive = true;
    }
  }
}

void mouseReleased() {
  if (isCuDraggingActive)
    isCuDraggingActive = false;
  else if (isSuDraggingActive)
    isSuDraggingActive = false;
  isTouch = false;
}

