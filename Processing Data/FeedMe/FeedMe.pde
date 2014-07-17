//The GPL License (GPL)
// email: vailancio248@gmail.com
import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;
Maxim maxim;
AudioPlayer woosh,atmos,music,bubbleSound,sonic;
PImage background,bubbleImage;
float time, lastTime;

float magnify = 200; // This is how big we want the rose to be.
float phase = 0; // Phase Coefficient : this is basically how far round the circle we are going to go
float amp = 0; // Amp Coefficient : this is basically how far from the origin we are.
int elements = 128;// This is the number of points and lines we will calculate at once. 1000 is alot actually. 
float threshold = 0.35;// try increasing this if it jumps around too much
int wait=0;
boolean playit;

//Tadpoles
int n_tadpoles = 14;
tadpole[] p=new tadpole[n_tadpoles]; 
//int tadpoleSize = 18;
boolean[] notHungry;

/*
//GUI
Toggle t;
boolean dragging = false;
*/

//Physics
Physics physics;
Body fp[], td[];
Body mouseTR;
float worldDensity=10.0;
CollisionDetector detector;

//Food
int maxFoodParticles=400;
float maxFoodSize = 8;
boolean[] foodDelete;
int foodPartCount=0;
PImage foodImage;
int[] ateCount;
float[] foodSize;
int totalAteCount =0;
float gravity=-0.1;
// the tint colors we can apply
color [] tints; 

//Timers
int savedTime;
int totalTime = 5000;
float timer = 10000.0;

//Bubbles
Bubble[] bubbles;
Bubble[] bubblesENV;
int pos;
boolean bubbling;
boolean bubbleable;

//SETTINGS
int DIAMETER_MIN = 4;
int DIAMETER_MAX = 15;
int SPEED_MIN = 1; //speed of the upward movements
int SPEED_MAX = 2;
float SOUND_SPEED_MIN = 0.1;
int SOUND_SPEED_MAX = 2;
int SPREAD = 20; //how far from the mouse position bubbles are created

void setup()
{
  background=loadImage("underwater.jpg");
  //background=loadImage("data/underwaterscene.jpg");
  size(background.width, background.height);
  frameRate(60);
  savedTime = millis();
  maxim = new Maxim(this);
  woosh = maxim.loadFile("Water slosh.wav");
  woosh.setLooping(false);
  woosh.volume(0.5);
  atmos = maxim.loadFile("Underwater.wav");
  atmos.setLooping(true);
  atmos.volume(0.5);
  woosh.volume(1);
  //load music
  music = maxim.loadFile("mybeat.wav");
  music.setLooping(true);
  music.volume(1);
  music.setAnalysing(true);
  
  sonic = maxim.loadFile("sonic.wav");
  sonic.setLooping(false);
  background(0);
  rectMode(CENTER);
  //Bubbles

  //Sounds
  bubbleSound = maxim.loadFile("bubble.wav");
  bubbleSound.setLooping(true);
  bubbleSound.volume(2);

  //flag setup
  bubbleable = true;
  bubbling = false;

  //bubble array starts empty
  bubbles = new Bubble[0];
  bubblesENV = new Bubble[0];
  
  bubbleImage = loadImage("bubble.png");

  //GUI
  stroke(1);
  fill(0, 0, 0, 50);
  //t = new Toggle("Play Music", 100, height-100, 80, 30);

  //Tadpoles
  for (int i=0;i<p.length;i++) {
    p[i]=new tadpole();
  } 
  
  //Create world scene
  initScene();
  
  //Food coloring
  tints = new color[5];
  tints[0] = color(234, 170, 72);
  tints[1]= color(24, 84, 56);
  tints[2] = color(7, 6, 38);
  tints[3] = color(50, 70, 43);
  tints[4] = color(11, 25, 36);
  
  //Food size
  //Setup food size
  //Do not do this inside custom renderer.
  for(int i=0;i<fp.length;i++){
      foodSize[i]=random(3, maxFoodSize);
  }

  //Text
  textSize(11);
}

void draw()
{
  //load grunge texture

  //load ovelaying background 
  image(background, 0, 0, background.width, background.height);
  time=millis()-lastTime;
  lastTime=millis();

  //load underwater enviroment sound.
  atmos.play();

  //Load tadpoles
  for (int i=0;i<p.length;i++) {
    p[i].update();
    p[i].display();
  }
  
  //Load food
  //dropFood();

  //GUI
  //t.display();   
  //load particles
  particles();
  updateTadpoleTrackers();
  removeObjects();

  String s = "Total Score: ";
  fill(255);
  textAlign(LEFT);
  text(s+totalAteCount, width-170, 50);
  text("Hungry Tadpoles: "+getHungry(), width-170, 70); 
  float foodRemaining = maxFoodParticles-foodPartCount;
  foodRemaining=foodRemaining/maxFoodParticles*100;
  text("Food Remaining: "+foodRemaining+" %", width-170, 90); 
  fill(127,127,127);
  text("Frame Rate: "+frameRate,width-170, height-25);


  if (getHungry() == 0) {
    physics.destroy();
    textAlign(CENTER);
    text("You won!", width/2, height/2);
  }

  if (foodPartCount == maxFoodParticles) {
    physics.destroy();
    textAlign(CENTER);
    text("Sorry no more food left!", width/2, height/2);
  }  

  //Update mouse tracker
  mouseTR.setPosition(physics.screenToWorld(mouseX, mouseY));
  
  //Bubbles
  initBubbles();
}

void mouseDragged() {
  //Play underwater woosh sound  
  woosh.play();
  atmos.play();
}

void mousePressed()
{

  bubbling = true;
  bubbleSound.play();

  //Play underwater bloop bloop sound

  atmos.play();
  woosh.play();

  woosh.ramp(1., 1000);

  //t.mousePressed();

  for (int i=0;i<p.length;i++) {
    p[i].update();
  }
}

void mouseReleased()
{
  bubbling = false;
  bubbleSound.stop();
  woosh.ramp(0., 1000);
}

//
void particles() {
  strokeWeight(1);
  stroke(3);
  fill(0, 0, 0, 90);
  ellipse(random(800), random(600), 1, 1);
}
//
//

void initBubbles(){
  //bubbles can be created in every 2 'draw() ticks'
  bubbleable = !bubbleable;
  
   //inertia is based on how fast the user is dragging/swiping
    int inertia = mouseX - pmouseX;
    //diameter is random inside limits
    int diam = round(random(DIAMETER_MIN, DIAMETER_MAX));
    //speed will be inversely proportional to diameter
    int speed = ceil(map(diam, DIAMETER_MAX, DIAMETER_MIN, SPEED_MIN, SPEED_MAX));
  
  //Normal random bubbles
  if(bubbleable){
    timer =random(450, 600);
    int passedTime = millis() - savedTime;
    if (passedTime > timer) {
      //Generate a random burst
      int burstSize = (int) random(1,16);
      int bubblePosX = (int) random(0,width);
      for(int k=0; k < burstSize;k++){
        bubblesENV = (Bubble[])append(bubblesENV, new Bubble(bubblePosX, height, diam, speed, inertia));
      }  
      savedTime = millis();
    }
  }
  
  //creates bubbles while mouse is pressed
  if (bubbling && bubbleable) {
    //creates a bubble and put it in the array
    bubbles = (Bubble[])append(bubbles, new Bubble(random(mouseX-SPREAD, mouseX+SPREAD), random(mouseY-SPREAD, mouseY+SPREAD), diam, speed, inertia));
 
    //changes the bubble sound according to the diameter
    bubbleSound.speed(map(diam, DIAMETER_MIN, DIAMETER_MAX, SOUND_SPEED_MIN, SOUND_SPEED_MAX)*2);
  }

  //moves all the bubbles created so far
  for (int i = 0;i < bubbles.length;++i) {
    bubbles[i] = new Bubble(bubbles[i].x, bubbles[i].y, bubbles[i].diameter, bubbles[i].speed, bubbles[i].inertia);
  }

  for (int i = 0;i < bubblesENV.length;++i) {
    bubblesENV[i] = new Bubble(bubblesENV[i].x, bubblesENV[i].y, bubblesENV[i].diameter, bubblesENV[i].speed, bubblesENV[i].inertia);
  }

  //checks for bubbles which are out of the stage
  for (int i = 0;i < bubbles.length;++i) {
    if (bubbles[i].y + bubbles[i].diameter/2 < 0) {
      //if it's out, remove it from the array, overwriting its position with the rest of the array...
      arrayCopy(bubbles, i+1, bubbles, i, bubbles.length-(i+1));
      //...and using shorten() to remove the last unnecessary element
      bubbles = (Bubble[])shorten(bubbles);
    }
  }  

  for (int i = 0;i < bubblesENV.length;++i) {
    if (bubblesENV[i].y + bubblesENV[i].diameter/2 < 0) {
      //if it's out, remove it from the array, overwriting its position with the rest of the array...
      arrayCopy(bubblesENV, i+1, bubblesENV, i, bubblesENV.length-(i+1));
      //...and using shorten() to remove the last unnecessary element
      bubblesENV = (Bubble[])shorten(bubblesENV);
    }
  }
}

///
void initScene() {
  physics = new Physics(this, width, height, 0, gravity, width*2, height*2, width, height, 100);
  physics.setCustomRenderingMethod(this, "myCustomRenderer");
  foodImage = loadImage("philosophers-stone-gray.png");
  physics.setDensity(worldDensity);

  fill(0, 0, 0, 255); 
  noStroke();
  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);
  fp = new Body[maxFoodParticles];
  foodDelete = new boolean[maxFoodParticles];
  notHungry = new boolean[n_tadpoles];
  ateCount = new int[n_tadpoles];
  foodSize = new float[maxFoodParticles];
  for (int i = 0; i < foodDelete.length; i++) foodDelete[i] = false;
  for (int i = 0; i < notHungry.length; i++) notHungry[i] = false;
  physics.setDensity(100.0);
  td = new Body[n_tadpoles];

  //Load mouse tracker
  mouseTR = physics.createCircle(0, 0, 10);
  loadTadpoleTrackers();
}


void loadTadpoleTrackers() {
  physics.setDensity(0);
  for (int j=0;j<p.length;j++) {
    td[j]= physics.createCircle(p[j].getPosition().x, p[j].getPosition().y, p[j].getSize());
  }
  //Set density back to normal
  physics.setDensity(worldDensity);
}

void updateTadpoleTrackers() {
  for (int i=0;i<p.length;i++) {
    
    //if(td[i]!=null){
      td[i].setPosition(physics.screenToWorld(p[i].getPosition().x, p[i].getPosition().y));
    //}else{
      //td[i]=physics.createCircle(p[i].getPosition().x, p[i].getPosition().y, p[i].getSize());
    //} 
   
  }
}

// this function renders the physics scene.
// this can either be called automatically from the physics
// engine if we enable it as a custom renderer or 
// we can call it from draw
void myCustomRenderer(World world) {
  //For food particles 
  dropFood();
  
  for (int i = 0,k=0; i < foodPartCount; i++,k++)
  {
    if(foodDelete[i]==false){
        Vec2 fpPos = physics.worldToScreen(fp[i].getWorldCenter());
        pushMatrix();
        translate(fpPos.x, fpPos.y);
        if(i%5==0){
            k=0;
        }
        //println("k:"+k+" i:"+i);
        if(k<5){
            tint(tints[k]);
        }    
        image(foodImage, 0, 0, foodSize[i], foodSize[i]);
        //remove tint
        tint(255,255,255);
        popMatrix();
    }   
  }
}

// This method gets called automatically when 
// there is a collision
void collision(Body b1, Body b2, float impulse)
{
  int tadpoleSize;
  //Collision between food and wall
     for (int i=0;i<fp.length;i++){
         if (b1 == fp[i] && (b2.getMass() == 0) || (b1.getMass() == 0) && b2 ==fp[i]){// its a crate
            if(impulse > 0){
                 println("Collision detected between food object "+i+" and the wall");
                 //println("Impulse:"+impulse);
                 foodDelete[i] = true;
                 //println("Delete signal set");
   
             }
             
         }   
     }
     


  /*
       //// Collision between tadpole and wall ///
   for (int i=0;i<n_tadpoles;i++){
   if (b1 == td[i] && (b2.getMass() == 0) || (b1.getMass() == 0) && b2 ==td[i]){
   println("Collision detected between tadpole "+i+" and the wall");
   println("Impulse:"+impulse);
   
   }
   */


  //Collision between tadpole and food particles
  for (int i=0;i<td.length;i++) {

    for (int k=0;k < maxFoodParticles;k++) {
      if (b1 == td[i] && b2==fp[k] || b2 == td[i] && b1==fp[k]) {
        //if(impulse > 0){
        println("Collision detected between food paticle "+k+" and the tadpole "+i);
        println("Impulse:"+impulse);
        if (notHungry[i]==false) {
          tadpoleSize=p[i].getSize();
          if (tadpoleSize < 16) {
            foodDelete[k] = true;
            ateCount[i]++;
            totalAteCount++;
            tadpoleSize++;
            p[i].setSize(tadpoleSize);
          }
          else {
            notHungry[i]=true;
            sonic.play();
            p[i].setColor(221, 255, 17);
          } 
          // }
        }
      }
    }
  }  

  //
}

////

// for removing : called in draw function

void removeObjects()
{
  for (int i = 0; i < foodPartCount; i++) {
    if (fp[i] != null && foodDelete[i]) {
      physics.removeBody(fp[i]);
      fp[i] = null;
    }
  }
}
//
void dropFood() {
  timer =random(500, timer);
  int passedTime = millis() - savedTime;
  if (foodPartCount != maxFoodParticles) {
    if (passedTime > timer) {
      if (foodPartCount < maxFoodParticles) {
        float positionX = random(0, width);
        float positionY = 0;
        fp[foodPartCount]= physics.createCircle(positionX, positionY, foodSize[foodPartCount]);
      }
      foodPartCount=foodPartCount+1;
      savedTime = millis();
    }
  }
}

//Count hungry tadpoles
int getHungry() {
  int count=n_tadpoles;
  for (int i=0;i<notHungry.length;i++) {
    if (notHungry[i]==true) {
      count--;
    }
  }
  return count;
}
///
class tadpole {
  PVector position, velocity, acceleration, dacceleration, mouse;
  PVector[]trail;
  color c;
  int radius=80;
  int clickTimer, siz=10;
  boolean clicked;
  PImage tadImg;

  tadpole() {
    position=new PVector(random(800), random(600));
    velocity=new PVector(random(0, 0), random(0, 0));
    acceleration=new PVector(random(-1, 1), random(-1, 1));
    dacceleration=new PVector(random(-1, 1), random(-1, 1));
    trail=new PVector[floor(random(20, 30))];
    c=color(50, floor(random(0, 6)), floor(random(10)));
    for (int i=0;i<trail.length;i++)trail[i]=new PVector(position.x, position.y);
    clickTimer=100;
    tadImg=loadImage("data/head.png");
  }

  void display() {

    strokeWeight(siz);

    stroke(c);
    makeTrail();
    pushMatrix();
    translate(position.x, position.y);
    rotate(velocity.heading2D());
    point(0, 0);
    image(tadImg, -siz/2, -siz/2, siz, siz);
    popMatrix();
  }

  void update() {

    dacceleration=new PVector(random(-4, 4), random(-4, 4));
    acceleration.add(dacceleration);

    if (clickTimer>100)
    {
      acceleration.add(toMouse());
      acceleration.limit(2);
      velocity.add(acceleration);
      velocity.limit(6);
    }  
    else {
      acceleration.add(awayMouse());
      acceleration.limit(6);
      velocity.add(acceleration);
      velocity.limit(6);
    }

    PVector temp=new PVector(velocity.x, velocity.y);
    temp.mult(time*0.03);
    position.add(temp);
    clickTimer++;
    bounce();
  }

  void bounce() {

    if (position.y>background.width && velocity.y>0) {
      velocity=new PVector(velocity.x, -velocity.y);
      acceleration=new PVector(acceleration.x, -acceleration.y);
    }

    if (position.y<0 && velocity.y<0) {
      velocity=new PVector(velocity.x, -velocity.y);
      acceleration=new PVector(acceleration.x, -acceleration.y);
    }

    if (position.x>background.width && velocity.x>0) {
      velocity=new PVector(-velocity.x, velocity.y);
      acceleration=new PVector(-acceleration.x, acceleration.y);
    }

    if (position.x<0 && velocity.x<0) {
      velocity=new PVector(-velocity.x, velocity.y);
      acceleration=new PVector(-acceleration.x, acceleration.y);
    }
  }

  void makeTrail() {
    for (int i=0;i<trail.length-1;i++) {
      trail[i]=new PVector(trail[i+1].x, trail[i+1].y);
    }
    trail[trail.length-1]=new PVector(position.x, position.y);

    for (int i=0;i<trail.length-1;i+=2) {
      stroke(c, i*255/trail.length);
      strokeWeight(i*siz/trail.length);
      line(trail[i].x, trail[i].y, trail[i+1].x, trail[i+1].y);
    }
  }



  PVector toMouse() {
    PVector m=new PVector(mouseX-position.x, mouseY-position.y);
    PVector n=new PVector(mouseX-position.x, mouseY-position.y);
    n.normalize();
    if (m.mag()>radius)
      n.mult(100000);
    else
      n.mult(40);
    n.div(m.mag()*m.mag());

    return n;
  }

  PVector awayMouse() {
    PVector n=new PVector(mouseX-position.x, mouseY-position.y);
    PVector m=toMouse();
    m=new PVector(-m.x, -m.y);
    m.mult(10000/((n.mag()*n.mag())+1)*(100/(clickTimer+1)));
    return m;
  }

  /*
     PVector setPosition(x,y){
   
   }*/

  void setSize(int size) {
    siz=size;
  }
  int getSize() {
    return siz;
  }  

  PVector getPosition() {
    return position;
  }

  void setColor(int x, int y, int z) {
    c=color(x, y, z);
  }
}

//class for Bubble objects
public class Bubble {
  public float x;
  public float y;
  public int diameter;
  public PImage image;
  public int speed;
  public int inertia;

  //constructor
  Bubble(float x, float y, int diameter, int speed, int inertia) {
    this.speed = speed;
    this.x = x + inertia/5;
    this.y = y - speed;
    this.diameter = diameter;
    this.image=bubbleImage;

    //reduce the inertia
    if (inertia > 0) {
      --inertia;
    } 
    else if (inertia < 0) {
      ++inertia;
    }
    this.inertia = inertia;

    //creates the 'body' of the bubble
    int r = diameter;
    //random index has issues
    //Requires too much processing power
    //tint(tints[(int) random(tints.length)],126);
    //Sequential index will work
    /*
    int k=0;
    if(k==5){
      k=0;
    }
    if(k<5){
      tint(tints[k],126);
    } 
    */
    //k++;
    image(image, x, y, r, r);
    noFill();
   for (r= diameter; r > 0.4*diameter; --r) {  
        pushMatrix();
        translate(x, y);
        scale(r,r);
        popMatrix();
    }
  }
  
  /*
  Vec2 getPosition(){
     Vec2 position=new Vec2(x,y);
     return position;
  }
  
  int getSize(){
    return diameter;
  }
  
  */
  
}



