private final static int JAVA_MODE = 0;
private final static int ANDROID_MODE = 1;
int buildMode = JAVA_MODE;

String VERSION = "1.0";

int screenWidth = 1920; // default
int screenHeight = 1080;  // default
int dividerSize = 10; // 2x2 photo collage layout divider line width

int cameraWidth = 1920;
int cameraHeight = 1080;
String eventText;
String instructionLineText;
String titleText="Photo Booth";
String OUTPUT_FILENAME = "IMG_";
String OUTPUT_COMPOSITE_FILENAME = "IMG_";
String OUTPUT_FOLDER_PATH="output";  // where to store photos
String fileType = "jpg"; //  other file types "png" "bmp"

String CAMERA_NAME_C920 = "HD Pro Webcam C920";
String CAMERA_NAME_USB = "USB Camera";
String CAMERA_NAME_UVC = "UVC Camera";
String CAMERA_NAME_BRIO = "Logitech BRIO";
String cameraName = CAMERA_NAME_C920;

// Camera Pipeline Examples for G-Streamer with Windows 10
String PIPELINE_C920 = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_USB = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D_USB_Camera = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=2560, height=960, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_UVC = "pipeline: ksvideosrc device-index=0 ! image/jpeg ! jpegdec ! videoconvert";  // works for UVC Camera AntVR CAP 2
String PIPELINE_BRIO = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=2160, framerate=30/1 ! jpegdec ! videoconvert";
String pipeline = PIPELINE_BRIO; // default

// Photo Booth Modes
private static final int PHOTO_MODE = 1;
private static final int STEREO3D_MODE = 2;  // TO DO
int mode = PHOTO_MODE;

String cameraOrientation;
int orientation = LANDSCAPE;
//int orientation = PORTRAIT;
float printWidth;
float printHeight;
float printAspectRatio = 4.0/6.0;  // default 4x6 inch print portrait orientation

int numberOfPanels = 1;
boolean mirror = false;  // mirror screen by horizontal flip
boolean DEBUG = false;
int countdownStart = 3;  // seconds
String ipAddress;  // photo booth computer IP Address
JSONObject configFile;
JSONObject configuration;
JSONObject display;
JSONObject camera;
JSONObject printer;

void initConfig() {
  if (buildMode == JAVA_MODE) {
    readConfig();
  } else if (buildMode == ANDROID_MODE) {
    //readAConfig();  // TODO call different method
  }
}

void readConfig() {
  //configFile = loadJSONObject(sketchPath()+File.separator+"config"+File.separator+"config.json");
  configFile = loadJSONObject(sketchPath("config")+File.separator+"config.json");
  configuration = configFile.getJSONObject("configuration");
  DEBUG = configFile.getBoolean("debug");
  mirror = configuration.getBoolean("mirrorScreen");
  countdownStart = configuration.getInt("countDownStart");
  fileType = configuration.getString("fileType");
  OUTPUT_FOLDER_PATH = configuration.getString("outputFolderPath");
  ipAddress = configuration.getString("IPaddress");
  instructionLineText = configuration.getString("instructionLineText");
  eventText = configuration.getString("eventText");

  display = configFile.getJSONObject("display");
  if (display != null) {
    screenWidth = display.getInt("width");
    screenHeight = display.getInt("height");
  }
  camera = configFile.getJSONObject("camera");
  cameraName = camera.getString("name");
  cameraWidth = camera.getInt("width");
  cameraHeight = camera.getInt("height");
  cameraOrientation = camera.getString("orientation");
  if (cameraOrientation != null && cameraOrientation.equals("landscape")) {
    orientation = LANDSCAPE;
  } else {
    orientation = PORTRAIT;
  }
  pipeline = camera.getString("pipeline");
  if (DEBUG) println("configuration camera name="+cameraName+ " cameraWidth="+cameraWidth + " cameraHeight="+ cameraHeight);
  if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
  printer = configFile.getJSONObject("printer");
  if (printer != null) {
    printWidth = printer.getFloat("printWidth");
    printHeight = printer.getFloat("printHeight");
    printAspectRatio = printWidth/printHeight;
  }
}
