import oscP5.*;
import netP5.*;
import controlP5.*;

/* ************************************************
    SoundCave simulator by enelija
      
      to use with the pd patch ICSpatialSoundCave
      
      cu stands for cave user
      su stands for sound user
   ************************************************ */

// sets debug on / off
final boolean debug = true; 

// absolute width and height for the canvas
int w = 500;
int h = 500;

// normalized user representation dimension
float uDim = 0.05;
float uDimHalf = uDim / 2.0;

// background color, cave and sound user colors
color bgColor = color(0, 0, 0);
color cuColor = color(255, 0, 0);
color suColor = color(0, 255, 0);

boolean isCuDraggingActive = false, isSuDraggingActive = false;

// stroke weight for user representation
int sw = 2;

// normalized cave and sound user positions
float cuX = 0.5, cuY = 0.5, suX = 1.0 - uDimHalf, suY = 1.0 - uDimHalf;

// volumes for environment, cave user, touch, bump sounds
float [] volumes = {0.5, 0.75, 1.0, 1.0};

//int environmentSound = 1, caveUserSound = 2, touchSound = 3, bumpSound = 4;
SpatialSoundEvent environmentSound, caveUserSound, touchSound, bumpSound;

void setup() {
  size(w, h);
  background(bgColor);
  rectMode(CENTER);
  noFill();
  strokeWeight(sw);
  textSize(10); 
  
  environmentSound = new SpatialSoundEvent(1);
  caveUserSound = new SpatialSoundEvent(2);
  touchSound = new SpatialSoundEvent(3);
  bumpSound = new SpatialSoundEvent(4);
  
  setupGUI();
  setupSendToPdServer();
  
  // set volumes for all sounds
  environmentSound.setVolume(volumes[0]);
  caveUserSound.setVolume(volumes[1]);
  touchSound.setVolume(volumes[2]);
  bumpSound.setVolume(volumes[3]);
  
  // send environmental sound event (only set the volume, no different distance or rotation needed)
  environmentSound.setIsOn(true);
  sendSoundEvent(environmentSound);
  
}

void draw() {
  background(bgColor);
  drawUserPositions(cuColor, cuX, cuY);
  drawUserPositions(suColor, suX, suY);
  drawInstructions();
  
  if (isOverlapping()) {
    // send bumpSoundEvent
  }
}

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
  if (mouseButton == RIGHT) {
    // send touchEvent
  }
  
  // do not let the user move a rectangle into the button area
  if (mouseY < h) {
    if (isInside(suX, suY, normalizeW(mouseX), normalizeW(mouseY))) {
      if (debug)
        println("Mouse pressed inside sound user rectangle");
      isSuDraggingActive = true;
    } else if (isInside(cuX, cuY, normalizeW(mouseX), normalizeH(mouseY))) {
      if (debug)
        println("Mouse pressed inside cave user rectangle");
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

void drawUserPositions(color c, float x, float y) {
  stroke(c);
  rect(x * h, y * w, w * uDim, h * uDim);
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

/* ------------------ Some helper functions ------------------ */
boolean isOverlapping() {
  return false;
}

// returns true if the coordinate ix/iy is inside a rectangle with the center
// coordinate cx, cy, using the dimension uDim
boolean isInside(float cx, float cy, float ix, float iy) {
  if (ix > (cx - uDimHalf) && ix < (cx + uDimHalf) && 
      iy > (cy - uDimHalf) && iy < (cy + uDimHalf))  
      return true;
  return false;
}

// normlize an x coordinate
float normalizeW(int x) {
  return x / float(w);
}

// normlize a y coordinate
float normalizeH(int y) {
  return y / float(h);
}

