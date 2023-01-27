// Apply filters to the live view
// Processing filters available are:
String[] filters = {"NONE", "THRESHOLD", "GRAY", "OPAQUE", "INVERT", "POSTERIZE", "BLUR", "ERODE", "DILATE"};

class ImageProcessor {
  int filterNum;

  // broken mirror filter parameters
  // Size of each cell in the grid
  int cellSize = 40;
  // Number of columns and rows for mirror
  int cols, rows;

  public ImageProcessor() {
    filterNum = 0;
    colorMode(RGB, 255, 255, 255, 100);
  }

  public PImage processImage(PImage temp) {
    temp.loadPixels();
    switch (filterNum) {
    case 0:
      temp.filter(0);
      break;
    case 1:
      temp.filter(GRAY);
      break;
    case 2:
      temp.filter(THRESHOLD, 0.5);
      break;
    case 3:
      temp.filter(POSTERIZE, 13);
      break;
    case 4:
      temp.filter(POSTERIZE, 8);  // best
      break;
    case 5:
      temp.filter(POSTERIZE, 5);
      break;
    case 6:
      temp.filter(POSTERIZE, 4);
      break;
    case 7:
      temp.filter(POSTERIZE, 3);
      break;
    case 8:
      temp = mirror(temp);
      break;
    default:
      //temp.filter(0);
      break;
    }
    return temp;
  }

  /**
   * Mirror example for Processing 4
   * by Daniel Shiffman.
   * Modified by Andy Modla
   * Each pixel from the video source is drawn as a rectangle with rotation based on brightness.
   */
  private PImage mirror(PImage img) {
    cols = img.width / cellSize;
    rows = img.height / cellSize;
    PGraphics pg;
    int length = img.width*img.height;
    img.loadPixels();
    pg = createGraphics(img.width, img.height, RENDERER);
    pg.beginDraw();
    pg.background(255);
    // Begin loop for columns
    for (int i = 0; i < cols; i++) {
      // Begin loop for rows
      for (int j = 0; j < rows; j++) {

        // Where are we, pixel-wise?
        int x = i*cellSize;
        int y = j*cellSize;
        int loc = (img.width - x - 1) + y*img.width; // Reversing x to mirror the image
        if (loc <0 || loc >= length) continue;
        float r = red(img.pixels[loc]);
        float g = green(img.pixels[loc]);
        float b = blue(img.pixels[loc]);
        // Make a new color with an alpha component
        color c = color(r, g, b, 75);

        // Code for drawing a single rect
        // Using translate in order for rotation to work properly
        pg.pushMatrix();
        pg.translate(x+cellSize/2, y+cellSize/2);
        // Rotation formula based on brightness
        pg.rotate((2 * PI * brightness(c) / 255.0));
        pg.rectMode(CENTER);
        pg.fill(c);
        pg.noStroke();
        // Rects are larger than the cell for some overlap
        pg.rect(0, 0, cellSize+6, cellSize+6);
        pg.popMatrix();
      }
    }
    pg.endDraw();
    PImage temp = pg.copy();
    return temp;
  }
}
