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

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    var frc: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    
    @IBOutlet weak var smallMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newPhotosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        return UICollectionViewCell
    }

}
