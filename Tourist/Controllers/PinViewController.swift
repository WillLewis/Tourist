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
    
    /// create an instance of the singleton
    var context: NSManagedObjectContext {
        return DataController.sharedInstance.viewContext
    }
    var dataController: DataController!
    
    ///fetch gets the data were interested into a context we can access...must be configured with a type
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pinnedLocation: Pin!
    
    var isCentered = false
    var centerLocation = CLLocation(latitude: 32.787663, longitude: -96.806163)
    var regionRadius: CLLocationDistance = 100000
    
    
    //MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.navigationItem.title = "Virtual Tourist"
            let edit = UIBarButtonItem(title: "Edit" , style: .plain, target: self, action: #selector(self.edit))
            self.navigationItem.rightBarButtonItem = edit
            
            if self.isCentered{
                self.centerMapOnLocation(location: self.centerLocation)
            }
            self.setupFetchedResultsController()
            //self.reloadInputViews()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.showsUserLocation = false
        setupFetchedResultsController()
        
        //initialize a long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(PinViewController.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
        self.isCentered = false
    }
    
    @objc func edit (){
       
    }
    
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        /// do not generate multiple pins during long press
        if gestureRecognizer.state != .began { return }
        
        /// get coordinates of the long pressed point
        let touchPoint = gestureRecognizer.location(in: mapView)
        
        /// convert location to CLLocationCorrdinate2D
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        /// generate pins
        let pin = Pin(context: context)
        pin.coordinate = touchMapCoordinate
        pin.latitude = touchMapCoordinate.latitude
        pin.longitude = touchMapCoordinate.longitude
        
        /// add pins to mapView
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
                print("Error creating photos for pin \(error?.localizedDescription)")
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
       
       /// configure the fetch request...with a sort rule
       let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
       
       /// add this sort descriptor to the sort descriptor array
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
            guard let pinnedLocation = sender as? Pin else { return }
            photoVC.pin = pinnedLocation
            
            
        }
    }
}
    // MARK: - MKMapViewDelegate
extension PinViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        /*
        let selectedPinAnnotation = mapView.selectedAnnotations.first as? Pin
        let pin = fetchedResultsController.fetchedObjects?.filter { $0.isEqual(selectedPinAnnotation?.coordinate)}.first
         
         print(selectedPinAnnotation?.coordinate ?? "no coordinate for selected pin")
         performSegue(withIdentifier: "ViewPhotos", sender: pin)
        */
        guard let pins = fetchedResultsController.fetchedObjects else {
            print("no fetch pins")
            return
        }
        if let coordinate = view.annotation?.coordinate, let selectedPinAnnotation = pins.first(where: {$0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude}) {
            
            pinnedLocation = selectedPinAnnotation
            print("the pinnned location is")
            print(pinnedLocation.coordinate)
            performSegue(withIdentifier: "ViewPhotos", sender: self)
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
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

