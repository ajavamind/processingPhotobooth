class PhotoBoothController {
  int currentState;
  PImage[] images;
  PImage currentImage;
  String datetime;

  boolean isPhotoShoot, endPhotoShoot;
  volatile int startPhotoShoot;
  int photoDelay = 20;
  int oldShootTimeout = 100;
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

    COUNTDOWN_BOX_WIDTH = SCREEN_WIDTH/20;
    COUNTDOWN_BOX_HEIGHT = 2*SCREEN_HEIGHT/20;
    COUNTDOWN_BOX_X = SCREEN_WIDTH/2-COUNTDOWN_BOX_WIDTH/2;
    COUNTDOWN_BOX_Y = SCREEN_HEIGHT/2-COUNTDOWN_BOX_HEIGHT/2;
    COUNTDOWN_TEXT_X = SCREEN_WIDTH/2-COUNTDOWN_BOX_WIDTH/4;
    COUNTDOWN_TEXT_Y = SCREEN_HEIGHT/2+COUNTDOWN_BOX_HEIGHT/4;

    currentState = 0;
    startPhotoShoot = 0;
    images = new PImage[MAX_PANELS];
    isPhotoShoot=false;
    endPhotoShoot=false;
    // save image space for panels
    for (int i=0; i<MAX_PANELS; i++) {
      images[i] = new PImage();
    }
  }

  void updatePanelSize() {
    if (numberOfPanels == MAX_PANELS) {
      PANEL_WIDTH = SCREEN_WIDTH/2;
      PANEL_HEIGHT = SCREEN_HEIGHT/2;
    } else {
      PANEL_WIDTH = SCREEN_WIDTH;
      PANEL_HEIGHT = SCREEN_HEIGHT;
    }
  }

  private void drawImage(PImage input) {
    if (mirror) {
      pushMatrix();
      scale(-1, 1);
      image(input, -SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
      popMatrix();
    } else {
      image(input, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
  }

  public void drawPrevious() {
    drawImage(images[currentState]);
  }

  public void drawCurrent() {
    drawImage(currentImage);
    drawMaskForScreen(printAspectRatio);
  }

  public void oldShoot() {
    if (oldShoot > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShoot++;
  }

  public void processImage(Capture input) {
    currentImage = imageProcessor.processImage(input);
    drawImage(currentImage);
    drawMaskForScreen(printAspectRatio);
  }

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot();
    else {

      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
      //drawDivider(numberOfPanels);

      //imageProcessor.filterNum = 0;
    }
  }

  public void startPhotoShoot() {
    if (isPhotoShoot) return;
    isPhotoShoot = true;
    startPhotoShoot = 0;
  }

  public void endPhotoShoot() {
    endPhotoShoot = true;
    //startPhotoShoot = 0;
    oldShoot = 0;
    drawPrevious();
  }

  public void drawPhotoShoot() {
    background(0);
    int digit = getCountDownDigit(countdownStart);
    if (digit > 0 && !endPhotoShoot) {
      drawCurrent();
      //fill(64);
      //rect(COUNTDOWN_BOX_X, COUNTDOWN_BOX_Y, COUNTDOWN_BOX_WIDTH, COUNTDOWN_BOX_HEIGHT);
      fill(0x80FFFF80);
      textSize(largeFontSize);
      text(str(digit), COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
      textSize(fontSize);
      fill(255);
    } else if (digit == 0) {
      drawCurrent();
    } else if (digit == -1) {
      // flash screen and take photo
      //background(255);
      background(0);
      //drawDivider(numberOfPanels);
      boolean done = incrementState();
      //drawPrevious();
      if (done) {
        drawPrevious();
        String saved = "Saved "+datetime;
        float tw = textWidth(saved);
        text(saved, SCREEN_WIDTH/2- tw/2, SCREEN_HEIGHT-SCREEN_HEIGHT/32);
        if (numberOfPanels == 4) {
          if (DEBUG) println("save collage " + datetime);
          PGraphics pg = saveCollage(OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime, fileType);
          PImage img = pg.copy();
          pg.dispose();
          float bw = (cameraWidth-(cameraHeight/printAspectRatio))/2.0;
          int sx = int(bw);
          image(img, sx/2, 0, img.width/4, img.height/4);
        } else if (numberOfPanels == 2) {
          saveScreen(OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime + "_2x1", fileType);
        }
        drawMaskForScreen(printAspectRatio);
      }
      startPhotoShoot=0;
    }
    startPhotoShoot++;
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
    return cdd;
  }

  public void nextFilter() {
    imageProcessor.filterNum = (imageProcessor.filterNum+1)%filters.length;
  }
  public void previousFilter() {
    imageProcessor.filterNum--;
    if (imageProcessor.filterNum < 0) {
      imageProcessor.filterNum = filters.length-1;
    }
  }
  public boolean incrementState() {
    boolean done = false;
    images[currentState] = currentImage.get();
    if (currentState == 0) {
      datetime = getDateTime();
    }
    if (DEBUG) println("save photo "+ (currentState+1) + " " + datetime);
    saveImage(images[currentState], currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
    currentState += 1;
    if (currentState == numberOfPanels) {
      done = true;
      currentState=0;
      endPhotoShoot();
    }
    return done;
  }
}
