/*
 * CPControl.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPFont.j"
@import "CPShadow.j"
@import "CPView.j"

#include "CoreGraphics/CGGeometry.h"
#include "Platform/Platform.h"

/*
    @global
    @group CPTextAlignment
*/
CPLeftTextAlignment         = 0;
/*
    @global
    @group CPTextAlignment
*/
CPRightTextAlignment        = 1;
/*
    @global
    @group CPTextAlignment
*/
CPCenterTextAlignment       = 2;
/*
    @global
    @group CPTextAlignment
*/
CPJustifiedTextAlignment    = 3;
/*
    @global
    @group CPTextAlignment
*/
CPNaturalTextAlignment      = 4;

/*
    @global
    @group CPControlSize
*/
CPRegularControlSize        = 0;
/*
    @global
    @group CPControlSize
*/
CPSmallControlSize          = 1;
/*
    @global
    @group CPControlSize
*/
CPMiniControlSize           = 2;

CPControlNormalBackgroundColor      = "CPControlNormalBackgroundColor";
CPControlSelectedBackgroundColor    = "CPControlSelectedBackgroundColor";
CPControlHighlightedBackgroundColor = "CPControlHighlightedBackgroundColor";
CPControlDisabledBackgroundColor    = "CPControlDisabledBackgroundColor";

CPControlTextDidBeginEditingNotification    = "CPControlTextDidBeginEditingNotification";
CPControlTextDidChangeNotification          = "CPControlTextDidChangeNotification";
CPControlTextDidEndEditingNotification      = "CPControlTextDidEndEditingNotification";

var CPControlBlackColor     = [CPColor blackColor];

/*! 
    @ingroup appkit
    @class CPControl

    CPControl is an abstract superclass used to implement user interface elements. As a subclass of CPView and CPResponder it has the ability to handle screen drawing and handling user input.
*/
@implementation CPControl : CPView
{
    id                  _value;
    
    // Target-Action Support
    id                  _target;
    SEL                 _action;
    int                 _sendActionOn;
    
    // Mouse Tracking Support
    BOOL                _continuousTracking;
    BOOL                _trackingWasWithinFrame;
    unsigned            _trackingMouseDownFlags;
    CGPoint             _previousTrackingLocation;
    
    JSObject            _ephemeralSubviewsForNames;
    CPSet               _ephereralSubviews;

    CPString            _toolTip;
}

+ (CPDictionary)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[CPLeftTextAlignment,
                                                CPTopVerticalTextAlignment,
                                                CPLineBreakByClipping,
                                                [CPColor blackColor],
                                                [CPFont systemFontOfSize:12.0],
                                                nil,
                                                _CGSizeMakeZero(),
                                                CPImageLeft,
                                                CPScaleToFit,
                                                _CGSizeMakeZero(),
                                                _CGSizeMake(-1.0, -1.0)]
                                       forKeys:[@"alignment",
                                                @"vertical-alignment",
                                                @"line-break-mode",
                                                @"text-color",
                                                @"font",
                                                @"text-shadow-color",
                                                @"text-shadow-offset",
                                                @"image-position",
                                                @"image-scaling",
                                                @"min-size",
                                                @"max-size"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _sendActionOn = CPLeftMouseUpMask;
        _trackingMouseDownFlags = 0;
    }
    
    return self;
}

/*!
    Sets the receiver's target action
    @param anAction Sets the action message that gets sent to the target.
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

/*!
    Returns the receiver's target action
*/
- (SEL)action
{
    return _action;
}

/*!
    Sets the receiver's target. The target receives action messages from the receiver.
    @param aTarget the object that will receive the message specified by action
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

/*!
    Returns the receiver's target. The target receives action messages from the receiver.
*/
- (id)target
{
    return _target;
}

/*!
    Causes <code>anAction</code> to be sent to <code>anObject</code>.
    @param anAction the action to send
    @param anObject the object to which the action will be sent
*/
- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [CPApp sendAction:anAction to:anObject from:self];
}

- (int)sendActionOn:(int)mask
{
    var previousMask = _sendActionOn;
    
    _sendActionOn = mask;
    
    return previousMask;
}

/*!
    Sets the tooltip for the receiver.
    @param aToolTip the tooltip
*/
/*
-(void)setToolTip:(CPString)aToolTip
{
    if (_toolTip == aToolTip)
        return;
    
    _toolTip = aToolTip;

#if PLATFORM(DOM)
    _DOMElement.title = aToolTip;
#endif
}
*/
/*!
    Returns the receiver's tooltip
*/
/*
-(CPString)toolTip
{
    return _toolTip;
}
*/

/*!
    Returns whether the control can continuously send its action messages.
*/
- (BOOL)isContinuous
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    return (_sendActionOn & CPPeriodicMask) !== 0;
}

/*!
    Sets whether the cell can continuously send its action messages.
 */
- (void)setContinuous:(BOOL)flag
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    if (flag)
        _sendActionOn |= CPPeriodicMask;
    else 
        _sendActionOn &= ~CPPeriodicMask;
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return NO;
}

- (void)trackMouse:(CPEvent)anEvent
{
    var type = [anEvent type],
        currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        isWithinFrame = [self tracksMouseOutsideOfFrame] || CGRectContainsPoint([self bounds], currentLocation);

    if (type === CPLeftMouseUp)
    {
        [self stopTracking:_previousTrackingLocation at:currentLocation mouseIsUp:YES];
        
        _trackingMouseDownFlags = 0;
    }
    
    else
    {
        if (type === CPLeftMouseDown)
        {
            _trackingMouseDownFlags = [anEvent modifierFlags];
            _continuousTracking = [self startTrackingAt:currentLocation];
        }
        else if (type === CPLeftMouseDragged)
        {
            if (isWithinFrame)
            {
                if (!_trackingWasWithinFrame)
                    _continuousTracking = [self startTrackingAt:currentLocation];
                
                else if (_continuousTracking)
                    _continuousTracking = [self continueTracking:_previousTrackingLocation at:currentLocation];
            }
            else
                [self stopTracking:_previousTrackingLocation at:currentLocation mouseIsUp:NO];
        }
        
        [CPApp setTarget:self selector:@selector(trackMouse:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
    }
    
    if ((_sendActionOn & (1 << type)) && isWithinFrame)
        [self sendAction:_action to:_target];
    
    _trackingWasWithinFrame = isWithinFrame;
    _previousTrackingLocation = currentLocation;
}

- (void)performClick:(id)sender 
{
    [self highlight:YES];
    [self setState:[self nextState]];
    [self sendAction:[self action] to:[self target]];
    [self highlight:NO];
}

- (unsigned)mouseDownFlags
{
    return _trackingMouseDownFlags;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [self highlight:YES];
    
    return (_sendActionOn & CPPeriodicMask) || (_sendActionOn & CPLeftMouseDraggedMask);
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    return (_sendActionOn & CPPeriodicMask) || (_sendActionOn & CPLeftMouseDraggedMask);
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self highlight:NO];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;
    
    [self trackMouse:anEvent];
}

/*!
    Returns the receiver's object value
*/
- (id)objectValue
{
    return _value;
}

/*!
    Set's the receiver's object value
*/
- (void)setObjectValue:(id)anObject
{
    _value = anObject;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the receiver's float value
*/
- (float)floatValue
{
    var floatValue = parseFloat(_value, 10);
    return isNaN(floatValue) ? 0.0 : floatValue;
}

/*!
    Sets the receiver's float value
*/
- (void)setFloatValue:(float)aValue
{
    [self setObjectValue:aValue];
}

/*!
    Returns the receiver's double value
*/
- (double)doubleValue
{
    var doubleValue = parseFloat(_value, 10);
    return isNaN(doubleValue) ? 0.0 : doubleValue;
}

/*!
    Set's the receiver's double value
*/
- (void)setDoubleValue:(double)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (int)intValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (int)integerValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntegerValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (CPString)stringValue
{
    return (_value === undefined || _value === nil) ? "" : String(_value);
}

/*!
    Set's the receiver's int value
*/
- (void)setStringValue:(CPString)anObject
{
    [self setObjectValue:anObject];
}

- (void)takeDoubleValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(doubleValue)])
        [self setDoubleValue:[sender doubleValue]];
}


- (void)takeFloatValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(floatValue)])
        [self setFloatValue:[sender floatValue]];
}


- (void)takeIntegerValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(integerValue)])
        [self setIntegerValue:[sender integerValue]];
}


- (void)takeIntValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(intValue)])
        [self setIntValue:[sender intValue]];
}


- (void)takeObjectValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(objectValue)])
        [self setObjectValue:[sender objectValue]];
}

- (void)takeStringValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(stringValue)])
        [self setStringValue:[sender stringValue]];
}

- (void)textDidBeginEditing:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidBeginEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidChange:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidEndEditing:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

#define BRIDGE(UPPERCASE, LOWERCASE, ATTRIBUTENAME) \
- (void)set##UPPERCASE:(id)aValue\
{\
[self setValue:aValue forThemeAttribute:ATTRIBUTENAME];\
}\
- (id)LOWERCASE\
{\
return [self valueForThemeAttribute:ATTRIBUTENAME];\
}

BRIDGE(Alignment, alignment, "alignment")
BRIDGE(VerticalAlignment, verticalAlignment, "vertical-alignment")
BRIDGE(LineBreakMode, lineBreakMode, "line-break-mode")
BRIDGE(TextColor, textColor, "text-color")
BRIDGE(Font, font, "font")
BRIDGE(TextShadowColor, textShadowColor, "text-shadow-color")
BRIDGE(TextShadowOffset, textShadowOffset, "text-shadow-offset")
BRIDGE(ImagePosition, imagePosition, "image-position")
BRIDGE(ImageScaling, imageScaling, "image-scaling")

- (void)setEnabled:(BOOL)isEnabled
{
    if (isEnabled)
        [self unsetThemeState:CPThemeStateDisabled];
    else
        [self setThemeState:CPThemeStateDisabled];
}

- (BOOL)isEnabled
{
    return ![self hasThemeState:CPThemeStateDisabled];
}

- (void)highlight:(BOOL)shouldHighlight
{
    [self setHighlighted:shouldHighlight];
}

- (void)setHighlighted:(BOOL)isHighlighted
{
    if (isHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

- (BOOL)isHighlighted
{
    return [self hasThemeState:CPThemeStateHighlighted];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aViewName
{
    return nil;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aViewName
{
    return _CGRectMakeZero();
}

- (CPView)layoutEphemeralSubviewNamed:(CPString)aViewName 
                           positioned:(CPWindowOrderingMode)anOrderingMode
      relativeToEphemeralSubviewNamed:(CPString)relativeToViewName
{
    if (!_ephemeralSubviewsForNames)
    {
        _ephemeralSubviewsForNames = {};
        _ephemeralSubviews = [CPSet set];
    }
    
    var frame = [self rectForEphemeralSubviewNamed:aViewName];

    if (frame && !_CGRectIsEmpty(frame))
    {
        if (!_ephemeralSubviewsForNames[aViewName])
        {
            _ephemeralSubviewsForNames[aViewName] = [self createEphemeralSubviewNamed:aViewName];
        
            [_ephemeralSubviews addObject:_ephemeralSubviewsForNames[aViewName]];
        
            if (_ephemeralSubviewsForNames[aViewName])
                [self addSubview:_ephemeralSubviewsForNames[aViewName] positioned:anOrderingMode relativeTo:_ephemeralSubviewsForNames[relativeToViewName]];
        }
        
        if (_ephemeralSubviewsForNames[aViewName])
            [_ephemeralSubviewsForNames[aViewName] setFrame:frame];
    }
    else if (_ephemeralSubviewsForNames[aViewName])
    {
        [_ephemeralSubviewsForNames[aViewName] removeFromSuperview];
        
        [_ephemeralSubviews removeObject:_ephemeralSubviewsForNames[aViewName]];
        delete _ephemeralSubviewsForNames[aViewName];
    }
    
    return _ephemeralSubviewsForNames[aViewName];
}

@end

var CPControlValueKey           = "CPControlValueKey",
    CPControlControlStateKey    = @"CPControlControlStateKey",
    CPControlIsEnabledKey       = "CPControlIsEnabledKey",
    
    CPControlTargetKey          = "CPControlTargetKey",
    CPControlActionKey          = "CPControlActionKey",
    CPControlSendActionOnKey    = "CPControlSendActionOnKey";

var __Deprecated__CPImageViewImageKey   = @"CPImageViewImageKey";

@implementation CPControl (CPCoding)

/*
    Initializes the control by unarchiving it from a coder.
    @param aCoder the coder from which to unarchive the control
    @return the initialized control
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setObjectValue:[aCoder decodeObjectForKey:CPControlValueKey]];

        [self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
        [self setAction:[aCoder decodeObjectForKey:CPControlActionKey]];

        [self sendActionOn:[aCoder decodeIntForKey:CPControlSendActionOnKey]];
    }
    
    return self;
}

/*
    Archives the control to the provided coder.
    @param aCoder the coder to which the control will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    var count = [_subviews count],
        ephemeral
        subviews = nil;

    if (count > 0 && [_ephemeralSubviews count] > 0)
    {
        subviews = [_subviews.slice(0) copy];
        
        while (count--)
            if ([_ephemeralSubviews containsObject:_subviews[count]])
                _subviews.splice(count, 1);
    }

    [super encodeWithCoder:aCoder];

    if (subviews)
        _subviews = subviews;

    if (_value !== nil)
        [aCoder encodeObject:_value forKey:CPControlValueKey];

    if (_target !== nil)
        [aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];

    if (_action !== NULL)
        [aCoder encodeObject:_action forKey:CPControlActionKey];

    [aCoder encodeInt:_sendActionOn forKey:CPControlSendActionOnKey];
}

@end

var _CPControlSizeIdentifiers               = [],
    _CPControlCachedColorWithPatternImages  = {},
    _CPControlCachedThreePartImagePattern   = {};

_CPControlSizeIdentifiers[CPRegularControlSize] = "Regular";
_CPControlSizeIdentifiers[CPSmallControlSize]   = "Small";
_CPControlSizeIdentifiers[CPMiniControlSize]    = "Mini";
    
function _CPControlIdentifierForControlSize(aControlSize)
{
    return _CPControlSizeIdentifiers[aControlSize];
}

function _CPControlColorWithPatternImage(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];
    
    var color = _CPControlCachedColorWithPatternImages[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]];
    
        color = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:aClassName + "/" + identifier + ".png"] size:sizes[identifier]]];

        _CPControlCachedColorWithPatternImages[identifier] = color;
    }
    
    return color;
}

function _CPControlThreePartImagePattern(isVertical, sizes, aClassName)
{
    var index = 2,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var color = _CPControlCachedThreePartImagePattern[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "2.png"] size:sizes[2]]
                ] isVertical:isVertical]];
                
        _CPControlCachedThreePartImagePattern[identifier] = color;
    }
    
    return color;
}
