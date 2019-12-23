//
//  PhotoViewController.swift
//  Tourist
//
//  Created by William Lewis on 12/14/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    var context: NSManagedObjectContext {
        return DataController.sharedInstance.viewContext
    }
    var frc: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newPhotosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: mapView.delegate = self
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        setupMap()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        frc = nil
    }
    
    @IBAction func tapNewCollection (_ sender: Any) {
        if photoCollectionView.indexPathsForSelectedItems?.count == 0 {
            downloadNewPhotos()
        } else {
            deleteSelectedPhoto()
            //TODO: enable Delete Button
        }
    }
    func downloadNewPhotos (){
        //TODO: add code for replacing  collection
        //Step1: delete existing collection
        //Step2: add new photos only if empty
    }
    
    func deleteSelectedPhoto(){
        //TODO: add code for deleting
        
    }
    //MARK: Helper functions
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMap(){
        let lat = CLLocationDegrees(pin.latitude)
        let lon = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        //TODO: configure the map region and delta
        
    }
    
    fileprivate func setCollectionFlowLayout() {
        //TODO: configure collection layout
    }
    
    //TODO: MapViewDelegate extension (see )
    //TODO: NSFetchedResultsControllerDelegate (see PVC)
    //TODO: controllerDidChangeContent (see PVC)
    //TODO: UICollectionViewDataSource
}


