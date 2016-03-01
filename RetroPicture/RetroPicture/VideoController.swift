//
//  VideoController.swift
//  RetroPicture
//
//  Created by Thibaut Coutard on 22/02/2016.
//  Copyright © 2016 Thibaut Coutard. All rights reserved.
//

import AVFoundation
import UIKit


// Test with take video only
class VideoController : UIViewController, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var session : AVCaptureSession?
    var torch : AVCaptureDevice?
    var previewLayer:AVCaptureVideoPreviewLayer!;

    var output : AVCaptureMovieFileOutput!
    var connection : AVCaptureConnection?
    
    override func viewDidLoad() {
        setup()
    }
    
    func setup(){
        self.session = AVCaptureSession()
        self.session!.sessionPreset = AVCaptureSessionPresetHigh
        
        // INPUT
        let devices : Array<AVCaptureDevice> = AVCaptureDevice.devices() as! Array<AVCaptureDevice>
        var camera:AVCaptureDevice!
        var microphone:AVCaptureDevice!
        
        for device in devices{
            print("Device name: \(device)")
            if device.hasTorch && device.isTorchModeSupported(AVCaptureTorchMode.On){
                self.torch = device
            }
            if device.hasMediaType(AVMediaTypeAudio){
                microphone = device
            }
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == .Back{
                    print("Device position: back.")
                    camera = device
                }
            }
        }
        
        // audio
        var VideoInput : AVCaptureDeviceInput?
        var audioInput : AVCaptureDeviceInput?
        do {
        if (microphone != nil){
            audioInput = try AVCaptureDeviceInput(device: microphone)
        }
        // video input
        if (camera != nil){
            VideoInput = try AVCaptureDeviceInput(device: camera)
        }
        } catch let error as NSError {
            print("Error when get device : \(error.description)")
        };
        if self.session!.canAddInput(audioInput){
            self.session!.addInput(audioInput);
        }
        if self.session!.canAddInput(VideoInput){
            self.session!.addInput(VideoInput);
        }
        
        let preferredTimeScale:Int32 = 30
        let totalSeconds:Int64 = Int64(Int(7) * Int(preferredTimeScale)) // after 7 sec video recording stop automatically
        let maxDuration:CMTime = CMTimeMake(totalSeconds, preferredTimeScale)
        self.output = AVCaptureMovieFileOutput()
        self.output!.maxRecordedDuration = maxDuration
        
        self.output!.minFreeDiskSpaceLimit = 1024 * 1024
        
        if session!.canAddOutput(self.output){
            session!.addOutput(self.output)
        }
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.connection = self.output.connectionWithMediaType(AVMediaTypeVideo)
        if self.connection!.supportsVideoStabilization == true{
            print("video stabilization avaible")
            self.connection!.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.Auto
        }
        self.connection!.videoOrientation = .PortraitUpsideDown
        
        self.session!.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        print("I'm here")
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
    
    func startRecording(){
        var outputUrl = NSURL(fileURLWithPath: NSTemporaryDirectory() + "test.mp4")
        self.output!.startRecordingToOutputFileURL(outputUrl, recordingDelegate: self)
    }
    
    func stopRecording(){
        self.output!.stopRecording()
    }
    @IBAction func takePictureClick(sender: AnyObject) {
        startRecording()
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!){
        print("Finish recording")
        var success:Bool = false
        if error != 0 && error != nil{
            print("error : \(error)")
            let value: AnyObject? = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey]
            if value == nil{
                success = true
            }else{
                success = false
            }
        }
        if success == true{
            stopRecording()
        }
    }

}