//
//  PlaceMarker..swift
//  ClusterBean MapView
//
//  Created by Sudip on 12/15/18.
//  Copyright © 2018 Sudeepasa. All rights reserved.

import UIKit
import GoogleMaps

class PlaceMarker: GMSMarker {
  let place: GooglePlace
  
  init(place: GooglePlace) {
    self.place = place
    super.init()
    
    position = place.coordinate
    icon = UIImage(named: place.placeType+"_pin")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = .pop
  }
}
