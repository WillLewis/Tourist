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
    var dataController: DataController!
    var frc: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    var diffableDataSource: UICollectionViewDiffableDataSource<Int, Photo>?
    var diffableSnapshot = NSDiffableDataSourceSnapshot<Int, Photo>()
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    ///TODO:@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newPhotosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self as? UICollectionViewDataSource
        setupFetchedResultsController()
        setupCollectionView()
        setupMap()
        setCollectionFlowLayout()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        setupMap()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        frc = nil
    }
    
    ///TODO: Fix this
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
        performFetch()
    }
    
    func downloadPhotos () {
        if let photos = frc.fetchedObjects {
            photos.forEach { context.delete($0)}
        }
        saveContext()
        FlickrClient.getPhotosByLocation(pin: pin) { (flickrResponse, error) in
            if let response = flickrResponse {
                self.pin.pages = Int32(response.photos.pages)
                self.pin.photos = self.configurePhotoSet(result: response.photos, pin: self.pin) as NSSet?
                self.saveContext()
                self.updateSnapshot()
            } else{
                print("Error creating photos for pin")
            }
        }
    }
    
    func configurePhotoSet(result: FlickrPhotos, pin: Pin) -> Set<Photo>? {
    var photos = Set<Photo>()
        if result.photo.isEmpty {
            return nil
        }
        result.photo.forEach { flickrPhoto in
            let photo = Photo(context: dataController.viewContext)
            photo.id = flickrPhoto.id
            photo.url = flickrPhoto.url
            photo.pin = pin
            photos.insert(photo)
        }
        saveContext()
        updateSnapshot()
        return photos
    }
    
    fileprivate func performFetch(){
        do {
            try frc.performFetch()
            updateSnapshot()
            print("perform fetch worked")
        } catch {
            print(error.localizedDescription)
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func saveContext() {
        do {
            try dataController.viewContext.save()
        } catch {
            fatalError("The save Context could not be performed: \(error.localizedDescription)")
        }
    }
    
    
    fileprivate func setupMap(){
        guard let pin = pin else { return}
        let lat = CLLocationDegrees(pin.latitude)
        let lon = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let regionRadius:CLLocationDistance = 100000
        
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)

        mapView.setRegion(coordinateRegion, animated: false)
        
        mapView.addAnnotation(annotation)
        print("the location showing is")
        print(annotation.coordinate)
        //TODO: configure the map region and delta
    }
    
    //MARK: NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    //MARK: Diffable Data Source
    fileprivate func setupCollectionView(){
        diffableDataSource = UICollectionViewDiffableDataSource.init(collectionView: collectionView, cellProvider: {collectionView, indexPath, photo in
        
        /*diffableDataSource = UICollectionViewDiffableDataSource<Int,Photo> (collectionView: collectionView) {
            (collectionView, indexPath, photo) -> UICollectionViewCell? in
          */
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else {fatalError("Cannot create new cell")}
        
            ///TODO: cell.activityIndicator.startAnimating()
            let photo = self.frc.object(at: indexPath)
            
            guard let imageData = photo.image else{
                FlickrClient.getPhoto(photo: photo) {(imageData, error) in
                    guard let imageData = imageData
                        
                        else {
                        return
                    }
                    cell.photoView.image = UIImage(data: imageData)
                    }
                ///TODO:cell.activityIndicator.stopAnimating()
                print("collection view set")
                return cell
            
            }
            cell.photoView.image = UIImage(data: imageData)
            ///TODO:cell.activityIndicator.stopAnimating()
            print("collection view set")
            return cell
        })
    }
    
    func updateSnapshot() {
        diffableSnapshot = NSDiffableDataSourceSnapshot<Int, Photo>()
        diffableSnapshot.appendSections([0])
        diffableSnapshot.appendItems(frc.fetchedObjects ?? [])
        diffableDataSource?.apply(self.diffableSnapshot)
        print("Snapshot updated")
    }
    
    func setCollectionFlowLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let dimension2 = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension2)
        print("collection flow layout set")
    }
}

    
    
    //TODO: Check Struct conformation to Hashable

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

