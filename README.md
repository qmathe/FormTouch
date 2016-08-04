FormTouch
=========

FormTouch is a minimalist and extensible form framework that makes it really easy to build static table views and complex nested forms with navigation. Its design is limited to a few core classes, but you can extend it to support new behaviors, cells and controls (slider, segmented control etc.). Out of the box, it includes:

- model/view synchronization layer based on KVO
- extensible integration with control events
- customizable editing cycle
- animated insertion/removal of rows and sections
- section with multiple option rows where a checkmark denotes the current choice
- rows that reproduce UI patterns seen in Settings app
	- label + detail label
	- label + any right aligned control like a switch
	- label + disclosure button to present or push a subcontroller


<img src="http://www.quentinmathe.com/github/Place%20View%206%20Tagged%20-%20iPhone%205.jpg" height="700" alt="Screenshot" />

To see in action, take a look at [Placeboard](http://www.placeboardapp.com) demo video.

Compatibility
-------------

FormTouch requires iOS 8 or higher and Xcode 7 or higher.

Installation
------------

Build FormTouch framework and drop it in your Xcode project.
