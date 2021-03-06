/****
* Copyright (C) 2013 Sam MacPherson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****/

package hxdom.js;

import haxe.rtti.Meta;
import haxe.Unserializer;
import hxdom.html.CharacterData;
import hxdom.html.Element;
import hxdom.html.HtmlElement;
import hxdom.html.Node;
import hxdom.Elements;
import hxdom.EventDispatcher;
import hxdom.SFunc;

using StringTools;

/**
 * Takes the browser parsed dom and returns the root node that was fed into the HTMLSerializer.run() method.
 * 
 * @author Sam MacPherson
 */
class Boot extends Unserializer {
	
	var elementLookup:Map<Int, Node>;					//Find elements from their id
	var initFuncs:List<SFunc<Void -> Void>>;		//Call these functions after init
	
	public function new () {
		super("");
		
		elementLookup = new Map<Int, Node>();
		initFuncs = new List<SFunc<Void -> Void>>();
	}
	
	function element (e:Element):Void {
		var velem = Reflect.field(e, "__vdom");
		
		//Check if there are any clientInit functions on the virtual node
		checkClientInit(velem);
		
		//Event listeners
		if (Reflect.hasField(e.dataset, "hxevents")) {
			var listeners:Map<String, List<{handler:SFunc<hxdom.html.Event -> Void>, cap:Bool}>> = doUnserialize(Reflect.field(e.dataset, "hxevents"));
			for (eventType in listeners.keys()) {
				for (eh in listeners.get(eventType)) {
					#if (js && !use_vdom)
					e.addEventListener(eventType, function (e) { eh.handler.call([e]); }, eh.cap);
					#end
				}
			}
		}
		
		//Element properties
		
		
		var sortedFields = Reflect.fields(e.dataset);
		sortedFields.sort(function (a, b) { return (a < b) ? -1 : 1; } );
		for (i in sortedFields) {
			if (i.startsWith("hxd")) {
				var key = i.substr(3);
				Reflect.setField(velem, key, doUnserialize(Reflect.field(e.dataset, i)));
			}
		}
	}
	
	function unserializeNode (node:Node):Void {
		switch (node.nodeType) {
			case Node.ELEMENT_NODE: 
				element(cast node);
				for (i in 0 ... node.childNodes.length) {
					unserializeNode(node.childNodes[i]);
				}
		}
	}
	
	function buildElementLookup (node:Node):Void {
		if (node.nodeType == Node.ELEMENT_NODE) {
			var el:Element = cast node;
			var cls = Type.resolveClass(Reflect.field(el.dataset, "hxclass"));
			//If this is not a hxdom element then just continue
			if (cls != null) {
				//Setup virtual dom element
				var velem:VirtualNode<Element> = Type.createEmptyInstance(cls);
				Reflect.setField(node, "__vdom", velem);
				Reflect.setField(velem, "node", node);
				
				//Place node into lookup
				var first = true;
				var remainingStr:String = null;
				var child = node.firstChild;
				for (i in el.getAttribute("data-hxid").split(" ")) {
					if (first) {
						//First is always the element ID
						var id = Std.parseInt(i);
						Reflect.setField(velem, "id", id);
						elementLookup.set(id, node);
						first = false;
					} else {
						//Any remaining ids are for text nodes
						var dash = i.indexOf('-');
						var id = Std.parseInt(i.substr(0, dash));
						var len = Std.parseInt(i.substr(dash + 1));
						
						var nodeToAdd = null;
						if (len > 0) {
							while (child.nodeType != Node.TEXT_NODE) child = child.nextSibling;
							
							var txt:hxdom.html.Text = cast child;
							nodeToAdd = child;
							if (remainingStr == null && txt.length == len) {
								//Node is an exact fit
								child = child.nextSibling;
							} else {
								//Node has been normalized -- need to split into sub-nodes
								if (remainingStr == null) {
									//First node gets to stay
									remainingStr = txt.data.substr(len);
									txt.data = txt.data.substr(0, len);
								} else {
									//The rest need to create new text nodes
									#if (js && !use_vdom)
									nodeToAdd = js.Browser.document.createTextNode(remainingStr.substr(0, len));
									#end
									node.insertBefore(nodeToAdd, child.nextSibling);
									if (remainingStr.length == len) {
										remainingStr = null;
									} else {
										remainingStr = remainingStr.substr(len);
									}
									child = child.nextSibling;
								}
							}
						} else {
							//Length 0 text node can be added anywhere
							nodeToAdd = hxdom.Browser.document.createTextNode("");
							node.insertBefore(nodeToAdd, child);
						}
						var vdomText = Type.createEmptyInstance(Text);
						Reflect.setField(vdomText, "id", id);
						Reflect.setField(vdomText, "node", nodeToAdd);
						Reflect.setField(nodeToAdd, "__vdom", vdomText);
						elementLookup.set(id, nodeToAdd);
					}
				}
				
				for (i in 0 ... node.childNodes.length) {
					buildElementLookup(node.childNodes[i]);
				}
			} else {
				//Could be unused div
				var unused = Reflect.field(el.dataset, "hxunused");
				if (unused != null) {
					for (i in 0 ... node.childNodes.length) {
						buildElementLookup(node.childNodes[i]);
					}
					node.parentElement.removeChild(node);
				}
			}
		}
	}
	
	/**
	 * Check if this class has any clientInit functions -- if so add them to the init phase.
	 */
	inline function checkClientInit (inst:Dynamic):Void {
		if (Std.is(inst, ClientOnly)) {
			initFuncs.add(new SFunc(inst, "__hxdomBoot", null));
		}
	}
	
	/**
	 * Sets up a unserialize call by messing with the buffer and position.
	 */
	function doUnserialize (str:String):Dynamic {
		buf = str;
		pos = 0;
		length = str.length;
		
		return unserialize();
	}
	
	public override function unserialize ():Dynamic {
		switch (get(pos)) {
			case 'D'.code:
				//Element ID reference
				pos++;
				var e = elementLookup.get(readDigits());
				if (e == null) throw "Missing element reference!";
				return Reflect.field(e, "__vdom");
			case 'O'.code:
				//Static class reference
				pos++;
				var name = super.unserialize();
				return Type.resolveClass(name);
			case 'c'.code:
				var inst = super.unserialize();
				
				checkClientInit(inst);
				
				return inst;
			default:
				return super.unserialize();
		}
	}
	
	public static function init ():VirtualNode<HtmlElement> {
		#if (js && !use_vdom)
		var html = js.Browser.document.childNodes[1];
		var boot = new Boot();
		boot.buildElementLookup(html);
		boot.unserializeNode(html);
		
		//Run init functions
		for (i in boot.initFuncs) {
			i.call();
		}
		
		//Activate mutation observers if turned on
		var body = Reflect.field(js.Browser.document.body, "__vdom");
		var observe = Reflect.field(body, "__observe");
		if (observe) {
			DomTools.observe(body);
		}
		
		return Reflect.field(html, "__vdom");
		#else
		throw "Only available to JS.";
		return null;
		#end
	}
	
}