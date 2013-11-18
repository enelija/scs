// OSC variables
OscP5 oscP5;
NetAddress pdServer;
int pdServerPort = 12345;
int listenerPort = 12346;
String pdServerAddress = "127.0.0.1";
String msgPattern = "/SonicCave";

void setupCommunication() {
  oscP5 = new OscP5(this, listenerPort);
  pdServer = new NetAddress(pdServerAddress, pdServerPort);
  if (DEBUG) {
    println("Setup connection to " + pdServerAddress + ":" + pdServerPort);
  }
}

void sendSoundEvent(SpatialSoundEvent se, boolean sendOnlyOn) {
  if (sendOnlyOn && se.isOn()) {
    OscMessage message = new OscMessage(msgPattern + "/" + se.getNumber());
    if (se.isOn())
      message.add(se.getVolume());
    else
      message.add(0.0);
    message.add(se.getDistance());
    message.add(se.getAngle());
    
    if (DEBUG) {
      print("Sending OSC message with pattern " + message.addrPattern());
      print(" and typetag " + message.typetag() + ": ");
      if (se.isOn())
        print(se.getVolume());
      else
        print("0.0");
      println(" " + se.getDistance() +  " " + se.getAngle());
    }
    
    oscP5.send(message, pdServer);
  }
}
  
