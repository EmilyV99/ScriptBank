
========================================= 2.53 versions =========================================
To use:
Combine the example global with your global (if you have one; if not, you can just use the example)
Change the parameters in the function call to 'setIcePhysics()' in your global- instructions vary
	per script, and are included in comments in the script file. You can 'CTRL+F' for 'void setIcePhysics'
	to find it.
Make sure to 'import "std.zh"' and 'import "LinkMovement.zh"'
	If you don't have LinkMovement.zh, it is available on the PZC database.

========================================= 2.55 versions =========================================
To use:
Combine the example global with your global (if you have one; if not, you can just use the example)
Change the parameters in the function call to 'setIcePhysics()' in your global- instructions vary
	per script, and are included in comments in the script file. You can 'CTRL+F' for 'void setIcePhysics'
	to find it.

========================================= What do they do? =========================================
The 'ForceSlide' versions function as Pokemon Ice. Sliding on it will slide until you hit a wall,
	including across screen boundaries. The edges of the map count as walls for this purpose.
Any item of the specified item class will disable this ice. (using an itemclass of 0 will make nothing disable it)
	
The 'Slippery' versions function as basic slippery ice. It can be slightly or majorly slippery,
	depending on the 'accel', 'decel', and 'maxspd' parameters you use.
An item of the specified item class will affect this ice. (using an itemclass of 0 will make nothing affect it)
	A level 1 will be ignored; in case you want to combine these scripts, this makes it easier for you.
	A level 2 will halve the acceleration and double the deceleration.
	A level 3 or higher will disable this ice.
