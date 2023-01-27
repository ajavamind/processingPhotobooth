// Webcam Photobooth Application
// Copyright 2022 Andy Modla
// Build with Processing 4.0.1 SDK
// Using Processing video library version 2.2.1 with GStreamer version 1.20.3

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;

private static final boolean DEBUG = true;
String VERSION = "1.4.11";

Capture video;
private final static int NUM_BUFFERS = 2;
volatile PImage[] camImage = new PImage[NUM_BUFFERS];
volatile int camIndex = 0;
volatile int nextIndex = 1;
boolean streaming = false;

PFont font;
int fontSize;
int largeFontSize;
PhotoBoothController photoBoothController;
ImageProcessor imageProcessor;

String RENDERER = JAVA2D;
//String RENDERER = P2D;  // a bug in video library prevents this render mode from working with filters
//String RENDERER = P3D;
int renderer = 0; // JAVA2D 0, P2D 1, P3D 2
boolean runFilter = true;  // set to false when RENDERER is P2D or P3D until video library fixed
float FRAME_RATE = 24;
float delayFactor = 3;
float timeoutFactor = 3;

private static final int PREVIEW_OFF = -1;
private static final int PREVIEW = 0;
private static final int PREVIEW_END = 1;
int preview = PREVIEW_OFF; // default no preview

int legendPage = -1;
String[] legend1;
String[] legend2;
String[][] legend;

String[] cameras = null;
int cameraIndex = 0;
boolean showCameras = false;
boolean screenMask = true;
boolean screenshot = false;
int screenshotCounter = 1;

public void setup() {
  //fullScreen(RENDERER);
  //size(1080, 1920, RENDERER);  // for debug
  size(1920, 1080, RENDERER);  // for debug
  //size(3840, 2160, RENDERER);  // for debug

  initConfig();

  screenWidth = width;
  screenHeight = height;
  if (DEBUG) println("screenWidth="+screenWidth + " screenHeight="+screenHeight);
  //text("Checking for camera connection", 20, height/2);													
  photoBoothController = new PhotoBoothController();
  intializeMulti(ipAddress);  // address of a device on this private network
  frameRate(FRAME_RATE);
  smooth();
  font = loadFont("SansSerif-64.vlw");
  textFont(font);
  if (screenWidth >= 3840) {
    fontSize = 96;
  } else if (screenWidth >= 1920) {
    fontSize = 48;
  } else if (screenWidth >= 960) {
    fontSize = 24;
  } else {
    fontSize = 24;
  }
  textSize(fontSize);
  largeFontSize = 6*fontSize;

  legend1 = loadStrings("keyLegend.txt");
  legend2 = loadStrings("keyLegend2.txt");
  legend = new String[][] { legend1, legend2};

  if (OUTPUT_FOLDER_PATH.equals("output")) {  // default
    //OUTPUT_FOLDER_PATH = sketchPath() + File.separator + "output";
    OUTPUT_FOLDER_PATH = sketchPath("output");
  } else {
  }
  if (DEBUG) println("OUTPUT_FOLDER_PATH="+OUTPUT_FOLDER_PATH);

  // get list of cameras connected
  boolean camAvailable = false;
  cameraIndex = 0;  // default camera index
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
    video = null;
  } else {
    if (DEBUG) println("Available cameras:");
    camAvailable = true;
    for (int i = 0; i < cameras.length; i++) {
      if (DEBUG) println(cameras[i]+" "+i);
      if (cameras[i].equals(cameraName)) {
        cameraIndex = i;
      }
    }

    if (DEBUG) println("Found Camera: "+cameras[cameraIndex]+".");

    //String dev = cameras[cameraIndex].substring(0,cameras[cameraIndex].lastIndexOf(" #"));
    //println(dev+".");
    //String dev = cameras[cameraIndex];
    //String[] features = Capture.getCapabilities(dev);
    //if (DEBUG) printArray(features);

    // replace index number in PIPELINE
    //pipeline = pipeline.replaceFirst("device-index=0", "device-index="+str(cameraIndex));
    // The camera can be initialized directly using an
    // element from the array returned by list()
    // default first camera found at index 0
    if (camAvailable) {

      //video = new Capture(this, cameras[cameraIndex]);  // using default pipeline only captured low resolution of camera example 640x480 for HD Pro Webcam C920
      // pipeline for windows 10 - captures full HD 1920x1080 for HD Pro Webcam C920

      if (pipeline != null) {
        video = new Capture(this, cameraWidth, cameraHeight, pipeline);
        if (DEBUG) println("Using PIPELINE=" + pipeline);
      } else {
        video= new Capture(this, cameraWidth, cameraHeight, cameras[cameraIndex]);
        if (DEBUG) println("Using camera: " + cameras[cameraIndex] );
      }
      video.start();
    }
  }

  noStroke();
  noCursor();
  background(0);

  imageProcessor = new ImageProcessor();

  // force focus on window so that key input always works without a mouse
  if (buildMode == JAVA_MODE) {
    try {
      if (RENDERER.equals(P2D)) {
        ((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
        delayFactor = 3;
        timeoutFactor = 3;
        renderer = 1;
        runFilter = false;   // temporary until video library fixes bug
        if (DEBUG) println("No Filter!");
      } else if (RENDERER.equals(P3D)) {
        ((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
        delayFactor = 3;
        timeoutFactor = 3;
        renderer = 2;
        runFilter = false;   // temporary until video library fixes bug
        if (DEBUG) println("No Filter!");
      } else {
        ((java.awt.Canvas) surface.getNative()).requestFocus();  // for JAVA2D (default)
        delayFactor = .66;
        timeoutFactor = 3;
        renderer = 0;
      }
    }
    catch (Exception ren) {
      println("Renderer: "+RENDERER+ " Window focus exception: " + ren.toString());
      renderer = 0;
    }
  }
  photoBoothController.setTimeouts(delayFactor, timeoutFactor);
  surface.setTitle(titleText);
  if (DEBUG) println("Renderer: "+RENDERER);
  if (DEBUG) println("delayFactor = "+delayFactor+" timeoutFactor="+timeoutFactor);

  if (DEBUG) println("finished setup()");
}

void captureEvent(Capture camera) {
  image(camera, 0, 0, 0, 0);  // work around for P2D and P3D Capture buffer not loaded
  camera.read();
  if (renderer > 0) { // P2D and P3D
    camera.loadPixels(); // needed for P2D. P3D
    camImage[nextIndex] = camera;
  } else {  // JAVA2D
    camImage[nextIndex] = camera.copy();
  }

  camIndex = nextIndex;
  nextIndex++;
  nextIndex = nextIndex & 1; // alternating 2 buffers
  streaming = true;
}

public void draw() {
  //System.gc();
  // process any inputs to steer operation drawing the display
  int command = keyUpdate(); // decode key inputs received on threads outside the draw thread loop

  if (legendPage >= 0) {
    background(0);
    drawLegend(legend[legendPage]);
    saveScreenshot();
    return;
  }

  if (showCameras && cameras != null) {
    background(0);
    drawCameraList();
    saveScreenshot();
    return;
  }

  if (video == null) {
    background(0);
    fill(255);
    text("No Cameras Available. ", 10, screenHeight/2);
    text("Check camera connection or other applications using the camera.", 10, screenHeight/2+screenHeight/16);
    text("Press Q Key to Exit.", 10, screenHeight/2+ screenHeight/8);
    if (command == ENTER) {
      exit();
    }
    saveScreenshot();
    return;
  }

  // wait for video buffered image
  if (!streaming) return;

  if (photoBoothController.endPhotoShoot) {
    photoBoothController.oldShoot(); // show result
  } else {
    if (preview != PREVIEW_OFF) {
      photoBoothController.drawLast();
    } else {
      photoBoothController.processImage(camImage[camIndex]);
    }
    drawText();  //  TODO make PGraphic
    if (photoBoothController.isPhotoShoot) {
      photoBoothController.drawPhotoShoot();
    }
  }
  // Drawing finished, check for screenshot
  saveScreenshot();
}

void drawLegend(String[] legend) {
  fill(255);
  int vertOffset = fontSize;
  int horzOffset = 20;

  for (int i=0; i<legend.length; i++) {
    if (i==0) {
      text(legend[i] + " Version: "+ VERSION, horzOffset, vertOffset*(i+1));
    }
    text(legend[i], horzOffset, vertOffset*(i+1));
  }
}

void drawCameraList() {
  fill(255);
  int vertOffset = fontSize;
  int horzOffset = 20;
  int i = 0;
  String appd = "";
  if (cameras.length == 0) {
    appd = "No Cameras Available";
    text(appd, horzOffset, vertOffset*(i+1));
  } else {
    while ( i < cameras.length) {
      appd = "";
      if (cameraIndex == i) appd = " selected";
      text(cameras[i]+appd, horzOffset, vertOffset*(i+1));
      i++;
    }
  }
  i++;
  text("mirror="+(mirror==true ? "ON": "OFF"), horzOffset, vertOffset*(i++));
  text("orientation="+(orientation==LANDSCAPE ? "LANDSCAPE":"PORTRAIT"), horzOffset, vertOffset*(i++));
  text("multiCamEnabled=" + multiCamEnabled, horzOffset, vertOffset*(i++));
  text("Broadcast IPAddress="+ broadcastIpAddress, horzOffset, vertOffset*(i++));
  text("doubleTrigger="+doubleTrigger, horzOffset, vertOffset*(i++));
  text("doubleTriggerDelay="+doubleTriggerDelay+" ms", horzOffset, vertOffset*(i++));
}

// Draw instruction and event text on screen
void drawText() {
  fill(128);
  if (preview == PREVIEW_OFF) {
    float angleText;
    float tw;
    if (orientation == LANDSCAPE) {
      pushMatrix();
      tw = textWidth(instructionLineText);
      translate(screenWidth/2- tw/2, screenHeight/24);
      text(instructionLineText, 0, 0);
      popMatrix();

      pushMatrix();
      tw = textWidth(eventText);
      translate(screenWidth/2- tw/2, screenHeight-screenHeight/32);
      text(eventText, 0, 0);
      popMatrix();
    } else {
      angleText = radians(270);
      tw = textWidth(instructionLineText);
      pushMatrix();
      translate(screenWidth/32, screenHeight/2+tw/2);
      rotate(angleText);
      text(instructionLineText, 0, 0);
      popMatrix();

      tw = textWidth(eventText);
      pushMatrix();
      translate(screenWidth-screenWidth/32, screenHeight/2+tw/2);
      rotate(angleText);
      text(eventText, 0, 0);
      popMatrix();
    }
  }
}

void saveScreenshot() {
  if (screenshot) {
    screenshot = false;
    saveScreen(OUTPUT_FOLDER_PATH, "screenshot_", number(screenshotCounter), "png");
    if (DEBUG) println("save "+ "screenshot_" + number(screenshotCounter));
    screenshotCounter++;
  }
}

// Save image of the composite screen
void saveScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

String getDateTime() {
  Date current_date = new Date();
  String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(current_date);
  return timeStamp;
}

// calls exiftool exe in the path
// sets portrait orientation by rotate camera left
void setEXIF(String filename) {
  try {
    Process process = Runtime.getRuntime().exec("exiftool -n -orientation=6 "+filename);
    process.waitFor();
  }
  catch (Exception ex) {
  }
}

// calls printPhoto.bat in the sketch path
void printPhoto(String filenamePath) {
  if (filenamePath == null) return;
  try {
    if (DEBUG) println("process "+sketchPath() + File.separator + "printPhoto.bat "+ filenamePath);
    Process process = Runtime.getRuntime().exec(sketchPath()+ File.separator + "printPhoto.bat "+filenamePath);
    process.waitFor();
  }
  catch (Exception ex) {
  }
}

void stop() {
  if (DEBUG) println("stop");
  video.stop();
  super.stop();
}

// Add leading zeroes to number
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
