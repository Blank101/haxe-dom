package hxdom.macro;

/**
 * Performs a bunch of macro magic to allow you to instantiate DOM elements.
 * 
 * @author Sam MacPherson
 */
#if js @:autoBuild(hxdom.macro.NodeMacros.buildJS()) #else @:autoBuild(hxdom.macro.NodeMacros.build()) #end
interface DOM {
}