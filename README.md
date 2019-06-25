AR-Connect
======
AR-Connect is an iOS application for helping users find each other using augmented reality. Using Firebase, RxSwift, and ARKit, AR Connect provides a simple and easy way to set a meetup location with a friend and find their way there.

![Imgur](https://i.imgur.com/aKan8ro.png?1) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
![Imgur](https://i.imgur.com/gFmgtVL.png?1) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
![Imgur](https://i.imgur.com/1fhIEI4.png?1)
## Motivation

In a crowded city, everyone knows the frustration of coming out of the subway and not knowing which way is North or which street they need to walk down. Often we'll choose our best guess, watch our location indicator move down the wrong street, then turn around and figure it out from there.

Then after that, once you get to where you need to go, you and your friend struggle to figure out the details regarding the exact location of the meet up spot.

*What side of the street are we meeting on?*
*How close are they?*
*Which corner are they standing on?*

**This is the problem I am addressing with AR Connect**

By allowing users to agree on a meetup location, receive their own walking directions and visual path to their meetup spot, and see their path in augmented reality using ARKit, AR Connect provides a simple and intuitive tool for making connecting with friends that much easier.

Users can:
* Request to connect with a user at a chosen meetup location
* Use their camera in AR to see a graphical representation of the shortest path to their meetup spot
* See a visual indicator of their friend's location

*NOTE: User locations are not disclosed until both users agree to connect.*

## Features

* Backend communication using Firebase's Realtime Database
* Reactive design pattern using MVVM and RxSwift
* Geographic coordinate to ARKit Node conversions

## Frameworks/Technologies

* ARKit
* Firebase
* RxSwift/RxCocoa
* MapKit
* Core Location
* SwiftLint

*AR Connect is currently in development.. stay tuned for updates!*
