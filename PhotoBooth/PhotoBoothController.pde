class PhotoBoothController {
  int currentState;
  PImage[] images;
  PImage currentImage;
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

  private void drawImage(PImage input, int state) {
    if (flipHorz) {
      pushMatrix();
      scale(-1, 1);
      if (state == 0) {
        image(input, -PANEL_WIDTH, 0, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 1) {
        translate(-PANEL_WIDTH, 0);
        image(input, -PANEL_WIDTH-dividerSize, 0, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 2) {
        image(input, -PANEL_WIDTH, PANEL_HEIGHT + dividerSize, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 3) {
        translate(-PANEL_WIDTH, 0);
        image(input, -PANEL_WIDTH-dividerSize, PANEL_HEIGHT + dividerSize, PANEL_WIDTH, PANEL_HEIGHT);
      }
      popMatrix();
    } else {
      if (state == 0) {
        image(input, 0, 0, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 1) {
        image(input, PANEL_WIDTH + dividerSize, 0, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 2) {
        image(input, 0, PANEL_HEIGHT + dividerSize, PANEL_WIDTH, PANEL_HEIGHT);
      } else if (state == 3) {
        image(input, PANEL_WIDTH + dividerSize, PANEL_HEIGHT + dividerSize, PANEL_WIDTH, PANEL_HEIGHT);
      }
    }
  }

  public void drawPrevious() {
    if (numberOfPanels > 1) {
      for (int i=0; i<currentState; i++) {
        drawImage(images[i], i);
        //if(DEBUG) println("draw panel "+i);
      }
    } else {
      // one panel
      drawImage(images[0], 0);
      if (DEBUG) println("draw one panel");
    }
  }

  public void oldShoot() {
    if (oldShoot > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShoot++;
  }

  public void processImage(Capture input) {
    currentImage = imageProcessor.processImage(input);
    drawImage(currentImage, currentState);
  }

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot();
    else {
      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
      drawDivider(numberOfPanels);

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
    startPhotoShoot = 0;
    oldShoot = 0;
    drawPrevious();
  }

  public void drawPhotoShoot() {
    int digit = getCountDownDigit(countdownStart);
    if (digit > 0 && !endPhotoShoot) {
      fill(64);
      rect(COUNTDOWN_BOX_X, COUNTDOWN_BOX_Y, COUNTDOWN_BOX_WIDTH, COUNTDOWN_BOX_HEIGHT);
      fill(255);
      text(str(digit), COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
    } else if (digit == 0) {
      // flash screen and take photo
      //background(255);
      background(0);
      drawDivider(numberOfPanels);
      boolean done = incrementState();
      drawPrevious();
      if (done) {
        String datetime = getDateTime();
        if (DEBUG) println("save photos "+datetime);
        saveImages(images, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
        if (numberOfPanels == 4) {
          saveCompositeScreen(OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime + "_5", fileType);
        } else if (numberOfPanels == 2) {
          saveCompositeScreen(OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime + "_2x1", fileType);
        }
        text("Saved "+datetime, SCREEN_WIDTH/6, SCREEN_HEIGHT-SCREEN_HEIGHT/32);
      }
      startPhotoShoot=0;
    }

    startPhotoShoot++;
  }

  int getCountDownDigit(int initial) {
    int cdd = -1;
    if (startPhotoShoot < photoDelay) {
      cdd = initial;
    } else if (startPhotoShoot >= photoDelay && startPhotoShoot < 2*photoDelay) {
      cdd = initial-1;
    } else if (startPhotoShoot >= 2*photoDelay && startPhotoShoot < 3*photoDelay) {
      cdd = initial-2;
    } else if (startPhotoShoot >= 3*photoDelay && startPhotoShoot < 4*photoDelay) {
      cdd = initial-3;
    } else if (startPhotoShoot >= 4*photoDelay) {
      cdd = initial-4;
    }
    return cdd;
  }

  public void incrementFilter() {
    imageProcessor.filterNum = (imageProcessor.filterNum+1)%filters.length;
  }
  public void decrementFilter() {
    imageProcessor.filterNum--;
    if (imageProcessor.filterNum < 0) {
      imageProcessor.filterNum = filters.length-1;
    }
  }
  public boolean incrementState() {
    boolean done = false;
    images[currentState] = currentImage.get();
    currentState += 1;
    if (currentState == numberOfPanels) {
      done = true;
      endPhotoShoot();
    }
    currentState = currentState%numberOfPanels;
    return done;
  }
}
