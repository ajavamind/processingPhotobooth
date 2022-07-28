
//int CAMERA_WIDTH = 3840; // UVC 3D camera
//int CAMERA_HEIGHT = 1080;
//int CAMERA_WIDTH = 1920;
//int CAMERA_HEIGHT = 1080;

//int CAMERA_WIDTH = 3840;
//int CAMERA_HEIGHT = 2160;
int cameraWidth = 1920;
int cameraHeight = 1080;

String eventText;
String instructionLineText;
String OUTPUT_FILENAME = "IMG_";
String OUTPUT_COMPOSITE_FILENAME = "IMG_";
String OUTPUT_FOLDER_PATH="output";  // where to store photos
String fileType = "jpg"; //  other file types "png" "bmp"

String CAMERA_NAME_C920 = "HD Pro Webcam C920";
String CAMERA_NAME_USB = "USB Camera";
String CAMERA_NAME_UVC = "UVC Camera";
String CAMERA_NAME_BRIO = "Logitech BRIO";
String cameraName = CAMERA_NAME_C920;

// Pipeline G-Steamer for Windows 10
String PIPELINE_C920 = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_USB = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D_USB_Camera = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=2560, height=960, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_UVC = "pipeline: ksvideosrc device-index=0 ! image/jpeg ! jpegdec ! videoconvert";  // works for UVC Camera AntVR CAP 2
String PIPELINE_BRIO = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=2160, framerate=30/1 ! jpegdec ! videoconvert";
String pipeline = PIPELINE_BRIO;

int numberOfPanels = 1;
boolean flipHorz = false;  // mirror screen
boolean DEBUG = false;
int countdownStart = 3;  // seconds
String ipAddress;  // photo booth computer IP Address
JSONObject configFile;
JSONObject configuration;
JSONObject camera;

void initConfig() {
  configFile = loadJSONObject(sketchPath()+File.separator+"config"+File.separator+"config.json");
  configuration = configFile.getJSONObject("configuration");
  DEBUG = configuration.getBoolean("debug");
  flipHorz = configuration.getBoolean("mirrorScreen");
  countdownStart = configuration.getInt("countDownStart");
  fileType = configuration.getString("fileType");
  OUTPUT_FOLDER_PATH = configuration.getString("outputFolderPath");
  ipAddress = configuration.getString("IPaddress");
  instructionLineText = configuration.getString("instructionLineText");
  eventText = configuration.getString("eventText");

  camera = configuration.getJSONObject("camera");
  cameraName = camera.getString("name");
  cameraWidth = camera.getInt("width");
  cameraHeight = camera.getInt("height");
  pipeline = camera.getString("pipeline");
  if (DEBUG) println("configuration camera name="+cameraName);
}
