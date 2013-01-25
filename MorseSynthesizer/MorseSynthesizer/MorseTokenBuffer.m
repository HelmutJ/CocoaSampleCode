/*
    File: MorseTokenBuffer.m
Abstract: Generate internal representation for morse code and 
embedded commands.

Most of this code is specific to morse encoding and is of little interest 
for speech synthesis in general.
 Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#import "MorseTokenBuffer.h"

@implementation MorseTokenBuffer

- (void)clear
{
	if (tokens) {
		free(tokens);
		tokens		= NULL;
		capacity	= 0;
		valid		= 0;
		next		= 0;

		free(callbacks);
		callbacks	= NULL;
		cbCapacity	= 0;
		cbValid		= 0;
		cbNext		= 0;
	}
}

- (void)dealloc
{
	[self clear];
}

- (void)wantWordCallbacks:(SEL)selector
{
	wordCallback	= selector;
}

- (void)reserveCapacity:(int)increment
{
	if (capacity < valid+increment) {
		capacity= capacity < 1024 ? 1024 : capacity*2;
		tokens	= (char *)realloc(tokens, capacity);
	}
}

- (void)encodeCallback:(MorseCallback *)callback
{
	if (cbValid == cbCapacity) {
		cbCapacity= cbCapacity < 64 ? 64 : cbCapacity*2;
		callbacks = (MorseCallback *)realloc(callbacks, sizeof(MorseCallback)*cbCapacity);
	}
	callbacks[cbValid++] = *callback;
	[self reserveCapacity:1];
	tokens[valid++] = kMorseCallback;
}

- (void)encodeWordCallback:(CFRange)word
{
	if (wordCallback) {
		MorseCallback wordCB;
		wordCB.selector	= wordCallback;
		wordCB.arg.r	= word;
		[self encodeCallback:&wordCB];
	}
}

- (void)fixupWordCallback:(CFIndex)end
{
	/* We need to issue the callback at the beginning of the word, but won't 
	   know the length until we've seen the end.
	*/
	if (wordCallback)
		callbacks[cbValid-1].arg.r.length = end-callbacks[cbValid-1].arg.r.location;
}

- (void)encodeLetter:(const char *)marks
{
	while (*marks) {
		if (*marks == '.' || *marks == '-')
			[self reserveCapacity:2];
		switch (*marks++) {
		case '.':
			if (!wasPrintable)
				[self encodeWordCallback:CFRangeMake(wordStart, 0)];
			tokens[valid++] = kMorseDit;
			tokens[valid++] = kMorseMarkGap;
			break;
		case '-':
			if (!wasPrintable)
				[self encodeWordCallback:CFRangeMake(wordStart, 0)];
			tokens[valid++] = kMorseDah;
			tokens[valid++] = kMorseMarkGap;
			break;
		case ',':
			if (valid && tokens[valid-1] == kMorseCharGap)
				tokens[valid-1] = kMorseWordGap;
			break;
		case '!':
			tokens[valid-1] = kMorseSentenceGap;
			break;
		case ' ':
		case 0:
			tokens[valid-1] = kMorseCharGap;
			break;
		}
	}
}

- (void)encodeWordBreak
{
	if (valid && tokens[valid-1] == kMorseCharGap)
		tokens[valid-1] = kMorseWordGap;
}

- (void)encodeText:(CFStringRef)text range:(CFRange)range
{
	wasPrintable = NO;
	CFIndex	end	= range.location+range.length;
	for (CFIndex i = range.location; i<end; ++i) {
		BOOL isPrintable = YES;
		if (!wasPrintable) 
			wordStart	= i;
		switch (CFStringGetCharacterAtIndex(text, i)) {
		case 'a':
			[self encodeLetter:".-"];
			break;
		case 'b':
			[self encodeLetter:"-..."];
			break;
		case 'c':
			[self encodeLetter:"-.-."];
			break;
		case 'd':
			[self encodeLetter:"-.."];
			break;
		case 'e':
			[self encodeLetter:"."];
			break;
		case 'f':
			[self encodeLetter:"..-."];
			break;
		case 'g':
			[self encodeLetter:"--."];
			break;
		case 'h':
			[self encodeLetter:"...."];
			break;
		case 'i':
			[self encodeLetter:".."];
			break;
		case 'j':
			[self encodeLetter:".---"];
			break;
		case 'k':
			[self encodeLetter:"-.-"];
			break;
		case 'l':
			[self encodeLetter:".-.."];
			break;
		case 'm':
			[self encodeLetter:"--"];
			break;
		case 'n':
			[self encodeLetter:"-."];
			break;
		case 'o':
			[self encodeLetter:"---"];
			break;
		case 'p':
			[self encodeLetter:".--."];
			break;
		case 'q':
			[self encodeLetter:"--.-"];
			break;
		case 'r':
			[self encodeLetter:".-."];
			break;
		case 's':
			[self encodeLetter:"..."];
			break;
		case 't':
			[self encodeLetter:"-"];
			break;
		case 'u':
			[self encodeLetter:"..-"];
			break;
		case 'v':
			[self encodeLetter:"...-"];
			break;
		case 'w':
			[self encodeLetter:".--"];
			break;
		case 'x':
			[self encodeLetter:"-..-"];
			break;
		case 'y':
			[self encodeLetter:"-.--"];
			break;
		case 'z':
			[self encodeLetter:"--.."];
			break;
		/* 
		 * Throw in some accented characters to make character encoding more interesting
		 */
		case 0x00E0:	/* a with grave accent 	*/
		case 0x00E5:	/* a with ring above   	*/
			[self encodeLetter:".--.-"];
			break;
		case 0x00E4:	/* a with diaeresis	   	*/
			[self encodeLetter:".-.-"];
			break;
		case 0x00E8:	/* e with grave accent 	*/
			[self encodeLetter:".-..-"];
			break;
		case 0x00E9:	/* e with acute accent	*/
			[self encodeLetter:"..-.."];
			break;
		case 0x00F1:	/* n with tilde			*/
			[self encodeLetter:"--.--"];
			break;
		case 0x00F6:	/* o with diaeresis		*/
			[self encodeLetter:"---."];
			break;
		case 0x00FC:	/* u with diaeresis		*/
			[self encodeLetter:"..--"];
			break;			
		case '1':
			[self encodeLetter:".----"];
			break;
		case '2':
			[self encodeLetter:"..---"];
			break;
		case '3':
			[self encodeLetter:"...--"];
			break;
		case '4':
			[self encodeLetter:"....-"];
			break;
		case '5':
			[self encodeLetter:"....."];
			break;
		case '6':
			[self encodeLetter:"-...."];
			break;
		case '7':
			[self encodeLetter:"--..."];
			break;
		case '8':
			[self encodeLetter:"---.."];
			break;
		case '9':
			[self encodeLetter:"----."];
			break;
		case '0':
			[self encodeLetter:"-----"];
			break;
		case '.':
		case '!':
			isPrintable 	= NO;
			if (wasPrintable)
				[self fixupWordCallback:i];
			[self encodeWordCallback:CFRangeMake(i, 1)];
			[self encodeLetter:",... - --- .--.!"]; 		/* STOP		 	*/
			break;
		case '?':
			isPrintable     = NO;
			if (wasPrintable)
				[self fixupWordCallback:i];
			[self encodeWordCallback:CFRangeMake(i, 1)];
			[self encodeLetter:",--.- ..- . .-. -.--!"]; 	/* QUERY   		*/
			break;
		default:
			isPrintable = NO;
			if (wasPrintable)
				[self fixupWordCallback:i];
			[self encodeLetter:","];						/* Word break 	*/
			break;
		}
		wasPrintable = isPrintable;
	}
	if (wasPrintable)
		[self fixupWordCallback:end];
}

- (void)encodeText:(CFStringRef)text 
{
	[self encodeText:text range:CFRangeMake(0, CFStringGetLength(text))];
}

- (void)encodeFloatCallback:(SEL)sel value:(float)value
{
	MorseCallback	floatCB;
	floatCB.selector	= sel;
	floatCB.arg.f		= value;
	[self encodeCallback:&floatCB];
}

- (void)encodeSyncCallback:(SEL)sel value:(uint32_t)value
{
	MorseCallback	syncCB;
	syncCB.selector	= sel;
	syncCB.arg.u		= value;
	[self encodeCallback:&syncCB];
}

- (void)executeCallback:(id)obj
{
	MorseCallback * cb = callbacks+cbNext++;
	[obj performSelector:cb->selector withObject:[NSValue valueWithPointer:cb]];
}

- (void)trimTokens:(MorseToken)fromToken
{
	char * found = (char *)memchr(tokens+next, fromToken, valid-next);
	if (found)
		valid = found-tokens+next;
}

- (MorseToken)peekNextToken
{
	return next < valid ? tokens[next] : kMorseNone;
}

- (MorseToken)fetchNextToken
{
	return next < valid ? tokens[next++] : kMorseNone;
}

- (void)skipGaps
{
	while (next < valid && tokens[next] >= kMorseMarkGap)
		++next;
}

- (CFStringRef)morseCharacters
{
	CFMutableStringRef phon = CFStringCreateMutable(NULL, 0);
	for (;;) {
		UniChar codez[2]= {0,0};
		switch ([self fetchNextToken]) {
		case kMorseNone:
			return (CFStringRef)phon;
		case kMorseDit:
			codez[0] = '.';
			break;
		case kMorseDah:
			codez[0] = '-';
			break;
		case kMorseMarkGap:
			continue;
		case kMorseCharGap:
			codez[0] = ' ';
			break;
		default:
			codez[0] = ' ';
			codez[1] = ' ';
			break;
		}
		CFStringAppendCharacters(phon, codez, 1+(codez[1] != 0));
	}
}

@end
