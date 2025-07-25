import java.util.*;

/*
This creative tool creates a form of a paint-by-number coloring template. 
From an original image, it creates a simplified version of it (by defining colorAmount, colorRange and BLURValue) and turns this into a coloring template

To START, change fileName into name of your image and RUN. 
Tweak colorAmount if you want more/less colors (if more colors are added, the result becomes more detailed, making it more complex)
Tweak colorRange to add less/more variation in colors
Tweak BLURValue, lower value = more detailed, higher value = less detailed
*/


// DEFINE THOSE VARIABLES, POSSIBLE CHANGE PER PICTURE
int colorAmount = 20;
int colorRange = 600;
String fileName = "images/flower.jpg";
int BLURValue = 3;


PImage img, img2, img3, eraser, save;
PGraphics offscreen;
Map<Integer, Integer> colorCounts;
List<Map.Entry<Integer, Integer>> list;
int[] palette;
int previousCol;
int selectedStrokeWeight = 1;
int counter = 0;
boolean eraserON = false;
int selectedColor = color(100, 100, 100);
float selectedSaturation = 100;
float selectedBrightness = 100;
float selectedHue = 0;
float pickerX, pickerY1, pickerY2, pickerY3, pickerY4, pickerY5, pickerWidth, pickerHeight;



void setup() {
  size(1000, 1000);
  colorCounts = new HashMap<Integer, Integer>();

  // make offscreen buffer
  offscreen = createGraphics(1000, 1000);

  img = loadImage(fileName);
  img.resize(500, 500);

  img2 = img.copy();
  img.filter(BLUR, BLURValue);

  img.loadPixels();

  // make color palette
  palette = makeColorPalette(colorAmount, img, colorRange);

  // Map each pixel to the nearest color in the palette
  for (int i = 0; i < img.pixels.length; i++) {
    img.pixels[i] = findNearestPaletteColor(img.pixels[i]);
  }
  img3 = img.copy(); // create copy of the mapped, blurred image
  
  // then do edgeDetection
  edgeDetection(img);

  img.updatePixels();

  eraser = loadImage("tools/eraser2.png");
  save = loadImage("tools/save.png");
  eraser.resize(30, 30);
  save.resize(30, 30);


  makePickers();
  image(eraser, pickerX+pickerWidth+70, pickerY5);
  image(save, pickerX+pickerWidth+130, pickerY5);
}

void draw() {

  // draw everything onto the screen

  image(img2, 0, 0);
  image(img3, width/2, 0);
  image(img, width/2, height/2);

  // activate the pickers
  strokePicker();
  colorPicker();
  huePicker();
  brightnessPicker();
  saturationPicker();


  // draw an 'activating' rectangle around the eraser if it's been clicked on, otherwise, remove it by drawing a black rectangle above it
  if (eraserON) {
    stroke(255, 0, 0);
    noFill();
    rect(pickerX+pickerWidth+60, pickerY5-8, 50, 50);
    noStroke();
  } else {
    stroke(0, 0, 0);
    noFill();
    rect(pickerX+pickerWidth+60, pickerY5-8, 50, 50);
  }

  // draw a rectangle with the selected color
  fill(selectedColor);
  rect(pickerX+pickerWidth+65, pickerY2+pickerHeight/2, pickerHeight*2, pickerHeight*2);

  // check if the mouse is pressed and within the specified area of the coloring picture
  if (mousePressed && mouseY > height/2 && mouseX > width/2) {
    // Start drawing on the offscreen buffer
    offscreen.beginDraw();
    offscreen.strokeWeight(selectedStrokeWeight); // set the stroke weight for the offscreen buffer
    offscreen.stroke(selectedColor); // set the color for the paint brush in the offscreen buffer
    offscreen.line(mouseX, mouseY, pmouseX, pmouseY); // draw the line on the offscreen buffer
    offscreen.strokeWeight(1);
    offscreen.noStroke(); // prevent other strokes from being adjusted
    offscreen.endDraw(); // End drawing on the offscreen buffer
  }

  // Display the offscreen buffer
  image(offscreen, 0, 0);
}


void makePickers() {
  // set values for pickers
  pickerX = width/15;
  pickerY1 = height/10*5.5;
  pickerY2 = height/10*6.5;
  pickerY3 = height/10*7.5;
  pickerY4 = height/10*8.5;
  pickerY5 = height/10*9.2;
  pickerWidth = 200;
  pickerHeight = 50;

  // background of picker area
  background(0);
  // create rectangles for pickers
  fill(255);
  rect(pickerX, pickerY1, pickerWidth, pickerHeight);
  rect(pickerX, pickerY4, pickerWidth, pickerHeight/2);
  rect(pickerX, pickerY5, pickerWidth, pickerHeight/2);

  // adding labels
  fill(255);
  textSize(18);
  textAlign(LEFT, TOP);
  text("Stroke picker", pickerX, pickerY1 - 30);
  text("Color picker", pickerX, pickerY2 - 30);
  text("Hue picker", pickerX, pickerY3 - 30);
  text("Saturation picker", pickerX, pickerY4 -30);
  text("Brightness picker", pickerX, pickerY5 -30);
}

void strokePicker() {
  // updates the stroke of the "paint brush"
  if (mousePressed) {
    if (mouseX > pickerX && mouseX < pickerX+pickerWidth && mouseY > pickerY1 && mouseY < pickerY1+pickerHeight) { // stroke picker area
      selectedStrokeWeight = mouseX/20; // make the strokeweight somewhat smaller than the X value of the mouse
      offscreen.beginDraw();
      offscreen.strokeWeight(1); // strokeweight of the rectangle of the strokepicker
      offscreen.stroke(0);
      offscreen.fill(255);
      offscreen.rect(pickerX, pickerY1, pickerWidth, pickerHeight);
      offscreen.strokeWeight(selectedStrokeWeight); // select the strokeweight for the "paint brush"
      offscreen.line(mouseX, pickerY1, mouseX, pickerY1+pickerHeight); // draw a line at the selected strokeweight, with the selected strokeweight
      offscreen.noStroke(); // prevent other strokes to resemble
      offscreen.endDraw();
    }
  }
}


void colorPicker() {
  // creates a color picker of the amount of colors specified in the palette
  offscreen.beginDraw();

  for (int i = 0; i < palette.length; i++) {
    offscreen.fill(palette[i]); // fill every stripe with the next color in the palette
    offscreen.rect(pickerX+i* (pickerWidth/palette.length), pickerY2, pickerWidth/palette.length, pickerHeight); // create a rectangle for every color with a dynamic width of the total size of the palette
  }
  offscreen.endDraw();
}


void huePicker() {
  // creates a hue picker of 360 colors
  offscreen.beginDraw();
  offscreen.colorMode(HSB, 360, 100, 100);

  for (int i = 0; i < 360; i++) {
    offscreen.noStroke();
    offscreen.fill(i, 100, 100); // fill every stripe with the next color
    offscreen.rect(pickerX+ + i*(pickerWidth / 360), pickerY3, pickerWidth/360, pickerHeight); // create a rectangle for every color
  }
  offscreen.colorMode(RGB, 255);
  offscreen.endDraw();
}

void saturationPicker() {
  // creates a saturation picker of 100 values
  offscreen.beginDraw();
  offscreen.colorMode(HSB, 360, 100, 100);

  for (int i = 0; i < 100; i++) {
    offscreen.noStroke();
    offscreen.fill(selectedColor, 0, i); // fill every stripe with the next color
    offscreen.rect(pickerX+ + i*(pickerWidth / 100), pickerY5, pickerWidth/100, pickerHeight/2); // create a rectangle for every color
  }
  offscreen.colorMode(RGB, 255);
  offscreen.endDraw();
}

void brightnessPicker() {
  // creates a brightness picker of 100 values
  offscreen.beginDraw();
  offscreen.colorMode(HSB, 360, 100, 100);

  for (int i = 0; i < 100; i++) {
    offscreen.noStroke();
    offscreen.fill(selectedColor, i, 100); // fill every stripe with the next color
    offscreen.rect(pickerX+ + i*(pickerWidth / 100), pickerY4, pickerWidth/100, pickerHeight/2); // create a rectangle for every color
  }
  offscreen.colorMode(RGB, 255);
  offscreen.endDraw();
}

void mousePressed() {
  // if mousepressed in a certain area, change the selected color, activate eraser or save the picture

  // PALETTE
  if (mouseY >= pickerY2 && mouseY <= pickerY2 + pickerHeight && mouseX < pickerX+pickerWidth && mouseX > pickerX) {         // color palette of picture area
    int inPalette = int(map(mouseX, pickerX, pickerX+pickerWidth, 0, palette.length));                                       // map the coordinates into the length of the palette
    selectedColor = palette[inPalette];                                                                                      // pick the selected color out of the palette
    push();
    colorMode(HSB, 360, 100, 100);
    selectedHue = hue(selectedColor);                                                                                        // update selected hue
    colorMode(RGB, 255); 
    pop();
    eraserON = false;                                                                                                        // when clicked on a color, de-activate eraser
  }

  // HUE
  else if (mouseY >= pickerY3 && mouseY <= pickerY3 + pickerHeight && mouseX < pickerX+pickerWidth && mouseX > pickerX) {  // hue palette area
    selectedColor = int(map(mouseX, pickerX, pickerX+pickerWidth, 0, 360));                                                // map the coordinates into the length of the hue (360)
    selectedHue = selectedColor;                                                                                           // update selectedHue
    selectedColor = HSBtoRGB(selectedColor, selectedSaturation, selectedBrightness);                                       // change from HSB to RGB
    eraserON = false;                                                                                                      // when clicked on a color, de-activate eraser
  }

  // SATURATION
  else if (mouseY >= pickerY4 && mouseY <= pickerY4 + pickerHeight/2 && mouseX < pickerX+pickerWidth && mouseX > pickerX) {  // saturation area
    selectedSaturation = int(map(mouseX, pickerX, pickerX+pickerWidth, 0, 100));                                             // map the coordinates into the length of the saturation (100)
    selectedColor = HSBtoRGB(selectedHue, selectedSaturation, selectedBrightness);                                           // change from HSB to RGB
    eraserON = false;                                                                                                        // when clicked on a color, de-activate eraser
  }

  // BRIGHTNESS
  else if (mouseY >= pickerY5 && mouseY <= pickerY5 + pickerHeight/2 && mouseX < pickerX+pickerWidth && mouseX > pickerX) {  // brightness area
    selectedBrightness = int(map(mouseX, pickerX, pickerX+pickerWidth, 0, 100));                                             // map the coordinates into the length of the brightness (100)
    selectedColor = HSBtoRGB(selectedHue, selectedSaturation, selectedBrightness);                                           // change from HSB to RGB
    eraserON = false;                                                                                                        // when clicked on a color, de-activate eraser
  }

  // EREASER
  else if (mouseX > pickerX+pickerWidth+70 && mouseX < pickerX+pickerWidth+70+30 && mouseY > pickerY5) {                     // eraser erea
    selectedColor = color(255);                                                                                              // make the stroke white, like an eraser
    eraserON = true;                                                                                                         // activate eraser
  }

  // SAVING
  else if (mouseX > pickerX+pickerWidth+130 && mouseX < pickerX+pickerWidth+130+30 && mouseY > pickerY5) {                   // save area
    PImage saveImg = get(width/2, height/2, 500, 500);                                                                       // get only the colored picture
    saveImg.save("results_saved/myColoringpicture" + counter + ".jpg");                                                                    // save the colored picture
    counter++;                                                                                                               // add counter to prevent overwriting if multiple are saved

    // add an "activating" rectangle, so that the user knows it has been clicked (togehter with the textual feedback)
    stroke(255, 0, 0);
    noFill();
    rect(pickerX+pickerWidth+120, pickerY5-8, 50, 50);
    println("Coloring picture saved!");
  }
}

void mouseReleased() {
  // make the "activated" rectangle of the save button black, to let it disappear
  stroke(0, 0, 0);
  noFill();
  rect(pickerX+pickerWidth+120, pickerY5-8, 50, 50);
}


int findNearestPaletteColor(int the_color) {
  // map every pixel color of the image to an existing color of the palette
  // takes a color of a pixel and returns an integer of the nearest color in distance

  // calculate the distance to the first color of the palette to create a comparable variable in the for loop
  int nearestColor = palette[0];
  float nearestDist = dist(red(the_color), green(the_color), blue(the_color), red(nearestColor), green(nearestColor), blue(nearestColor));

  for (int i = 1; i < palette.length; i++) {
    float d = dist(red(the_color), green(the_color), blue(the_color), red(palette[i]), green(palette[i]), blue(palette[i]));
    if (d < nearestDist) { // if the next color in the palette is smaller in distance than the current nearest color, make it the new nearest color
      nearestDist = d;
      nearestColor = palette[i];
    }
  }

  return nearestColor; // return the color that resembles the current color the most
}

color HSBtoRGB(float hue, float saturation, float brightness) {
  // turn a HSB color into a RGB color
  // takes a hue color and returns a RGB color value
  colorMode(HSB, 360, 100, 100); // put current mode into HSB
  color hsbColor = color(hue, saturation, brightness);

  // put current mode into RGB and extract individual R G and B values out of the made hsb color
  colorMode(RGB, 255);
  float r = red(hsbColor);
  float g = green(hsbColor);
  float b = blue(hsbColor);

  return color(r, g, b); // return rgb value
}


int[] makeColorPalette(int amount, PImage img, int colorRange) {
  // makes a color palette with a specified length with the most striking colors out of all colors detected in the image
  // takes the length of the palette (amount), the image and the colorRange, which defines the variability of the colors and returns the created palette

  // make a dictionary (map) of unique colors and counts how often they occur
  // loops over the total pixels of the image with a specified range to reach more different colors
  for (int i = 0; i < img.pixels.length; i=i+colorRange) {
    int col = img.pixels[i];                                 // extract the color
    if (colorCounts.containsKey(col)) {                      // checks if color is already in the map
      colorCounts.put(col, colorCounts.get(col) + 1);        // if so, count one extra
    } else {
      colorCounts.put(col, 1);                               // if not, put it in the map
    }
  }

  // create a list from elements of the map and sort it (hashmaps can't be sorted)
  list = new ArrayList<>(colorCounts.entrySet());
  list.sort(Map.Entry.comparingByValue(Comparator.reverseOrder()));

  // extract the top 'amount' colors
  int[] palette = new int[amount];
  for (int i = 0; i < amount; i++) {
    palette[i] = list.get(i).getKey();
  }

  return palette; // returns the palette of top x amount of colors in it
}

void edgeDetection(PImage img) {
  offscreen.beginDraw();
  // compares each pixel to the next one to detect color change. If there is a color change, make it black to create an edge, otherwise make it white
  // takes an image and turns it into a black and white coloring picture
  for (int x = 0; x < height/2; x++) {            // loop over every row
    color previousCol = img.pixels[x * height/2]; // initialize the previous color at the start of each column, to prevent comparing the top row to the bottom row

    for (int y = 1; y < width/2; y++) {           // loop over every row
      int index = y + (x * height)/2;
      color col = img.pixels[index];              // get pixel color

      if (previousCol != col) {
        img.pixels[index] = color(0);             // if previous color is not the current color, change the current color into black
      } else {
        img.pixels[index] = color(255);           // if previous color is the current color, change the current color into white
      }

      previousCol = col;                          // make the current color the previous color
    }
  }
  offscreen.endDraw();
}
