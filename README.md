FormTouch
=========

[![Build Status](https://travis-ci.org/qmathe/FormTouch.svg?branch=master)](https://travis-ci.org/qmathe/FormTouch)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/tadija/FormTouch/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

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

### Carthage

Add the following line to your Cartfile, run `carthage update` to build the framework and drag the built FormTouch.framework into your Xcode project.

    github "qmathe/FormTouch" to your Cartfile

### Manually

Build FormTouch framework and drop it into your Xcode project.
