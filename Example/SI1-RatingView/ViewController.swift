//
//  ViewController.swift
//  SI1-RatingView
//
//  Created by SI-Du on 06/15/2019.
//  Copyright (c) 2019 SI-Du. All rights reserved.
//

import UIKit
import SI1_RatingView

class ViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var ratingView: RatingView!
    @IBOutlet private weak var ratingValueLabel: UILabel!
    
    // MARK: - Properties
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        configurationView()
    }
    
    // MARK: - Initialization Method
    private func configurationView() {
        ratingView.delegate = self
        ratingView.type = .floatRating
        ratingView.fullImage = UIImage(named: "ic_star_filled")
        ratingView.normalImage = UIImage(named: "ic_star_outline")
        ratingView.maxRatingValue = 6
        ratingView.minRatingValue = 0
        ratingView.currentRatingValue = 4.4
    }
}
// MARK: - RatingViewDelegate
extension ViewController: RatingViewDelegate {
    func ratingView(_ ratingView: RatingView, didUpdate rating: Double) {
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
                let alert = UIAlertController(title: nil, message: "Your rating value: \(rating)", preferredStyle: .alert)
                let cancleButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancleButton)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            print("Your rating value: \(rating)")
        }
    }
    
    func ratingView(_ ratingView: RatingView, isUpdating rating: Double) {
        ratingValueLabel.text = String(rating)
        print("Is update rating view \(rating)")
    }
}

