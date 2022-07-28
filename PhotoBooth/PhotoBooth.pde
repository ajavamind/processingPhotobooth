// Modified for a webcam
// Andy Modla 2022

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;


Capture cam;
PImage camImage;

int SCREEN_WIDTH = 3840;
int SCREEN_HEIGHT = 2160;

int dividerSize = 5;
PFont font;
int fontSize;
PhotoBoothController photoBoothController;
ImageProcessor imageProcessor;

public void settings() {
  fullScreen();  // 16:9 aspect ratio assumption
  //  // testing sizes
  //  //  size(3840, 2160, P2D);
  //  //  size(1920,1080,P2D);
  //  //  //size(1920, 1080, P2D);
  //  //  //size(2400, 1080, P2D);  // TODO needs aspect ratio adjustment for camera
  //  //  //size(3200, 1440, P2D);  // TODO needs aspect ratio adjustment for camera
  //  //  //size(960, 540, P2D);
}

public void setup() {
  //size(1920, 1080);
  initConfig();
  SCREEN_WIDTH = width;
  SCREEN_HEIGHT = height;
  photoBoothController = new PhotoBoothController();
  frameRate(30);
  smooth();
  font = loadFont("SansSerif-64.vlw");
  textFont(font); 
  if (SCREEN_WIDTH >= 3840) {
    fontSize = 192;
  } else if (SCREEN_WIDTH >= 1920) {
    fontSize = 96;
  } else if (SCREEN_WIDTH >= 960) {
    fontSize = 48;
  } else {
    fontSize = 24;
  }
  textSize(fontSize);

  if (OUTPUT_FOLDER_PATH.equals("output")) {  // default
    OUTPUT_FOLDER_PATH = sketchPath() + File.separator + "output";
  } else {
  }
  if (DEBUG) println("OUTPUT_FOLDER_PATH="+OUTPUT_FOLDER_PATH);

  // get list of cameras connected
  String[] cameras = null;
  boolean camAvailable = false;
  int cameraIndex = 0;
  int retrys = 10;
  while (!camAvailable && retrys > 0) {
    try {
      cameras = Capture.list();
      retrys--;
    } 
    catch (Exception ex) {
      cameras = null;
    }
    if (cameras != null && cameras.length > 0) {
      break;
    }
    delay(200); // wait 200 Ms
  }

  if (cameras == null || cameras.length == 0) {
    if (DEBUG) println("There are no cameras available for capture.");
    //exit();
  } else {
    if (DEBUG) println("Available cameras:");
    camAvailable = true;
    for (int i = 0; i < cameras.length; i++) {
      if (DEBUG) println(cameras[i]+" "+i);
      if (cameras[i].equals(cameraName)) {
        cameraIndex = i;
      }
    }

    if (DEBUG) println("Using Camera: "+cameras[cameraIndex]);

    // replace index number in PIPELINE
    pipeline = pipeline.replaceFirst("device-index=0", "device-index="+str(cameraIndex));
    // The camera can be initialized directly using an 
    // element from the array returned by list()
    // default first camera found at index 0
    if (camAvailable) {

      //cam = new Capture(this, cameras[cameraIndex]);  // using default pipeline only captured low resolution of camera example 640x480 for HD Pro Webcam C920
      // pipeline for windows 10 - captures full HD 1920x1080 for HD Pro Webcam C920
      cam = new Capture(this, cameraWidth, cameraHeight, pipeline); 
      if (DEBUG) println("PIPELINE="+pipeline);
      cam.start();
    }
  }      

  noStroke();
  noCursor();
  background(0);
  drawDivider(numberOfPanels);
  imageProcessor = new ImageProcessor();

  // force focus on window so that key input always works without a mouse
  //((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
  ((java.awt.Canvas) surface.getNative()).requestFocus();  // for JAVA2D (default)
  if (DEBUG) println("finished setup()");
}

public void draw() {
  int command = keyUpdate(); // decode key inputs received on threads outside the draw thread loop  

  if (cam == null) {
    fill(255);
    text("No Camera Available", 10, SCREEN_HEIGHT/2);
    return;
  }

  if (cam.available() == true) {
    cam.read();
  }

  if (!photoBoothController.endPhotoShoot) { 
    photoBoothController.processImage(cam);
    text(instructionLineText, SCREEN_WIDTH/2- SCREEN_WIDTH/8, SCREEN_HEIGHT/16);
    text(eventText, SCREEN_WIDTH/4, SCREEN_HEIGHT-SCREEN_HEIGHT/32);
    if (photoBoothController.isPhotoShoot) {
      photoBoothController.drawPhotoShoot();
    }
  } else {
    photoBoothController.oldShoot();
  }
}

//void captureEvent(Capture c) {
//  cam.read();
//}

void drawDivider(int numberOfPanels) {
  fill(255);
  if (numberOfPanels == 4) {
    rect(0, SCREEN_HEIGHT/2, SCREEN_WIDTH, dividerSize);
    rect(SCREEN_WIDTH/2, 0, dividerSize, SCREEN_HEIGHT);
  } else if (numberOfPanels == 2) {
    rect(SCREEN_WIDTH/2, 0, dividerSize, SCREEN_HEIGHT);
  } else {
    // one panel assumed
  }
}

// Save images chosen
void saveImages(PImage[] images, String outputFolderPath, String outputFilename, String suffix, String filetype) {
  for (int i=0; i<numberOfPanels; i++) {
    images[i].save(outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(i+1) + "." + filetype);
  }
}

// Save image of the composite screen
void saveCompositeScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

// Save composite from original images 
void saveCompositeOriginal(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  // TODO
}

String getDateTime() {
  Date current_date = new Date();
  String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(current_date);
  return timeStamp;
}


void stop() {
  if (DEBUG) println("stop");
  cam.stop();
  super.stop();
}

String number(int index) {
  // fix size of index number at 4 characters long
  if (index == 0)
    return "";
  else if (index < 10)
    return ("000" + String.valueOf(index));
  else if (index < 100)
    return ("00" + String.valueOf(index));
  else if (index < 1000)
    return ("0" + String.valueOf(index));
  return String.valueOf(index);
}
