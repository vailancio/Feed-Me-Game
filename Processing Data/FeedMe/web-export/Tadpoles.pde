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




int HORIZONTAL = 0;
int VERTICAL   = 1;
int UPWARDS    = 2;
int DOWNWARDS  = 3;

class Widget
{

  
  PVector pos;
  PVector extents;
  String name;

  color inactiveColor = color(60, 60, 100);
  color activeColor = color(100, 100, 160);
  color bgColor = inactiveColor;
  color lineColor = color(255);
  
  
  
  void setInactiveColor(color c)
  {
    inactiveColor = c;
    bgColor = inactiveColor;
  }
  
  color getInactiveColor()
  {
    return inactiveColor;
  }
  
  void setActiveColor(color c)
  {
    activeColor = c;
  }
  
  color getActiveColor()
  {
    return activeColor;
  }
  
  void setLineColor(color c)
  {
    lineColor = c;
  }
  
  color getLineColor()
  {
    return lineColor;
  }
  
  String getName()
  {
    return name;
  }
  
  void setName(String nm)
  {
    name = nm;
  }


  Widget(String t, int x, int y, int w, int h)
  {
    pos = new PVector(x, y);
    extents = new PVector (w, h);
    name = t;
    //registerMethod("mouseEvent", this);
  }

  void display()
  {
  }

  boolean isClicked()
  {
    
    if (mouseX > pos.x && mouseX < pos.x+extents.x 
      && mouseY > pos.y && mouseY < pos.y+extents.y)
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  public void mouseEvent(MouseEvent event)
  {
    //if (event.getFlavor() == MouseEvent.PRESS)
    //{
    //  mousePressed();
    //}
  }
  
  
  boolean mousePressed()
  {
    return isClicked();
  }
  
  boolean mouseDragged()
  {
    return isClicked();
  }
  
  
  boolean mouseReleased()
  {
    return isClicked();
  }
}

class Button extends Widget
{
  PImage activeImage = null;
  PImage inactiveImage = null;
  PImage currentImage = null;
  color imageTint = color(255);
  
  Button(String nm, int x, int y, int w, int h)
  {
    super(nm, x, y, w, h);
  }
  
  void setImage(PImage img)
  {
    setInactiveImage(img);
    setActiveImage(img);
  }
  
  void setInactiveImage(PImage img)
  {
    if(currentImage == inactiveImage || currentImage == null)
    {
      inactiveImage = img;
      currentImage = inactiveImage;
    }
    else
    {
      inactiveImage = img;
    }
  }
  
  void setActiveImage(PImage img)
  {
    if(currentImage == activeImage || currentImage == null)
    {
      activeImage = img;
      currentImage = activeImage;
    }
    else
    {
      activeImage = img;
    }
  }
  
  void setImageTint(float r, float g, float b)
  {
    imageTint = color(r,g,b);
  }

  void display()
  {
    if(currentImage != null)
    {
      //float imgHeight = (extents.x*currentImage.height)/currentImage.width;
      float imgWidth = (extents.y*currentImage.width)/currentImage.height;
      
      
      pushStyle();
      imageMode(CORNER);
      tint(imageTint);
      image(currentImage, pos.x, pos.y, imgWidth, extents.y);
      stroke(bgColor);
      noFill();
      rect(pos.x, pos.y, imgWidth,  extents.y);
      noTint();
      popStyle();
    }
    else
    {
      pushStyle();
      stroke(lineColor);
      fill(bgColor);
      rect(pos.x, pos.y, extents.x, extents.y);
  
      fill(lineColor);
      textAlign(CENTER, CENTER);
      text(name, pos.x + 0.5*extents.x, pos.y + 0.5* extents.y);
      popStyle();
    }
  }
  
  boolean mousePressed()
  {
    if (super.mousePressed())
    {
      bgColor = activeColor;
      if(activeImage != null)
        currentImage = activeImage;
      return true;
    }
    return false;
  }
  
  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      bgColor = inactiveColor;
      if(inactiveImage != null)
        currentImage = inactiveImage;
      return true;
    }
    return false;
  }
}

class Toggle extends Button
{
  boolean on = false;

  Toggle(String nm, int x, int y, int w, int h)
  {
    super(nm, x, y, w, h);
  }


  boolean get()
  {
    return on;
  }

  void set(boolean val)
  {
    on = val;
    if (on)
    {
      bgColor = activeColor;
      if(activeImage != null)
        currentImage = activeImage;
    }
    else
    {
      bgColor = inactiveColor;
      if(inactiveImage != null)
        currentImage = inactiveImage;
    }
  }

  void toggle()
  {
    set(!on);
  }

  
  boolean mousePressed()
  {
    return super.isClicked();
  }

  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      toggle();
      return true;
    }
    return false;
  }
}

class RadioButtons extends Widget
{
  public Toggle [] buttons;
  
  RadioButtons (int numButtons, int x, int y, int w, int h, int orientation)
  {
    super("", x, y, w*numButtons, h);
    buttons = new Toggle[numButtons];
    for (int i = 0; i < buttons.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        bx = x+i*(w+5);
        by = y;
      }
      else
      {
        bx = x;
        by = y+i*(h+5);
      }
      buttons[i] = new Toggle("", bx, by, w, h);
    }
  }
  
  void setNames(String [] names)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(i >= names.length)
        break;
      buttons[i].setName(names[i]);
    }
  }
  
  void setImage(int i, PImage img)
  {
    setInactiveImage(i, img);
    setActiveImage(i, img);
  }
  
  void setAllImages(PImage img)
  {
    setAllInactiveImages(img);
    setAllActiveImages(img);
  }
  
  void setInactiveImage(int i, PImage img)
  {
    buttons[i].setInactiveImage(img);
  }

  
  void setAllInactiveImages(PImage img)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      buttons[i].setInactiveImage(img);
    }
  }
  
  void setActiveImage(int i, PImage img)
  {
    buttons[i].setActiveImage(img);
  }
  
  
  
  void setAllActiveImages(PImage img)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      buttons[i].setActiveImage(img);
    }
  }

  void set(String buttonName)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].getName().equals(buttonName))
      {
        buttons[i].set(true);
      }
      else
      {
        buttons[i].set(false);
      }
    }
  }
  
  int get()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].get())
      {
        return i;
      }
    }
    return -1;
  }
  
  String getString()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].get())
      {
        return buttons[i].getName();
      }
    }
    return "";
  }

  void display()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      buttons[i].display();
    }
  }

  boolean mousePressed()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mousePressed())
      {
        return true;
      }
    }
    return false;
  }
  
  boolean mouseDragged()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mouseDragged())
      {
        return true;
      }
    }
    return false;
  }

  boolean mouseReleased()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mouseReleased())
      {
        for(int j = 0; j < buttons.length; j++)
        {
          if(i != j)
            buttons[j].set(false);
        }
        //buttons[i].set(true);
        return true;
      }
    }
    return false;
  }
}

class Slider extends Widget
{
  float minimum;
  float maximum;
  float val;
  int textWidth = 60;
  int orientation = HORIZONTAL;

  Slider(String nm, float v, float min, float max, int x, int y, int w, int h, int ori)
  {
    super(nm, x, y, w, h);
    val = v;
    minimum = min;
    maximum = max;
    orientation = ori;
    if(orientation == HORIZONTAL)
      textWidth = 60;
    else
      textWidth = 20;
    
  }

  float get()
  {
    return val;
  }

  void set(float v)
  {
    val = v;
    val = constrain(val, minimum, maximum);
  }

  void display()
  {
    
    float textW = textWidth;
    if(name == "")
      textW = 0;
    pushStyle();
    textAlign(LEFT, TOP);
    fill(lineColor);
    text(name, pos.x, pos.y);
    stroke(lineColor);
    noFill();
    if(orientation ==  HORIZONTAL){
      rect(pos.x+textW, pos.y, extents.x-textWidth, extents.y);
    } else {
      rect(pos.x, pos.y+textW, extents.x, extents.y-textW);
    }
    noStroke();
    fill(bgColor);
    float sliderPos; 
    if(orientation ==  HORIZONTAL){
        sliderPos = map(val, minimum, maximum, 0, extents.x-textW-4); 
        rect(pos.x+textW+2, pos.y+2, sliderPos, extents.y-4);
    } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        sliderPos = map(val, minimum, maximum, 0, extents.y-textW-4); 
        rect(pos.x+2, pos.y+textW+2, extents.x-4, sliderPos);
    } else if(orientation == UPWARDS){
        sliderPos = map(val, minimum, maximum, 0, extents.y-textW-4); 
        rect(pos.x+2, pos.y+textW+2 + (extents.y-textW-4-sliderPos), extents.x-4, sliderPos);
    };
    popStyle();
  }

  
  boolean mouseDragged()
  {
    if (super.mouseDragged())
    {
      float textW = textWidth;
      if(name == "")
        textW = 0;
      if(orientation ==  HORIZONTAL){
        set(map(mouseX, pos.x+textW, pos.x+extents.x-4, minimum, maximum));
      } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-4, minimum, maximum));
      } else if(orientation == UPWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-4, maximum, minimum));
      };
      return true;
    }
    return false;
  }

  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      float textW = textWidth;
      if(name == "")
        textW = 0;
      if(orientation ==  HORIZONTAL){
        set(map(mouseX, pos.x+textW, pos.x+extents.x-10, minimum, maximum));
      } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-10, minimum, maximum));
      } else if(orientation == UPWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-10, maximum, minimum));
      };
      return true;
    }
    return false;
  }
}

class MultiSlider extends Widget
{
  Slider [] sliders;
  /*
  MultiSlider(String [] nm, float min, float max, int x, int y, int w, int h, int orientation)
  {
    super(nm[0], x, y, w, h*nm.length);
    sliders = new Slider[nm.length];
    for (int i = 0; i < sliders.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        bx = x;
        by = y+i*h;
      }
      else
      {
        bx = x+i*w;
        by = y;
      }
      sliders[i] = new Slider(nm[i], 0, min, max, bx, by, w, h, orientation);
    }
  }
  */
  MultiSlider(int numSliders, float min, float max, int x, int y, int w, int h, int orientation)
  {
    super("", x, y, w, h*numSliders);
    sliders = new Slider[numSliders];
    for (int i = 0; i < sliders.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        bx = x;
        by = y+i*h;
      }
      else
      {
        bx = x+i*w;
        by = y;
      }
      sliders[i] = new Slider("", 0, min, max, bx, by, w, h, orientation);
    }
  }
  
  void setNames(String [] names)
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(i >= names.length)
        break;
      sliders[i].setName(names[i]);
    }
  }

  void set(int i, float v)
  {
    if(i >= 0 && i < sliders.length)
    {
      sliders[i].set(v);
    }
  }
  
  float get(int i)
  {
    if(i >= 0 && i < sliders.length)
    {
      return sliders[i].get();
    }
    else
    {
      return -1;
    }
    
  }

  void display()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      sliders[i].display();
    }
  }

  
  boolean mouseDragged()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(sliders[i].mouseDragged())
      {
        return true;
      }
    }
    return false;
  }

  boolean mouseReleased()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(sliders[i].mouseReleased())
      {
        return true;
      }
    }
    return false;
  }
}

//The MIT License (MIT)

//Copyright (c) 2013 Mick Grierson, Matthew Yee-King, Marco Gillies

//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



import java.util.ArrayList;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.BufferedInputStream;
import java.net.MalformedURLException;
import java.net.URL;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.SourceDataLine;

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

//import android.content.res.Resources;
// import android.app.Activity; 
// import android.os.Bundle; 
// import android.media.*;
// import android.media.audiofx.Visualizer;
// import android.content.res.AssetFileDescriptor;
// import android.hardware.*;


public class Maxim {

    private float sampleRate;

    public final float[] mtof = {
	0f, 8.661957f, 9.177024f, 9.722718f, 10.3f, 10.913383f, 11.562325f, 12.25f, 12.978271f, 13.75f, 14.567617f, 15.433853f, 16.351599f, 17.323914f, 18.354048f, 19.445436f, 20.601723f, 21.826765f, 23.124651f, 24.5f, 25.956543f, 27.5f, 29.135235f, 30.867706f, 32.703197f, 34.647827f, 36.708096f, 38.890873f, 41.203445f, 43.65353f, 46.249302f, 49.f, 51.913086f, 55.f, 58.27047f, 61.735413f, 65.406395f, 69.295654f, 73.416191f, 77.781746f, 82.406891f, 87.30706f, 92.498604f, 97.998856f, 103.826172f, 110.f, 116.540939f, 123.470825f, 130.81279f, 138.591309f, 146.832382f, 155.563492f, 164.813782f, 174.61412f, 184.997208f, 195.997711f, 207.652344f, 220.f, 233.081879f, 246.94165f, 261.62558f, 277.182617f, 293.664764f, 311.126984f, 329.627563f, 349.228241f, 369.994415f, 391.995422f, 415.304688f, 440.f, 466.163757f, 493.883301f, 523.25116f, 554.365234f, 587.329529f, 622.253967f, 659.255127f, 698.456482f, 739.988831f, 783.990845f, 830.609375f, 880.f, 932.327515f, 987.766602f, 1046.502319f, 1108.730469f, 1174.659058f, 1244.507935f, 1318.510254f, 1396.912964f, 1479.977661f, 1567.981689f, 1661.21875f, 1760.f, 1864.655029f, 1975.533203f, 2093.004639f, 2217.460938f, 2349.318115f, 2489.015869f, 2637.020508f, 2793.825928f, 2959.955322f, 3135.963379f, 3322.4375f, 3520.f, 3729.31f, 3951.066406f, 4186.009277f, 4434.921875f, 4698.63623f, 4978.031738f, 5274.041016f, 5587.651855f, 5919.910645f, 6271.926758f, 6644.875f, 7040.f, 7458.620117f, 7902.132812f, 8372.018555f, 8869.84375f, 9397.272461f, 9956.063477f, 10548.082031f, 11175.303711f, 11839.821289f, 12543.853516f, 13289.75f
    };

    private AudioThread audioThread;
    private PApplet processing;

    public Maxim (PApplet processing) {
	this.processing = processing;
	sampleRate = 44100f;
	audioThread = new AudioThread(sampleRate, 4096, false);
	audioThread.start();
	    
    }

    public float[] getPowerSpectrum() {
	return audioThread.getPowerSpectrum();
    }

    /** 
     *  load the sent file into an audio player and return it. Use
     *  this if your audio file is not too long want precision control
     *  over looping and play head position
     * @param String filename - the file to load
     * @return AudioPlayer - an audio player which can play the file
     */
    public AudioPlayer loadFile(String filename) {
	// this will load the complete audio file into memory
	AudioPlayer ap = new AudioPlayer(filename, sampleRate, processing);
	audioThread.addAudioGenerator(ap);
	// now we need to tell the audiothread
	// to ask the audioplayer for samples
	return ap;
    }

    /**
     * Create a wavetable player object with a wavetable of the sent
     * size. Small wavetables (<128) make for a 'nastier' sound!
     * 
     */
    public WavetableSynth createWavetableSynth(int size) {
	// this will load the complete audio file into memory
	WavetableSynth ap = new WavetableSynth(size, sampleRate);
	audioThread.addAudioGenerator(ap);
	// now we need to tell the audiothread
	// to ask the audioplayer for samples
	return ap;
    }
    // /**
    //  * Create an AudioStreamPlayer which can stream audio from the
    //  * internet as well as local files.  Does not provide precise
    //  * control over looping and playhead like AudioPlayer does.  Use this for
    //  * longer audio files and audio from the internet.
    //  */
    // public AudioStreamPlayer createAudioStreamPlayer(String url) {
    //     AudioStreamPlayer asp = new AudioStreamPlayer(url);
    //     return asp;
    // }
}




/**
 * This class can play audio files and includes an fx chain 
 */
public class AudioPlayer implements Synth, AudioGenerator {
    private FXChain fxChain;
    private boolean isPlaying;
    private boolean isLooping;
    private boolean analysing;
    private FFT fft;
    private int fftInd;
    private float[] fftFrame;
    private float[] powerSpectrum;

    //private float startTimeSecs;
    //private float speed;
    private int length;
    private short[] audioData;
    private float startPos;
    private float readHead;
    private float dReadHead;
    private float sampleRate;
    private float masterVolume;

    float x1, x2, y1, y2, x3, y3;

    public AudioPlayer(float sampleRate) {
	fxChain = new FXChain(sampleRate);
	this.sampleRate = sampleRate;
    }

    public AudioPlayer (String filename, float sampleRate, PApplet processing) {
	//super(filename);
	this(sampleRate);
	try {
	    // how long is the file in bytes?
	    //long byteCount = getAssets().openFd(filename).getLength();
	    File f = new File(processing.dataPath(filename));
	    long byteCount = f.length();
	    //System.out.println("bytes in "+filename+" "+byteCount);

	    // check the format of the audio file first!
	    // only accept mono 16 bit wavs
	    //InputStream is = getAssets().open(filename); 
	    BufferedInputStream bis = new BufferedInputStream(new FileInputStream(f));

	    // chop!!

	    int bitDepth;
	    int channels;
	    boolean isPCM;
	    // allows us to read up to 4 bytes at a time 
	    byte[] byteBuff = new byte[4];

	    // skip 20 bytes to get file format
	    // (1 byte)
	    bis.skip(20);
	    bis.read(byteBuff, 0, 2); // read 2 so we are at 22 now
	    isPCM = ((short)byteBuff[0]) == 1 ? true:false; 
	    //System.out.println("File isPCM "+isPCM);

	    // skip 22 bytes to get # channels
	    // (1 byte)
	    bis.read(byteBuff, 0, 2);// read 2 so we are at 24 now
	    channels = (short)byteBuff[0];
	    //System.out.println("#channels "+channels+" "+byteBuff[0]);
	    // skip 24 bytes to get sampleRate
	    // (32 bit int)
	    bis.read(byteBuff, 0, 4); // read 4 so now we are at 28
	    sampleRate = bytesToInt(byteBuff, 4);
	    //System.out.println("Sample rate "+sampleRate);
	    // skip 34 bytes to get bits per sample
	    // (1 byte)
	    bis.skip(6); // we were at 28...
	    bis.read(byteBuff, 0, 2);// read 2 so we are at 36 now
	    bitDepth = (short)byteBuff[0];
	    //System.out.println("bit depth "+bitDepth);
	    // convert to word count...
	    bitDepth /= 8;
	    // now start processing the raw data
	    // data starts at byte 36
	    int sampleCount = (int) ((byteCount - 36) / (bitDepth * channels));
	    audioData = new short[sampleCount];
	    int skip = (channels -1) * bitDepth;
	    int sample = 0;
	    // skip a few sample as it sounds like shit
	    bis.skip(bitDepth * 4);
	    while (bis.available () >= (bitDepth+skip)) {
		bis.read(byteBuff, 0, bitDepth);// read 2 so we are at 36 now
		//int val = bytesToInt(byteBuff, bitDepth);
		// resample to 16 bit by casting to a short
		audioData[sample] = (short) bytesToInt(byteBuff, bitDepth);
		bis.skip(skip);
		sample ++;
	    }

	    float secs = (float)sample / (float)sampleRate;
	    //System.out.println("Read "+sample+" samples expected "+sampleCount+" time "+secs+" secs ");      
	    bis.close();


	    // unchop
	    readHead = 0;
	    startPos = 0;
	    // default to 1 sample shift per tick
	    dReadHead = 1;
	    isPlaying = false;
	    isLooping = true;
	    masterVolume = 1;
	} 
	catch (FileNotFoundException e) {

	    e.printStackTrace();
	}
	catch (IOException e) {
	    e.printStackTrace();
	}
    }

    public void setAnalysing(boolean analysing_) {
	this.analysing = analysing_;
	if (analysing) {// initialise the fft
	    fft = new FFT();
	    fftInd = 0;
	    fftFrame = new float[1024];
	    powerSpectrum = new float[fftFrame.length/2];
	}
    }

    public float getAveragePower() {
	if (analysing) {
	    // calc the average
	    float sum = 0;
	    for (int i=0;i<powerSpectrum.length;i++){
		sum += powerSpectrum[i];
	    }
	    sum /= powerSpectrum.length;
	    return sum;
	}
	else {
	    System.out.println("call setAnalysing to enable power analysis");
	    return 0;
	}
    }
    public float[] getPowerSpectrum() {
	if (analysing) {
	    return powerSpectrum;
	}
	else {
	    System.out.println("call setAnalysing to enable power analysis");
	    return null;
	}
    }

    /** 
     *convert the sent byte array into an int. Assumes little endian byte ordering. 
     *@param bytes - the byte array containing the data
     *@param wordSizeBytes - the number of bytes to read from bytes array
     *@return int - the byte array as an int
     */
    private int bytesToInt(byte[] bytes, int wordSizeBytes) {
	int val = 0;
	for (int i=wordSizeBytes-1; i>=0; i--) {
	    val <<= 8;
	    val |= (int)bytes[i] & 0xFF;
	}
	return val;
    }

    /**
     * Test if this audioplayer is playing right now
     * @return true if it is playing, false otherwise
     */
    public boolean isPlaying() {
	return isPlaying;
    }

    /**
     * Set the loop mode for this audio player
     * @param looping 
     */
    public void setLooping(boolean looping) {
	isLooping = looping;
    }

    /**
     * Move the start pointer of the audio player to the sent time in ms
     * @param timeMs - the time in ms
     */
    public void cue(int timeMs) {
	//startPos = ((timeMs / 1000) * sampleRate) % audioData.length;
	//readHead = startPos;
	//System.out.println("AudioPlayer Cueing to "+timeMs);
	if (timeMs >= 0) {// ignore crazy values
	    readHead = (((float)timeMs / 1000f) * sampleRate) % audioData.length;
	    //System.out.println("Read head went to "+readHead);
	}
    }

    /**
     *  Set the playback speed,
     * @param speed - playback speed where 1 is normal speed, 2 is double speed
     */
    public void speed(float speed) {
	//System.out.println("setting speed to "+speed);
	dReadHead = speed;
    }

    /**
     * Set the master volume of the AudioPlayer
     */

    public void volume(float volume) {
	masterVolume = volume;
    }

    /**
     * Get the length of the audio file in samples
     * @return int - the  length of the audio file in samples
     */
    public int getLength() {
	return audioData.length;
    }
    /**
     * Get the length of the sound in ms, suitable for sending to 'cue'
     */
    public float getLengthMs() {
	return ((float) audioData.length / sampleRate * 1000f);
    }

    /**
     * Start playing the sound. 
     */
    public void play() {
	isPlaying = true;
    }

    /**
     * Stop playing the sound
     */
    public void stop() {
	isPlaying = false;
    }

    /**
     * implementation of the AudioGenerator interface
     */
    public short getSample() {
	if (!isPlaying) {
	    return 0;
	}
	else {
	    short sample;
	    readHead += dReadHead;
	    if (readHead > (audioData.length - 1)) {// got to the end
		//% (float)audioData.length;
		if (isLooping) {// back to the start for loop mode
		    readHead = readHead % (float)audioData.length;
		}
		else {
		    readHead = 0;
		    isPlaying = false;
		}
	    }

	    // linear interpolation here
	    // declaring these at the top...
	    // easy to understand version...
	    //      float x1, x2, y1, y2, x3, y3;
	    x1 = floor(readHead);
	    x2 = x1 + 1;
	    y1 = audioData[(int)x1];
	    y2 = audioData[(int) (x2 % audioData.length)];
	    x3 = readHead;
	    // calc 
	    y3 =  y1 + ((x3 - x1) * (y2 - y1));
	    y3 *= masterVolume;
	    sample = fxChain.getSample((short) y3);
	    if (analysing) {
		// accumulate samples for the fft
		fftFrame[fftInd] = (float)sample / 32768f;
		fftInd ++;
		if (fftInd == fftFrame.length - 1) {// got a frame
		    powerSpectrum = fft.process(fftFrame, true);
		    fftInd = 0;
		}
	    }

	    //return sample;
	    return (short)y3;
	}
    }

    public void setAudioData(short[] audioData) {
	this.audioData = audioData;
    }

    public short[] getAudioData() {
	return audioData;
    }

    public void setDReadHead(float dReadHead) {
	this.dReadHead = dReadHead;
    }

    ///
    //the synth interface
    // 

    public void ramp(float val, float timeMs) {
	fxChain.ramp(val, timeMs);
    } 



    public void setDelayTime(float delayMs) {
	fxChain.setDelayTime( delayMs);
    }

    public void setDelayFeedback(float fb) {
	fxChain.setDelayFeedback(fb);
    }

    public void setFilter(float cutoff, float resonance) {
	fxChain.setFilter( cutoff, resonance);
    }
}

/**
 * This class can play wavetables and includes an fx chain
 */
public class WavetableSynth extends AudioPlayer {

    private short[] sine;
    private short[] saw;
    private short[] wavetable;
    private float sampleRate;

    public WavetableSynth(int size, float sampleRate) {
	super(sampleRate);
	sine = new short[size];
	for (float i = 0; i < sine.length; i++) {
	    float phase;
	    phase = TWO_PI / size * i;
	    sine[(int)i] = (short) (sin(phase) * 32768);
	}
	saw = new short[size];
	for (float i = 0; i<saw.length; i++) {
	    saw[(int)i] = (short) (i / (float)saw.length *32768);
	}

	this.sampleRate = sampleRate;
	setAudioData(sine);
	setLooping(true);
    }

    public void setFrequency(float freq) {
	if (freq > 0) {
	    //System.out.println("freq freq "+freq);
	    setDReadHead((float)getAudioData().length / sampleRate * freq);
	}
    }

    public void loadWaveForm(float[] wavetable_) {
	if (wavetable == null || wavetable_.length != wavetable.length) {
	    // only reallocate if there is a change in length
	    wavetable = new short[wavetable_.length];
	}
	for (int i=0;i<wavetable.length;i++) {
	    wavetable[i] = (short) (wavetable_[i] * 32768);
	}
	setAudioData(wavetable);
    }
}

public interface Synth {
    public void volume(float volume);
    public void ramp(float val, float timeMs);  
    public void setDelayTime(float delayMs);  
    public void setDelayFeedback(float fb);  
    public void setFilter(float cutoff, float resonance);
    public void setAnalysing(boolean analysing);
    public float getAveragePower();
    public float[] getPowerSpectrum();
}

public class AudioThread extends Thread
{
    private int minSize;
    //private AudioTrack track;
    private short[] bufferS;
    private byte[] bOutput;
    private ArrayList audioGens;
    private boolean running;

    private FFT fft;
    private float[] fftFrame;
    private SourceDataLine sourceDataLine;
    private int blockSize;

    public AudioThread(float samplingRate, int blockSize) {
	this(samplingRate, blockSize, false);
    }

    public AudioThread(float samplingRate, int blockSize, boolean enableFFT)
    {
	this.blockSize = blockSize;
	audioGens = new ArrayList();
	// we'll do our dsp in shorts
	bufferS = new short[blockSize];
	// but we'll convert to bytes when sending to the sound card
	bOutput = new byte[blockSize * 2];
	AudioFormat audioFormat = new AudioFormat(samplingRate, 16, 1, true, false);
	DataLine.Info dataLineInfo = new DataLine.Info(SourceDataLine.class, audioFormat);
	    
	sourceDataLine = null;
	// here we try to initialise the audio system. try catch is exception handling, i.e. 
	// dealing with things not working as expected
	try {
	    sourceDataLine = (SourceDataLine) AudioSystem.getLine(dataLineInfo);
	    sourceDataLine.open(audioFormat, bOutput.length);
	    sourceDataLine.start();
	    running = true;
	} catch (LineUnavailableException lue) {
	    // it went wrong!
	    lue.printStackTrace(System.err);
	    System.out.println("Could not initialise audio. check above stack trace for more info");
	    //System.exit(1);
	}


	if (enableFFT) {
	    try {
		fft = new FFT();
	    }
	    catch(Exception e) {
		System.out.println("Error setting up the audio analyzer");
		e.printStackTrace();
	    }
	}
    }

    // overidden from Thread
    public void run() {
	running = true;
	while (running) {
	    //System.out.println("AudioThread : ags  "+audioGens.size());
	    for (int i=0;i<bufferS.length;i++) {
		// we add up using a 32bit int
		// to prevent clipping
		int val = 0;
		if (audioGens.size() > 0) {
		    for (int j=0;j<audioGens.size(); j++) {
			AudioGenerator ag = (AudioGenerator)audioGens.get(j);
			val += ag.getSample();
		    }
		    val /= audioGens.size();
		}
		bufferS[i] = (short) val;
	    }
	    // send it to the audio device!
	    sourceDataLine.write(shortsToBytes(bufferS, bOutput), 0, bOutput.length);
	}
    }
	
    public void addAudioGenerator(AudioGenerator ag) {
	audioGens.add(ag);
    }

    /**
     * converts an array of 16 bit samples to bytes
     * in little-endian (low-byte, high-byte) format.
     */
    private byte[] shortsToBytes(short[] sData, byte[] bData) {
	int index = 0;
	short sval;
	for (int i = 0; i < sData.length; i++) {
	    //short sval = (short) (fData[j][i] * ShortMaxValueAsFloat);
	    sval = sData[i];
	    bData[index++] = (byte) (sval & 0x00FF);
	    bData[index++] = (byte) ((sval & 0xFF00) >> 8);
	}
	return bData;
    }

    /**
     * Returns a recent snapshot of the power spectrum 
     */
    public float[] getPowerSpectrum() {
	// process the last buffer that was calculated
	if (fftFrame == null) {
	    fftFrame = new float[bufferS.length];
	}
	for (int i=0;i<fftFrame.length;i++) {
	    fftFrame[i] = ((float) bufferS[i] / 32768f);
	}
	return fft.process(fftFrame, true);
	//return powerSpectrum;
    }
}

/**
 * Implement this interface so the AudioThread can request samples from you
 */
public interface AudioGenerator {
    /** AudioThread calls this when it wants a sample */
    short getSample();
}


public class FXChain  {
    private float currentAmp;
    private float dAmp;
    private float targetAmp;
    private boolean goingUp;
    private Filter filter;

    private float[] dLine;   

    private float sampleRate;

    public FXChain(float sampleRate_) {
	sampleRate = sampleRate_;
	currentAmp = 1;
	dAmp = 0;
	// filter = new MickFilter(sampleRate);
	filter = new RLPF(sampleRate);

	//filter.setFilter(0.1, 0.1);
    }

    public void ramp(float val, float timeMs) {
	// calc the dAmp;
	// - change per ms
	targetAmp = val;
	dAmp = (targetAmp - currentAmp) / (timeMs / 1000 * sampleRate);
	if (targetAmp > currentAmp) {
	    goingUp = true;
	}
	else {
	    goingUp = false;
	}
    }


    public void setDelayTime(float delayMs) {
    }

    public void setDelayFeedback(float fb) {
    }

    public void volume(float volume) {
    }


    public short getSample(short input) {
	float in;
	in = (float) input / 32768;// -1 to 1

	in =  filter.applyFilter(in);
	if (goingUp && currentAmp < targetAmp) {
	    currentAmp += dAmp;
	}
	else if (!goingUp && currentAmp > targetAmp) {
	    currentAmp += dAmp;
	}  

	if (currentAmp > 1) {
	    currentAmp = 1;
	}
	if (currentAmp < 0) {
	    currentAmp = 0;
	}  
	in *= currentAmp;  
	return (short) (in * 32768);
    }

    public void setFilter(float f, float r) {
	filter.setFilter(f, r);
    }
}


// /**
//  * Represents an audio source is streamed as opposed to being completely loaded (as WavSource is)
//  */
// public class AudioStreamPlayer {
// 	/** a class from the android API*/
// 	private MediaPlayer mediaPlayer;
// 	/** a class from the android API*/
// 	private Visualizer viz; 
// 	private byte[] waveformBuffer;
// 	private byte[] fftBuffer;
// 	private byte[] powerSpectrum;

// 	/**
// 	 * create a stream source from the sent url 
// 	 */
// 	public AudioStreamPlayer(String url) {
// 	    try {
// 		mediaPlayer = new MediaPlayer();
// 		//mp.setAuxEffectSendLevel(1);
// 		mediaPlayer.setLooping(true);

// 		// try to parse the URL... if that fails, we assume it
// 		// is a local file in the assets folder
// 		try {
// 		    URL uRL = new URL(url);
// 		    mediaPlayer.setDataSource(url);
// 		}
// 		catch (MalformedURLException eek) {
// 		    // couldn't parse the url, assume its a local file
// 		    AssetFileDescriptor afd = getAssets().openFd(url);
// 		    //mp.setDataSource(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());
// 		    mediaPlayer.setDataSource(afd.getFileDescriptor());
// 		    afd.close();
// 		}

// 		mediaPlayer.prepare();
// 		//mediaPlayer.start();
// 		//System.out.println("Created audio with id "+mediaPlayer.getAudioSessionId());
// 		viz = new Visualizer(mediaPlayer.getAudioSessionId());
// 		viz.setEnabled(true);
// 		waveformBuffer = new byte[viz.getCaptureSize()];
// 		fftBuffer = new byte[viz.getCaptureSize()/2];
// 		powerSpectrum = new byte[viz.getCaptureSize()/2];
// 	    }
// 	    catch (Exception e) {
// 		System.out.println("StreamSource could not be initialised. Check url... "+url+ " and that you have added the permission INTERNET, RECORD_AUDIO and MODIFY_AUDIO_SETTINGS to the manifest,");
// 		e.printStackTrace();
// 	    }
// 	}

// 	public void play() {
// 	    mediaPlayer.start();
// 	}

// 	public int getLengthMs() {
// 	    return mediaPlayer.getDuration();
// 	}

// 	public void cue(float timeMs) {
// 	    if (timeMs >= 0 && timeMs < getLengthMs()) {// ignore crazy values
// 		mediaPlayer.seekTo((int)timeMs);
// 	    }
// 	}

// 	/**
// 	 * Returns a recent snapshot of the power spectrum as 8 bit values
// 	 */
// 	public byte[] getPowerSpectrum() {
// 	    // calculate the spectrum
// 	    viz.getFft(fftBuffer);
// 	    short real, imag;
// 	    for (int i=2;i<fftBuffer.length;i+=2) {
// 		real = (short) fftBuffer[i];
// 		imag = (short) fftBuffer[i+1];
// 		powerSpectrum[i/2] = (byte) ((real * real)  + (imag * imag));
// 	    }
// 	    return powerSpectrum;
// 	}

// 	/**
// 	 * Returns a recent snapshot of the waveform being played 
// 	 */
// 	public byte[] getWaveForm() {
// 	    // retrieve the waveform
// 	    viz.getWaveForm(waveformBuffer);
// 	    return waveformBuffer;
// 	}
// } 

/**
 * Use this class to retrieve data about the movement of the device
 */
public class Accelerometer  {
    //private SensorManager sensorManager;
    //private Sensor accelerometer;
    private float[] values;

    public Accelerometer() {
	//sensorManager = (SensorManager)getSystemService(SENSOR_SERVICE);
	//accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
	//sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
	values = new float[3];
	System.out.println("Java accelerometer will generate values of zero!");
    }

    public float[] getValues() {
	return values;
    }

    public float getX() {
	return values[0];
    }

    public float getY() {
	return values[1];
    }

    public float getZ() {
	return values[2];
    }

}

public interface Filter {
    public void setFilter(float f, float r);
    public float applyFilter(float in);
}

/** https://github.com/supercollider/supercollider/blob/master/server/plugins/FilterUGens.cpp */

public class RLPF implements Filter {
    float a0, b1, b2, y1, y2;
    float freq;
    float reson;
    float sampleRate;
    boolean changed;

    public RLPF(float sampleRate_) {
	this.sampleRate = sampleRate_;
	reset();
	this.setFilter(sampleRate / 4, 0.01f);
    }
    private void reset() {
	a0 = 0.f;
	b1 = 0.f;
	b2 = 0.f;
	y1 = 0.f;
	y2 = 0.f;
    }
    /** f is in the range 0-sampleRate/2 */
    public void setFilter(float f, float r) {
	// constrain 
	// limit to 0-1 
	f = constrain(f, 0, sampleRate/4);
	r = constrain(r, 0, 1);
	// invert so high r -> high resonance!
	r = 1-r;
	// remap to appropriate ranges
	f = map(f, 0f, sampleRate/4, 30f, sampleRate / 4);
	r = map(r, 0f, 1f, 0.005f, 2f);

	System.out.println("rlpf: f "+f+" r "+r);

	this.freq = f * TWO_PI / sampleRate;
	this.reson = r;
	changed = true;
    }

    public float applyFilter(float in) {
	float y0;
	if (changed) {
	    float D = tan(freq * reson * 0.5f);
	    float C = ((1.f-D)/(1.f+D));
	    float cosf = cos(freq);
	    b1 = (1.f + C) * cosf;
	    b2 = -C;
	    a0 = (1.f + C - b1) * .25f;
	    changed = false;
	}
	y0 = a0 * in + b1 * y1 + b2 * y2;
	y2 = y1;
	y1 = y0;
	if (Float.isNaN(y0)) {
	    reset();
	}
	return y0;
    }
}

/** https://github.com/micknoise/Maximilian/blob/master/maximilian.cpp */

class MickFilter implements Filter {

    private float f, res;
    private float cutoff, z, c, x, y, out;
    private float sampleRate;

    MickFilter(float sampleRate) {
	this.sampleRate = sampleRate;
    }

    public void setFilter(float f, float r) {
	f = constrain(f, 0, 1);
	res = constrain(r, 0, 1);
	f = map(f, 0, 1, 25, sampleRate / 4);
	r = map(r, 0, 1, 1, 25);
	this.f = f;
	this.res = r;    

	//System.out.println("mickF: f "+f+" r "+r);
    }
    public float applyFilter(float in) {
	return lores(in, f, res);
    }

    public float lores(float input, float cutoff1, float resonance) {
	//cutoff=cutoff1*0.5;
	//if (cutoff<10) cutoff=10;
	//if (cutoff>(sampleRate*0.5)) cutoff=(sampleRate*0.5);
	//if (resonance<1.) resonance = 1.;

	//if (resonance>2.4) resonance = 2.4;
	z=cos(TWO_PI*cutoff/sampleRate);
	c=2-2*z;
	float r=(sqrt(2.0f)*sqrt(-pow((z-1.0f), 3.0f))+resonance*(z-1))/(resonance*(z-1));
	x=x+(input-y)*c;
	y=y+x;
	x=x*r;
	out=y;
	return out;
    }
}


/*
 * This file is part of Beads. See http://www.beadsproject.net for all information.
 * CREDIT: This class uses portions of code taken from MPEG7AudioEnc. See readme/CREDITS.txt.
 */

/**
 * FFT performs a Fast Fourier Transform and forwards the complex data to any listeners. 
 * The complex data is a float of the form float[2][frameSize], with real and imaginary 
 * parts stored respectively.
 * 
 * @beads.category analysis
 */
public class FFT {

    /** The real part. */
    protected float[] fftReal;

    /** The imaginary part. */
    protected float[] fftImag;

    private float[] dataCopy = null;
    private float[][] features;
    private float[] powers;
    private int numFeatures;

    /**
     * Instantiates a new FFT.
     */
    public FFT() {
	features = new float[2][];
    }

    /* (non-Javadoc)
     * @see com.olliebown.beads.core.UGen#calculateBuffer()
     */
    public float[] process(float[] data, boolean direction) {
	if (powers == null) powers = new float[data.length/2];
	if (dataCopy==null || dataCopy.length!=data.length)
	    dataCopy = new float[data.length];
	System.arraycopy(data, 0, dataCopy, 0, data.length);

	fft(dataCopy, dataCopy.length, direction);
	numFeatures = dataCopy.length;
	fftReal = calculateReal(dataCopy, dataCopy.length);
	fftImag = calculateImaginary(dataCopy, dataCopy.length);
	features[0] = fftReal;
	features[1] = fftImag;
	// now calc the powers
	return specToPowers(fftReal, fftImag, powers);
    }

    public float[] specToPowers(float[] real, float[] imag, float[] powers) {
	float re, im;
	double pow;
	for (int i=0;i<powers.length;i++) {
	    //real = spectrum[i][j].re();
	    //imag = spectrum[i][j].im();
	    re = real[i];
	    im = imag[i];
	    powers[i] = (re*re + im * im);
	    powers[i] = (float) Math.sqrt(powers[i]) / 10;
	    // convert to dB
	    pow = (double) powers[i];
	    powers[i] = (float)(10 *  Math.log10(pow * pow)); // (-100 - 100)
	    powers[i] = (powers[i] + 100) * 0.005f; // 0-1
	}
	return powers;
    }

    /**
     * The frequency corresponding to a specific bin 
     * 
     * @param samplingFrequency The Sampling Frequency of the AudioContext
     * @param blockSize The size of the block analysed
     * @param binNumber 
     */
    public  float binFrequency(float samplingFrequency, int blockSize, float binNumber)
    {    
	return binNumber*samplingFrequency/blockSize;
    }

    /**
     * Returns the average bin number corresponding to a particular frequency.
     * Note: This function returns a float. Take the Math.round() of the returned value to get an integral bin number. 
     * 
     * @param samplingFrequency The Sampling Frequency of the AudioContext
     * @param blockSize The size of the fft block
     * @param freq  The frequency
     */

    public  float binNumber(float samplingFrequency, int blockSize, float freq)
    {
	return blockSize*freq/samplingFrequency;
    }

    /** The nyquist frequency for this samplingFrequency 
     * 
     * @params samplingFrequency the sample
     */
    public  float nyquist(float samplingFrequency)
    {
	return samplingFrequency/2;
    }

    /*
     * All of the code below this line is taken from Holger Crysandt's MPEG7AudioEnc project.
     * See http://mpeg7audioenc.sourceforge.net/copyright.html for license and copyright.
     */

    /**
     * Gets the real part from the complex spectrum.
     * 
     * @param spectrum
     *            complex spectrum.
     * @param length 
     *       length of data to use.
     * 
     * @return real part of given length of complex spectrum.
     */
    protected  float[] calculateReal(float[] spectrum, int length) {
	float[] real = new float[length];
	real[0] = spectrum[0];
	real[real.length/2] = spectrum[1];
	for (int i=1, j=real.length-1; i<j; ++i, --j)
	    real[j] = real[i] = spectrum[2*i];
	return real;
    }

    /**
     * Gets the imaginary part from the complex spectrum.
     * 
     * @param spectrum
     *            complex spectrum.
     * @param length 
     *       length of data to use.
     * 
     * @return imaginary part of given length of complex spectrum.
     */
    protected  float[] calculateImaginary(float[] spectrum, int length) {
	float[] imag = new float[length];
	for (int i=1, j=imag.length-1; i<j; ++i, --j)
	    imag[i] = -(imag[j] = spectrum[2*i+1]);
	return imag;
    }

    /**
     * Perform FFT on data with given length, regular or inverse.
     * 
     * @param data the data
     * @param n the length
     * @param isign true for regular, false for inverse.
     */
    protected  void fft(float[] data, int n, boolean isign) {
	float c1 = 0.5f; 
	float c2, h1r, h1i, h2r, h2i;
	double wr, wi, wpr, wpi, wtemp;
	double theta = 3.141592653589793/(n>>1);
	if (isign) {
	    c2 = -.5f;
	    four1(data, n>>1, true);
	} 
	else {
	    c2 = .5f;
	    theta = -theta;
	}
	wtemp = Math.sin(.5*theta);
	wpr = -2.*wtemp*wtemp;
	wpi = Math.sin(theta);
	wr = 1. + wpr;
	wi = wpi;
	int np3 = n + 3;
	for (int i=2,imax = n >> 2, i1, i2, i3, i4; i <= imax; ++i) {
	    /** @TODO this can be optimized */
	    i4 = 1 + (i3 = np3 - (i2 = 1 + (i1 = i + i - 1)));
	    --i4; 
	    --i2; 
	    --i3; 
	    --i1; 
	    h1i =  c1*(data[i2] - data[i4]);
	    h2r = -c2*(data[i2] + data[i4]);
	    h1r =  c1*(data[i1] + data[i3]);
	    h2i =  c2*(data[i1] - data[i3]);
	    data[i1] = (float) ( h1r + wr*h2r - wi*h2i);
	    data[i2] = (float) ( h1i + wr*h2i + wi*h2r);
	    data[i3] = (float) ( h1r - wr*h2r + wi*h2i);
	    data[i4] = (float) (-h1i + wr*h2i + wi*h2r);
	    wr = (wtemp=wr)*wpr - wi*wpi + wr;
	    wi = wi*wpr + wtemp*wpi + wi;
	}
	if (isign) {
	    float tmp = data[0]; 
	    data[0] += data[1];
	    data[1] = tmp - data[1];
	} 
	else {
	    float tmp = data[0];
	    data[0] = c1 * (tmp + data[1]);
	    data[1] = c1 * (tmp - data[1]);
	    four1(data, n>>1, false);
	}
    }

    /**
     * four1 algorithm.
     * 
     * @param data
     *            the data.
     * @param nn
     *            the nn.
     * @param isign
     *            regular or inverse.
     */
    private  void four1(float data[], int nn, boolean isign) {
	int n, mmax, istep;
	double wtemp, wr, wpr, wpi, wi, theta;
	float tempr, tempi;

	n = nn << 1;        
	for (int i = 1, j = 1; i < n; i += 2) {
	    if (j > i) {
		// SWAP(data[j], data[i]);
		float swap = data[j-1];
		data[j-1] = data[i-1];
		data[i-1] = swap;
		// SWAP(data[j+1], data[i+1]);
		swap = data[j];
		data[j] = data[i]; 
		data[i] = swap;
	    }      
	    int m = n >> 1;
	    while (m >= 2 && j > m) {
		j -= m;
		m >>= 1;
	    }
	    j += m;
	}
	mmax = 2;
	while (n > mmax) {
	    istep = mmax << 1;
	    theta = 6.28318530717959 / mmax;
	    if (!isign)
		theta = -theta;
	    wtemp = Math.sin(0.5 * theta);
	    wpr = -2.0 * wtemp * wtemp;
	    wpi = Math.sin(theta);
	    wr = 1.0;
	    wi = 0.0;
	    for (int m = 1; m < mmax; m += 2) {
		for (int i = m; i <= n; i += istep) {
		    int j = i + mmax;
		    tempr = (float) (wr * data[j-1] - wi * data[j]);  
		    tempi = (float) (wr * data[j]   + wi * data[j-1]);  
		    data[j-1] = data[i-1] - tempr;
		    data[j]   = data[i] - tempi;
		    data[i-1] += tempr;
		    data[i]   += tempi;
		}
		wr = (wtemp = wr) * wpr - wi * wpi + wr;
		wi = wi * wpr + wtemp * wpi + wi;
	    }
	    mmax = istep;
	}
    }
}



