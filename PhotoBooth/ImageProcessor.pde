
String[] filters = {"NONE", "THRESHOLD", "GRAY", "OPAQUE", "INVERT", "POSTERIZE", "BLUR", "ERODE", "DILATE"};

class ImageProcessor {
  int filterNum;

  // broken mirror filter parameters
  // Size of each cell in the grid
  int cellSize = 20;
  // Number of columns and rows in our system
  int cols, rows;

  public ImageProcessor() {
    filterNum = 0;
    cols = width / cellSize;
    rows = height / cellSize;
    colorMode(RGB, 255, 255, 255, 100);
  }

  public PImage processImage(Capture input) {
    PImage output = null;
    output = input;
    //output.loadPixels();
    //output.updatePixels();
      
    //if (DEBUG) println("Filter: "+filters[filterNum]);
    switch (filterNum) {
    case 0:
      break;
    case 1:
      output.filter(GRAY);
      break;
    case 2:
      output.filter(THRESHOLD, 0.5);
      break;
    case 3:
      output.filter(POSTERIZE, 13);
      break;
    case 4:
      output.filter(POSTERIZE, 8);  // best
      break;
    case 5:
      output.filter(POSTERIZE, 5);
      break;
      //case 6:
      //  output.filter(POSTERIZE, 4);
      //  break;
      //case 7:
      //  output.filter(POSTERIZE, 3);
      //  break;
      case 8:
        output = mirror(output);
        break;
    default:
      break;
    }
    return output;
  }

  /**
   * Source Mirror example
   * by Daniel Shiffman.
   *
   * Each pixel from the video source is drawn as a rectangle with rotation based on brightness.
   */
  // Experimental
  private PImage mirror(PImage img) {
    PGraphics pg;
    int length = img.width*img.height;
    img.loadPixels();
    pg = createGraphics(img.width, img.height);
    pg.beginDraw();

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
        pushMatrix();
        pg.translate(x+cellSize/2, y+cellSize/2);
        // Rotation formula based on brightness
        pg.rotate((2 * PI * brightness(c) / 255.0));
        pg.rectMode(CENTER);
        pg.fill(c);
        pg.noStroke();
        // Rects are larger than the cell for some overlap
        pg.rect(0, 0, cellSize+6, cellSize+6);
        popMatrix();
      }
    }
    pg.endDraw();
    return pg.copy();
  }
}
