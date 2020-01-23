//
//  ViewController.swift
//  Tourist
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.

import UIKit
import MapKit
import CoreData

class PinViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var context: NSManagedObjectContext {
        return DataController.sharedInstance.viewContext
    }
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pinnedLocation: Pin!
    var isCentered = false
    var centerLocation = CLLocation(latitude: 32.787663, longitude: -96.806163)
    var regionRadius: CLLocationDistance = 100000
    
    
    //MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.navigationItem.title = "Pin A Place"
            if self.isCentered{
                self.centerMapOnLocation(location: self.centerLocation)
            }
            self.setupFetchedResultsController()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.showsUserLocation = false
        setupFetchedResultsController()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(PinViewController.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
        self.isCentered = false
    }
    
    
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .began { return } /// do not generate multiple pins during long press
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let pin = Pin(context: context)
        pin.coordinate = touchMapCoordinate
        pin.latitude = touchMapCoordinate.latitude
        pin.longitude = touchMapCoordinate.longitude
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.addAnnotation(annotation)
        createPhotosForPin(pin: pin)
        try? context.save()
    }
    
   //MARK: Helper functions
    fileprivate func createPhotosForPin(pin: Pin){
        FlickrClient.getPhotosByLocation(pin: pin) {(flickrResponse, error) in
            if let response = flickrResponse {
                pin.pages = Int32(response.photos.pages)
                pin.photos = self.configurePhotoSet(result: response.photos, pin: pin) as NSSet?
                self.saveContext()
            } else {
                print("Error creating photos for pin")
            }
        }
    }
    
    fileprivate func configurePhotoSet(result: FlickrPhotos, pin: Pin) -> Set<Photo>? {
    var photos = Set<Photo>()
        if result.photo.isEmpty {
            return nil
        }
        result.photo.forEach { flickrPhoto in
            let photo = Photo(context: context)
            photo.id = flickrPhoto.id
            photo.url = flickrPhoto.url
            photo.title = flickrPhoto.title
            photo.pin = pin
            photos.insert(photo)
        }
        saveContext()
        return photos
    }
    
    fileprivate func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Save cant be performed \(nserror), \(nserror.userInfo), \(error.localizedDescription)")
        }
    }
        
   fileprivate func setupFetchedResultsController() {
       let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
       let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
       fetchRequest.sortDescriptors = [sortDescriptor]
       fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
       fetchedResultsController.delegate = self
    
       do {
           try fetchedResultsController.performFetch()
           reloadPins()
       } catch {
           fatalError("The fetch could not be performed: \(error.localizedDescription)")
       }
   }
    
    func reloadPins() {
        guard let pins = fetchedResultsController.fetchedObjects else { return }
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewPhotos" {
            let photoVC = segue.destination as! PhotoViewController
            photoVC.dataController = dataController
            photoVC.pin = pinnedLocation
            let backItem = UIBarButtonItem()
            backItem.title = "Back To Pins"
            navigationItem.backBarButtonItem = backItem
            
        }
    }
}
    // MARK: - MKMapViewDelegate
extension PinViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pins = fetchedResultsController.fetchedObjects else {
            print("no fetch pins")
            return
        }
        if let coordinate = view.annotation?.coordinate, let selectedPin = pins.first(where: {$0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude}) {
               pinnedLocation = selectedPin
               performSegue(withIdentifier: "ViewPhotos", sender: self)
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .systemIndigo
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView!.annotation = annotation
            pinView!.displayPriority = .required
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

//MARK: FetchedResultsControllerDelegate
extension PinViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reloadPins()
     }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let point = anObject as? Pin else {
            preconditionFailure("changes should be for map points")
        }
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = point.coordinate
        
        switch type {
        case .insert:
            self.mapView.addAnnotation(pointAnnotation)
            
        case .delete:
            self.mapView.removeAnnotation(pointAnnotation)
        
        default:
            break
        }
    }
}

