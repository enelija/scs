/* ************************************************
    SoundCave simulator by enelija
      
      to use with the pd patch ICSpatialSoundCave
      
      cu stands for cave user
      su stands for sound user
   ************************************************ */

// import libraries
import oscP5.*;
import netP5.*;
import controlP5.*;
   
// sets debug on / off
final boolean DEBUG = true; 

// sounds, set numbers as used in the PD patch
// numbers have to be in consecutive ascending order
final int CALM = 0;
final int AGGRESSIVE = 1;
final int BUMP = 2;
final int TOUCH = 3;
final int HIT = 4;
final int NUMBER_INTERACTIONS = 5;
float [] volumes = {0.7, 0.75, 1.0, 1.0, 1.0};
SpatialSoundEvent soundEvents[] = new SpatialSoundEvent[NUMBER_INTERACTIONS];

// absolute width and height for the canvas
int w = 650;
int h = 650;

// normalized user representation dimension
float uDim = 0.05;
float uDimHalf = uDim / 2.0;

// background color, cave and sound user colors
color bgColor = color(0, 0, 0);
color cuColor = color(255, 0, 0);
color suColor = color(0, 255, 0);

// stroke weight for user representation
int sw = 2;

// normalized threshold: below is calm, greater or equal means aggressive
float movementThreshold = 0.5;

// normalized sound source, cave and sound user starting positions
float centerX = 0.5, centerY = 0.5;
float cuX = centerX, cuY = centerY, suX = 1.0 - uDimHalf, suY = 1.0 - uDimHalf;
float oCuX = centerX, oCuY = centerY;
float epsilon = 0.001;
float virtualRoomScale = 1.0;
float interactionBodyDistanceScale = 2.5;      // TODO: test with various upscalings

// variable for calculating the velocity
int oldTimeStamp = 0; 

// interaction variables
boolean isCuDraggingActive = false, isSuDraggingActive = false;
boolean isNewOverlap = true;
boolean isTouch = false, isHit = false;

// variables for text output on the screen
String cuMovementDetails = "Cave user movement: NONE\n";
String cuInteractionDetails = "Cave user interaction: NONE\n";


/* ----------------- Setup and main loop ----------------- */
void setup() {
  size(w, h);
  background(bgColor);
  rectMode(CENTER);
  noFill();
  strokeWeight(sw);
  textSize(12); 
    
  setupSounds();
  setupGUI();
  setupCommunication(); 
}

void draw() {  
  reactOnCaveUserMovement();    
  reactOnCaveUserInteractions();
  
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
  oCuX = cuX;
  oCuY = cuY;
  oldTimeStamp = millis();
  isHit = false;
  isTouch = false;
}


/* ----------------------- Functions ----------------------- */
void setupSounds() {
  soundEvents[CALM] = new SpatialSoundEvent(0);
  soundEvents[AGGRESSIVE] = new SpatialSoundEvent(1);
  soundEvents[BUMP] = new SpatialSoundEvent(2);
  soundEvents[TOUCH] = new SpatialSoundEvent(3);
  soundEvents[HIT] = new SpatialSoundEvent(4);
  
  // set volumes for all sounds
  for (int i = 0; i < NUMBER_INTERACTIONS; ++i)
    soundEvents[i].setVolume(volumes[i]);
}

// react on slow (calm) and fast (aggressive) cave user movement
void reactOnCaveUserMovement() {
  // for cave user movement calculate the distance of the cave user from the center (sound source)
  float distance = dist(centerX, centerY, cuX, cuY);
  float angle = 180.0 + atan2((centerY - cuY), (centerX - cuX)) * 180.0 / PI;
  float cuVelocity = getCuVelocity();  
  
  // create a string which contains the details of the movement
  String vel = String.format("%.2f", cuVelocity);
  if (cuVelocity > epsilon && cuVelocity < movementThreshold) {
    cuMovementDetails = "Cave user movement: CALM\n" + vel;
    sendSoundDataAndEvent(CALM, distance, angle);
  } else if (cuVelocity >= movementThreshold){
    cuMovementDetails = "Cave user movement: AGGRESSIVE\n" + vel;
    sendSoundDataAndEvent(AGGRESSIVE, distance, angle);
  }
}

// react on cave user interactions bump, hit, touch
void reactOnCaveUserInteractions() {
  float distance = 0.0;
  float angle = 0.0;
      
  // react on BUMP
  if (isNewOverlap && isOverlap()) {
    // for bump interaction calculate the distance of the cave from the center (sound source)
    distance = dist(centerX, centerY, cuX, cuY) * interactionBodyDistanceScale;
    angle = 180.0 + atan2((centerY - cuY), (centerX - cuX)) * 180.0 / PI;
    cuInteractionDetails = "Cave user interaction: BUMP\n";
    String d = String.format("%.2f", distance);
    String a = String.format("%.2f", angle);
    cuInteractionDetails = cuInteractionDetails + d + "   " + a;
    sendSoundDataAndEvent(BUMP, distance, angle);
    isNewOverlap = false; 
  } else if (!isOverlap()) 
    isNewOverlap = true;
  
  // react on HIT
  if (isHit) {
    // for hit and touch interactions calculate the distance of the hit/touch position
    // in relation to the sound user
    distance = dist(normalizeW(mouseX), normalizeH(mouseY), suX, suY) * interactionBodyDistanceScale;
    angle = 180.0 + atan2((centerY - suY), (centerX - suX)) * 180.0 / PI;
    cuInteractionDetails = "Cave user interaction: HIT\n";
    String d = String.format("%.2f", distance);
    String a = String.format("%.2f", angle);
    cuInteractionDetails = cuInteractionDetails + d + "   " + a;
    sendSoundDataAndEvent(HIT, distance, angle);
    
  // react on TOUCH
  } else if (isTouch) {
    distance = dist(normalizeW(mouseX), normalizeH(mouseY), suX, suY) * interactionBodyDistanceScale;
    angle = 180.0 + atan2((centerY - suY), (centerX - suX)) * 180.0 / PI;
    cuInteractionDetails = "Cave user interaction: TOUCH\n";
    String d = String.format("%.2f", distance);
    String a = String.format("%.2f", angle);
    cuInteractionDetails = cuInteractionDetails + d + "   " + a;
    sendSoundDataAndEvent(TOUCH, distance, angle);
  }
}

// update the sound source data and send the event to the pd patch
void sendSoundDataAndEvent(int interaction, float distance, float angle) {
    // set distance and angle for spatial sound
    soundEvents[interaction].setDistance(distance * virtualRoomScale);
    soundEvents[interaction].setAngle(angle);
    // send sound event, but only when the sound is turned on
    sendSoundEvent(soundEvents[interaction], true);
}

float getCuVelocity() {
    float distance = dist(oCuX, oCuY, cuX, cuY);
    float td = float(millis() - oldTimeStamp);
    // calculate pixels/second for now
    return distance / td * 1000;
}

boolean updateCaveUserPosition() {
  if (abs(oCuX - cuX) > epsilon && abs(oCuY - cuY) > epsilon) {
    // calculate velocity, here in pixels/second
    float distance = dist(oCuX, oCuY, cuX, cuY);
    float td = float(millis() - oldTimeStamp);
    float velocity = distance / td;
    return true;
  }
  return false;
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
float normalizeW(int x) {
  return x / float(w);
}

// normlize a y coordinate
float normalizeH(int y) {
  return y / float(h);
}

void drawUserPositions(color c, float x, float y) {
  stroke(c);
  noFill();
  rect(x * h, y * w, w * uDim, h * uDim);
  line(x * h, y * w, (x + uDim * 0.75) * h, y * w); 
}

void drawInstructions() {
  fill(cuColor);
  text("CAVE user", 10, h - 50);
  fill(suColor);
  text("SOUND user", 10, h - 30);
  fill(255);
  text("LMB: drag users / RMB: touch sound user", 10, h - 10);
  noFill();
}

void drawDetails() {
  fill(255);
  text(cuMovementDetails, width - 220, 25);
  text(cuInteractionDetails, width - 220, 70);
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
    if (isInside(suX, suY, normalizeW(mouseX), normalizeW(mouseY))) {
      isSuDraggingActive = true;
    } else if (isInside(cuX, cuY, normalizeW(mouseX), normalizeH(mouseY))) {
      isCuDraggingActive = true;
    }
  }
}

void mouseReleased() {
  if (isCuDraggingActive) 
    isCuDraggingActive = false;
  else if (isSuDraggingActive) 
    isSuDraggingActive = false;
}
