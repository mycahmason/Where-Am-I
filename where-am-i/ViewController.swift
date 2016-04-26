
/*
 Uses CoreLocation.framework in the project Build Phases
 For location while using the app, add to Info.plist: NSLocationWhenInUseUsageDescription (String) "display text"
 For location ALWAYS, add to Info.plist: NSLocationAlwaysUsageDescription (String) "display text"
 */

import UIKit
import MapKit // Needed for the map
import CoreLocation // Needed for accessing location

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: - Properties
    
    /// Label for displaying Latitude
    @IBOutlet var labelLatitude: UILabel!
    
    /// Label for displaying Longitude
    @IBOutlet var labelLongitude: UILabel!
    
    /// Label for displaying address line 1
    @IBOutlet var labelAddress1: UILabel!
    
    /// Label for displaying address line 2
    @IBOutlet var labelAddress2: UILabel!
    
    /// Map
    @IBOutlet var map: MKMapView!
    
    /// Location manager - for tracking users location
    var locationManager = CLLocationManager()
    
    /// Pin drop (annotation)
    var annotation = MKPointAnnotation()
    
    /// Locations used for overlay (line)
    var myLocations: [CLLocation] = []
    
    // MARK: - View Lifecycle
    
    /// Runs once when view is first loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupLocationManager()
        self.setupMap()
    }
    
    // MARK: - IBActions
    
    /// Change the map view based on selection (Standard, Satellite, Hybrid)
    @IBAction func barBtnChangeMapType(sender: UISegmentedControl) {
        
        switch(sender.selectedSegmentIndex) {
            
        case 0:
            self.map.mapType = MKMapType.Standard
            
        case 1:
            self.map.mapType = MKMapType.Satellite
            
        case 2:
            self.map.mapType = MKMapType.Hybrid
            
        default:
            break
        }
    }
    
    // MARK: - Custom Methods
    
    /// Setup the core location manager instance
    func setupLocationManager() {
        
        // Set locationManager delegate as self
        self.locationManager.delegate = self
        
        // Set for the best location accuracy (tradeoff: uses more battery)
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Get permission to access users location
        self.locationManager.requestWhenInUseAuthorization()
        
        // Start updating users location
        self.locationManager.startUpdatingLocation()
    }
    
    /// Setup the map instance with default location
    func setupMap() {
        
        // Set map delegate as self
        self.map.delegate = self
        
        // Start with default of Cupertino (Apple)
        let latitude: CLLocationDegrees = 37.33233141
        let longitude: CLLocationDegrees = -122.0312186
        
        // Starting zoom level
        let latDelta: CLLocationDegrees = 0.06
        let lonDelta: CLLocationDegrees = 0.06
        
        // 1) Create the SPAN
        let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        // 2) Create the LOCATION
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        
        // 3) Create the REGION with location and span
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        // 4) Set the REGION on the MAP
        self.map.setRegion(region, animated: true)
        
        // 5) Set the pin location (annotation)
        self.annotation.coordinate = location
        
        // 6) Drop the pin (annotation)
        self.map.addAnnotation(self.annotation)
    }
    
    /// Setup the overlay line
    func setupOverlayLine() {
        
        // Get index for most recent 2 locations
        let sourceIndex = self.myLocations.count - 1
        let destinationIndex = self.myLocations.count - 2
        
        // Get coordinates of most recent 2 locations
        let sourceCoordinate = self.myLocations[sourceIndex].coordinate
        let destinationCoordinate = self.myLocations[destinationIndex].coordinate
        
        // Create an overlay line with two most recent points
        var points = [sourceCoordinate, destinationCoordinate]
        let geodesic = MKPolyline(coordinates: &points[0], count: points.count)
        
        // Add the overlay line via the mapView(...) delegate method
        self.map.addOverlay(geodesic)
    }
    
    // MARK: - Delegate Methods
    
    /// Draw the 'overlay' line on the map
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 4
            return polylineRenderer
        }
        
        // Can't return 'nil', has return MKOverlayRenderer
        return MKOverlayRenderer()
    }
    
    /// Use the locationManager func from CLLocationManagerDelegate to get users location
    /// and update the map and pin
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Get the location from the array
        let location = locations[0]
        self.myLocations.append(location)
        
        // Update labels on screen for lat & long
        self.labelLatitude.text = String(location.coordinate.latitude)
        self.labelLongitude.text = String(location.coordinate.longitude)
        
        
        // Using Reverse Geocode Location, get the users nearest address
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            // ERROR
            if (error != nil) {
                print("Reverse geocoder failed with error", error!.localizedDescription)
                return
            }
            
            // The placemark stores data for a given lat & long coordinate (country, state, city, street address, etc)
            
            // As lons as we have a placemark...
            if (placemarks!.count > 0) {
                
                // Grab it from the array
                let pm = placemarks![0]
                
                // Text for updating address labels on UI
                var address1Text: String = ""
                var address2Text: String = ""
                
                // As long as there are values for each, update the string to include the info
                
                // Street #
                if (pm.subThoroughfare != nil) {
                    
                    address1Text += pm.subThoroughfare!
                    address1Text += " "
                }
                
                // Street
                if (pm.thoroughfare != nil) {
                    
                    address1Text += pm.thoroughfare!
                }
                
                // City
                if (pm.locality != nil) {
                    
                    address2Text += pm.locality!
                    address2Text += " "
                }
                
                // State
                if (pm.administrativeArea != nil) {
                    
                    address2Text += pm.administrativeArea!
                    address2Text += " "
                }
                
                // ZIP
                if (pm.postalCode != nil) {
                    
                    address2Text += pm.postalCode!
                }
                
                // Update the UI labels
                self.labelAddress1.text = address1Text
                self.labelAddress2.text = address2Text
                
            } else {
                
                print("Problem with the data received from geocoder")
            }
            
            // As long as we have multiple locations, setup the overlay
            if (self.myLocations.count > 1) {
                
                self.setupOverlayLine()
            }
            
            // Create a 2D location for centering the map and pin drop
            let location2D: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            
            
            // Center the map to the new location
            var region = self.map.region
            region.center = location2D
            self.map.setRegion(region, animated: true)
            
            
            // Move the pin to new location (annotation)
            self.annotation.coordinate = location2D
        })
    }
}

