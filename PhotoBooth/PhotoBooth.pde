// Modified for a webcam
// Andy Modla 2022

import processing.video.*;

String OUTPUT_FILENAME = "IMG_";
String OUTPUT_COMPOSITE_FILENAME = "COM_";
String OUTPUT_FOLDER_PATH="output";
String FILE_TYPE = "jpg";

Capture cam;
int SCREEN_WIDTH = 3840;
int SCREEN_HEIGHT = 2160;
int CAMERA_WIDTH = 1920;
int CAMERA_HEIGHT = 1080;

int dividerSize = 5;
PFont font;
PhotoBoothController photoBoothController;

void settings() {
  fullScreen();
}

void setup() {
  SCREEN_WIDTH = width;
  SCREEN_HEIGHT = height;
  photoBoothController = new PhotoBoothController();
  frameRate(15);
  smooth();
  font = loadFont("SansSerif-64.vlw"); 
  textFont(font); 
  textSize(192);
  OUTPUT_FOLDER_PATH = sketchPath() + "output";
  println("OUTPUT_FOLDER_PATH="+OUTPUT_FOLDER_PATH);
  
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    //exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]+" "+i);
    }

    // The camera can be initialized directly using an 
    // element from the array returned by list()

    //cam = new Capture(this, cameras[0]);
    // pipeline for windows 10 only;
    cam = new Capture(this, CAMERA_WIDTH, CAMERA_HEIGHT, "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert");  // for Windows 10
    cam.start();
  }      

  noStroke();
  //  from processingPhotobooth.pde
  background(0);
  drawDivider();
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
    //  depth = kinect.getRawDepth();
    //    photoBoothController.drawPrevious();
    photoBoothController.processImage(cam);
    if (photoBoothController.isPhotoShoot) {
      photoBoothController.drawPhotoShoot();
    }
  } else {
    photoBoothController.oldShoot();
  }
}

void drawDivider() {
  fill(255);
  rect(0, SCREEN_HEIGHT/2, SCREEN_WIDTH, dividerSize);
  rect(SCREEN_WIDTH/2, 0, dividerSize, SCREEN_HEIGHT);
}

void saveImages(PImage[] images, String outputFolderPath, String outputFilename, String suffix, String filetype) {
  for (int i=0; i<4; i++) {
  images[i].save(outputFolderPath + File.separator + outputFilename + suffix +"_"+ i + "." + filetype);
  }
}

void saveCompositeScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

void stop() {
  println("stop");
  cam.stop();
  super.stop();
}
