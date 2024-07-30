//
//  ViewController.swift
//  ARDummy
//
//  Created by Adeel Tahir on 26/12/2022.
//

import UIKit
import SceneKit
import ARKit
import simd
import Photos

class ARBrushViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var recordButton : UIButton!
    
    let vertBrush = VertBrush()
    var buttonDown = false
    
    var clearDrawingButton : UIButton!
    var toggleModeButton : UIButton!
    
    var frameIdx = 0
    var splitLine = false
    var lineRadius : Float = 0.001
    
    var metalLayer: CAMetalLayer! = nil
    var hasSetupPipeline = false
    
    var videoRecorder : MetalVideoRecorder? = nil
    
    var tempVideoUrl : URL? = nil
    
    enum ColorMode : Int {
        case color
        case normal
        case rainbow
    }
    
    var currentColor : SCNVector3 = SCNVector3(1,0.5,0)
    var colorMode : ColorMode = .rainbow
    
    // smooth the pointer position a bit
    var avgPos : SCNVector3! = nil
    
    var recordingOrientation : UIInterfaceOrientationMask? = nil
    var touchLocation : CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        sceneView.delegate = self
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/world.scn")!
        sceneView.scene = scene
        
        metalLayer = self.sceneView.layer as? CAMetalLayer
        
        metalLayer.framebufferOnly = false
        
        addButtons()
        
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(tapHandler))
        tap.minimumPressDuration = 0
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.sceneView.addGestureRecognizer(tap)
        
        PHPhotoLibrary.requestAuthorization { status in
            print(status)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        let sw = self.view.bounds.size.width
        let sh = self.view.bounds.size.height
        
        let off : CGFloat = 50
        clearDrawingButton.center = CGPoint(x: sw - off, y: sh - off )
        toggleModeButton.center = CGPoint(x: off, y: sh - off)
//        recordButton.center = CGPoint(x: sw/2.0, y: sh - off)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let orientation = recordingOrientation {
            return orientation
        } else {
            return .all
        }
    }
    
    //MARK: - TapHandlingMethods
    @objc func tapHandler(gesture: UITapGestureRecognizer) {
        
        if gesture.state == .began {
            self.touchLocation = gesture.location(in: self.sceneView)
            buttonTouchDown()
            
        } else if gesture.state == .ended {
            buttonTouchUp()
        } else if gesture.state == .changed {
            
            if buttonDown {
                self.touchLocation = gesture.location(in: self.sceneView)
            }
        }
    }
    
    func buttonTouchDown() {
        splitLine = true
        buttonDown = true
        avgPos = nil
        //        let pointer = getPointerPosition()
        //        if pointer.valid {
        //            self.addBall(pointer.pos)
        //        }
    }
    
    func buttonTouchUp() {
        buttonDown = false
    }
    
    // MARK: - Buttons
    private func addButtons() {
        
        let c1 = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        let c2 = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 0.4)
        let c3 = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.4)
        
        clearDrawingButton = AppUtility.shared.getRoundyButton(size: 55, imageName: "stop", c1, c2)
        clearDrawingButton.addTarget(self, action:#selector(self.clearDrawing), for: .touchUpInside)
        self.view.addSubview(clearDrawingButton)
        
        toggleModeButton = AppUtility.shared.getRoundyButton(size: 55, imageName: "plus", c1, c3)
        toggleModeButton.addTarget(self, action:#selector(self.toggleColorMode), for: .touchUpInside)
        self.view.addSubview(toggleModeButton)
        
        recordButton.layer.borderColor = UIColor.white.cgColor
        recordButton.layer.borderWidth = 3
//        recordButton = AppUtility.shared.getRoundyButton(size: 55, imageName: "", UIColor.red.withAlphaComponent(0.5), UIColor.red.withAlphaComponent(0.5))
//        recordButton.addTarget(self, action:#selector(self.recordTapped), for: .touchUpInside)
//        recordButton.alpha = 0.5
//        self.view.addSubview(recordButton)
    }
    
    @objc func toggleColorMode() {
        
        Haptics.strongBoom()
        self.colorMode = ColorMode(rawValue: (self.colorMode.rawValue + 1) % 3)!
        
    }
    
    @objc func clearDrawing() {
        
        Haptics.threeWeakBooms()
        vertBrush.clear()
    }
    
    private func startAnimating() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            if self.recordButton.alpha == 1.0 {
                self.recordButton.alpha = 0.0
            } else {
                self.recordButton.alpha = 1.0
            }
        } completion: { _ in
            if let rec = self.videoRecorder, rec.isRecording {
                self.startAnimating()
            } else {
                self.recordButton.alpha = 1.0
            }
        }
    }
    
    @IBAction func recordTapped(_ sender: UIButton?) {
        startAnimating()
        
        if let rec = self.videoRecorder, rec.isRecording {
            
            rec.endRecording {
                
                Haptics.strongBoom()
                
                DispatchQueue.main.async {
//                    self.recordButton.alpha = 0.5
                    self.exportRecordedVideo()
                    self.recordingOrientation = nil
                }
            }
            
        } else {
            
            
            let videoOutUrl = URL.documentsDirectory().appendingPathComponent("temp_video.mp4")
            
            if FileManager.default.fileExists(atPath: videoOutUrl.path) {
                try! FileManager.default.removeItem(at: videoOutUrl)
            }
            
            let size = self.metalLayer.drawableSize
            
            
            Haptics.strongBoom()
            
            let rec = MetalVideoRecorder(outputURL: videoOutUrl, size: size)
            rec?.startRecording()
            
            self.videoRecorder = rec
            
//            self.recordButton.alpha = 1.0
            
            self.tempVideoUrl = videoOutUrl
            
            
            
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                self.recordingOrientation = .landscapeLeft
            case .landscapeRight:
                self.recordingOrientation = .landscapeRight
            case .portrait:
                self.recordingOrientation = .portrait
            case .portraitUpsideDown:
                self.recordingOrientation = .portraitUpsideDown
            case .unknown:
                self.recordingOrientation = nil
            }
            
        }
        
    }
    
    func exportRecordedVideo() {
        
        guard let videoUrl = self.tempVideoUrl else { return }
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
            
        }) { saved, error in
            
            if !saved {
                
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error saving video", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                print(" Video exported")
            }
        }
    }
}

extension ARBrushViewController: UIGestureRecognizerDelegate {
    
    //MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

