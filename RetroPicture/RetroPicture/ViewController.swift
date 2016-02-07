//
//  ViewController.swift
//  test
//
//  Created by Thibaut Coutard on 10/01/2016.
//  Copyright © 2016 Thibaut Coutard. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    let stillImageOutput = AVCaptureStillImageOutput()
    
    @IBOutlet weak var imageView: UIImageView!
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!;
    var videoDataOutputQueue : dispatch_queue_t!;
    var previewLayer:AVCaptureVideoPreviewLayer!;
    var captureDevice : AVCaptureDevice!
    let session=AVCaptureSession();
    var imageData : UIImage?
    
    @IBAction func takePictureClick(sender: AnyObject) {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
            (imageDataSampleBuffer, error) -> Void in
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
            
            if let currentFilter = CIFilter(name: "CISepiaTone") {
                let beginImage = CIImage(data: data)
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                let filteredImage = UIImage(CIImage: currentFilter.valueForKey(kCIOutputImageKey) as! CIImage!)
                dispatch_async(dispatch_get_main_queue())
                    {
                        self.imageData = filteredImage
                        self.performSegueWithIdentifier("takePicture", sender: sender)
                }
            }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "takePicture") {
            let galleryItemViewController = segue.destinationViewController as? SavePictureController
            galleryItemViewController?.myPicture =  imageData
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        self.session.startRunning()
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if self.session.canAddOutput(stillImageOutput) {
            self.session.addOutput(stillImageOutput)
        }
        self.setupAVCapture();
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
                return false;
        }
        else {
            return true;
        }
    }
}

extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSessionPreset640x480;
        let devices = AVCaptureDevice.devices();
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice;
                    if captureDevice != nil {
                        beginSession();
                        break;
                    }
                }
            }
        }
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            err = error
            deviceInput = nil
        };
        if err != nil {
            print("error: \(err?.localizedDescription)");
        }
        if self.session.canAddInput(deviceInput){
            self.session.addInput(deviceInput);
        }
        
        self.videoDataOutput = AVCaptureVideoDataOutput();
        self.videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue);
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput);
        }
        self.videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true;
        self.videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = AVCaptureVideoOrientation.Portrait
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        session.startRunning();
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        let comicEffect = CIFilter(name: "CISepiaTone")
    
        comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        let filteredImage = UIImage(CIImage: comicEffect!.valueForKey(kCIOutputImageKey) as! CIImage!)
        dispatch_async(dispatch_get_main_queue())
            {
                self.imageView.image = filteredImage
        }

    }
    
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    
}
