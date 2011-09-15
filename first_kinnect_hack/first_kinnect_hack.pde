
import oscP5.*;
import netP5.*;

OscP5 oscP5;

// Creating an array of objects.
Mover movers;
Hashtable<Integer, PVector> attractors = new Hashtable<Integer, PVector>();


void setup() {
  oscP5 = new OscP5(this, "127.0.0.1", 7110);

  size(screen.width/2,screen.height/2);
  smooth();
  background(255);
  // Initializing all the elements of the array
  movers = new Mover(); 
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
  fill(255,10);
  rect(0,0,width,height);

  
    movers.update();
    movers.checkEdges();
    movers.display(); 
    
    for(PVector pv: attractors.values())
    {
          stroke(0);
          fill(255,0,0);
          ellipse(pv.x,pv.y,5,5);
    }  
}

class Mover {

  PVector location;
  PVector velocity;
  PVector acceleration;
  float topspeed;

  Mover() {
    location = new PVector(random(width),random(height));
    velocity = new PVector(0,0);
    topspeed = 4;
  }

  void update() {

    // Our algorithm for calculating acceleration:
    
    PVector mouse = new PVector(width/2,height/2);
    for(PVector pv: attractors.values())
    {
      PVector dirTo = PVector.sub(mouse, pv);
      dirTo.div(2);
      mouse.add(dirTo);
    }
    PVector dir = PVector.sub(mouse,location);  // Find vector pointing towards mouse
    dir.normalize();     // Normalize
    dir.mult(0.5);       // Scale 
    acceleration = dir;  // Set to acceleration

    // Motion 101!  Velocity changes by acceleration.  Location changes by velocity.
    velocity.add(acceleration);
    velocity.limit(topspeed);
    location.add(velocity);
  }

  void display() {
    stroke(0);
    fill(175);
    ellipse(location.x,location.y,16,16);
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

