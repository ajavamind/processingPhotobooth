static final int KEYCODE_ENTER = 10;
static final int KEYCODE_ESC = 27;
static final int KEYCODE_SPACE = 32;


void keyPressed() {
  int lastKeyCode = keyCode;
  println("keyCode="+lastKeyCode);

  switch(lastKeyCode) {
  case KEYCODE_ESC:
    println("ESC exit");
    if (cam != null) {
      cam.stop();
      cam.dispose();
    }
    cam = null;
    exit();
    break;
  case KEYCODE_SPACE:
  case KEYCODE_ENTER:
    if (!photoBoothController.isPhotoShoot) {
      photoBoothController.tryPhotoShoot();
    }
    break;
  case LEFT:
    photoBoothController.decrementFilter();
    break;
  case RIGHT:
    photoBoothController.incrementFilter();
    break;
  default:
    break;
  }
}
