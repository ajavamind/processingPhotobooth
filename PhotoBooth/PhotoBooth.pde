// Modified for a webcam
// Andy Modla 2022

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;

String OUTPUT_FILENAME = "IMG_";
String OUTPUT_COMPOSITE_FILENAME = "COM_";
String OUTPUT_FOLDER_PATH="output";
String FILE_TYPE = "jpg";

String CAMERA_NAME = "HD Pro Webcam C920";
String CAMERA_NAME1 = "USB Camera";
 // Pipeline G-Steamer for Windows 10
String PIPELINE = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";

Capture cam;
int SCREEN_WIDTH = 3840;
int SCREEN_HEIGHT = 2160;
int CAMERA_WIDTH = 1920;
int CAMERA_HEIGHT = 1080;

int dividerSize = 5;
int COUNTDOWN_START = 3;
PFont font;
int fontSize;
PhotoBoothController photoBoothController;
int numberOfPanels = 4;

void settings() {
  fullScreen();
  //size(1920, 1080);
  //size(2400, 1080);  // TODO needs aspect ratio adjustment for camera
  //size(3200, 1440);  // TODO needs aspect ratio adjustment for camera
  //size(960, 540);
}

void setup() {
  SCREEN_WIDTH = width;
  SCREEN_HEIGHT = height;
  photoBoothController = new PhotoBoothController();
  frameRate(15);
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

  OUTPUT_FOLDER_PATH = sketchPath() + "Output";
  println("OUTPUT_FOLDER_PATH="+OUTPUT_FOLDER_PATH);

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
    println("There are no cameras available for capture.");
    //exit();
  } else {
    println("Available cameras:");
    camAvailable = true;
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]+" "+i);
      if (cameras[i].equals(CAMERA_NAME)) {
        cameraIndex = i;
      }
    }
    
    println("Using Camera: "+cameras[cameraIndex]);

    // replace index number in PIPELINE
    PIPELINE = PIPELINE.replaceFirst("device-index=0", "device-index="+str(cameraIndex));
    // The camera can be initialized directly using an 
    // element from the array returned by list()
    // default first camera found at index 0
    if (camAvailable) {
      //cam = new Capture(this, cameras[cameraIndex]);  // default pipeline only captures low resolution of camera example 640x480 for HD Pro Webcam C920
      // pipeline for windows 10 only - captures full HD 1920x1080 for HD Pro Webcam C920
      cam = new Capture(this, CAMERA_WIDTH, CAMERA_HEIGHT, PIPELINE); 
      cam.start();
    }
  }      

  noStroke();
  background(0);
  drawDivider(numberOfPanels);
}

void draw() {
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
    if (photoBoothController.isPhotoShoot) {
      photoBoothController.drawPhotoShoot();
    }
  } else {
    photoBoothController.oldShoot();
  }
}

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

void saveImages(PImage[] images, String outputFolderPath, String outputFilename, String suffix, String filetype) {
  for (int i=0; i<numberOfPanels; i++) {
    images[i].save(outputFolderPath + File.separator + outputFilename + suffix +"_"+ i + "." + filetype);
  }
}

void saveCompositeScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

String getDateTime() {
  Date current_date = new Date();
  String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(current_date);
  return timeStamp;
}


void stop() {
  println("stop");
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
