//
// File:       hud.cpp
//
// Abstract:   This example performs an NBody simulation which calculates a gravity field 
//             and corresponding velocity and acceleration contributions accumulated 
//             by each body in the system from every other body.  This example
//             also shows how to mitigate computation between all available devices
//             including CPU and GPU devices, as well as a hybrid combination of both,
//             using separate threads for each simulator.
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//

////////////////////////////////////////////////////////////////////////////////

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <map>

#include <OpenGL/gl.h>
#include <ApplicationServices/ApplicationServices.h>

#include "graphics.h"
#include "hud.h"


StuffPerSecondMeter::StuffPerSecondMeter(size_t frameBufferSize, bool rampUp)
        : _frameBufferSize(frameBufferSize),
        _frameBuffer(new double[frameBufferSize]),
        _i(0),
        _rampUp(rampUp),
        _n(0)
{}

StuffPerSecondMeter::~StuffPerSecondMeter()
{
    delete [] _frameBuffer;
}

void StuffPerSecondMeter::reset()
{
    for (size_t i = 0; i < _frameBufferSize; ++i)
    {
        _frameBuffer[i] = 0.0;
    }
    _n = 0;
}

void StuffPerSecondMeter::recordFrame(double stuff, double dt)
{
    ++_n;
    _frameBuffer[_i] = stuff / dt;
    _i = (_i + 1) % _frameBufferSize;
}

double StuffPerSecondMeter::stuffPerSecond() const
{
    double total = 0.0;
    for (size_t i = 0; i < _frameBufferSize; ++i)
    {
        total += _frameBuffer[i];
    }
    return total / (_rampUp ? _frameBufferSize : std::min(_n, _frameBufferSize));
}

//----------------------------------------------------------------------------

#define TICKS            8
#define SUBTICKS         4
#define CENTERX          0.5
#define CENTERY          0.5
#define NEEDLE_THICKNESS 12
#define OFFSCREEN        5000
#define LEGEND_WIDTH     256.0
#define LEGEND_HEIGHT    64.0
#define VALUE_WIDTH      128.0
#define VALUE_HEIGHT     64.0


static std::map<std::string, GLuint> value_textures;

static GLuint value_texture(std::string const &text)
{
    return CreateTextureWithLabel(text, 52, true, VALUE_WIDTH, VALUE_HEIGHT);
}

static std::string stringify(unsigned i)
{
    char buffer[16];
    sprintf(buffer, "%u", i);
    return buffer;
}

template <class T>
GLuint value_texture_for(const T &t)
{
    std::string text = stringify(t);
    GLuint texture = value_textures[text];

    if (texture == 0)
    {
        texture = value_texture(text);
        value_textures[text] = texture;
    }

    return texture;
}

static void drawMarks(CGContextRef gc, int width, int height, int max)
{
    float   angle, c, s, tick, radius, needle;
    float   r0, r1, r2, r3, cx, cy;
    int     i, start, end, redline, section;

    cx        = CENTERX * width;
    cy        = CENTERY * height;
    redline   = TICKS * SUBTICKS * 0.8;
    radius    = 0.5 * (width > height ? width : height);
    needle    = radius * 0.85;

    for (section = 0; section < 2; section++)
    {
        start = section ? redline + 1 : 0;
        end   = section ? TICKS * SUBTICKS : redline;

        if (section)
            CGContextSetRGBStrokeColor(gc, 1.0, 0.1, 0.1, 1.0);
        else
            CGContextSetRGBStrokeColor(gc, 0.9, 0.9, 1.0, 1.0);

        // inner tick ring
        r0        = 0.97 * needle;
        r1        = 1.04 * needle;
        r2        = 1.00 * needle;
        r3        = 1.01 * needle;
        for (i = start; i <= end ; i++)
        {
            tick  = i / (float)(SUBTICKS * TICKS);
            angle = (2.0 / 3.0) * (2 * M_PI) * tick  -  M_PI / 6;

            c     = cos(angle);
            s     = sin(angle);

            if (i % SUBTICKS != 0)
            {
                CGContextMoveToPoint(gc, cx - r0*c, cy + r0*s);
                CGContextAddLineToPoint(gc, cx - r1*c, cy + r1*s);
            }
            else
            {
                CGContextMoveToPoint(gc, cx - r2*c, cy + r2*s);
                CGContextAddLineToPoint(gc, cx - r3*c, cy + r3*s);
            }
        }
        CGContextSetLineWidth(gc, 2.0);
        CGContextStrokePath(gc);

        // outer tick ring
        start = ((float)start / SUBTICKS) + section;
        end   = ((float)end / SUBTICKS);
        r0        = 1.05 * needle;
        r1        = 1.14 * needle;
        for (i = start; i <= end ; i++)
        {
            tick  = i / (float)(TICKS);
            angle = (2.0 / 3.0) * (2 * M_PI) * tick  -  M_PI / 6;

            c     = cos(angle);
            s     = sin(angle);

            CGContextMoveToPoint(gc, cx - r0*c, cy + r0*s);
            CGContextAddLineToPoint(gc, cx - r1*c, cy + r1*s);
        }
        CGContextSetLineWidth(gc, 3.0);
        CGContextStrokePath(gc);
    }

    CGContextSelectFont(gc, "Arial Bold Italic", 20.0, kCGEncodingMacRoman);
    r0        = 0.82 * needle;

    for (i = 0 ; i <= max ; i += (max / TICKS))
    {
        char   text[20];
        float dx, dy;

        sprintf(text, "%d", i);
        
        // hardcoded text centering for this font size
        {
            if (i > 199)
                dx = -18;
            else if (i > 99)
                dx = -17;
            else if (i > 0)
                dx = -14;
            else
                dx = -12;
            dy = -6.0;
        }
        angle = (2.0 / 3.0) * (2 * M_PI) * i / max  -    M_PI / 6;

        c     = cos(angle);
        s     = sin(angle);

        CGContextShowTextAtPoint(gc, cx - r0*c + dx, cy + r0*s + dy,
                                 text, strlen(text));
    }
}

static void initBackground(unsigned w, unsigned h, unsigned max)
{
    CGColorSpaceRef colorspace;
    CGContextRef  gc;
    unsigned char *data;
    float cx, cy;
    float radius, needle;

    data = (unsigned char *)malloc(w * h * 4);

    colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    gc         = CGBitmapContextCreate(data, w, h, 8, w * 4, colorspace,
                                   kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);

    cx    = CENTERX * w;
    cy    = CENTERY * h;
    radius = 0.5 * (w > h ? w : h);
    needle = radius * 0.85;

    // background
    CGContextTranslateCTM(gc, 0.0, h);
    CGContextScaleCTM(gc, 1.0, -1.0);
    CGContextClearRect(gc, CGRectMake(0, 0, w, h));
    CGContextSetRGBFillColor(gc, 0.0, 0.0, 0.0, 0.7);
    CGContextAddArc(gc, cx, cy, radius, 0, 2*M_PI, false);
    CGContextFillPath(gc);

    CGGradientRef gradient;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 0.5,  // Start color
                              0.0, 0.0, 0.0, 0.0
                            }; // End color

    gradient = CGGradientCreateWithColorComponents (colorspace, components,
               locations, num_locations);
    // top rim light
    CGContextSaveGState(gc);
    CGContextAddArc(gc, cx, cy, radius, 0, 2*M_PI, false);
    CGContextAddArc(gc, cx, cy, needle*1.05, 0, 2*M_PI, false);
    CGContextEOClip(gc);
    CGContextDrawRadialGradient (gc, gradient,
                                 CGPointMake(cx, cy*1.00), radius*1.01,
                                 CGPointMake(cx, cy*0.96), radius*0.98, 0);
    // bottom rim light
    CGContextDrawRadialGradient (gc, gradient,
                                 CGPointMake(cx, cy*1.00), radius*1.01,
                                 CGPointMake(cx, cy*1.04), radius*0.98, 0);
    // top bevel
    CGContextDrawRadialGradient (gc, gradient,
                                 CGPointMake(cx, cy*2.2), radius*0.2,
                                 CGPointMake(cx, cy*1.0), radius*1.0, 0);
    // bottom bevel
    CGContextRestoreGState(gc);
    CGContextSaveGState(gc);
    CGContextAddArc(gc, cx, cy, needle*1.05, 0, 2*M_PI, false);
    CGContextAddArc(gc, cx, cy, needle*0.96, 0, 2*M_PI, false);
    CGContextEOClip(gc);
    CGContextDrawRadialGradient (gc, gradient,
                                 CGPointMake(cx, cy* -.5), radius*0.2,
                                 CGPointMake(cx, cy*1.0), radius*1.0, 0);

    CGGradientRelease(gradient);
    CGContextRestoreGState(gc);

    CGContextSetRGBFillColor(gc, 0.9, 0.9, 1.0, 1.0);
    CGContextSetRGBStrokeColor(gc, 0.9, 0.9, 1.0, 1.0);
    CGContextSetLineCap(gc, kCGLineCapRound);

    // draw several glow passes, with the content offscreen
    CGContextTranslateCTM(gc, 0, OFFSCREEN - 10);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawMarks(gc, w, h, max);
    CGContextTranslateCTM(gc, 0, 20);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawMarks(gc, w, h, max);
    CGContextTranslateCTM(gc, -10, -10);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawMarks(gc, w, h, max);
    CGContextTranslateCTM(gc, 20, 0);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawMarks(gc, w, h, max);
    CGContextTranslateCTM(gc, -10, -OFFSCREEN);

    // draw real content
    CGContextSetShadowWithColor(gc, CGSizeMake(0, 1), 6.0, CGColorCreateGenericRGB(0.7, 0.7, 1.0, 0.9));
    drawMarks(gc, w, h, max);

    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);

    CGContextRelease(gc);
    CGColorSpaceRelease(colorspace);
    free(data);
}

static float angleForValue(float val, int max)
{
    if (val < 0.0)   val = 0.0;
    if (val > max*1.05)  val = max + 1.05;

    return  M_PI / 6 - (2.0 / 3.0)*(2*M_PI)*val / max;
}

static void drawNeedle(CGContextRef gc, int w, int h, float angle)
{
    float dx, dy, cx, cy, radius, needle;

    cx    = CENTERX * w;
    cy    = CENTERY * h;
    dx    = -cos(angle);
    dy    = -sin(angle);
    radius = 0.5 * (w > h ? w : h);
    needle = radius * 0.85;

    CGContextMoveToPoint(gc, cx + needle*dx - 0.5*dy,
                         cy + needle*dy + 0.5*dx);
    CGContextAddLineToPoint(gc, cx + needle*dx + 0.5*dy,
                            cy + needle*dy - 0.5*dx);
    CGContextAddLineToPoint(gc, cx - NEEDLE_THICKNESS*dx + 0.5*NEEDLE_THICKNESS*dy,
                            cy - NEEDLE_THICKNESS*dy - 0.5*NEEDLE_THICKNESS*dx);
    CGContextAddArc(gc, cx - NEEDLE_THICKNESS*dx, cy - NEEDLE_THICKNESS*dy,
                    0.5*NEEDLE_THICKNESS, angle - 0.5*M_PI, angle + 0.5*M_PI, false);
    CGContextAddLineToPoint(gc, cx - NEEDLE_THICKNESS*dx - 0.5*NEEDLE_THICKNESS*dy,
                            cy - NEEDLE_THICKNESS*dy + 0.5*NEEDLE_THICKNESS*dx);
    CGContextFillPath(gc);
}

static void initNeedle(unsigned w, unsigned h, unsigned max)
{
    CGColorSpaceRef colorspace;
    CGContextRef  gc;
    unsigned char *data;
    float cx, cy;
    float angle, radius, needle;

    data = (unsigned char *)malloc(w * h * 4);

    colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    gc         = CGBitmapContextCreate(data, w, h, 8, w * 4, colorspace,
                                   kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);


    cx    = CENTERX * w;
    cy    = CENTERY * h;
    radius = 0.5 * (w > h ? w : h);
    needle = radius * 0.85;

    CGContextTranslateCTM(gc, 0.0, h);
    CGContextScaleCTM(gc, 1.0, -1.0);
    CGContextClearRect(gc, CGRectMake(0, 0, w, h));
    angle = 0;//angleForValue(0, max);

    {
        // draw glow reflecting on inner bevel
        float    dx, dy;
        dx         = -cos(angle) + 1;
        dy         = -sin(angle) + 1;

        CGGradientRef gradient;
        size_t num_locations = 2;
        CGFloat locations[2] = { 0.0, 1.0 };
        CGFloat components[8] = { 0.7, 0.7, 1.0, 0.7,  // Start color
                                  0.0, 0.0, 0.0, 0.0
                                }; // End color

        gradient = CGGradientCreateWithColorComponents (colorspace, components,
                   locations, num_locations);
        CGContextSaveGState(gc);
        CGContextAddArc(gc, cx, cy, needle*1.05, 0, 2*M_PI, false);
        CGContextAddArc(gc, cx, cy, needle*0.96, 0, 2*M_PI, false);
        CGContextEOClip(gc);
        CGContextDrawRadialGradient (gc, gradient,
                                     CGPointMake(cx*dx, cy*dy), radius*0.1,
                                     CGPointMake(cx*1.0, cy*1.0), radius*1.0, 0);
        CGContextRestoreGState(gc);
    }

    CGContextSetRGBFillColor(gc, 0.9, 0.9, 1.0, 1.0);

    // draw several glow passes, with the content offscreen
    CGContextTranslateCTM(gc, 0, OFFSCREEN - 10);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawNeedle(gc, w, h, angle);
    CGContextTranslateCTM(gc, 0, 20);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawNeedle(gc, w, h, angle);
    CGContextTranslateCTM(gc, -10, -10);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawNeedle(gc, w, h, angle);
    CGContextTranslateCTM(gc, 20, 0);
    CGContextSetShadowWithColor(gc, CGSizeMake(0, OFFSCREEN), 48.0, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 0.7));
    drawNeedle(gc, w, h, angle);
    CGContextTranslateCTM(gc, -10, -OFFSCREEN);

    // draw real content
    CGContextSetShadowWithColor(gc, CGSizeMake(0, 1), 6.0, CGColorCreateGenericRGB(0.0, 0.0, 0.5, 0.7));
    drawNeedle(gc, w, h, angle);

    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);

    CGContextRelease(gc);
    CGColorSpaceRelease(colorspace);
    free(data);
}

//----------------------------------------------------------------------------

SmoothMeter::SmoothMeter(unsigned w, unsigned h, unsigned max, const char *legendText)
        : _w(w),
        _h(h),
        _max(max),
        _value(0.0),
        _smoothValue(0.0),
        _backgroundTexture(0),
        _needleTexture(0),
        _legendTexture(0),
        _legend(legendText)
{}

SmoothMeter::~SmoothMeter()
{}

void SmoothMeter::reset()
{
    _value = 0.0;
    _smoothValue = 0.0;
}

void SmoothMeter::setTargetValue(double target)
{
    _value = target;
}

void SmoothMeter::update()
{
    // a bit hacky -- should really be time-based
    double step = _max / 60.0;

    if (fabs(_smoothValue - _value) < step)
    {
        _smoothValue = _value;
    }
    else if (_value > _smoothValue)
    {
        _smoothValue += step;
    }
    else if (_value < _smoothValue)
    {
        _smoothValue -= step;
    }
}

void SmoothMeter::draw()
{
    int value = lrint(_smoothValue);
    float angle = angleForValue(_smoothValue, _max) * 180 / M_PI;

    if (0 == _backgroundTexture)
    {
        glGenTextures(1, &_backgroundTexture);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _backgroundTexture);
        initBackground(_w, _h, _max);
    }

    if (0 == _needleTexture)
    {
        glGenTextures(1, &_needleTexture);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _needleTexture);
        initNeedle(_w, _h, _max);
    }

    if (0 == _legendTexture)
    {
        _legendTexture = CreateTextureWithLabel(_legend, 36, false, LEGEND_WIDTH, LEGEND_HEIGHT);
    }

    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glMatrixMode(GL_TEXTURE);
    glPushMatrix();
    glLoadIdentity();
    glScalef(_w, _h, 1);
    glMatrixMode(GL_MODELVIEW);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _backgroundTexture);
    DrawQuad(_w* -0.5, _h* -0.5, _w, _h);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _needleTexture);
    glPushMatrix();
    glRotatef(angle, 0, 0, 1);
    DrawQuad(_w* -0.5, _h* -0.5, _w, _h);
    glPopMatrix();

    glMatrixMode(GL_TEXTURE);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, _legendTexture);
    DrawQuadInverted(-0.5 * LEGEND_WIDTH, -220, LEGEND_WIDTH, LEGEND_HEIGHT);

    // FIXME purge unused values, or don't use the global cache
    glBindTexture(GL_TEXTURE_2D, value_texture_for(value));
    DrawQuadInverted(-0.5 * VALUE_WIDTH, -110, VALUE_WIDTH, VALUE_HEIGHT);

    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
}

//----------------------------------------------------------------------------

Button::Button(float x, float y, float w, float h)
        : _x(x), _y(y), _w(w), _h(h)
{}

Button::~Button()
{

}

bool Button::contains(float x, float y) const
{
    return x >= _x && x <= _x + _w && y >= _y && y <= _y + _h;
}

TrackingState TrackButton(Button const *button, float x, float y, TrackingState previous)
{
    bool hit = button->contains(x, y);
    switch (previous)
    {
    case NOTHING:
        return hit ? PRESSED : NOTHING;
    case PRESSED:
    case UNPRESSED:
        return hit ? PRESSED : UNPRESSED;
    }

    abort();
}

void DrawButton(Button const *button)
{
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 1.0);
    glVertex2f(button->x(), button->y());
    glTexCoord2f(1.0, 1.0);
    glVertex2f(button->x() + button->w(), button->y());
    glTexCoord2f(1.0, 0.0);
    glVertex2f(button->x() + button->w(), button->y() + button->h());
    glTexCoord2f(0.0, 0.0);
    glVertex2f(button->x(), button->y() + button->h());
    glEnd();
}

static void AddRoundedRectToPath(CGContextRef context, CGRect rect,
                                 float ovalWidth, float ovalHeight)
{
    float fw, fh;

    if (ovalWidth == 0 || ovalHeight == 0)
    {
        CGContextAddRect(context, rect);
        return;
    }

    CGContextSaveGState(context);

    CGContextTranslateCTM (context, CGRectGetMinX(rect),
                           CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;

    CGContextMoveToPoint(context, fw, fh / 2);
    CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, 1);
    CGContextClosePath(context);

    CGContextRestoreGState(context);
}

void InitButton(unsigned w, unsigned h)
{
    CGColorSpaceRef colorspace;
    CGContextRef  gc;
    unsigned char *data;
    float cx, cy;

    data = (unsigned char *)malloc(w * h * 4);

    colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    gc = CGBitmapContextCreate(data, w, h, 8, w * 4, colorspace,
                               kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);

    cx = CENTERX * w;
    cy = CENTERY * h;

    // background
    CGContextTranslateCTM(gc, 0.0, h);
    CGContextScaleCTM(gc, 1.0, -1.0);
    CGContextClearRect(gc, CGRectMake(0, 0, w, h));
    CGContextSetRGBFillColor(gc, 0.0, 0.0, 0.0, 0.8);

    AddRoundedRectToPath(gc, CGRectMake(w*0.05, h*0.5 - 32, w*0.9, 64), 32, 32);
    CGContextFillPath(gc);

    CGGradientRef gradient;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 0.5,  // Start color
                              0.0, 0.0, 0.0, 0.0
                            }; // End color

    gradient = CGGradientCreateWithColorComponents (colorspace, components,
               locations, num_locations);
    // top bevel
    CGContextSaveGState(gc);
    AddRoundedRectToPath(gc, CGRectMake(w*0.05, h*0.5 - 32, w*0.9, 64), 32, 32);
    CGContextEOClip(gc);
    CGContextDrawLinearGradient (gc, gradient,
                                 CGPointMake(cx, cy + 32),
                                 CGPointMake(cx, cy), 0);
    CGContextDrawLinearGradient (gc, gradient,
                                 CGPointMake(cx, cy - 32),
                                 CGPointMake(cx, cy - 16), 0);

    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);

    CGContextRelease(gc);
    CGColorSpaceRelease(colorspace);
    free(data);
}
