// ControlP5 stuff
ControlP5 cp5;
CheckBox cbSounds;

void setupGUI() {
  cp5 = new ControlP5(this);
  cbSounds = cp5.addCheckBox("environment sound")
             .setPosition(10, 10)
             .setColorForeground(color(120))
             .setColorActive(color(255))
             .setColorLabel(color(255))
             .setSize(20, 20)
             .addItem("ENVIRONMENT", environmentSound.getNumber())
             .addItem("CAVE USER", caveUserSound.getNumber())
             .addItem("BUMP", touchSound.getNumber())
             .addItem("TOUCH", bumpSound.getNumber());
}

// TODO: only send changes, not all four
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(cbSounds)) {
    for (int i = 0; i < cbSounds.getArrayValue().length; i++) {
      int n = (int)cbSounds.getArrayValue()[i];
      if ((i + 1) == environmentSound.getNumber()) {
        if (n == 1)
          environmentSound.setIsOn(true);
        else
          environmentSound.setIsOn(false);
        sendSoundEvent(environmentSound);
      } else if ((i + 1) == caveUserSound.getNumber()) {
        if (n == 1)
          caveUserSound.setIsOn(true);
        else
          caveUserSound.setIsOn(false);
        sendSoundEvent(caveUserSound);
      } else if ((i + 1) == touchSound.getNumber()) {
        if (n == 1)
          touchSound.setIsOn(true);
        else
          touchSound.setIsOn(false);
        sendSoundEvent(touchSound);
      } else if ((i + 1) == bumpSound.getNumber()) {
        if (n == 1)
          bumpSound.setIsOn(true);
        else
          bumpSound.setIsOn(false);
        sendSoundEvent(bumpSound);
      } 
    }
    if (debug)
      println("-----------------");
  }
}
