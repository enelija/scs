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
             .addItem("/0 POSITION", soundEvents[POSITION].getNumber())
             .addItem("/1 VELOCITY", soundEvents[VELOCITY].getNumber())
             .addItem("/2 BUMP",     soundEvents[BUMP].getNumber())
             .addItem("/3 TOUCH",    soundEvents[TOUCH].getNumber())
             .addItem("/4 HIT",      soundEvents[HIT].getNumber());
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(cbSounds)) {
    for (int i = 0; i < cbSounds.getArrayValue().length; i++) {
      int n = (int)cbSounds.getArrayValue()[i];
      // turn sound on
      if (n == 1 && !soundEvents[i].isOn()) {
        soundEvents[i].setIsOn(true);
        if (i == POSITION && soundEvents[i].isLooped())
          sendSoundEvent(soundEvents[i]);
      // turn sound off
      } else if ((n == 0) && soundEvents[i].isOn()) {
        soundEvents[i].setIsOn(false);
        sendSoundEventOff(soundEvents[i]);
      }
    }
  }
}
