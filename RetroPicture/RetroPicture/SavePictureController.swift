//
//  SavePictureController.swift
//  RetroPicture
//
//  Created by Thibaut Coutard on 05/02/2016.
//  Copyright © 2016 Thibaut Coutard. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary

// View Manage Picture (save, share)
class SavePictureController : UIViewController {
    var myPicture : CIImage!
    
    @IBOutlet weak var myImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myImageView.image = UIImage(CIImage: myPicture, scale: 1, orientation: .Right)
    }
    
    @IBAction func OnBackClick(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func OnShareClick(sender: AnyObject) {
        var sharingItem = [AnyObject]()
        let softwareContext = CIContext(options:[kCIContextUseSoftwareRenderer: true])
        
        // 3
        let cgimg = softwareContext.createCGImage(myPicture, fromRect:myPicture.extent)

        sharingItem.append(UIImage(CGImage:cgimg, scale: 1, orientation: .Right))
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: sharingItem,
            applicationActivities: nil)
        let presentationController = activityViewController.popoverPresentationController
        presentationController?.sourceView = sender as? UIView // Needed to support the iPads
        presentationController?.sourceRect = CGRect(
            origin: CGPointZero,
            size: CGSize(width: sender.frame.width, height: sender.frame.height))
        
        //Lets show off
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func OnSaveClick(sender: AnyObject) {
        // 2
        let softwareContext = CIContext(options:[kCIContextUseSoftwareRenderer: true])
        
        // 3
        let cgimg = softwareContext.createCGImage(myPicture, fromRect:myPicture.extent)
        
        // 4
        let library = ALAssetsLibrary()
        library.writeImageToSavedPhotosAlbum(cgimg,
            metadata:myPicture.properties,
            completionBlock:nil)    }
}
