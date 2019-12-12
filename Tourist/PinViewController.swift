//
//  ViewController.swift
//  Tourist
//
//  Created by William Lewis on 12/11/19.
//  Copyright © 2019 William Lewis. All rights reserved.

import UIKit
import MapKit
import CoreData

class PinViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    //we implicitly unwrap because we count on its dependency being injected by the AppDelegate
    var dataController: DataController!
    
    
    //fetch gets the data were interested into a context we can access...must be configured with a type
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
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

            self.mapView.delegate = self
            

            if self.isCentered{
                self.centerMapOnLocation(location: self.centerLocation)
            }
            self.setupFetchedResultsController()
            self.reloadInputViews()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME:  Restore Map Region
        //restoreMapRegion(true)
        
        self.mapView.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        self.reloadInputViews()
        setupFetchedResultsController()
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.showsUserLocation = false
        
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
        //do not generate multiple pins during long press
        if gestureRecognizer.state != .began { return }
        
        //get coordinates of the long pressed point
        let touchPoint = gestureRecognizer.location(in: mapView)
        
        //convert location to CLLocationCorrdinate2D
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        //generate pins
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        //set the coordinate
        myPin.coordinate = touchMapCoordinate
        
        //add pins to mapView
        self.mapView.addAnnotation(myPin)
        
//        let album = Album(coordinate: touchMapCoordinate, context: sharedContext)
//        mapView.addAnnotation(album)
    }
    
    //MARK: Helper functions
    fileprivate func setupFetchedResultsController() {
        
        /*this makes fetch request work witha a specific subclass and returns a new fetch request
         initialized with that entity*/
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        //configure the fetch request...with a sort rule
        let sortDescriptor = NSSortDescriptor(key: "place", ascending: false)
        
        //add this sort descriptor to the sort descriptor array
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    // MARK: - MKMapViewDelegate
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
            if let toOpen = view.annotation?.subtitle! {
                UIApplication.shared.open(URL(string: toOpen)!)
            }
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
    }
}
//MARK: FetchedResultsControllerDelegate
extension PinViewController: NSFetchedResultsControllerDelegate {
    
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
        
        case .update:
            self.mapView.removeAnnotation(pointAnnotation)
            self.mapView.addAnnotation(pointAnnotation)

        case .move:
            fatalError("Cant move point because of sort description.")
        
        default:
            break
        }
    }
}

