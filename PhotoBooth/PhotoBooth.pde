// Webcam Photobooth
// Copyright 2022 Andy Modla
// Build with Processing 4.0.1
// Uses Processing video library version 2.2.1 with GStreamer version 1.20.3

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;

private static final boolean DEBUG = true;
String VERSION = "1.4.1";

Capture video;
private final static int NUM_BUFFERS = 2;
volatile PImage[] camImage = new PImage[NUM_BUFFERS];
volatile int camIndex = 0;
volatile int nextIndex = 1;

PFont font;
int fontSize;
int largeFontSize;
PhotoBoothController photoBoothController;
ImageProcessor imageProcessor;
String RENDERER = JAVA2D;
//String RENDERER = P2D;  // a bug in video library prevents this render mode from working
//String RENDERER = P3D;


private static final int PREVIEW_OFF = -1;
private static final int PREVIEW = 0;
private static final int PREVIEW_END = 1;
int preview = PREVIEW_OFF; // default no preview
boolean showLegend = false;
String[] legend;

public void setup() {
  initConfig();
  fullScreen(RENDERER);
  // size(1920, 1080, RENDERER);  // for debug

  screenWidth = width;
  screenHeight = height;
  //text("Checking for camera connection", 20, height/2);													
  if (DEBUG) println("screenWidth="+screenWidth+" screenHeight="+screenHeight);
  photoBoothController = new PhotoBoothController();
  frameRate(60);
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

  legend = loadStrings("keyLegend.txt");

  if (OUTPUT_FOLDER_PATH.equals("output")) {  // default
    //OUTPUT_FOLDER_PATH = sketchPath() + File.separator + "output";
    OUTPUT_FOLDER_PATH = sketchPath("output");
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

    if (DEBUG) println("Using Camera: "+cameras[cameraIndex+cameraNumber]);

    // replace index number in PIPELINE
    pipeline = pipeline.replaceFirst("device-index=0", "device-index="+str(cameraIndex));
    // The camera can be initialized directly using an
    // element from the array returned by list()
    // default first camera found at index 0
    if (camAvailable) {

      //video = new Capture(this, cameras[cameraIndex]);  // using default pipeline only captured low resolution of camera example 640x480 for HD Pro Webcam C920
      // pipeline for windows 10 - captures full HD 1920x1080 for HD Pro Webcam C920

      //video = new Capture(this, cameraWidth, cameraHeight, pipeline);
      //if (DEBUG) println("PIPELINE="+pipeline);
      video= new Capture(this, cameraWidth, cameraHeight, cameras[cameraIndex+cameraNumber]);
      if (DEBUG) println("Not using pipeline set");

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
      if (RENDERER.equals(P2D) || RENDERER.equals(P3D)) {
        ((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
      } else {
        ((java.awt.Canvas) surface.getNative()).requestFocus();  // for JAVA2D (default)
      }
    }
    catch (Exception ren) {
      println("Renderer: "+RENDERER+ " Window focus exception: " + ren.toString());
    }
  }
  surface.setTitle(titleText);
  if (DEBUG) println("Renderer: "+RENDERER);
  if (DEBUG) println("finished setup()");
}

void captureEvent(Capture camera) {
  camera.read();
  // buffer captured video frame
  if (RENDERER.equals(P2D) || RENDERER.equals(P3D)) {
    PImage temp = createImage(camera.width, camera.height, RGB);
    camera.loadPixels();
    arrayCopy(camera.pixels, temp.pixels);
    camImage[nextIndex] = temp;
  } else {
    camImage[nextIndex] = camera.copy();
  }

  camIndex = nextIndex;
  nextIndex++;
  nextIndex = nextIndex & 1; // alternating 2 buffers
}

public void draw() {
  // process any inputs to steer operation drawing the display
  int command = keyUpdate(); // decode key inputs received on threads outside the draw thread loop
  if (showLegend) {
    background(0);
    drawLegend();
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
    return;
  }

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
}

void drawLegend() {
  int vertOffset = fontSize;
  int horzOffset = 20;
  for (int i=0; i<legend.length; i++) {
    if (i==0) {
      text(legend[i] + " Version: "+ VERSION, horzOffset, vertOffset*(i+1));
    }
    text(legend[i], horzOffset, vertOffset*(i+1));
  }
}

// Draw instruction and event text on screen
void drawText() {
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
