// Modified for a webcam
// Copyright 2022 Andy Modla

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;

Capture cam;
PImage camImage;
PImage[] collage;
PFont font;
int fontSize;
int largeFontSize;
PhotoBoothController photoBoothController;
ImageProcessor imageProcessor;
String RENDERER = JAVA2D;  // P2D; //
boolean preview = false;

public void settings()
{
  initConfig();
  size(screenWidth, screenHeight, RENDERER);
}

public void setup() {
  surface.setTitle(titleText);
  screenWidth = width;
  screenHeight = height;
  if (DEBUG) println("screenWidth="+screenWidth+" screenHeight="+screenHeight);
  photoBoothController = new PhotoBoothController();
  frameRate(30);
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
    cam = null;
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
  //noCursor();
  background(0);
  //drawDivider(numberOfPanels);
  collage = new PImage[4];
  imageProcessor = new ImageProcessor();

  // force focus on window so that key input always works without a mouse
  if (buildMode == JAVA_MODE) {
    if (RENDERER.equals(P2D) || RENDERER.equals(P3D)) {
      ((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
    } else {
      ((java.awt.Canvas) surface.getNative()).requestFocus();  // for JAVA2D (default)
    }
  }
  if (DEBUG) println("finished setup()");
}

public void draw() {
  // process any inputs to steer operation drawing the display
  int command = keyUpdate(); // decode key inputs received on threads outside the draw thread loop

  if (cam == null) {
    background(0);
    fill(255);
    text("No Cameras Available. ", 10, screenHeight/2);
    text("Check camera connection and other applications using the camera.", 10, screenHeight/2+screenHeight/16);
    text("Press ESC Key or Mouse Left Button to Exit.", 10, screenHeight/2+ screenHeight/8);
    if (command == ENTER) {
      exit();
    }
    return;
  }

  if (cam.available() == true) {
    cam.read();
  }

  if (!photoBoothController.endPhotoShoot) {
    if (preview) {
      photoBoothController.drawLast();
    } else {
      photoBoothController.processImage(cam);
    }
    drawText();
    if (photoBoothController.isPhotoShoot) {
      photoBoothController.drawPhotoShoot();
    }
  } else {  // show result
    photoBoothController.oldShoot();
  }
}

//void captureEvent(Capture c) {
//  cam.read();
//}

void drawText() {
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

//void drawDivider(int numberOfPanels) {
//  fill(255);
//  if (numberOfPanels == 4) {
//    rect(0, screenHeight/2, screenWidth, dividerSize);
//    rect(screenWidth/2, 0, dividerSize, screenHeight);
//  } else if (numberOfPanels == 2) {
//    rect(screenWidth/2, 0, dividerSize, screenHeight);
//  } else {
//    // one panel assumed
//  }
//}

// mask screen for 16/9 display 1920x1080 pixels to 6x4 print 1620x1080 pixels
void drawMask() {
  fill(0);
  rect(0, 0, 150, 1080);
  rect(1770, 0, 150, 1080);
  fill(255);
}

// draw mask for screen to match print image aspect ratio
// 4x6 print aspect ratio
void drawMaskForScreen( float printAspectRatio) {
  float x = 0;
  float y = 0;
  float w = (screenWidth-(screenHeight/printAspectRatio))/2.0;
  float h = screenHeight;
  fill(0);
  rect(x, y, w, h);  // left side
  rect(screenWidth-w, y, w, h);  // right side
  fill(255);

  // check for collage mode
  if (numberOfPanels == 4) {
    // draw collage position and count
    float angleText = 0;
    float tw;
    noFill();
    stroke(255);
    float xt = 0;
    float yt = 0;
    pushMatrix();
    if (orientation == LANDSCAPE) {
      xt = screenWidth-w;
      yt = w/2;
    } else {
      xt = w/2;
      yt = w-w/4;
      angleText = radians(270);
    }
    translate(xt, yt);
    rotate(angleText);
    text(" "+str(photoBoothController.currentState+1)+"/"+str(numberOfPanels), 0, 0);
    popMatrix();

    // drawing collage matrix
    strokeWeight(4);
    if (orientation == LANDSCAPE) {
      rect(0, 0, w, w);  // square
      fill(255);
      rect(0, w/2, w, 2); // horizontal line
      rect(w/2, 0, 2, w);  // vertical line
      switch(photoBoothController.currentState) {
      case 0:
        circle(w/4, w/2-w/4, w/4);
        break;
      case 1:
        circle(w/4+w/2, w/2-w/4, w/4);
        break;
      case 2:
        circle(w/4, w/2+w/4, w/4);
        break;
      case 3:
        circle(w/4+w/2, w/2+w/4, w/4);
        break;
      }
    } else {
      rect(0, h-w, w, w);  // square
      fill(255);
      rect(0, h-w/2, w, 2); // horizontal line
      rect(w/2, h-w, 2, w);  // vertical line
      switch(photoBoothController.currentState) {
      case 1:
        circle(w/4, h-w/2-w/4, w/4);
        break;
      case 3:
        circle(w/4+w/2, h-w/2-w/4, w/4);
        break;
      case 0:
        circle(w/4, h-w/2+w/4, w/4);
        break;
      case 2:
        circle(w/4+w/2, h-w/2+w/4, w/4);
        break;
      }
    }
  }
}

// crop for printing
PImage cropForPrint(PImage src, float printAspectRatio) {
  if (DEBUG) println("cropForPrint "+printAspectRatio);
  float bw = (cameraWidth-(cameraHeight/printAspectRatio))/2.0;
  int sx = int(bw);
  int sy = 0;
  int sw = cameraWidth-int(2*bw);
  int sh = cameraHeight;
  int dx = 0;
  int dy = 0;
  int dw = sw;
  int dh = cameraHeight;
  PImage img = createImage(dw, dh, RGB);
  img.copy(src, sx, sy, sw, sh, dx, dy, dw, dh);  // cropped copy
  if (mirror) {
    PGraphics pg;
    pg = createGraphics(dw, dh);
    pg.beginDraw();
    pg.background(0);
    pg.pushMatrix();
    pg.scale(-1, 1);
    pg.image(img, -dw, 0, dw, dh);  // horizontal flip
    pg.popMatrix();
    pg.endDraw();
    img = pg.copy();
    pg.dispose();
  }
  return img;
}

// Save all images array
//void saveImages(PImage[] images, String outputFolderPath, String outputFilename, String suffix, String filetype) {
//  for (int i=0; i<numberOfPanels; i++) {
//    // original camera photo
//    //images[i].save(outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(i+1) + "." + filetype);
//    // crop and save
//    images[i] = cropForPrint(images[i], printAspectRatio);
//    images[i].save(outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(i+1) + "_cr"+ "." + filetype);
//  }
//}

// Save image
void saveImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
  // crop and save
  collage[index] = cropForPrint(img, printAspectRatio);
  String filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_cr"+ "." + filetype;
  collage[index].save(filename);
  if (orientation == PORTRAIT) {
    setEXIF(filename);
  }
}

// Save image of the composite screen
void saveScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

// Save composite collage from original photos
// images input already cropped
PGraphics saveCollage(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  PGraphics pg;
  int w = int(cameraHeight/printAspectRatio);
  int h = cameraHeight;
  pg = createGraphics(2*w, 2*h);
  pg.beginDraw();
  pg.background(0);
  pg.fill(255);
  // build collage
  if (orientation == LANDSCAPE) {
    for (int i=0; i<numberOfPanels; i++) {
      switch (i) {
      case 0:
        pg.image(collage[i], 0, 0, w, h);
        break;
      case 1:
        pg.image(collage[i], w, 0, w, h);
        break;
      case 2:
        pg.image(collage[i], 0, h, w, h);
        break;
      case 3:
        pg.image(collage[i], w, h, w, h);
        break;
      default:
        break;
      }
    }
  } else { // portrait
    for (int i=0; i<numberOfPanels; i++) {
      switch (i) {
      case 1:
        pg.image(collage[i], 0, 0, w, h);
        break;
      case 3:
        pg.image(collage[i], w, 0, w, h);
        break;
      case 0:
        pg.image(collage[i], 0, h, w, h);
        break;
      case 2:
        pg.image(collage[i], w, h, w, h);
        break;
      default:
        break;
      }
    }
  }
  // draw dividers
  pg.rect(0, h-dividerSize/2, 2*w, dividerSize);
  pg.rect(w-dividerSize/2, 0, dividerSize, 2*h);
  pg.endDraw();
  String filename = outputFolderPath + File.separator + outputFilename + suffix + "_" + number(5) + "_cr"+ "." + filetype;
  pg.save(filename);
  if (orientation == PORTRAIT) {
    setEXIF(filename);
  }
  return pg;
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
