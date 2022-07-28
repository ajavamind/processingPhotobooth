
String[] filters = {"NONE", "THRESHOLD", "GRAY", "OPAQUE", "INVERT", "POSTERIZE", "BLUR", "ERODE", "DILATE"};

class ImageProcessor {
  int filterNum;
  public ImageProcessor() {
    filterNum = 0;
  }

  public PImage processImage(Capture input) {
    PImage output = null;
    try {
      output =  input;
    } 
    catch (Exception ex) {
      ex.printStackTrace(System.out);
    }
    //if (DEBUG) println("Filter: "+filters[filterNum]);
    switch (filterNum) {
    case 0:
      output.filter(0);  // None - needed to get image out of gStreamer
      break;
    case 1:
      output.filter(GRAY);
      break;
    case 2:
      output.filter(THRESHOLD, 0.3);
      break;
    case 3:
      output.filter(POSTERIZE, 13);
      break;
    case 4:
      output.filter(POSTERIZE, 8);
      break;
    case 5:
      output.filter(POSTERIZE, 5);
      break;
    case 6:
      output.filter(POSTERIZE, 4);
      break;
    case 7:
      output.filter(POSTERIZE, 3);
      break;
    case 8:
      output.filter(POSTERIZE, 2);
      break;
    default:
      break;
    }
    return output;
  }
}
