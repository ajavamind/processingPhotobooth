class PhotoBoothController {
  int currentState;
  PImage[] images;
  PImage currentImage;
  ImageProcessor imageProcessor;
  boolean isPhotoShoot, endPhotoShoot;
  int startPhotoShoot;
  int photoDelay = 20;
  int oldShootTimeout = 100;
  int oldShoot = 0;
  int compositeCounter = 1;

  int PANEL_WIDTH;
  int PANEL_HEIGHT;
  int COUNTDOWN_BOX_WIDTH;
  int COUNTDOWN_BOX_HEIGHT;
  int COUNTDOWN_BOX_X;
  int COUNTDOWN_BOX_Y;
  int COUNTDOWN_TEXT_X;
  int COUNTDOWN_TEXT_Y;

  public PhotoBoothController() {
    PANEL_WIDTH = SCREEN_WIDTH/2;
    PANEL_HEIGHT = SCREEN_HEIGHT/2;
    COUNTDOWN_BOX_WIDTH = SCREEN_WIDTH/16;
    COUNTDOWN_BOX_HEIGHT = SCREEN_WIDTH/16;
    COUNTDOWN_BOX_X = SCREEN_WIDTH/2-COUNTDOWN_BOX_WIDTH/2;
    COUNTDOWN_BOX_Y = SCREEN_HEIGHT/2-COUNTDOWN_BOX_HEIGHT/2;
    COUNTDOWN_TEXT_X = SCREEN_WIDTH/2-COUNTDOWN_BOX_WIDTH/4;
    COUNTDOWN_TEXT_Y = SCREEN_HEIGHT/2+COUNTDOWN_BOX_HEIGHT/4;
    currentState = 0;
    startPhotoShoot = 0;
    images = new PImage[4];
    isPhotoShoot=false;
    endPhotoShoot=false;
    for (int i=0; i<4; i++) {
      images[i] = new PImage();
    }
    imageProcessor = new ImageProcessor();
  }

  private void drawImage(PImage input, int state) {
    if (state == 0) {
      image(input, 0, 0);
    } else if (state == 1) {
      image(input, PANEL_WIDTH + dividerSize, 0);
    } else if (state == 2) {
      image(input, 0, PANEL_HEIGHT + dividerSize);
    } else if (state == 3) {
      image(input, PANEL_WIDTH + dividerSize, PANEL_HEIGHT + dividerSize);
    }
  }

  public void drawPrevious() {
    for (int i=0; i<currentState; i++) {
      drawImage(images[i], i);
    }
  }

  public void oldShoot() {
    if (oldShoot > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShoot++;
  }

  public void processImage(PImage input) {
    currentImage = imageProcessor.processImage(input);
    drawImage(currentImage, currentState);
  }

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot();
    else {
      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
      drawDivider();
      //fill(255);
      //rect(0, PANEL_HEIGHT, SCREEN_WIDTH, dividerSize);
      //rect(PANEL_WIDTH, 0, dividerSize, SCREEN_HEIGHT);

      imageProcessor.filterNum = 0;
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
    fill(64);
    rect(COUNTDOWN_BOX_X, COUNTDOWN_BOX_Y, COUNTDOWN_BOX_WIDTH, COUNTDOWN_BOX_HEIGHT);
    fill(255);
    if (startPhotoShoot < photoDelay) {
      text("4", COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
    } else if (startPhotoShoot > photoDelay && startPhotoShoot < 2*photoDelay) {
      text("3", COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
    } else if (startPhotoShoot > 2*photoDelay && startPhotoShoot < 3*photoDelay) {
      text("2", COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
    } else if (startPhotoShoot > 3*photoDelay && startPhotoShoot < 4*photoDelay) {
      text("1", COUNTDOWN_TEXT_X, COUNTDOWN_TEXT_Y);
    } else if (startPhotoShoot > 4*photoDelay) {
      // flash screen and take photo
      background(255);
      background(0);
      drawDivider();
      boolean done = incrementState();
      drawPrevious();

      if (done) {
        saveImages(images, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, str(compositeCounter) + "_"+str(startPhotoShoot), FILE_TYPE);
        saveCompositeScreen(OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, str(compositeCounter), FILE_TYPE);
        compositeCounter++;
      }
      startPhotoShoot=0;
    }
    startPhotoShoot++;
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
    if (currentState == 4) {
      done = true;
      endPhotoShoot();
    }
    currentState = currentState%4;
    return done;
  }
}
