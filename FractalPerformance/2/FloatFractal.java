/*

File: FloatFractal.java

Abstract: This class generates a fractal using the diamond-square method
    implemented recursively.  This implementation passes integers defining
	the x/y coordinate of the points used rather than using a Point object.
	The point of this change is to show the performance and memory advantages
	you can attain by avoiding object allocation in cases where it is
	unnecesary.
	
    To see the fundamental code changes for this iteration of the demo
    search for the keyword "WWDC CHANGE".

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
import java.util.*;
import javax.swing.*;

/**
 * Class that generates a new fractal using the diamond-square method implemented in a
 * recursive algorithm.
 *
 * @author Joshua Outwater
 */
public class FloatFractal {
    /** Size of the fractal to generate.  Must be 2^n + 1 */
    private int _gridSize;
    /** Roughness value which creates more dramatic peaks/valleys when increased. */
    private float _fudgeFactor;
    private float[][] _data;
    private Random _random = new Random();
    private float _tmpHeight;
    private int _xDiff;
    private int _yDiff;
    private float _minHeight;
    private float _maxHeight;

    /* The range of values contained by this fractal. */
    private float _range;

    public FloatFractal(int gridSize, float fudgeFactor) {
        _gridSize = gridSize;
        _fudgeFactor = fudgeFactor;
        _data = new float[_gridSize][_gridSize];
    }

    /**
     * Return the 2D data array that contains the fractal data.
     */
    public float[][] getData() {
        return _data;
    }

    /**
     * Get the percentage of the range for the specified value in the fractal.
     *
     * @param x column
     * @param y row
     * @return percentage
     */
    public float getPercentageHeight(int x, int y) {
        return (_data[x][y] - _minHeight) / _range;
    }

    public float getMaxHeight() {
        return _maxHeight;
    }

    public float getMinHeight() {
        return _minHeight;
    }

    private void updateMinMaxHeight(float value) {
        if (value > _maxHeight) {
            _maxHeight = value;
        }

        if (value < _minHeight) {
            _minHeight = value;
        }
    }

    /**
     * Generate a new fractal.
     */
    public void generateFractal() {
        // Initialize the min/max height values.
        _minHeight = Float.MAX_VALUE;
        _maxHeight = Float.MIN_VALUE;

        // Initialize the data array.
        for (int x = 0; x < _gridSize; x++) {
            for (int y = 0; y < _gridSize; y++) {
                _data[x][y] = Float.MIN_VALUE;
            }
        }

        seedRecursiveData();

        recursiveGenerateFractal(0, 0, 0, _gridSize - 1, _gridSize - 1, 0,
                _gridSize - 1, _gridSize - 1, _fudgeFactor);

        // Calculate the range of values.
        _range = _maxHeight - _minHeight;
    }

    /**
     * Seed the four corners of the data map so we can generate a fractal.
     */
    private void seedRecursiveData() {
        _data[0][0] = (_random.nextFloat() % _fudgeFactor) *
                (_random.nextBoolean() ? 1 : -1);
        _data[0][_gridSize - 1] = (_random.nextFloat() % _fudgeFactor) *
                (_random.nextBoolean() ? 1 : -1);
        _data[_gridSize - 1][0] = (_random.nextFloat() % _fudgeFactor) *
                (_random.nextBoolean() ? 1 : -1);
        _data[_gridSize - 1][_gridSize - 1] = (_random.nextFloat() % _fudgeFactor) *
                (_random.nextBoolean() ? 1 : -1);
        updateMinMaxHeight(_data[0][0]);
        updateMinMaxHeight(_data[0][_gridSize - 1]);
        updateMinMaxHeight(_data[_gridSize - 1][0]);
        updateMinMaxHeight(_data[_gridSize - 1][_gridSize - 1]);
    }

    /**
     * Recursive algorithm that generates a fractal using the diamond-square method.
	 *
	 * WWDC CHANGE - Instead of passing in Point objects for each corner of the
     * square we want to calculate use ints defining the x,y position.
     */
    private void recursiveGenerateFractal(int topLeft_x, int topLeft_y,
			int bottomLeft_x, int bottomLeft_y,
            int bottomRight_x, int bottomRight_y,
			int topRight_x, int topRight_y, float fudgeFactor) {

        /**
         * Diamond step:
         *  Use the four points defining this square to calculate the value at the center.
         *  The center point is determined by averaging the square's edge values plus a random
         *  value.  By adding this new center point we have now created four diamonds.
         */
        // Calculate the midpoint of the square.
        int midPoint_x = (topLeft_x + topRight_x) / 2;
		int midPoint_y = (topLeft_y + bottomLeft_y) / 2;

        // Exit case.
        if (midPoint_x == topLeft_x && midPoint_y == topLeft_y) {
            return;
        }

        // Calculate the height of this new point.
        _tmpHeight = (_data[topLeft_x][topLeft_y] +
                _data[bottomLeft_x][bottomLeft_y] +
                _data[bottomRight_x][bottomRight_y] +
                _data[topRight_x][topRight_y]) / 4;
        _tmpHeight += (_random.nextFloat() % fudgeFactor) * (_random.nextBoolean() ? 1 : -1);
        _data[midPoint_x][midPoint_y] = _tmpHeight;
        updateMinMaxHeight(_data[midPoint_x][midPoint_y]);

        /**
         * Square step:
         *  Use the four points defining the diamonds to calculate the value at the center.  The
         *  center point is determined by averaging the diamond's edge values plus a random value.
         *  By adding these new center points to the diamonds we have now returned the grid to
         *  squares.
         */
        // Calculate the offscreen diamond point for the topMid if it wasn't calculated already.
        int topMid_x = (topLeft_x + topRight_x) / 2;
		int topMid_y = topLeft_y;
        if (_data[topMid_x][topMid_y] == Float.MIN_VALUE) {
            _yDiff = midPoint_y - topMid_y;
            _tmpHeight = Float.MIN_VALUE;
            if (topMid_y - _yDiff >= 0) {
                _tmpHeight = _data[topMid_x][topMid_y - _yDiff];
            }
            // Calculate the height of this new point.
            _data[topMid_x][topMid_y] = ((_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[topLeft_x][topLeft_y] +
                    _data[midPoint_x][midPoint_y] +
                    _data[topRight_x][topRight_y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[topMid_x][topMid_y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[topMid_x][topMid_y]);
        }

        // Calculate the offscreen diamond point for the midLeft if it wasn't calucaulted already.
		int midLeft_x = topLeft_x;
		int midLeft_y = (topLeft_y + bottomLeft_y) / 2;
        if (_data[midLeft_x][midLeft_y] == Float.MIN_VALUE) {
            _xDiff = midPoint_x - midLeft_x;
            _tmpHeight = Float.MIN_VALUE;
            if (midLeft_x - _xDiff >= 0) {
                _tmpHeight = _data[midLeft_x - _xDiff][midLeft_y];
            }
            // Calculate the height of this new point.
            _data[midLeft_x][midLeft_y] = (_data[topLeft_x][topLeft_y] +
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[bottomLeft_x][bottomLeft_y] +
                    _data[midPoint_x][midPoint_y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[midLeft_x][midLeft_y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[midLeft_x][midLeft_y]);
        }

        // Calculate the offscreen diamond point for the bottomMid if it wasn't calucaulted already.
        int bottomMid_x = (bottomLeft_x + bottomRight_x) / 2;
		int bottomMid_y = bottomLeft_y;
        if (_data[bottomMid_x][bottomMid_y] == Float.MIN_VALUE) {
            _yDiff = bottomMid_y - midPoint_y;
            _tmpHeight = Float.MIN_VALUE;
            if (bottomMid_y + _yDiff < _gridSize) {
                _tmpHeight = _data[bottomMid_x][bottomMid_y + _yDiff];
            }
            // Calculate the height of this new point.
            _data[bottomMid_x][bottomMid_y] = (_data[midPoint_x][midPoint_y] +
                    _data[bottomLeft_x][bottomLeft_y] +
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[bottomRight_x][bottomRight_y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[bottomMid_x][bottomMid_y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[bottomMid_x][bottomMid_y]);
        }

        // Calculate the offscreen diamond point for the midRight.
        int midRight_x = topRight_x;
		int midRight_y = (topRight_y + bottomRight_y) / 2;
        if (_data[midRight_x][midRight_y] == Float.MIN_VALUE) {
            _xDiff = midRight_x - midPoint_x;
            _tmpHeight = Float.MIN_VALUE;
            if (midRight_x + _xDiff < _gridSize) {
                _tmpHeight = _data[midRight_x + _xDiff][midRight_y];
            }
            // Calculate the height of this new point.
            _data[midRight_x][midRight_y] = (_data[topRight_x][topRight_y] +
                    _data[midPoint_x][midPoint_y] +
                    _data[bottomRight_x][bottomRight_y] + 
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0)) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[midRight_x][midRight_y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[midRight_x][midRight_y]);
        }

        // Halve the height for next round.
        fudgeFactor /= 2;

        // Generate fractal data for each new square.
		recursiveGenerateFractal(topLeft_x, topLeft_y, midLeft_x, midLeft_y,
            midPoint_x, midPoint_y, topMid_x, topMid_y, fudgeFactor);
        recursiveGenerateFractal(midLeft_x, midLeft_y, bottomLeft_x, bottomLeft_y,
            bottomMid_x, bottomMid_y, midPoint_x, midPoint_y, fudgeFactor);
        recursiveGenerateFractal(midPoint_x, midPoint_y, bottomMid_x, bottomMid_y,
            bottomRight_x, bottomRight_y, midRight_x, midRight_y, fudgeFactor);
        recursiveGenerateFractal(topMid_x, topMid_y, midPoint_x, midPoint_y,
            midRight_x, midRight_y, topRight_x, topRight_y, fudgeFactor);
    }

    public String toString() {
        StringBuffer strBuf = new StringBuffer();
        for (int x = 0; x < _gridSize; x++) {
            for (int y = 0; y < _gridSize; y++) {
                strBuf.append(_data[x][y] + " ");
            }
            strBuf.append("\n");
        }
        return strBuf.toString();
    }
}
