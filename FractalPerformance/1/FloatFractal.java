/*

File: FloatFractal.java

Abstract: This class generates a fractal using the diamond-square method
    implemented recursively.

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

        recursiveGenerateFractal(new Point(0, 0),
                new Point(0, _gridSize - 1),
                new Point(_gridSize - 1, 0),
                new Point(_gridSize - 1, _gridSize - 1), _fudgeFactor);

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
     */
    private void recursiveGenerateFractal(Point topLeft, Point bottomLeft,
            Point bottomRight, Point topRight, float fudgeFactor) {

        /**
         * Diamond step:
         *  Use the four points defining this square to calculate the value at the center.
         *  The center point is determined by averaging the square's edge values plus a random
         *  value.  By adding this new center point we have now created four diamonds.
         */
        // Calculate the midpoint of the square.
        Point midPoint = new Point((topLeft.x + topRight.x) / 2,
                (topLeft.y + bottomLeft.y) / 2) ;

        // Exit case.
        if (midPoint.equals(topLeft)) {
            return;
        }

        // Calculate the height of this new point.
        _tmpHeight = (_data[topLeft.x][topLeft.y] +
                _data[bottomLeft.x][bottomLeft.y] +
                _data[bottomRight.x][bottomRight.y] +
                _data[topRight.x][topRight.y]) / 4;
        _tmpHeight += (_random.nextFloat() % fudgeFactor) * (_random.nextBoolean() ? 1 : -1);
        _data[midPoint.x][midPoint.y] = _tmpHeight;
        updateMinMaxHeight(_data[midPoint.x][midPoint.y]);

        /**
         * Square step:
         *  Use the four points defining the diamonds to calculate the value at the center.  The
         *  center point is determined by averaging the diamond's edge values plus a random value.
         *  By adding these new center points to the diamonds we have now returned the grid to
         *  squares.
         */
        // Calculate the offscreen diamond point for the topMid if it wasn't calculated already.
        Point topMid = new Point((topLeft.x + topRight.x) / 2, topLeft.y);
        if (_data[topMid.x][topMid.y] == Float.MIN_VALUE) {
            _yDiff = midPoint.y - topMid.y;
            _tmpHeight = Float.MIN_VALUE;
            if (topMid.y - _yDiff >= 0) {
                _tmpHeight = _data[topMid.x][topMid.y - _yDiff];
            }
            // Calculate the height of this new point.
            _data[topMid.x][topMid.y] = ((_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[topLeft.x][topLeft.y] +
                    _data[midPoint.x][midPoint.y] +
                    _data[topRight.x][topRight.y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[topMid.x][topMid.y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[topMid.x][topMid.y]);
        }

        // Calculate the offscreen diamond point for the midLeft if it wasn't calucaulted already.
        Point midLeft = new Point(topLeft.x , (topLeft.y + bottomLeft.y) / 2);
        if (_data[midLeft.x][midLeft.y] == Float.MIN_VALUE) {
            _xDiff = midPoint.x - midLeft.x;
            _tmpHeight = Float.MIN_VALUE;
            if (midLeft.x - _xDiff >= 0) {
                _tmpHeight = _data[midLeft.x - _xDiff][midLeft.y];
            }
            // Calculate the height of this new point.
            _data[midLeft.x][midLeft.y] = (_data[topLeft.x][topLeft.y] +
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[bottomLeft.x][bottomLeft.y] +
                    _data[midPoint.x][midPoint.y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[midLeft.x][midLeft.y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[midLeft.x][midLeft.y]);
        }

        // Calculate the offscreen diamond point for the bottomMid if it wasn't calucaulted already.
        Point bottomMid = new Point((bottomLeft.x + bottomRight.x) / 2, bottomLeft.y);
        if (_data[bottomMid.x][bottomMid.y] == Float.MIN_VALUE) {
            _yDiff = bottomMid.y - midPoint.y;
            _tmpHeight = Float.MIN_VALUE;
            if (bottomMid.y + _yDiff < _gridSize) {
                _tmpHeight = _data[bottomMid.x][bottomMid.y + _yDiff];
            }
            // Calculate the height of this new point.
            _data[bottomMid.x][bottomMid.y] = (_data[midPoint.x][midPoint.y] +
                    _data[bottomLeft.x][bottomLeft.y] +
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0) +
                    _data[bottomRight.x][bottomRight.y]) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[bottomMid.x][bottomMid.y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[bottomMid.x][bottomMid.y]);
        }

        // Calculate the offscreen diamond point for the midRight.
        Point midRight = new Point(topRight.x, (topRight.y + bottomRight.y) / 2);
        if (_data[midRight.x][midRight.y] == Float.MIN_VALUE) {
            _xDiff = midRight.x - midPoint.x;
            _tmpHeight = Float.MIN_VALUE;
            if (midRight.x + _xDiff < _gridSize) {
                _tmpHeight = _data[midRight.x + _xDiff][midRight.y];
            }
            // Calculate the height of this new point.
            _data[midRight.x][midRight.y] = (_data[topRight.x][topRight.y] +
                    _data[midPoint.x][midPoint.y] +
                    _data[bottomRight.x][bottomRight.y] + 
                    (_tmpHeight != Float.MIN_VALUE ? _tmpHeight : 0)) /
                        (_tmpHeight != Float.MIN_VALUE ? 4 : 3);
            _data[midRight.x][midRight.y] += (_random.nextFloat() % fudgeFactor) *
                    (_random.nextBoolean() ? 1 : -1);
            updateMinMaxHeight(_data[midRight.x][midRight.y]);
        }

        // Halve the height for next round.
        fudgeFactor /= 2;

        // Generate fractal data for each new square.
        recursiveGenerateFractal(topLeft, midLeft, midPoint, topMid, fudgeFactor);
        recursiveGenerateFractal(midLeft, bottomLeft, bottomMid, midPoint, fudgeFactor);
        recursiveGenerateFractal(midPoint, bottomMid, bottomRight, midRight, fudgeFactor);
        recursiveGenerateFractal(topMid, midPoint, midRight, topRight, fudgeFactor);
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
