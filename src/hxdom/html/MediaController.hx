/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package hxdom.html;

#if (js && !use_vdom)
typedef MediaController = js.html.MediaController;
#else
class MediaController extends EventTarget {
	
	public var buffered(default, null):TimeRanges;

	/** Setter throws DOMException. */
	public var currentTime:Float;

	public var defaultPlaybackRate:Float;

	public var duration(default, null):Float;

	public var muted:Bool;

	public var paused(default, null):Bool;

	public var playbackRate:Float;

	public var played(default, null):TimeRanges;

	public var seekable(default, null):TimeRanges;

	/** Setter throws DOMException. */
	public var volume:Float;

	public function new () {
		
	}

	public function pause ():Void {
		
	}

	public function play ():Void {
		
	}
	
}
#end