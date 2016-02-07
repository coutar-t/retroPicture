//
//  SavePictureController.swift
//  RetroPicture
//
//  Created by Thibaut Coutard on 05/02/2016.
//  Copyright © 2016 Thibaut Coutard. All rights reserved.
//

import Foundation
import UIKit

class SavePictureController : UIViewController {
    var myPicture : UIImage?
    
    @IBOutlet weak var myImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myImageView.image = myPicture
    }
    
    @IBAction func OnBackClick(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func OnShareClick(sender: AnyObject) {
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [self.myPicture!],
            applicationActivities: nil)
        let presentationController = activityViewController.popoverPresentationController
        presentationController?.sourceView = sender as! UIView // Needed to support the iPads
        presentationController?.sourceRect = CGRect(
            origin: CGPointZero,
            size: CGSize(width: sender.frame.width, height: sender.frame.height))
        
        //Lets show off
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func OnSaveClick(sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(self.myPicture!, nil, nil, nil)
    }
}
