//
//  MapViewController.swift
//
//  MapViewController.swift
//  ClusterBean MapView
//
//  Created by Sudip on 12/15/18.
//  Copyright © 2018 Sudeepasa. All rights reserved.
//
import UIKit
import GoogleMaps

class MapVC: UIViewController {
  
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var mapView: GMSMapView! //pass the map
  @IBOutlet private weak var mapCenterPinImage: UIImageView!
  @IBOutlet private weak var pinImageVerticalConstraint: NSLayoutConstraint!
  private var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
  private let locationManager = CLLocationManager()
  private let dataProvider = GoogleDataProvider()
  private let searchRadius: Double = 1000 //nearby 100O
  
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self // like in tableview
    locationManager.requestWhenInUseAuthorization() //ask the user for authorization
    mapView.delegate = self
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let navigationController = segue.destination as? UINavigationController,
      let controller = navigationController.topViewController as? TypesTableViewController else {
        return
    }
    controller.selectedTypes = searchedTypes
    controller.delegate = self
  }
  
  private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
    let geocoder = GMSGeocoder()
    
    geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
      self.addressLabel.unlock()
      
      guard let address = response?.firstResult(), let lines = address.lines else {
        return
      }
      
      self.addressLabel.text = lines.joined(separator: "\n")
      
      let labelHeight = self.addressLabel.intrinsicContentSize.height
      self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0,
                                          bottom: labelHeight, right: 0)
      
      UIView.animate(withDuration: 0.25) {
        self.pinImageVerticalConstraint.constant = ((labelHeight - self.view.safeAreaInsets.top) * 0.5)
        self.view.layoutIfNeeded()
      }
    }
  }
  
  func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
    mapView.clear()
    
    dataProvider.fetchPlacesNearCoordinate(coordinate, radius:searchRadius, types: searchedTypes) { places in
      places.forEach {
        let marker = PlaceMarker(place: $0)
        marker.map = self.mapView
      }
    }
  }
  
  @IBAction func refreshPlaces(_ sender: Any) {
    //refresh the current view
    fetchNearbyPlaces(coordinate: mapView.camera.target)
    
  }
}

// MARK: - TypesTableViewControllerDelegate
extension MapVC: TypesTableViewControllerDelegate {
  func typesController(_ controller: TypesTableViewController, didSelectTypes types: [String]) {
    searchedTypes = controller.selectedTypes.sorted()
    dismiss(animated: true)
    fetchNearbyPlaces(coordinate: mapView.camera.target)
  }
}

// MARK: - CLLocationManagerDelegate
extension MapVC: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    guard status == .authorizedWhenInUse else {
      return
    }
    
    locationManager.startUpdatingLocation()
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = true
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else {
      return
    }
    
    mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
    locationManager.stopUpdatingLocation()
    fetchNearbyPlaces(coordinate: location.coordinate)
  }
}

// MARK: - GMSMapViewDelegate
extension MapVC: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    reverseGeocodeCoordinate(position.target)
  }
  
  func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
    addressLabel.lock()
    
    if (gesture) {
      mapCenterPinImage.fadeIn(0.25)
      mapView.selectedMarker = nil
    }
  }
  
  func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
    guard let placeMarker = marker as? PlaceMarker else {
      return nil
    }
    guard let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView else {
      return nil
    }
    
    infoView.nameLabel.text = placeMarker.place.name
    if let photo = placeMarker.place.photo {
      infoView.placePhoto.image = photo
    } else {
      infoView.placePhoto.image = UIImage(named: "generic")
    }
    
    return infoView
  }
  
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    mapCenterPinImage.fadeOut(0.25)
    return false
  }
  
  func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
    mapCenterPinImage.fadeIn(0.25)
    mapView.selectedMarker = nil
    return false
  }
}
