// Configuration from JSON file
// Looks for file my.config.json
// If not found uses config.json the default file - do not change config.json

private final static int JAVA_MODE = 0;
private final static int ANDROID_MODE = 1;
int buildMode = JAVA_MODE;

int screenWidth = 1920; // default
int screenHeight = 1080;  // default
float screenAspectRatio;
int dividerSize = 10; // 2x2 photo collage layout divider line width

int cameraWidth = 1920;
int cameraHeight = 1080;
float cameraAspectRatio;

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
int cameraNumber = 0;

// Camera Pipeline Examples for G-Streamer with Windows 10
String PIPELINE_C920 = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_USB = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D_USB_Camera = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=2560, height=960, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_UVC = "pipeline: ksvideosrc device-index=0 ! image/jpeg ! jpegdec ! videoconvert";  // works for UVC Camera AntVR CAP 2
String PIPELINE_BRIO = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=2160, framerate=30/1 ! jpegdec ! videoconvert";
String pipeline = PIPELINE_BRIO; // default

String cameraOrientation;
int orientation = LANDSCAPE;
//int orientation = PORTRAIT;

float printWidth;
float printHeight;
float printAspectRatio = 4.0/6.0;  // default 4x6 inch print portrait orientation

int numberOfPanels = 1;
boolean mirrorPrint = false;  // mirror photos saved for print by horizontal flip
boolean mirror = false;

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
    //readAConfig();  // TODO call different configuration function
  }
}

void readConfig() {
  String filenamePath = sketchPath()+File.separator+"config"+File.separator+"my_config.json";
  if (!fileExists(filenamePath)) {
    filenamePath = sketchPath()+File.separator+"config"+File.separator+"config.json"; // default for development code test
  }
  configFile = loadJSONObject(filenamePath);
  //configFile = loadJSONObject("config.json");
  //configFile = loadJSONObject(sketchPath("config")+File.separator+"config.json");
  configuration = configFile.getJSONObject("configuration");
  //DEBUG = configFile.getBoolean("debug");
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
  screenAspectRatio = (float)screenWidth/(float)screenHeight;
  camera = configFile.getJSONObject("camera");
  cameraName = camera.getString("name");
  cameraWidth = camera.getInt("width");
  cameraHeight = camera.getInt("height");
  cameraAspectRatio = (float) cameraWidth / (float) cameraHeight;
  if (DEBUG) println("cameraWidth="+cameraWidth + " cameraHeight="+cameraHeight+ " cameraAspectRatio="+cameraAspectRatio);
  cameraOrientation = camera.getString("orientation");
  if (cameraOrientation != null && cameraOrientation.equals("landscape")) {
    orientation = LANDSCAPE;
  } else {
    orientation = PORTRAIT;
  }
  pipeline = camera.getString("pipeline");
  try {
    cameraNumber = camera.getInt("number");
  }
  catch (RuntimeException rte) {
    cameraNumber = 0;
  }
  if (DEBUG) println("cameraNumber="+cameraNumber);
  if (DEBUG) println("configuration camera name="+cameraName+ " cameraWidth="+cameraWidth + " cameraHeight="+ cameraHeight);
  if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
  if (DEBUG) println("mirror="+mirror);
  printer = configFile.getJSONObject("printer");
  if (printer != null) {
    printWidth = printer.getFloat("printWidth");
    printHeight = printer.getFloat("printHeight");
    printAspectRatio = printWidth/printHeight;
  }
}

// Check if file exists
boolean fileExists(String filenamePath) {
  File newFile = new File (filenamePath);
  if (newFile.exists()) {
    if (DEBUG) println("File "+ filenamePath+ " exists");
    return true;
  }
  return false;
}
