class PhotoBoothController {
  int currentState;
  PImage[] images;
  volatile PImage currentImage;
  volatile PImage currentRawImage;
  PImage[] collage; // print aspect ratio
  PImage collage2x2;
  String datetime;

  boolean isPhotoShoot, endPhotoShoot;
  volatile int startPhotoShoot;
  volatile boolean noCountDown = false;
  int photoDelay = 20;
  int oldShootTimeout = 60;
  int oldShoot = 0;

  int MAX_PANELS = 4;
  int PANEL_WIDTH;
  int PANEL_HEIGHT;
  int COUNTDOWN_BOX_WIDTH;
  int COUNTDOWN_BOX_HEIGHT;
  int COUNTDOWN_BOX_X;
  int COUNTDOWN_BOX_Y;
  int COUNTDOWN_TEXT_X;
  int COUNTDOWN_TEXT_Y;

  public PhotoBoothController() {
    updatePanelSize();

    COUNTDOWN_BOX_WIDTH = screenWidth/20;
    COUNTDOWN_BOX_HEIGHT = 2*screenHeight/20;
    COUNTDOWN_BOX_X = screenWidth/2-COUNTDOWN_BOX_WIDTH/2;
    COUNTDOWN_BOX_Y = screenHeight/2-COUNTDOWN_BOX_HEIGHT/2;
    COUNTDOWN_TEXT_X = screenWidth/2-COUNTDOWN_BOX_WIDTH/4;
    COUNTDOWN_TEXT_Y = screenHeight/2+COUNTDOWN_BOX_HEIGHT/4;

    currentState = 0;
    startPhotoShoot = 0;
    images = new PImage[MAX_PANELS];
    isPhotoShoot=false;
    endPhotoShoot=false;
    // save image space for panels
    for (int i=0; i<MAX_PANELS; i++) {
      images[i] = new PImage();
    }
    collage = new PImage[4];
  }

  void updatePanelSize() {
    if (numberOfPanels == MAX_PANELS) {
      PANEL_WIDTH = screenWidth/2;
      PANEL_HEIGHT = screenHeight/2;
    } else {
      PANEL_WIDTH = screenWidth;
      PANEL_HEIGHT = screenHeight;
    }
  }

  private void drawImage(PImage input, boolean preview) {
    float h = screenHeight;
    float w = ((float)screenHeight/printAspectRatio);

    if (preview) {
      background(0);
      if (orientation == LANDSCAPE) {
        image(input, (screenWidth-w)/2, 0, w, screenHeight);
      } else {
        if (mirror) {
          image(input, (screenWidth-w)/2, 0, w, screenHeight);
        } else {
          image(input, (screenWidth-w)/2, 0, w, screenHeight);
          //pushMatrix();
          //translate(width/2, height/2);
          //rotate(-PI);
          //image(input, -screenWidth/2+(screenWidth-w)/2, -screenHeight/2, w, screenHeight);
          //popMatrix();
        }
      }
    } else {
      if (mirror) {
        pushMatrix();
        scale(-1, 1);
        image(input, -screenWidth, 0, screenWidth, screenHeight);
        popMatrix();
      } else {
        if (orientation == LANDSCAPE) {
          image(input, 0, 0, screenWidth, screenHeight);
        } else {
          pushMatrix();
          translate(width/2, height/2);
          rotate(-PI);
          image(input, -screenWidth/2, -screenHeight/2, screenWidth, screenHeight);
          popMatrix();
        }
      }
    }
  }

  public void drawPrevious() {
    drawImage(collage[currentState], true);
  }

  public void drawLast() {
    if (numberOfPanels == 1) {
      if (collage[0] != null) {
        //if (DEBUG) println("drawLast()");
        drawImage(collage[0], true);
      }
    } else {
      drawCollage(collage2x2);
    }
    drawMaskForScreen(printAspectRatio);
  }

  public void drawCurrent() {
    drawImage(currentImage, false);
    drawMaskForScreen(printAspectRatio);
  }

  public void oldShoot() {
    if (oldShoot > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShoot++;
  }

  public void processImage(PImage input) {
    if (input == null) return;
    if (imageProcessor.filterNum > 0) currentRawImage = input.get();
    currentImage = imageProcessor.processImage(input);
    drawImage(currentImage, false);
    drawMaskForScreen(printAspectRatio);
  }

  //public void processImageAlt(Capture input) {
  //  PImage temp = input;
  //  currentImage = imageProcessor.processImage(temp);
  //  drawImage(currentImage, false);
  //  drawMaskForScreen(printAspectRatio);
  //}

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot();
    else {
      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
    }
  }

  public void startPhotoShoot() {
    if (isPhotoShoot) return;
    isPhotoShoot = true;
    startPhotoShoot = 0;
  }

  public void endPhotoShoot() {
    endPhotoShoot = true;
    oldShoot = 0;
    if (DEBUG) println("endPhotoShoot drawPrevious()");
    drawPrevious();
  }

  public void drawPhotoShoot() {
    background(0);
    int digit = getCountDownDigit(countdownStart);
    if (digit > 0 && !endPhotoShoot) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitS = str(digit);
      float tw = textWidth(digitS);
      float th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        pushMatrix();
        translate(screenWidth/2, screenHeight/2+th);
        text(digitS, -tw/2, 0);
        popMatrix();
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitS, -tw/2, 0);
        popMatrix();
      }
      textSize(fontSize);
      fill(255);
    } else if (digit == 0) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitS = "FREEZE!";
      float tw = textWidth(digitS);
      float th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        pushMatrix();
        translate(screenWidth/2, screenHeight/2+th);
        text(digitS, -tw/2, 0);
        popMatrix();
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitS, -tw/2, 0);
        popMatrix();
      }
      textSize(fontSize);
      fill(255);
    } else if (digit == -1) {
      // flash screen and take photo
      background(0);
      boolean done = incrementState();
      if (done) {
        if (DEBUG) println("done drawPrevious()");
        drawPrevious();
        String saved = "Saved "+datetime;
        float tw = textWidth(saved);
        //if (orientation == LANDSCAPE) {
        //  pushMatrix();
        //  translate(screenWidth/2, screenHeight/2);
        //  text(saved, -tw/2, 0);
        //  popMatrix();
        //} else {
        //  pushMatrix();
        //  translate(screenWidth/2, screenHeight/2);
        //  rotate(-HALF_PI);
        //  text(saved, -tw/2, 0);
        //  popMatrix();
        //}

        if (orientation == LANDSCAPE) {
          pushMatrix();
          translate(screenWidth/2, screenHeight/24);
          text(saved, -tw/2, 0);
          popMatrix();
        } else {
          float angleText = radians(270);
          pushMatrix();
          //translate(screenWidth/2, screenHeight/2);
          translate(screenWidth/32, screenHeight/2+tw/2);
          rotate(angleText);
          text(saved, 0, 0);
          popMatrix();
        }
        if (numberOfPanels == 4) {
          if (DEBUG) println("save collage2x2 " + datetime);
          PGraphics pg = saveCollage(collage, OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime, fileType);
          collage2x2 = pg.copy();
          pg.dispose();
          drawCollage(collage2x2);
        }
        drawMaskForScreen(printAspectRatio);
      }
      startPhotoShoot=0;
    }
    startPhotoShoot++;
  }

  void drawCollage(PImage img) {
    if (img != null) {
      //float bw = (cameraWidth-(cameraHeight/printAspectRatio))/2.0;
      float bw = (screenWidth-(screenHeight/printAspectRatio))/2.0;
      int sx = int(bw);
      //image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      image(img, sx, 0, img.width/(2*cameraHeight/screenHeight), img.height/(2*cameraHeight/screenHeight));
    }
  }

  int getCountDownDigit(int initial) {
    int cdd = -1;
    int aDelay = photoDelay/4;
    if (numberOfPanels == 4) {
      aDelay = photoDelay/4;
    }
    if (startPhotoShoot < aDelay) {
      cdd = initial;
    } else if (startPhotoShoot >= aDelay && startPhotoShoot < 2*aDelay) {
      cdd = initial-1;
    } else if (startPhotoShoot >= 2*aDelay && startPhotoShoot < 3*aDelay) {
      cdd = initial-2;
    } else if (startPhotoShoot >= 3*aDelay && startPhotoShoot < 4*aDelay) {
      cdd = initial-3;
    } else if (startPhotoShoot >= 4*aDelay) {
      cdd = initial-4;
    }
    if (noCountDown) {
      noCountDown = false;
      startPhotoShoot = 4*aDelay;
      cdd = initial-3;
    }
    return cdd;
  }

  public void setFilter(int num) {
    imageProcessor.filterNum = num;
  }

  public int getFilter() {
    return imageProcessor.filterNum;
  }

  public boolean incrementState() {
    boolean done = false;
    images[currentState] = currentImage.get();
    if (currentState == 0) {
      datetime = getDateTime();
    }
    if (DEBUG) println("save photo "+ (currentState+1) + " " + datetime);
    if (imageProcessor.filterNum > 0) {
      saveImage(currentRawImage, currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "NF", fileType);
    }
    saveImage(images[currentState], currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
    currentState += 1;
    if (currentState == numberOfPanels) {
      done = true;
      currentState=0;
      endPhotoShoot();
    }
    return done;
  }

  // Save image
  public void saveImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    // crop and save
    collage[index] = cropForPrint(img, printAspectRatio);  // adjusts for mirror
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_cr"+ "." + filetype;
    collage[index].save(filename);
    if (orientation == PORTRAIT) {
      setEXIF(filename);
    }
  }

  // crop for printing
  PImage cropForPrint(PImage src, float printAspectRatio) {
    if (DEBUG) println("cropForPrint "+printAspectRatio+ " mirrorPrint="+mirrorPrint+" " +(orientation==LANDSCAPE? "Landscape":"Portrait"));
    // first crop creating a new PImage
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
    // next mirror image if needed
    if (mirrorPrint && orientation == PORTRAIT) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.scale(-1, 1);
      pg.image(img, -dw, 0, dw, dh);  // horizontal flip
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    } else if (!mirrorPrint && orientation == PORTRAIT) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.translate(dw/2, dh/2);
      pg.rotate(PI);
      pg.image(img, -dw/2, -dh/2, dw, dh);  // rotate -180
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    } else if (mirrorPrint && orientation == LANDSCAPE) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.scale(-1, 1);
      pg.image(img, -dw, 0, dw, dh);  // horizontal flip
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    }
    return img;
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

  void splitImage(PImage photo, int verticalOffset, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    if (photo == null) return;
    // split into two files, save in images[2] images[3]
    PGraphics left = createGraphics(photo.width/2, photo.height);
    PGraphics right = createGraphics(photo.width/2, photo.height);
    left.beginDraw();
    left.image(photo, 0, 0, photo.width, photo.height);
    left.endDraw();
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_l"+ "." + filetype;
    left.save(filename);
    images[2] = left;
    right.beginDraw();
    right.image(photo, -photo.width/2, verticalOffset, photo.width, photo.height);
    right.endDraw();
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_r"+ "." + filetype;
    right.save(filename);
    images[3] = right;
  }

  // Save composite collage from original photos
  // images input already cropped
  PGraphics saveCollage(PImage[] collage, String outputFolderPath, String outputFilename, String suffix, String filetype) {
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
}
