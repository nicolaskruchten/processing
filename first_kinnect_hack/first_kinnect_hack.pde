
import oscP5.*;
import netP5.*;

OscP5 oscP5;

// Creating an array of objects.
ArrayList<Mover> movers;
Hashtable<Integer, PVector> attractors = new Hashtable<Integer, PVector>();
Lure lure;

void setup() {
  oscP5 = new OscP5(this, "127.0.0.1", 7110);

  size(screen.width,screen.height);
  //smooth();
  background(255);
  // Initializing all the elements of the array
  movers = new ArrayList<Mover>();
  for(int i = 0; i< 10; i++) movers.add(new Mover()); 
  lure = new Lure();
}

/* incoming osc message are forwarded to the oscEvent method. */
// Here you can easily see the format of the OSC messages sent. For each user, the joints are named with 
// the joint named followed by user ID (head0, neck0 .... r_foot0; head1, neck1.....)
void oscEvent(OscMessage msg) {
  msg.print();
  
  if (msg.checkAddrPattern("/joint") && msg.checkTypetag("sifff")) {
    // We have received joint coordinates, let's find out which skeleton/joint and save the values ;)
    Integer id = msg.get(1).intValue();
      PVector lhand = attractors.get(id);
      PVector rhand = attractors.get(id*-1);
    if (msg.get(0).stringValue().equals("l_hand")) {
      lhand.x = msg.get(2).floatValue()*width;
      lhand.y = msg.get(3).floatValue()*height;
    }
    else if (msg.get(0).stringValue().equals("r_hand")) {
      rhand.x = msg.get(2).floatValue()*width;
      rhand.y = msg.get(3).floatValue()*height;
    }
  }
  else if (msg.checkAddrPattern("/new_user") && msg.checkTypetag("i")) {
    // A new user is in front of the kinect... Tell him to do the calibration pose!
    println("New user with ID = " + msg.get(0).intValue());
  }
  else if(msg.checkAddrPattern("/new_skel") && msg.checkTypetag("i")) {
    //New skeleton calibrated! Lets create it!
    Integer id = msg.get(0).intValue();
    attractors.put(id, new PVector());
    attractors.put(id*-1, new PVector());
  }
  else if(msg.checkAddrPattern("/lost_user") && msg.checkTypetag("i")) {
    //Lost user/skeleton
    Integer id = msg.get(0).intValue();
    println("Lost user " + id);
    attractors.remove(id);
    attractors.remove(id*-1);
  }
}


void draw() {
  noStroke();
  fill(0,10);
  rect(0,0,width,height);

  lure.update();

  for(Mover m: movers)
  {
    m.update();
    m.checkEdges();
    m.display(); 
  }
    
    for(PVector pv: attractors.values())
    {
      //fill(255,0,0);
      //ellipse(pv.x,pv.y,5,5);
    }  
}

class Lure {
 PVector location;
 PVector velocity;
 float topspeed;
 boolean burst;
 
 Lure() {
    location = new PVector(random(width),random(height));
    velocity = new PVector(random(5),random(5));
    topspeed = 10;
    burst = true;
 }
 
 void update() {
   
    boolean first = true;
    PVector focus = new PVector(width/2,height/2);
    for(PVector pv: attractors.values())
    {
        PVector dirTo = PVector.sub(pv, focus);
        dirTo.div(2);
        focus.add(dirTo);
    }
    
    
    if(true)
    {
      location.x=focus.x;
      location.y=focus.y;
      burst = 100 > focus.dist(new PVector(width/2,height/2));
    }
    else
    {
    PVector dir = PVector.sub(focus,location);  // Find vector pointing towards mouse
    dir.normalize();     // Normalize
    
    float xTemp = dir.x;
    float a = dir.heading2D();
    dir.x = cos(a);
    dir.y = sin(a);
    dir.mult(random(1));
    

    // Motion 101!  Velocity changes by acceleration.  Location changes by velocity.
    velocity.add(dir);
    velocity.limit(topspeed);
    location.add(velocity);
    }
    
      //fill(0,0,255);
      //ellipse(location.x,location.y,5,5);
    
 }
}

class Mover {

  PVector location;
  PVector velocity;
  float topspeed;
  PVector burstLure;

  Mover() {
    location = new PVector(random(width),random(height));
    velocity = new PVector(0,0);
    topspeed = 6;
    burstLure = new PVector(random(width),random(height));
  }

  void update() {

    // Our algorithm for calculating acceleration:
    
    PVector dir = lure.burst ? PVector.sub(burstLure, location) : PVector.sub(lure.location,location);
    dir.normalize();
    float xTemp = dir.x;
    float a = random(0.2)+dir.heading2D();
    dir.x = cos(a);
    dir.y = sin(a);
    dir.mult(random(1));
    
    velocity.add(dir);
    velocity.limit(topspeed);
    location.add(velocity);
  }

  void display() {
    noStroke();
    fill(255, 255, 0, 90);
    ellipse(location.x,location.y,16,16);
    fill(255, 255, 0);
    ellipse(location.x,location.y,8,8);
  }

  void checkEdges() {

    if (location.x > width) {
      location.x = 0;
    } else if (location.x < 0) {
      location.x = width;
    }

    if (location.y > height) {
      location.y = 0;
    }  else if (location.y < 0) {
      location.y = height;
    }

  }

}

