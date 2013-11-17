// OSC variables
OscP5 oscP5;
NetAddress pdServer;
int pdServerPort = 12345;
String pdServerAddress = "127.0.0.1";
String msgPattern = "/SonicCave";

void setupSendToPdServer() {
  oscP5 = new OscP5(this, pdServerPort);
  pdServer = new NetAddress(pdServerAddress, pdServerPort);
  if (debug) {
    println("Setup connection to " + pdServerAddress + ":" + pdServerPort);
  }
}

void sendSoundEvent(SpatialSoundEvent se) {
  println(se.getNumber());
  OscMessage message = new OscMessage(msgPattern + "/" + se.getNumber());
  if (se.getIsOn())
    message.add(se.getVolume());
  else
    message.add(0.0);
  message.add(se.getDistance());
  message.add(se.getAngle());
  
  if (debug) {
    print("Sending OSC message with pattern " + message.addrPattern());
    print(" and typetag " + message.typetag() + ": ");
    println( se.getVolume() + " " + se.getDistance() +  " " + se.getAngle());
  }
}
  
