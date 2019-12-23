//
//  PhotoView+Extension.swift
//  Tourist
//
//  Created by William Lewis on 12/23/19.
//  Copyright © 2019 William Lewis. All rights reserved.
//

import Foundation
import UIKit

extension PhotoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frc.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        return UICollectionViewCell
    }
}
