// Keyboard input handling
// These codes (ASCII) are for Java applications
// Android codes (not implemented) differ with some keys

static final int KEYCODE_BACKSPACE = 8;
static final int KEYCODE_TAB = 9;
static final int KEYCODE_ENTER = 10;
static final int KEYCODE_ESC = 27;
static final int KEYCODE_SPACE = 32;
static final int KEYCODE_COMMA = 44;
static final int KEYCODE_MINUS = 45;
static final int KEYCODE_PERIOD = 46;
static final int KEYCODE_SLASH = 47;
static final int KEYCODE_0 = 48;
static final int KEYCODE_1 = 49;
static final int KEYCODE_2 = 50;
static final int KEYCODE_3 = 51;
static final int KEYCODE_4 = 52;
static final int KEYCODE_5 = 53;
static final int KEYCODE_6 = 54;
static final int KEYCODE_7 = 55;
static final int KEYCODE_8 = 56;
static final int KEYCODE_9 = 57;
static final int KEYCODE_SEMICOLON = 59;
static final int KEYCODE_PLUS = 61;
static final int KEYCODE_EQUAL = 61;
static final int KEYCODE_A = 65;
static final int KEYCODE_B = 66;
static final int KEYCODE_C = 67;
static final int KEYCODE_D = 68;
static final int KEYCODE_E = 69;
static final int KEYCODE_F = 70;
static final int KEYCODE_G = 71;
static final int KEYCODE_H = 72;
static final int KEYCODE_I = 73;
static final int KEYCODE_J = 74;
static final int KEYCODE_K = 75;
static final int KEYCODE_L = 76;
static final int KEYCODE_M = 77;
static final int KEYCODE_N = 78;
static final int KEYCODE_O = 79;
static final int KEYCODE_P = 80;
static final int KEYCODE_Q = 81;
static final int KEYCODE_R = 82;
static final int KEYCODE_S = 83;
static final int KEYCODE_T = 84;
static final int KEYCODE_U = 85;
static final int KEYCODE_V = 86;
static final int KEYCODE_W = 87;
static final int KEYCODE_X = 88;
static final int KEYCODE_Y = 89;
static final int KEYCODE_Z = 90;
static final int KEYCODE_LEFT_BRACKET = 91;
static final int KEYCODE_BACK_SLASH = 92;
static final int KEYCODE_RIGHT_BRACKET = 93;
static final int KEYCODE_DEL = 127;
//static final int KEYCODE_MEDIA_NEXT = 87;
//static final int KEYCODE_MEDIA_PLAY_PAUSE = 85;
//static final int KEYCODE_MEDIA_PREVIOUS = 88;
static final int KEYCODE_PAGE_DOWN = 93;
static final int KEYCODE_PAGE_UP = 92;
static final int KEYCODE_PLAY = 126;
static final int KEYCODE_MEDIA_STOP = 86;
static final int KEYCODE_MEDIA_REWIND = 89;
static final int KEYCODE_MEDIA_RECORD = 130;
static final int KEYCODE_MEDIA_PAUSE = 127;
static final int KEYCODE_VOLUME_UP = 0;  // TODO
static final int KEYCODE_VOLUME_DOWN = 0; // TODO
static final int KEYCODE_MOVE_HOME = 122;
static final int KEYCODE_MOVE_END  = 123;
static final int KEYCODE_TILDE_QUOTE = 192;
static final int KEYCODE_SINGLE_QUOTE = 222;
//static final int KEYCODE_TRIGGER_PHOTO = 1000;
//static final int KEYCODE_TRIGGER_COLLAGE = 1001;

private static final int NOP = 0;
private static final int EXIT = 1;

// lastKey and lastKeyCode are handled in the draw loop
private int lastKey;
private int lastKeyCode;


// remote joystick key B - ESC key A - LEFT
void mousePressed() {
  int button = mouseButton;
  if (DEBUG) println("mousePressed()");
  if (DEBUG) println("mouseButton="+mouseButton + " LEFT=" + LEFT + " RIGHT="+RIGHT+" CENTER="+CENTER);
  if (button == LEFT) {  // remote key A
    lastKeyCode = KEYCODE_ENTER;
    if (DEBUG) println("mousePressed set lastKeyCode="+lastKeyCode);
  } else if (button == RIGHT) {
    lastKeyCode = KEYCODE_ESC;
  } else if (button == CENTER) {
    lastKeyCode = KEYCODE_C;  // collage
  }
}

void keyReleased() {
}

void keyPressed() {
  if (DEBUG) println("key="+key + " keydecimal=" + int(key) + " keyCode="+keyCode);        
  //if (DEBUG) Log.d(TAG, "key=" + key + " keyCode=" + keyCode);  // Android
  if (key==ESC) {
    key = 0;
    keyCode = KEYCODE_ESC;
    //endLogger();
    //    keyCode = 0;
    //    return;
  } else if (key == 65535 && keyCode == 0) { // special case all other keys
    key = 0;
    keyCode = KEYCODE_C;  // use collage mode
  }
  lastKey = key;
  lastKeyCode = keyCode;
}

// Handling key in the main loop not in keyPressed()
// returns NOP on no key processed
// returns command code when a key is to be processed
int keyUpdate() {
  int cmd = NOP;  // return code

  switch(lastKeyCode) {
  case KEYCODE_Q:
    if (DEBUG) println("Exit Program");
    if (cam != null) {
      cam.stop();
      cam.dispose();
    }
    exit();
    break;
  case KEYCODE_ENTER:
    preview = PREVIEW_OFF;
    if (!photoBoothController.isPhotoShoot) {
      photoBoothController.tryPhotoShoot();
    }
    cmd = ENTER;
    break;
    // 3D camera adjust parallax
  case KEYCODE_0:
  case KEYCODE_1:
  case KEYCODE_2:
  case KEYCODE_3:
  case KEYCODE_4:
  case KEYCODE_5:
  case KEYCODE_6:
  case KEYCODE_7:
  case KEYCODE_8:
  case KEYCODE_9:
    int index = lastKeyCode-KEYCODE_0;
    photoBoothController.setFilter(index);
    if (DEBUG) println("setFilter="+photoBoothController.getFilter());
    break;
  case KEYCODE_M:  // mirror view
    mirror = !mirror;
    if (DEBUG) println("mirror="+mirror);
    break;
  case KEYCODE_C:
    preview = PREVIEW_OFF;
    set2x2Photo();
    break;
  case KEYCODE_S:
    preview = PREVIEW_OFF;
    setSinglePhoto();
    break;
  case KEYCODE_P:  // portrait orientation
    orientation = PORTRAIT;
    if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
    break;
  case KEYCODE_L:  // landscape orientation
    orientation = LANDSCAPE;
    if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
    break;
  case KEYCODE_TAB:
    preview = PREVIEW_OFF;
    showLegend = ! showLegend;
    if (DEBUG) println("preview=OFF "+preview);
    break;
  case KEYCODE_SPACE:
    // Immediate capture not countdown
    photoBoothController.noCountDown = true;
    preview = PREVIEW_OFF;
    if (!photoBoothController.isPhotoShoot) {
      photoBoothController.tryPhotoShoot();
    }
    cmd = ENTER;
    break;
  case KEYCODE_ESC:
    // toggle preview last photo or collage
    preview++;
    if (preview >= PREVIEW_END) {
      preview = PREVIEW_OFF;
    } 
    if (DEBUG) println("preview="+preview);
    break;
  case KEYCODE_D: // toggle DEBUG, output debug information to the console
    //DEBUG = !DEBUG;
    if (DEBUG) println("mirror="+mirror);
    if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
    break;
  default:
    break;
  }
  // clear out last keycode
  lastKey = 0;
  lastKeyCode = 0;
  return cmd;
}

// Single Photo mode
boolean setSinglePhoto() {
  boolean changed = false;
  if (numberOfPanels != 1) {
    numberOfPanels = 1;
    background(0);
    photoBoothController.updatePanelSize();
    changed = true;
  }
  return changed;
}

// Collage 2x2 Photo mode
boolean set2x2Photo() {
  boolean changed = false;
  if (numberOfPanels != 4) {
    numberOfPanels = 4;
    background(0);
    photoBoothController.updatePanelSize();
    changed = true;
  }
  return changed;
}
