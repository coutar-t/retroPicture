//
//  ViewController.swift
//  test
//
//  Created by Thibaut Coutard on 10/01/2016.
//  Copyright © 2016 Thibaut Coutard. All rights reserved.
//

import UIKit
import AVFoundation

// View with cameraPreview
class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    let stillImageOutput = AVCaptureStillImageOutput()
    let mixpanel = Mixpanel.sharedInstanceWithToken("b59b2852f2e7d98331cfb3952b8fee5a")
    
    @IBOutlet weak var imageView: UIImageView!
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!; 
    var videoDataOutputQueue : dispatch_queue_t!;
    var previewLayer:AVCaptureVideoPreviewLayer!;
    var videoDeviceBack : AVCaptureDevice!
    var videoDeviceFront : AVCaptureDevice!
    let session=AVCaptureSession();
    var imageData : CIImage!
    var effect = ["CISepiaTone", "CIPhotoEffectNoir", "CICrystallize", "CIEdges", "CIEdgeWork", "CIGloom", "CIHexagonalPixellate", "CILineOverlay", "CIPixellate", "CIPointillize"]
    var selectedEffect : Int!
    var selectedCamera : Bool!
    var deviceInput:AVCaptureDeviceInput?

    
    @IBAction func changeCameraClick(sender: AnyObject) {
        self.session.removeInput(deviceInput)
        if (selectedCamera==true) {
            do {
                deviceInput = try AVCaptureDeviceInput(device: videoDeviceFront)
            } catch let error as NSError {
                deviceInput = nil
            };

        } else {
            do {
                deviceInput = try AVCaptureDeviceInput(device: videoDeviceBack)
            } catch let error as NSError {
                deviceInput = nil
            };
        }
        selectedCamera = !selectedCamera
        self.session.addInput(deviceInput!)
        self.videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = AVCaptureVideoOrientation.Portrait

        self.session.commitConfiguration()
        
    }
    
    @IBAction func takePictureClick(sender: AnyObject) {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
            (imageDataSampleBuffer, error) -> Void in
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
            
            let beginImage = CIImage(data: data)
            let currentFilter = self.getFilter(beginImage)
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                dispatch_async(dispatch_get_main_queue())
                    {
                        self.imageData = currentFilter.outputImage
                        self.performSegueWithIdentifier("takePicture", sender: sender)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "takePicture") {
            let galleryItemViewController = segue.destinationViewController as? SavePictureController
            galleryItemViewController!.myPicture =  self.imageData
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedCamera = true
        self.selectedEffect = 0
        self.mixpanel.track("FIRST", properties: ["filter" : "1"]);
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        self.session.startRunning()
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if self.session.canAddOutput(stillImageOutput) {
            self.session.addOutput(stillImageOutput)
        }
        self.setupAVCapture();
        
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                self.selectedEffect = self.selectedEffect + 1 >= self.effect.count ? 0 : self.selectedEffect + 1
            case UISwipeGestureRecognizerDirection.Down:
                print("Swiped down")
            case UISwipeGestureRecognizerDirection.Left:
                self.selectedEffect = self.selectedEffect - 1 < 0 ? self.effect.count - 1 : self.selectedEffect - 1
            case UISwipeGestureRecognizerDirection.Up:
                print("Swiped up")
            default:
                break
            }
        }
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
                    videoDeviceBack = device as? AVCaptureDevice;
                }
                if(device.position == AVCaptureDevicePosition.Front) {
                    videoDeviceFront = device as? AVCaptureDevice;
                }
            }
        }
        if videoDeviceBack != nil {
            beginSession();
        }
    }
    
    func beginSession(){
        var err : NSError? = nil
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDeviceBack)
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
    
    func getFilter(cameraImage: CIImage!) -> CIFilter {
        let comicEffect = CIFilter(name: self.effect[self.selectedEffect])
        comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        return comicEffect!
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        let comicEffect = getFilter(cameraImage)
        let filteredImage = UIImage(CIImage: comicEffect.outputImage!)
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
