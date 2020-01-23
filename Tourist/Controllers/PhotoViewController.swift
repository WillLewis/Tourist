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
    @IBOutlet weak var newPhotosButton: UIButton!
    
    
    //MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        self.navigationController?.navigationBar.tintColor = UIColor.systemIndigo
        setupFetchedResultsController()
        setupCollectionView()
        setupMap()
        setCollectionFlowLayout()
        reloadPin()
        updateSnapshot()
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        frc = nil
    }
    
    //MARK: UI Methods
    
    ///Delete functionality
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier:nil, previewProvider: nil) { _ in
            let action = UIAction(title: "Delete Picture") { _ in
                let d = self.diffableDataSource
                if let photoToDelete = d?.itemIdentifier(for: indexPath) {
                    var snapshot = self.diffableDataSource?.snapshot()
                    snapshot?.deleteItems([photoToDelete])
                    self.diffableDataSource?.apply(snapshot!)
                    print("deleted", photoToDelete)
                }
            }
            let menu = UIMenu(title: "", children: [action])
            return menu
        }
        saveContext()
        return config
        
    }
    @IBAction func newAlbumButton(_ sender: Any) {
        downloadNewAlbum()
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
    
    //MARK: Photo Data Model Methods
    func downloadNewAlbum () {
        if let photos = frc.fetchedObjects {
            photos.forEach { context.delete($0)}
        }
        saveContext()
        updateSnapshot()
        FlickrClient.getPhotosByLocation(pin: pin) { (flickrResponse, error) in
            if let response = flickrResponse {
                self.pin.pages = Int32(response.photos.pages)
                self.pin.photos = self.configurePhotoSet(result: response.photos, pin: self.pin) as NSSet?
                self.saveContext()
                self.updateSnapshot()
            } else{
                print("Error downloading new album")
            }
        }
        saveContext()
        updateSnapshot()
    }
    
    func configurePhotoSet(result: FlickrPhotos, pin: Pin) -> Set<Photo>? {
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
        updateSnapshot()
        return photos
    }
    
    fileprivate func performFetch(){
        do {
            try frc.performFetch()
            updateSnapshot()
        } catch {
            print(error.localizedDescription)
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func saveContext() {
        do {
            try context.save()
        } catch {
            fatalError("The save Context could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: Map Data Model Methods
    
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
    }
    
    func reloadPin() {
        guard let pin = pin else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.addAnnotation(annotation)
    }
    
    //MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    //MARK: Diffable Data Source
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        performFetch()
    }
    
    fileprivate func setupCollectionView(){
        diffableDataSource = UICollectionViewDiffableDataSource.init(collectionView: collectionView, cellProvider: {collectionView, indexPath, photo in
            /*Alternative: diffableDataSource = UICollectionViewDiffableDataSource<Int,Photo> (collectionView: collectionView) {
             (collectionView, indexPath, photo) -> UICollectionViewCell? in
             */
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else {fatalError("Cannot create new cell")}
            
            cell.activityIndicator.hidesWhenStopped = true
            cell.activityIndicator.startAnimating()
            let photo = self.frc.object(at: indexPath)
            
            guard let imageData = photo.image else{
                FlickrClient.getPhoto(photo: photo) {(imageData, error) in
                    guard let imageData = imageData
                        
                        else {
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
        })
        updateSnapshot()
    }
    
    func updateSnapshot() {
        diffableSnapshot = NSDiffableDataSourceSnapshot<Int, Photo>()
        diffableSnapshot.appendSections([0])
        diffableSnapshot.appendItems(frc.fetchedObjects ?? [])
        diffableDataSource?.apply(self.diffableSnapshot)
        print("Snapshot updated")
    }
    
    
}

extension PhotoViewController: MKMapViewDelegate {
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

