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

class PhotoViewController: UIViewController, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var context: NSManagedObjectContext {
        return DataController.sharedInstance.viewContext
    }
    var frc: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newPhotosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
        if collectionView.indexPathsForSelectedItems?.count == 0 {
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
        let space: CGFloat = 2.0
        let dimension = (view.frame.size.width - (2 * space)) / 2.0
        let dimension2 = (view.frame.size.width - (2 * space)) / 4.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension2)
    }
    
    
    //TODO: NSFetchedResultsControllerDelegate (see PVC)
    //TODO: controllerDidChangeContent (see PVC)
    //TODO: UICollectionViewDataSource
}

extension PhotoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frc.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.activityIndicator.startAnimating()
        let photo = frc.object(at: indexPath)
        
        guard let imageData = photo.image else{
            FlickrClient.getPhoto(photo: photo) {(imageData, error) in
                guard let imageData = imageData else {
                    return
                }
                cell.photoView.image = UIImage(data: imageData)
                }
            cell.activityIndicator.stopAnimating()
            return cell
            
        }
        cell.photoView.image = UIImage(data: imageData)
        cell.activityIndicator.stopAnimating()
        return cell
    }
    
}
extension PhotoViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .systemTeal
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

