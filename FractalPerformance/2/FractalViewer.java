/*

File: FractalViewer.java

Abstract: Implementation of a fractal viewer that displays data as a height map.
    The point of this implementation is to show the slow nature of rendering
    image data by using fillRect.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright © 2001-2005 Apple Computer, Inc., All Rights Reserved

*/

import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import javax.swing.*;

/**
 * A fractal viewer that displays fractal data as a height map.
 *
 * @author Joshua Outwater
 */
public class FractalViewer extends JFrame {
    /** Used to control which fractal iterations should be painted to the screen. */
    private int _interval = 1;
    /** Size of the fractal to generate.  Must be 2^n + 1 */
    private int _gridSize = 513;
    /** Roughness value which creates more dramatic peaks/valleys when increased. */
    private float _floatFudge = 1;
    /** Flag used to control the fractal generator thread. */ 
    private boolean _run = true;

    public static void main(String args[]) {
        new FractalViewer();
    }

    public FractalViewer() {
        super("Float Fractal Viewer using fillRect()");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        getContentPane().setLayout(new BorderLayout());
        getContentPane().add(BorderLayout.CENTER, new FloatFractalPanel());
		
		Rectangle screenBounds = GraphicsEnvironment.getLocalGraphicsEnvironment().
			getDefaultScreenDevice().getDefaultConfiguration().getBounds();
		int maxSize = screenBounds.width > screenBounds.height ?
			screenBounds.width : screenBounds.height;
		int size = (maxSize / 3) * 2;
		int x = (screenBounds.width - maxSize + maxSize / 3) / 2;
		int y = (screenBounds.height - maxSize + maxSize / 3) / 2;
		setBounds(x, y, size, size);
		setVisible(true);
    }

    public class FloatFractalPanel extends JPanel {
        private BufferedImage image;
        private FloatFractal fractal;
        private Thread thread;
        private int toggle = 0;
		
		/** Large font used for displaying the fractals per minute. */
		private Font largeFont = new Font("Lucida Sans", Font.BOLD, 42);
		/** Transparent color used for background of text so it's readable. */
		private Color transColor = new Color(0f, 0f, 0f, .5f);
        /** Total number of fractals generated. */
        private int numGenerated = 0;
        /** Fractals per minute. */
        private int fractalsPerMin = 0;
        /** Total time used to generate a fractal in milliseconds. */
        private long timeToGenerate = 0;
        /** Total time used to render a fractal in milliseconds. */
        private long timeToRender = 0;
        /** Average time used to generate a fractal in milliseconds. */
        private long aveTimeToGenerate = 0;
        /** Average time used to render a fractal in milliseconds. */
        private long aveTimeToRender = 0;

        public FloatFractalPanel() {
            KeyStroke spaceKey = KeyStroke.getKeyStroke(KeyEvent.VK_SPACE, 0, false);
            InputMap inputMap = getInputMap(JComponent.WHEN_FOCUSED);
            inputMap.put(spaceKey, "TOGGLE");
            ActionMap actionMap = getActionMap();
            actionMap.put("TOGGLE", new ToggleAction());

            image = new BufferedImage(_gridSize, _gridSize, BufferedImage.TYPE_INT_RGB);
            fractal = new FloatFractal(_gridSize, _floatFudge);
            thread = new FloatFractalThread();
            thread.start();
        }
            
        public Dimension getPreferredSize() {
            return new Dimension(image.getWidth(), image.getHeight());
        }

        public Dimension getMinimumSize() {
            return getPreferredSize();
        }

        public void paintComponent(Graphics g) {
            super.paintComponent(g);
            g.drawImage(image, 0, 0, getWidth(), getHeight(),
				0, 0, image.getWidth(), image.getHeight(), null);
        }

		/**
		 * Paint fractals per minute at top left corner of fractal.
		 */
		 public void paintFractalsPerMinute(Graphics g) {
			Font oldFont = g.getFont();
			g.setFont(largeFont);
			FontMetrics fm = g.getFontMetrics(g.getFont());
            int fontHeight = fm.getMaxDescent() + fm.getMaxAscent() + fm.getLeading();
			long totalTime = timeToGenerate + timeToRender;
            if (totalTime != 0) {
                fractalsPerMin = (int)(numGenerated * 60000 / totalTime);
            }
			String str = Integer.toString(fractalsPerMin) + " fpm";
			g.setColor(transColor);
            g.fillRoundRect(5, 5, fm.stringWidth(str) + 10, fontHeight + 10, 10, 10);
						g.setColor(Color.WHITE);
			g.drawString(str, 10, fontHeight + 10 - fm.getMaxDescent());
			g.setFont(oldFont);
		 }
		 
        /**
         * Paint bar graph data overlayed on top of the fractal image.
         */
        public void paintBarGraph(Graphics g) {
            int barLength = 300;
            int barHeight = 20;

            g.setColor(transColor);
            g.fillRoundRect(5, image.getHeight() - 15 - barHeight, barLength + 10, barHeight + 10, 10, 10);
			
			int y = image.getHeight() - 10 - barHeight;
			long totalTime = aveTimeToGenerate + aveTimeToRender;
            if (totalTime != 0) {
				g.setColor(Color.getHSBColor(0.17f, 0.70f, 1.0f));
                int generateBarLength = (int)(aveTimeToGenerate * barLength /
                        (aveTimeToGenerate + aveTimeToRender));
                g.fillRect(10, y, generateBarLength, barHeight);
				g.setColor(Color.getHSBColor(1.0f, 0.70f, 1.0f));
                g.fillRect(10 + generateBarLength, y, barLength - generateBarLength, barHeight);
            }
        }

		/**
         * Paint time data overlayed on top of the fractal image.
         */
        public void paintTimes(Graphics g) {
            FontMetrics fm = g.getFontMetrics(getFont());
            int fontHeight = fm.getMaxDescent() + fm.getMaxAscent() + fm.getLeading();

			String generateStr = "Average time to generate(ms): " + aveTimeToGenerate;
			String renderStr = "Average time to render(ms): " + aveTimeToRender;
			
			int boxWidth = generateStr.length() > renderStr.length() ? 
				fm.stringWidth(generateStr) : fm.stringWidth(renderStr);
            int boxHeight = fontHeight * 2;
            
            g.setColor(transColor);
            g.fillRoundRect(5, image.getHeight() - boxHeight - 20, boxWidth + 10,
				boxHeight + 15, 10, 10);

            g.setColor(Color.WHITE);
			g.drawString(generateStr, 10, image.getHeight() - 10 - fm.getMaxDescent());
			g.drawString(renderStr, 10, image.getHeight() - 15 - fontHeight - fm.getMaxDescent());
        }
    
        public class FloatFractalThread extends Thread {
            private long start;
            public void run() {
                while (_run) {
                    start = System.currentTimeMillis();
                    fractal.generateFractal();
                    timeToGenerate += System.currentTimeMillis() - start;
                    numGenerated++;
                    aveTimeToGenerate = timeToGenerate / numGenerated;
                    if (numGenerated % _interval == 0) {
                        // Display this fractal.
                        final float minHeight = fractal.getMinHeight();
                        final float maxHeight = fractal.getMaxHeight();
                        final float[][] data = fractal.getData();
                        final float range = maxHeight - minHeight;

						Graphics2D g2d = image.createGraphics();
                        start = System.currentTimeMillis();
						for (int x = 0; x < _gridSize; x++) {
							for (int y = 0; y < _gridSize; y++) {
								g2d.setColor(Color.getHSBColor(0.6f, 0.7f,
									fractal.getPercentageHeight(x, y)));
								g2d.fillRect(x, y, x + 1, y + 1);
							}
						}
						timeToRender += System.currentTimeMillis() - start;
                        aveTimeToRender = timeToRender / numGenerated;
						// Paint the timing information as necessary.
						paintFractalsPerMinute(g2d);
						if (toggle == 1) {
							paintTimes(g2d);
						} else if (toggle == 2) {
							paintBarGraph(g2d);
						}
						g2d.dispose();
						FloatFractalPanel.this.repaint();
                    }
                }
            }
        }

        private class ToggleAction extends AbstractAction {
            public void actionPerformed(ActionEvent ev) {
                toggle = (toggle + 1) % 3;
            }
        }
    }
}
